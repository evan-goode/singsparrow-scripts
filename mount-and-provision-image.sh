#!/usr/bin/env bash

set -e

if ((EUID)); then
   echo "This script must be run as root!"
   exit 1
fi

if [ $(uname) != Linux ]; then
	echo "This script only works on Linux!"
	exit 1
fi

image_path="$1"

if [ "$image_path" == "" ]; then
	echo "Image path not specified."
	exit 1
fi

loop_device="$(losetup -Pf --show "$image_path")"
echo "loop dev is $loop_device"
mount_point="$(mktemp -d)"
mount "${loop_device}p2" "$mount_point"
mount "${loop_device}p1" "$mount_point/boot"

scripts_directory="$mount_point/root/singsparrow-scripts"

git clone https://github.com/evan-goode/singsparrow-scripts.git

systemd-nspawn -D "$mount_point" "$scripts_directory/provision-raspberry-pi.sh"

umount -R "$mount_point"
losetup -d "$loop_device"

echo "Successfully provisioned $image_path."
