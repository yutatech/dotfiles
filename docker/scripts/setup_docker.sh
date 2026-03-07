#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"

wget -O $SCRIPT_DIR/get-docker.sh https://get.docker.com
sudo sh $SCRIPT_DIR/get-docker.sh
rm -f $SCRIPT_DIR/get-docker.sh

sudo usermod -aG docker ${USER}
sudo service docker start

# docker-composeコマンドが必要な場合(Ubuntu)
sudo apt install -y docker-compose