#!/bin/sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"

if [ -n "${BASH_VERSION}" ]; then
  source "$SCRIPT_DIR/source/bash_env.bash"
fi