# bash configuration

bind 'set completion-ignore-case on' # tab補完で大文字小文字を区別しない


if type pip &>/dev/null; then
  eval "$(pip completion --bash)"
fi