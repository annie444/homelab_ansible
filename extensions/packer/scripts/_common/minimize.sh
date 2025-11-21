#!/bin/sh -eux

case "$PACKER_BUILDER_TYPE" in
qemu)
  echo "Nothing to do for utm or qemu"
  exit 0
  ;;
esac

if [ -f /etc/sudoers.d/_packer_env ]; then
  rm -f /etc/sudoers.d/_packer_env
fi

# Whiteout root
count=$(df --sync -kP / | tail -n1 | awk -F ' ' '{print $4}')
count=$((count - 1))
dd if=/dev/zero of=/tmp/whitespace bs=1M count="$count" || echo "dd exit code $? is suppressed"
rm /tmp/whitespace

# Whiteout /boot
count=$(df --sync -kP /boot | tail -n1 | awk -F ' ' '{print $4}')
count=$((count - 1))
dd if=/dev/zero of=/boot/whitespace bs=1M count="$count" || echo "dd exit code $? is suppressed"
rm /boot/whitespace

set +e
swapuuid="$(/sbin/blkid -o value -l -s UUID -t TYPE=swap)"
case "$?" in
2 | 0) ;;
*) exit 1 ;;
esac
set -e

if [ "$swapuuid" != "" ]; then
  # Whiteout the swap partition to reduce box size
  # Swap is disabled till reboot
  swappart="$(readlink -f /dev/disk/by-uuid/"$swapuuid")"
  /sbin/swapoff "$swappart" || true
  dd if=/dev/zero of="$swappart" bs=1M || echo "dd exit code $? is suppressed"
  chmod 0600 "$swappart" || true
  /sbin/mkswap -U "$swapuuid" "$swappart" || echo "mkswap exit code $? is suppressed"
fi

sync
