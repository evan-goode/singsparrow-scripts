#!/usr/bin/env bash

cd "$(dirname "$0")"

if ((EUID)); then
   echo "This script must be run as root!"
   exit 1
fi

if [ "$(uname)" != Linux ]; then
	echo "This script only works on Linux!"
	exit 1
fi

image_path="$1"
hostname="$2"
if [ -z "$image_path" ] || [ -z "$hostname" ]; then
	echo "Usage: ./mount-and-provision-image.sh <path to image> <hostname>"
	exit 1
fi

loop_device="$(losetup -Pf --show "$image_path")"
mount_point="$(mktemp -d)"
mount "${loop_device}p2" "$mount_point"
mount "${loop_device}p1" "$mount_point/boot"

rm -f "$mount_point/etc/ld.so.preload"

internal_path=/root/payload/
payload_destination="$mount_point/$internal_path"
rsync -a ./payload/ "$payload_destination"
repo_destination="$payload_destination/singsparrow-ii/"
if ! [ -d "$repo_destination" ]; then
	git clone "https://github.com/evan-goode/singsparrow-ii.git" "$repo_destination"
fi

systemd-nspawn -D "$mount_point" "$internal_path/provision-raspberry-pi.sh" "$hostname"

umount -R "$mount_point"
losetup -d "$loop_device"
rm -r "$mount_point"
