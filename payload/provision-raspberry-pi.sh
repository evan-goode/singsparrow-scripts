#!/usr/bin/env bash

cd "$(dirname "$0")"

hostname="$1"
if [ -z "$hostname" ]; then
	echo "Usage: ./provision-raspberry-pi.sh <hostname>"
	exit 1
fi

sed '/^dtparam=audio=on$/d' /boot/config.txt
echo 'dtoverlay=hifiberry-dacplus' >> /boot/config.txt

cat << EOF > /etc/asound.conf
pcm.!default {
	type hw card 0
}
ctl.!default {
	type hw card 0
}
EOF

# Set hostname
echo "$hostname" > /etc/hostname

# Scramble the pi password
password_pi="$(openssl rand -base64 64 | tr -d '\n')"
echo "pi:$password_pi" | chpasswd

# packages
apt update
apt install -y \
	git \
	network-manager \
	python3-pip \
	python3-gpiozero
apt purge -y openresolv dhcpcd5

# SSH
mkdir -p ~/.ssh/
install -m 600 ./authorized_keys ~/.ssh/
systemctl enable ssh

# NetworkManager
mkdir -p /etc/NetworkManager/system-connections/
install -m 600 system-connections/* /etc/NetworkManager/system-connections/
systemctl enable NetworkManager

mkdir -p /var/singsparrow-ii/
install -m 644 song-a.wav /var/singsparrow-ii/
install -m 644 song-b.wav /var/singsparrow-ii/
cd ./singsparrow-ii/
make
make install
cp ./singsparrow-ii.toml /etc/
systemctl enable singsparrow-ii

apt install -y \
	neovim \
	mplayer
