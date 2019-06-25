#!/usr/bin/env bash

set -e
cd "$(dirname "$0")"

password_pi="$(openssl rand -base64 64)"
echo "$password_pi" | passwd --stdin pi
