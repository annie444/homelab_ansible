#!/bin/bash -eux

# set a default HOME_DIR environment variable if not set
HOME_DIR="${HOME_DIR:-/home/vagrant}"

case "$PACKER_BUILDER_TYPE" in
qemu)
  echo "installing pkgs necessary for QEMU guest support"
  dnf install -y --skip-broken qemu-guest-agent
  sed -i 's/^BLACKLIST_RPC=/# BLACKLIST_RPC=/' /etc/sysconfig/qemu-ga     # RHEL 8 instances
  sed -i 's/^FILTER_RPC_ARGS=/# FILTER_RPC_ARGS=/' /etc/sysconfig/qemu-ga # RHEL 9+ instances
  systemctl enable qemu-guest-agent
  systemctl start qemu-guest-agent

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
  else
    echo "Unable to determine if a reboot is needed defaulting to reboot anyway"
    REBOOT_NEEDED=true
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
