from __future__ import annotations

import argparse
import base64
import fnmatch
import hashlib
import json
import logging
import os
from pathlib import Path
import re
import stat
import subprocess
import sys
import tempfile
import time
from contextlib import ExitStack
from dataclasses import dataclass
from typing import BinaryIO, Callable, Protocol, TypedDict


CHUNK_SIZE: int = 1024 * 1024
LOGGER: logging.Logger = logging.getLogger("rsync")
BOOTSTRAP: str = (
    "import sys,types;"
    "s=sys.stdin.buffer.read(int(sys.stdin.buffer.readline()));"
    "m=types.ModuleType('dotfiles_rsync_worker');"
    "sys.modules[m.__name__]=m;"
    "exec(compile(s,'<dotfiles-rsync>','exec'),m.__dict__);"
    "m.worker()"
)


class SyncError(Exception):
    pass


class Entry(TypedDict):
    kind: str
    size: int
    mtime_ns: int
    ctime_ns: int
    digest: str


class Message(TypedDict, total=False):
    op: str
    path: str
    name: str
    exists: bool
    windows: bool
    item: Entry
    entries: dict[str, Entry]
    protected: list[str]
    exclude: list[str]
    checksum: bool
    offset: int
    content: str
    digest: str
    mtime_ns: int
    error: str


class Endpoint(Protocol):
    def request(self, message: Message) -> Message: ...


class Digest(Protocol):
    def update(self, data: bytes, /) -> None: ...
    def hexdigest(self) -> str: ...


@dataclass(frozen=True)
class Location:
    host: str | None
    path: str
    contents: bool


@dataclass
class Options:
    recursive: bool = False
    times: bool = False
    checksum: bool = False
    dry_run: bool = False
    delete: bool = False
    verbose: bool = True
    progress: bool = True
    stats: bool = False
    quiet: bool = False
    human_readable: bool = False
    exclude: tuple[str, ...] = ()
    modify_window: float = 1.0


@dataclass
class Plan:
    directories: list[str]
    files: list[str]
    deletions: list[str]


def format_size(value: int | float, human: bool = False) -> str:
    if not human:
        return f"{value:,.0f}"
    unit: str
    for unit in ("", "K", "M", "G", "T", "P"):
        if abs(value) < 1000 or unit == "P":
            return f"{value:,.0f}" if not unit else f"{value:.2f}{unit}"
        value /= 1000
    raise AssertionError("Unreachable size unit.")


def format_rate(value: float) -> str:
    unit: str
    for unit in ("B/s", "kB/s", "MB/s", "GB/s", "TB/s"):
        if value < 1024 or unit == "TB/s":
            return f"{value:7.2f}{unit}"
        value /= 1024
    raise AssertionError("Unreachable rate unit.")


def format_duration(seconds: float) -> str:
    total: int = max(0, int(seconds))
    hours: int
    remainder: int
    hours, remainder = divmod(total, 3600)
    minutes: int
    seconds_left: int
    minutes, seconds_left = divmod(remainder, 60)
    return f"{hours}:{minutes:02d}:{seconds_left:02d}"


def display_name(relative: str) -> str:
    # ファイル名に含まれる制御文字を端末の制御シーケンスとして出力しない。
    return "".join(
        f"\\#{ord(character):03o}" if ord(character) < 32 or ord(character) == 127 else character
        for character in relative
    )


class TransferDisplay:
    def __init__(self, options: Options) -> None:
        self.options: Options = options
        self.started: float = time.monotonic()
        self.file_started: float = self.started
        self.last_update: float = -float("inf")
        self.inline: bool = False
        self.width: int = 0
        self.root_file_name: str = "."

    def line(self, text: str = "") -> None:
        if not self.options.quiet:
            self.end_progress()
            print(text, flush=True)

    def end_progress(self) -> None:
        if self.inline:
            print(flush=True)
            self.inline = False
            self.width = 0

    def start_file(self, name: str) -> None:
        if self.options.quiet:
            return
        if self.options.verbose or self.options.progress:
            self.line(display_name(self.root_file_name if name == "." else name))
        self.file_started = time.monotonic()
        self.last_update = -float("inf")

    def progress(
        self, offset: int, size: int, transferred_files: int, remaining: int,
        total_files: int, complete: bool = False,
    ) -> None:
        if self.options.quiet or not self.options.progress or self.options.dry_run:
            return
        now: float = time.monotonic()
        if not complete and now - self.last_update < 1:
            return
        elapsed: float = max(now - self.file_started, 0.000001)
        rate: float = offset / elapsed
        percent: int = 100 if complete else min(99, int(offset * 100 / max(size, 1)))
        duration: str = (
            format_duration(elapsed) if complete
            else format_duration((size - offset) / rate) if rate else "--:--:--"
        )
        suffix: str = (
            f" (xfr#{transferred_files}, to-chk={remaining}/{total_files})" if complete else ""
        )
        text: str = (
            f"{format_size(offset, self.options.human_readable):>15} {percent:3d}% "
            f"{format_rate(rate)} {duration:>10}{suffix}"
        )
        if sys.stdout.isatty():
            print("\r" + text.ljust(self.width), end="", flush=True)
            self.inline = True
            self.width = len(text)
            if complete:
                self.end_progress()
        else:
            print(text, flush=True)
        self.last_update = now

    def finish(
        self, entries: dict[str, Entry], existing: dict[str, Entry], plan: Plan,
        transferred: int, source: Endpoint, destination: Endpoint, scan_seconds: float,
    ) -> None:
        if self.options.quiet:
            return
        elapsed: float = max(time.monotonic() - self.started, 0.000001)
        total_size: int = sum(item["size"] for item in entries.values() if item["kind"] == "file")
        planned_size: int = sum(entries[path]["size"] for path in plan.files)
        files: int = sum(item["kind"] == "file" for item in entries.values())
        directories: int = len(entries) - files
        size: Callable[[int | float], str] = lambda value: format_size(
            value, self.options.human_readable
        )
        self.line()
        if self.options.stats:
            self.line(f"Number of files: {len(entries):,} (reg: {files:,}, dir: {directories:,})")
            self.line(f"Number of created files: {len(entries.keys() - existing.keys()):,}")
            self.line(f"Number of deleted files: {len(plan.deletions):,}")
            self.line(f"Number of regular files transferred: {len(plan.files):,}")
            self.line(f"Total file size: {size(total_size)} bytes")
            self.line(f"Total transferred file size: {size(planned_size)} bytes")
            self.line(f"Literal data: {size(transferred)} bytes")
            self.line("Matched data: 0 bytes")
            self.line(f"File list generation time: {scan_seconds:.3f} seconds")
            self.line(f"Total run time: {elapsed:.3f} seconds")
            self.line()
        remote: list[RemoteEndpoint] = [
            endpoint for endpoint in (source, destination) if isinstance(endpoint, RemoteEndpoint)
        ]
        if remote:
            sent: int = sum(endpoint.sent_bytes for endpoint in remote)
            received: int = sum(endpoint.received_bytes for endpoint in remote)
            self.line(
                f"sent {size(sent)} bytes  received {size(received)} bytes  "
                f"{size((sent + received) / elapsed)} bytes/sec"
            )
        else:
            self.line(
                f"transferred {size(transferred)} bytes  {size(transferred / elapsed)} bytes/sec"
            )
        final: str = f"total size is {size(total_size)}"
        if remote:
            final += f"  speedup is {total_size / max(sent + received, 1):.2f}"
        self.line(final + (" (DRY RUN)" if self.options.dry_run else ""))


def parse_location(value: str) -> Location:
    if not value:
        raise SyncError("An empty path is not allowed.")
    if value.startswith("rsync://") or "::" in re.sub(r"\[[^\]]+\]", "ipv6", value):
        raise SyncError("rsync daemon URLs and double-colon syntax are not supported.")
    contents: bool = value.endswith(("/", "\\"))
    if re.match(r"^[A-Za-z]:", value) or value.startswith(("\\\\", "/", ".\\", "./")):
        return Location(None, value, contents)
    match: re.Match[str] | None = re.fullmatch(
        r"(?P<host>(?:[^@:\s]+@)?\[[^\]]+\]|[^/\\:\s]+):(?P<path>.+)", value
    )
    if match is None:
        return Location(None, value, contents)
    host: str = match["host"]
    if host.startswith("-"):
        raise SyncError("An SSH host must not start with '-'.")
    return Location(host, match["path"], contents)


def is_link(info: os.stat_result) -> bool:
    return stat.S_ISLNK(info.st_mode) or bool(
        getattr(info, "st_file_attributes", 0) & stat.FILE_ATTRIBUTE_REPARSE_POINT
    )


def checked_path(path: Path) -> Path:
    absolute: Path = Path(os.path.abspath(path.expanduser()))
    for candidate in (*reversed(absolute.parents), absolute):
        try:
            info: os.stat_result = candidate.lstat()
        except FileNotFoundError:
            continue
        if is_link(info):
            raise SyncError(f"Links and reparse points are not supported: {candidate}")
    return absolute


def file_digest(path: Path) -> str:
    digest: Digest = hashlib.sha256()
    with path.open("rb") as stream:
        block: bytes
        while block := stream.read(CHUNK_SIZE):
            digest.update(block)
    return digest.hexdigest()


def entry_for(path: Path, checksum: bool = False) -> Entry:
    info: os.stat_result = path.lstat()
    if is_link(info):
        raise SyncError(f"Links and reparse points are not supported: {path}")
    if not (stat.S_ISDIR(info.st_mode) or stat.S_ISREG(info.st_mode)):
        raise SyncError(f"Only regular files and directories are supported: {path}")
    item: Entry = {
        "kind": "dir" if stat.S_ISDIR(info.st_mode) else "file",
        "size": info.st_size,
        "mtime_ns": info.st_mtime_ns,
        "ctime_ns": info.st_ctime_ns,
        "digest": "",
    }
    if checksum and item["kind"] == "file":
        item["digest"] = file_digest(path)
        verify_entry(path, item)
    return item


def verify_entry(path: Path, expected: Entry) -> None:
    actual: Entry = entry_for(path)
    if (
        actual["kind"] != expected["kind"]
        or actual["size"] != expected["size"]
        or actual["mtime_ns"] != expected["mtime_ns"]
        or actual["ctime_ns"] != expected["ctime_ns"]
    ):
        raise SyncError(f"File changed during synchronization: {path}")


def excluded(relative: str, directory: bool, patterns: list[str]) -> bool:
    pattern: str
    for pattern in patterns:
        if pattern.endswith("/") and not directory:
            continue
        trimmed: str = pattern.rstrip("/")
        target: str = relative if "/" in trimmed else relative.rsplit("/", 1)[-1]
        if fnmatch.fnmatchcase(target, trimmed.lstrip("/")):
            return True
    return False


def validate_name(name: str, windows: bool) -> None:
    if name in ("", ".", "..") or "/" in name or "\\" in name or "\x00" in name:
        raise SyncError(f"Unsafe or non-portable filename: {name!r}")
    if windows and (
        re.search(r'[<>:"|?*\x00-\x1f]', name)
        or name.endswith((".", " "))
        or re.fullmatch(
            r"(CON|PRN|AUX|NUL|CONIN\$|CONOUT\$|COM[1-9\u00b9\u00b2\u00b3]|"
            r"LPT[1-9\u00b9\u00b2\u00b3])(?:\..*)?", name, re.IGNORECASE
        )
    ):
        raise SyncError(f"Filename cannot be represented on Windows: {name!r}")


class FileService:
    def __init__(self) -> None:
        self.root: Path | None = None
        self.upload: BinaryIO | None = None
        self.temporary: Path | None = None
        self.upload_path: Path | None = None

    def close(self) -> None:
        if self.upload is not None:
            self.upload.close()
            self.upload = None
        if self.temporary is not None:
            self.temporary.unlink(missing_ok=True)
            self.temporary = None

    def path(self, relative: str) -> Path:
        if self.root is None:
            raise SyncError("No synchronization root has been configured.")
        if relative == ".":
            return checked_path(self.root)
        part: str
        parts: list[str] = relative.split("/")
        for part in parts:
            validate_name(part, os.name == "nt")
        return checked_path(self.root.joinpath(*parts))

    def scan(self, patterns: list[str], checksum: bool) -> Message:
        root: Path = self.path(".")
        entries: dict[str, Entry] = {}
        protected: list[str] = []
        if not root.exists():
            return {
                "entries": entries, "protected": protected, "windows": os.name == "nt",
                "name": root.name,
            }
        pending: list[tuple[Path, str]] = [(root, ".")]
        while pending:
            path: Path
            relative: str
            path, relative = pending.pop()
            item: Entry = entry_for(path, checksum)
            entries[relative] = item
            if item["kind"] == "dir":
                child: Path
                for child in sorted(path.iterdir(), reverse=True):
                    child_relative: str = child.name if relative == "." else f"{relative}/{child.name}"
                    info: os.stat_result = child.lstat()
                    if excluded(child_relative, stat.S_ISDIR(info.st_mode), patterns):
                        protected.append(child_relative)
                        continue
                    validate_name(child.name, False)
                    pending.append((child, child_relative))
        return {
            "entries": entries, "protected": protected, "windows": os.name == "nt",
            "name": root.name,
        }

    def request(self, message: Message) -> Message:
        operation: str = message["op"]
        if operation in ("inspect", "configure"):
            path: Path = checked_path(Path(message["path"]))
            if os.name == "nt":
                component: str
                for component in path.parts[1:]:
                    validate_name(component, True)
            response: Message = {
                "path": str(path),
                "name": path.name,
                "windows": os.name == "nt",
                "exists": path.exists(),
            }
            if response["exists"]:
                response["item"] = entry_for(path)
            if operation == "configure":
                self.root = path
            return response
        if operation == "join":
            validate_name(message["name"], os.name == "nt")
            return {"path": str(Path(message["path"]) / message["name"])}
        if operation == "scan":
            return self.scan(message["exclude"], message["checksum"])
        if operation == "validate":
            seen: set[str] = set()
            relative: str
            for relative in message["entries"]:
                path = self.path(relative)
                key: str = str(path).casefold() if os.name == "nt" else str(path)
                if key in seen:
                    raise SyncError(f"Filename collision on destination: {relative}")
                seen.add(key)
            return {}
        path = self.path(message["path"])
        if operation == "verify":
            verify_entry(path, message["item"])
        elif operation == "digest":
            verify_entry(path, message["item"])
            digest: str = file_digest(path)
            verify_entry(path, message["item"])
            return {"digest": digest}
        elif operation == "read":
            verify_entry(path, message["item"])
            with path.open("rb") as source:
                source.seek(message["offset"])
                content: bytes = source.read(CHUNK_SIZE)
            verify_entry(path, message["item"])
            return {"content": base64.b64encode(content).decode("ascii")}
        elif operation == "mkdir":
            path.mkdir(parents=True, exist_ok=True)
        elif operation == "begin":
            if self.upload is not None:
                raise SyncError("A transfer is already in progress.")
            if path.exists() and not path.is_file():
                raise SyncError(f"Cannot replace a directory with a file: {path}")
            path.parent.mkdir(parents=True, exist_ok=True)
            self.upload = tempfile.NamedTemporaryFile(
                mode="w+b", prefix=".dotfiles-rsync-", dir=path.parent, delete=False
            )
            self.temporary = Path(self.upload.name)
            self.upload_path = path
        elif operation == "write":
            if self.upload is None or path != self.upload_path:
                raise SyncError("No matching transfer is in progress.")
            if self.upload.tell() != message["offset"]:
                raise SyncError("Unexpected transfer offset.")
            self.upload.write(base64.b64decode(message["content"], validate=True))
        elif operation == "commit":
            if self.upload is None or self.temporary is None or path != self.upload_path:
                raise SyncError("No matching transfer is in progress.")
            self.upload.flush()
            os.fsync(self.upload.fileno())
            self.upload.close()
            self.upload = None
            if file_digest(self.temporary) != message["digest"]:
                raise SyncError(f"Transfer checksum mismatch: {path}")
            if "mtime_ns" in message:
                os.utime(self.temporary, ns=(message["mtime_ns"], message["mtime_ns"]))
            # 既存ファイルの属性は維持し、新規ファイルは安全な一時ファイルの権限を使う。
            if path.exists():
                os.chmod(self.temporary, stat.S_IMODE(path.stat().st_mode))
            checked_path(path)
            os.replace(self.temporary, path)
            self.temporary = None
            self.upload_path = None
        elif operation == "time":
            os.utime(path, ns=(message["mtime_ns"], message["mtime_ns"]))
        elif operation == "delete":
            if message["path"] == ".":
                raise SyncError("Refusing to delete the synchronization root.")
            if message["item"]["kind"] == "dir":
                # 子の削除で時刻が変わるため、型を確認して空ディレクトリだけを削除する。
                if entry_for(path)["kind"] != "dir":
                    raise SyncError(f"Destination directory changed: {path}")
                path.rmdir()
            else:
                verify_entry(path, message["item"])
                path.unlink()
        else:
            raise SyncError(f"Unknown worker operation: {operation}")
        return {}


def encode_message(message: Message) -> bytes:
    return (json.dumps(message, ensure_ascii=True) + "\n").encode("ascii")


def decode_message(line: bytes) -> Message:
    message: Message = json.loads(line)
    if not isinstance(message, dict):
        raise SyncError("Invalid worker response.")
    return message


def worker() -> None:
    service: FileService = FileService()
    try:
        line: bytes
        for line in sys.stdin.buffer:
            try:
                response: Message = service.request(decode_message(line))
            except (OSError, ValueError, KeyError, SyncError) as error:
                response = {"error": str(error)}
            sys.stdout.buffer.write(encode_message(response))
            sys.stdout.buffer.flush()
            if "error" in response:
                break
    finally:
        service.close()


def ssh_command(host: str, port: int | None) -> list[str]:
    # IPv6 の角括弧は rsync 形式の区切りであり、ssh に渡すホスト名には含めない。
    host = re.sub(r"\[([^\]]+)\]$", r"\1", host)
    command: list[str] = ["ssh", "-T"]
    if port is not None:
        command.extend(["-p", str(port)])
    command.append(host)
    return command


def python_command(executable: str, code: str, shell: str = "sh") -> str:
    if not re.fullmatch(r"[\w .:\\/+-]+", executable) or executable.startswith("-"):
        raise SyncError("Unsafe remote Python executable. Specify an executable path, not a command.")
    invocation: str = executable
    if not re.fullmatch(r"[\w.+-]+", executable):
        invocation = f'"{executable}"'
        if shell == "powershell":
            invocation = "& " + invocation
        elif shell == "cmd":
            invocation = "call " + invocation
    # 二重引用符内のコードにはシェル展開文字を含めず、cmd/PowerShell/sh で共有する。
    return f'{invocation} -u -c "{code}"'


def detect_remote_shell(command: list[str]) -> str:
    probe: subprocess.CompletedProcess[bytes] = subprocess.run(
        [*command, "echo $PSVersionTable.PSVersion.Major"],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
    )
    output: str = probe.stdout.decode("utf-8", errors="replace").strip()
    if probe.returncode == 0:
        if output.isdigit():
            return "powershell"
        if output == "$PSVersionTable.PSVersion.Major":
            return "cmd"
        if output == ".PSVersion.Major":
            return "sh"
    raise SyncError(
        "Cannot detect the remote shell. Use --remote-shell sh, cmd, or powershell. "
        + probe.stderr.decode("utf-8", errors="replace").strip()
    )


class RemoteEndpoint:
    def __init__(
        self, location: Location, port: int | None, executable: str | None,
        shell: str = "auto",
    ) -> None:
        if location.host is None:
            raise SyncError("A remote host is required.")
        command: list[str] = ssh_command(location.host, port)
        if shell == "auto":
            shell = (
                detect_remote_shell(command)
                if executable and not re.fullmatch(r"[\w.+-]+", executable)
                else "sh"
            )
        candidates: tuple[str, ...] = (executable,) if executable else ("python3", "python")
        failures: list[str] = []
        candidate: str
        for candidate in candidates:
            probe: subprocess.CompletedProcess[bytes] = subprocess.run(
                [
                    *command,
                    python_command(candidate, "import sys;sys.exit(sys.version_info<(3,10))", shell),
                ],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
            )
            if probe.returncode == 0:
                break
            detail: str = probe.stderr.decode("utf-8", errors="replace").strip()
            failures.append(f"{candidate}: exit {probe.returncode}: {detail}")
            LOGGER.debug("Remote Python probe failed: %s", failures[-1])
            if probe.returncode == 255:
                raise SyncError(f"SSH connection failed: {detail}")
        else:
            raise SyncError("Remote Python 3.10+ was not found. " + "; ".join(failures))
        self.process: subprocess.Popen[bytes] = subprocess.Popen(
            [*command, python_command(candidate, BOOTSTRAP, shell)],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
        )
        if self.process.stdin is None or self.process.stdout is None:
            raise SyncError("Cannot create SSH protocol streams.")
        self.input: BinaryIO = self.process.stdin
        self.output: BinaryIO = self.process.stdout
        self.closed: bool = False
        self.sent_bytes: int = 0
        self.received_bytes: int = 0
        try:
            source: bytes = Path(__file__).read_bytes()
            header: bytes = f"{len(source)}\n".encode("ascii")
            self.input.write(header)
            self.input.write(source)
            self.input.flush()
            self.sent_bytes += len(header) + len(source)
        except (OSError, ValueError):
            self.close()
            raise

    def request(self, message: Message) -> Message:
        payload: bytes = encode_message(message)
        self.input.write(payload)
        self.input.flush()
        self.sent_bytes += len(payload)
        line: bytes = self.output.readline()
        self.received_bytes += len(line)
        if not line:
            raise SyncError("SSH worker disconnected before completing the operation.")
        response: Message = decode_message(line)
        if "error" in response:
            raise SyncError(f"Remote: {response['error']}")
        return response

    def close(self) -> None:
        if self.closed:
            return
        self.closed = True
        failure: str = ""
        try:
            self.input.close()
        except BrokenPipeError:
            LOGGER.debug("SSH input pipe was already closed.")
        try:
            self.process.wait(timeout=10)
        except subprocess.TimeoutExpired:
            failure = "SSH worker did not exit after its input was closed."
            self.process.terminate()
            try:
                self.process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.process.kill()
                self.process.wait()
        finally:
            self.output.close()
        if self.process.returncode != 0:
            failure = failure or f"SSH worker exited with code {self.process.returncode}."
        if failure:
            if sys.exc_info()[0] is not None:
                LOGGER.error("%s", failure)
            else:
                raise SyncError(failure)


def configure_endpoints(
    source: Endpoint, destination: Endpoint, source_location: Location,
    destination_location: Location, options: Options,
) -> tuple[Message, Message]:
    source_info: Message = source.request({"op": "configure", "path": source_location.path})
    destination_info: Message = destination.request(
        {"op": "inspect", "path": destination_location.path}
    )
    if not source_info["exists"]:
        raise SyncError(f"Source does not exist: {source_location.path}")
    directory: bool = source_info["item"]["kind"] == "dir"
    if source_location.contents and not directory:
        raise SyncError("A trailing separator requires a directory source.")
    if directory and not options.recursive:
        raise SyncError("Directory sources require -r / --recursive.")
    target: str = destination_info["path"]
    if destination_info["exists"] and destination_info["item"]["kind"] == "dir":
        if not directory or not source_location.contents:
            if not source_info["name"]:
                raise SyncError("A filesystem root source requires a trailing separator.")
            target = destination.request({
                "op": "join", "path": target, "name": source_info["name"]
            })["path"]
    destination_info = destination.request({"op": "configure", "path": target})
    if source_location.host is None and destination_location.host is None:
        source_path: Path = Path(source_info["path"])
        destination_path: Path = Path(destination_info["path"])
        if (
            source_path == destination_path
            or source_path in destination_path.parents
            or destination_path in source_path.parents
        ):
            raise SyncError("Source and destination must not overlap.")
    return source_info, destination_info


def make_plan(
    source: dict[str, Entry], destination: dict[str, Entry],
    protected: list[str], options: Options,
) -> Plan:
    directories: list[str] = []
    files: list[str] = []
    relative: str
    item: Entry
    for relative, item in source.items():
        existing: Entry | None = destination.get(relative)
        if existing is not None and item["kind"] != existing["kind"]:
            raise SyncError(f"File/directory type conflict: {relative}")
        if item["kind"] == "dir":
            if existing is None:
                directories.append(relative)
        elif (
            existing is None
            or item["size"] != existing["size"]
            or (options.checksum and item["digest"] != existing["digest"])
            or (
                not options.checksum
                and abs(item["mtime_ns"] - existing["mtime_ns"])
                > options.modify_window * 1_000_000_000
            )
        ):
            files.append(relative)
    deletions: list[str] = []
    if options.delete:
        for relative in destination.keys() - source.keys():
            if relative == ".":
                continue
            if any(path == relative or path.startswith(relative + "/") for path in protected):
                continue
            deletions.append(relative)
    return Plan(
        sorted(directories, key=lambda path: path.count("/")),
        sorted(files),
        sorted(deletions, key=lambda path: (path.count("/"), path), reverse=True),
    )


def transfer_file(
    source: Endpoint, destination: Endpoint, relative: str, item: Entry, options: Options,
    display: TransferDisplay, transferred_files: int, remaining: int, total_files: int,
) -> int:
    display.start_file(relative)
    try:
        destination.request({"op": "begin", "path": relative})
        offset: int = 0
        digest: Digest = hashlib.sha256()
        display.progress(0, item["size"], transferred_files, remaining, total_files)
        while offset < item["size"]:
            response: Message = source.request({
                "op": "read", "path": relative, "offset": offset, "item": item
            })
            content: bytes = base64.b64decode(response["content"], validate=True)
            if not content or len(content) > item["size"] - offset:
                raise SyncError(f"Source size changed during transfer: {relative}")
            digest.update(content)
            destination.request({
                "op": "write", "path": relative, "offset": offset, "content": response["content"]
            })
            offset += len(content)
            if offset < item["size"]:
                display.progress(offset, item["size"], transferred_files, remaining, total_files)
        source.request({"op": "verify", "path": relative, "item": item})
        if item["digest"] and digest.hexdigest() != item["digest"]:
            raise SyncError(f"Source checksum changed during transfer: {relative}")
        commit: Message = {"op": "commit", "path": relative, "digest": digest.hexdigest()}
        if options.times:
            commit["mtime_ns"] = item["mtime_ns"]
        destination.request(commit)
        display.progress(offset, item["size"], transferred_files, remaining, total_files, complete=True)
        return offset
    finally:
        display.end_progress()


def synchronize(
    source: Endpoint, destination: Endpoint, options: Options,
    display: TransferDisplay | None = None,
) -> None:
    if display is None:
        display = TransferDisplay(options)
    if options.verbose or options.progress:
        display.line("building file list ...")
    scan_started: float = time.monotonic()
    request: Message = {"op": "scan", "exclude": list(options.exclude), "checksum": options.checksum}
    source_scan: Message = source.request(request)
    destination_scan: Message = destination.request(request)
    scan_seconds: float = time.monotonic() - scan_started
    if options.verbose or options.progress:
        display.line("done")
    entries: dict[str, Entry] = source_scan["entries"]
    display.root_file_name = source_scan["name"]
    if not entries:
        raise SyncError("Source disappeared before synchronization.")
    destination.request({"op": "validate", "entries": entries})
    existing: dict[str, Entry] = destination_scan["entries"]
    if destination_scan["windows"]:
        # Windows では既存項目の大文字小文字だけが違っても、同じ同期先として扱う。
        spelling: dict[str, str] = {path.casefold(): path for path in entries}
        existing = {spelling.get(path.casefold(), path): item for path, item in existing.items()}
    plan: Plan = make_plan(
        entries, existing, destination_scan["protected"], options
    )
    relative: str
    if not options.checksum:
        candidates: list[str] = [
            path for path in plan.files
            if path in existing and entries[path]["size"] == existing[path]["size"]
        ]
        if candidates and (options.verbose or options.progress):
            display.line("comparing file contents ...")
        unchanged: set[str] = set()
        for relative in candidates:
            # 時刻の違いだけでは再送せず、両端で計算したハッシュだけを交換する。
            source_digest: str = source.request({
                "op": "digest", "path": relative, "item": entries[relative],
            })["digest"]
            destination_digest: str = destination.request({
                "op": "digest", "path": relative, "item": existing[relative],
            })["digest"]
            if source_digest == destination_digest:
                unchanged.add(relative)
        plan.files = [path for path in plan.files if path not in unchanged]
    transferred: int = 0
    for relative in plan.directories:
        if options.verbose or options.dry_run:
            display.line(display_name(relative) + "/")
        if not options.dry_run:
            destination.request({"op": "mkdir", "path": relative})
    file_order: dict[str, int] = {
        path: index for index, path in enumerate(sorted(
            path for path, item in entries.items() if item["kind"] == "file"
        ), start=1)
    }
    transferred_files: int = 0
    for relative in plan.files:
        if options.dry_run:
            display.line(display_name(source_scan["name"] if relative == "." else relative))
        else:
            transferred_files += 1
            transferred += transfer_file(
                source, destination, relative, entries[relative], options, display,
                transferred_files, len(file_order) - file_order[relative], len(file_order),
            )
    if not options.dry_run:
        # 削除前に走査全体を再検証し、追加・削除・変更されたコピー元を検出する。
        if options.verbose or options.progress:
            display.line("verifying source ...")
        current: dict[str, Entry] = source.request(request)["entries"]
        if current != entries:
            raise SyncError("Source tree changed; destination deletion was not performed.")
    for relative in plan.deletions:
        if options.verbose or options.dry_run:
            display.line("deleting " + display_name(relative))
        if not options.dry_run:
            item: Entry = existing[relative]
            destination.request({"op": "delete", "path": relative, "item": item})
    if options.times and not options.dry_run:
        for relative in sorted(entries, key=lambda path: path.count("/"), reverse=True):
            destination.request({
                "op": "time", "path": relative, "mtime_ns": entries[relative]["mtime_ns"]
            })
    display.finish(entries, existing, plan, transferred, source, destination, scan_seconds)


def argument_parser() -> argparse.ArgumentParser:
    parser: argparse.ArgumentParser = argparse.ArgumentParser(
        description="Whole-file synchronization over SSH (not the rsync wire protocol).",
        allow_abbrev=False, add_help=False,
    )
    parser.add_argument("--help", action="help", help="show this help message and exit")
    parser.add_argument("-r", "--recursive", action="store_true")
    parser.add_argument("-t", "--times", action="store_true")
    parser.add_argument("-c", "--checksum", action="store_true")
    parser.add_argument("-n", "--dry-run", action="store_true")
    parser.add_argument(
        "-v", "--verbose", action=argparse.BooleanOptionalAction, default=True,
        help="show file names and phases (default: enabled)",
    )
    parser.add_argument("-q", "--quiet", action="store_true", help="suppress non-error output")
    parser.add_argument("-h", "--human-readable", action="store_true", help="use readable size units")
    parser.add_argument("--delete", action="store_true")
    parser.add_argument("--exclude", action="append", default=[])
    parser.add_argument(
        "--progress", action=argparse.BooleanOptionalAction, default=True,
        help="show per-file percentage, speed, and ETA (default: enabled)",
    )
    parser.add_argument("--stats", action="store_true")
    parser.add_argument("--modify-window", type=float, default=1.0, metavar="SECONDS")
    parser.add_argument("--port", type=int)
    parser.add_argument("--remote-python", metavar="EXECUTABLE")
    parser.add_argument(
        "--remote-shell", default="auto", choices=("auto", "sh", "cmd", "powershell"),
        help="remote SSH login shell; auto detects it when an executable path needs quoting",
    )
    parser.add_argument(
        "--log-level", default="INFO",
        choices=("DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"),
    )
    parser.add_argument("source")
    parser.add_argument("destination")
    return parser


def main() -> int:
    parser: argparse.ArgumentParser = argument_parser()
    arguments: argparse.Namespace = parser.parse_args()
    logging.basicConfig(level=arguments.log_level, format="%(levelname)s: %(message)s")
    options: Options = Options(
        recursive=arguments.recursive, times=arguments.times, checksum=arguments.checksum,
        dry_run=arguments.dry_run, delete=arguments.delete, verbose=arguments.verbose,
        progress=arguments.progress, stats=arguments.stats, exclude=tuple(arguments.exclude),
        modify_window=arguments.modify_window, quiet=arguments.quiet,
        human_readable=arguments.human_readable,
    )
    try:
        if sys.version_info < (3, 10):
            raise SyncError("Python 3.10 or later is required.")
        if not 0 <= options.modify_window < float("inf"):
            raise SyncError("--modify-window must be finite and nonnegative.")
        if arguments.port is not None and not 1 <= arguments.port <= 65535:
            raise SyncError("--port must be between 1 and 65535.")
        source_location: Location = parse_location(arguments.source)
        destination_location: Location = parse_location(arguments.destination)
        if source_location.host is not None and destination_location.host is not None:
            raise SyncError("Remote-to-remote synchronization is not supported.")
        display: TransferDisplay = TransferDisplay(options)
        if options.verbose or options.progress:
            remote_host: str | None = source_location.host or destination_location.host
            if remote_host is not None:
                display.line(f"connecting to {display_name(remote_host)} ...")
            else:
                display.line("preparing synchronization ...")
        with ExitStack() as stack:
            source: Endpoint
            destination: Endpoint
            source = create_endpoint(
                source_location, arguments.port, arguments.remote_python, arguments.remote_shell, stack
            )
            destination = create_endpoint(
                destination_location, arguments.port, arguments.remote_python, arguments.remote_shell,
                stack,
            )
            configure_endpoints(source, destination, source_location, destination_location, options)
            synchronize(source, destination, options, display)
        return 0
    except (OSError, ValueError, SyncError) as error:
        LOGGER.error("%s", error)
        return 1
    except KeyboardInterrupt:
        LOGGER.error("Synchronization interrupted.")
        return 130


def create_endpoint(
    location: Location, port: int | None, executable: str | None, shell: str, stack: ExitStack,
) -> Endpoint:
    if location.host is None:
        local: FileService = FileService()
        stack.callback(local.close)
        return local
    remote: RemoteEndpoint = RemoteEndpoint(location, port, executable, shell)
    stack.callback(remote.close)
    return remote


if __name__ == "__main__":
    sys.exit(main())
