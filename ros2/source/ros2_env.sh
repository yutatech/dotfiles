export RCUTILS_COLORIZED_OUTPUT=1
export RCUTILS_CONSOLE_OUTPUT_FORMAT=[{severity}][{time}][{name}]:\ {message}
export ROSCONSOLE_FORMAT=[${severity}][${time}][${node}:${logger}]: ${message}


if [ -n "${ZSH_VERSION}" ]; then
    export PATH="$REPO_DIR/ros2/cmd:$PATH"
    fpath=($REPO_DIR/ros2/comp $fpath)
fi