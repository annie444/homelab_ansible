#!/bin/sh -eux

# set a default HOME_DIR environment variable if not set
HOME_DIR="${HOME_DIR:-/home/vagrant}"

case "$PACKER_BUILDER_TYPE" in
virtualbox-iso | virtualbox-ovf)
  ARCHITECTURE="$(uname -m)"
  VER="$(cat "$HOME_DIR"/.vbox_version)"
  ISO="VBoxGuestAdditions_$VER.iso"

  # mount the ISO to /tmp/vbox
  mkdir -p /tmp/vbox
  mount -o loop "$HOME_DIR"/"$ISO" /tmp/vbox

  echo "installing deps necessary to compile kernel modules"
  # We install things like kernel-headers here vs. kickstart files so we make sure we install them for the updated kernel not the stock kernel
  if [ -f "/bin/dnf" ]; then
    dnf install -y --skip-broken perl cpp gcc make bzip2 tar kernel-headers kernel-devel kernel-uek-devel || true # not all these packages are on every system
  elif [ -f "/usr/bin/apt-get" ]; then
    apt-get install -y build-essential dkms bzip2 tar linux-headers-"$(uname -r)"
  elif [ -f "/usr/bin/zypper" ]; then
    zypper install -y perl cpp gcc make bzip2 tar kernel-default-devel
  fi
  echo "installing the vbox additions for architecture $ARCHITECTURE"
  # this install script fails with non-zero exit codes for no apparent reason so we need better ways to know if it worked
  if [ "$ARCHITECTURE" = "aarch64" ]; then
    /tmp/vbox/VBoxLinuxAdditions-arm64.run --nox11 || true
  else
    /tmp/vbox/VBoxLinuxAdditions.run --nox11 || true
  fi

  if ! modinfo vboxsf >/dev/null 2>&1; then
    echo "Cannot find vbox kernel module. Installation of guest additions unsuccessful!"
    exit 1
  fi

  echo "unmounting and removing the vbox ISO"
  umount /tmp/vbox
  rm -rf /tmp/vbox
  rm -f "$HOME_DIR"/*.iso

  echo "removing kernel dev packages and compilers we no longer need"
  if [ -f "/bin/dnf" ]; then
    dnf remove -y gcc cpp kernel-headers kernel-devel kernel-uek-devel
  elif [ -f "/usr/bin/apt-get" ]; then
    apt-get remove -y build-essential gcc g++ make libc6-dev dkms linux-headers-"$(uname -r)"
  elif [ -f "/usr/bin/zypper" ]; then
    zypper -n rm -u kernel-default-devel gcc make
  fi

  echo "removing leftover logs"
  rm -rf /var/log/vboxadd*

  REBOOT_NEEDED=false
  # Check for the /var/run/reboot-required file (common on Debian/Ubuntu)
  if [ -f /var/run/reboot-required ]; then
    REBOOT_NEEDED=true
  # Check for the needs-restarting command (common on RHEL based systems)
  elif command -v needs-restarting >/dev/null 2>&1; then
    # needs-restarting -r: indicates a full reboot is needed (exit code 1)
    # needs-restarting -s: indicates a service restart is needed (exit code 1)
    if needs-restarting -r >/dev/null 2>&1 || needs-restarting -s >/dev/null 2>&1; then
      REBOOT_NEEDED=true
    fi
  fi

  if [ "$REBOOT_NEEDED" = true ]; then
    echo "pkgs installed needing reboot"
    shutdown -r now
    sleep 60
  else
    echo "no pkgs installed needing reboot"
  fi
  ;;
esac
