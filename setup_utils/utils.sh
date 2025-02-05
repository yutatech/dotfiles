# 引数に渡したファイル、環境変数、シンボリックリンクが存在することを確認
exists() {
  local files=$@
  if [ -n "${ZSH_VERSION}" ]; then
    files=(${=files})
  fi

  for file in $files; do
    if [ ! -e "$file" ]; then
      return 1
    fi
  done
  return 0
}

source_all() {
  local files=$@
  if [ -n "${ZSH_VERSION}" ]; then
    files=(${=files})
  fi

  for file in $files; do
    source $file
  done
}

is_configure_completed() {
  local source_files=$1
  local check_files=$2
  local command=$3
  local is_completed=0

  if ! exists "$source_files" ; then
    is_completed=1
  fi

  if ! exists "$check_files"; then
    is_completed=1
  fi

  if ! command -v $command > /dev/null 2>&1; then
    is_completed=1
  fi

  return $is_completed
}

check_and_install_commands() {
  local commands=$@
  if [ -n "${ZSH_VERSION}" ]; then
    commands=(${=commands})
  fi

  for command in $commands; do
    if ! command -v $command > /dev/null 2>&1; then
      echo "Installing $command..."
      if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install $command
      elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt install $command -y
      else
        echo "Unsupported OS. This script supports macOS and Ubuntu only."
        return 1
      fi
    fi
  done
}