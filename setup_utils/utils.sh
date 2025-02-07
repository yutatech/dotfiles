# 引数に渡したファイル、環境変数、シンボリックリンクが存在することを確認
file_exists() {
  local files=$@

  if [ -n "${ZSH_VERSION}" ]; then
    files=(${(Q)${(z)${(f)"$(print -r -- $@)"}}})
  fi

  for file in $files; do
    if [ ! -e "$file" ]; then
      return 1
    fi
  done
  return 0
}

symlink_exists() {
  local symlinks=$@

  if [ -n "${ZSH_VERSION}" ]; then
    symlinks=(${(Q)${(z)${(f)"$(print -r -- $@)"}}})
  fi

  for symlink in $symlinks; do
    if [ ! -L "$symlink" ]; then
      return 1
    fi
  done
  return 0
}

command_exists() {
  local commands=$@

  if [ -n "${ZSH_VERSION}" ]; then
    commands=(${(Q)${(z)${(f)"$(print -r -- $@)"}}})
  fi

  for command in $commands; do
    if ! command -v $command > /dev/null 2>&1; then
      return 1
    fi
  done
  return 0
}

source_all() {
  local files=$@

  if [ -n "${ZSH_VERSION}" ]; then
    files=(${(Q)${(z)${(f)"$(print -r -- $@)"}}})
  fi

  for file in $files; do
    source $file
  done
}

is_configure_completed() {
  local check_files=$1
  local symlinks=$2
  local commands=$3
  local is_completed=0

  if ! file_exists "$check_files"; then
    is_completed=1
  fi

  if ! symlink_exists "$symlinks"; then
    is_completed=1
  fi

  if ! command_exists "$commands"; then
    is_completed=1
  fi

  return $is_completed
}

check_and_install_commands() {
  local commands=$@

  if [ -n "${ZSH_VERSION}" ]; then
    commands=(${(Q)${(z)${(f)"$(print -r -- $@)"}}})
  fi

  for command in $commands; do
    if ! command -v $command > /dev/null 2>&1; then
      echo "Installing $command..."
      if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install $command
      else
        sudo apt install $command -y
      fi
    fi
  done
}