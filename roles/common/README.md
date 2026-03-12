# annie444.homelab.common

Baseline system hardening and configuration for Fedora and Enterprise Linux.

## Requirements

- `ansible-core >= 2.14`
- Target OS: Fedora 41, 42, 43 — or Enterprise Linux (RHEL/CentOS Stream) 9, 10
- The following collections must be installed (e.g. via `ansible-galaxy collection install`):
  - `fedora.linux_system_roles` — delegated to for journald, timesync, firewall, and postfix subtasks

## What the role does

The role applies a comprehensive system baseline across 19 subtask areas, executed in order:

**Security hardening**

- OS-level sysctl hardening, kernel command-line options, IOMMU, PTI, KASLR improvements
- FIPS cryptography policy (optional, see warnings)
- SSH server hardening with optional authorized-key deployment
- auditd configuration with OSPP-profile privilege command recording
- PAM password policy enforcement
- Kernel module loading lockdown, user namespace restriction, ia32 emulation disable (all opt-in)
- Kernel lockdown mode (`integrity` or `confidentiality`)
- USB, Thunderbolt, and Bluetooth port control

**Network**

- systemd-resolved configuration: DNS-over-TLS (DoT), DNSSEC
- MAC address randomization for Wi-Fi and Ethernet
- firewalld management with optional trusted-source restrictions
- NTP/PTP time synchronisation via chrony (or ntp); NTS support

**Package management**

- DNF tuning: parallelism, proxy, cache, docs, weak-deps, GPG enforcement
- `dnf-automatic` configuration with configurable update scope, timer or shutdown trigger
- Fedora major-version OS upgrade via `dnf system-upgrade` (non-ostree only)

**System setup**

- Hostname
- Admin user, group, UID/GID, shell, home directory, hashed password, SSH authorized key
- Custom CA certificate installation into the system trust store
- journald persistence, sizing, retention, compression, forwarding
- GRUB timeout, auto-hide, password, and extra kernel command-line options

**Services**

- fail2ban with configurable default action
- Postfix relay configuration for outbound mail
- QEMU guest agent, Incus guest agent
- cachefilesd for NFS/SMB client-side caching
- NFS and CIFS/SMB mount management via `/etc/fstab`

## Role Variables

### Required

| Variable            | Type  | Description                                                                |
| ------------------- | ----- | -------------------------------------------------------------------------- |
| `common_admin_user` | `str` | The admin user to ensure exists. Automatically added to the `wheel` group. |

---

### Hostname & Journald

| Variable                                  | Type        | Default | Description                                                              |
| ----------------------------------------- | ----------- | ------- | ------------------------------------------------------------------------ |
| `common_hostname`                         | `str`       | —       | If specified, set the system hostname.                                   |
| `common_journald_persistent`              | `bool`      | `false` | Store journal on disk in `/var/log/journal/`.                            |
| `common_journald_max_disk_size`           | `int` (MiB) | —       | Max total journal disk usage before rotation.                            |
| `common_journald_max_file_size`           | `int` (MiB) | —       | Max size of a single journal file.                                       |
| `common_journald_per_user`                | `bool`      | —       | Keep per-user journal data. Requires `common_journald_persistent: true`. |
| `common_journald_compression`             | `bool`      | —       | Compress journal objects larger than 512 bytes.                          |
| `common_journald_sync_interval`           | `int` (min) | —       | Sync interval to disk. Only applies when persistent.                     |
| `common_journald_forward_to_syslog`       | `bool`      | —       | Forward journal entries to a syslog daemon.                              |
| `common_journald_rate_limit_interval_sec` | `int` (sec) | —       | Rate-limit window for burst control.                                     |
| `common_journald_rate_limit_burst`        | `int`       | —       | Max messages per rate-limit window.                                      |
| `common_journald_keep_free`               | `int` (MiB) | —       | Minimum free filesystem space to maintain.                               |
| `common_journald_max_retention`           | `int` (min) | —       | Maximum age of journal entries before deletion.                          |

Journald tasks are delegated to `fedora.linux_system_roles.journald` and only run when at least one `common_journald_*` variable is defined.

---

### CA Certificates & DNS

| Variable                      | Type                           | Default         | Description                                                                                  |
| ----------------------------- | ------------------------------ | --------------- | -------------------------------------------------------------------------------------------- |
| `common_ca_certificates`      | `list[path]`                   | —               | Local paths to PEM or DER certificates to install in the system trust store.                 |
| `common_dns_servers`          | `list[str]`                    | —               | DNS servers. Use `address#servername` format when DoT is enabled for certificate validation. |
| `common_dns_servers_fallback` | `list[str]`                    | —               | Fallback DNS servers. Same format recommendation as above.                                   |
| `common_dns_over_tls`         | `yes` / `no` / `opportunistic` | `opportunistic` | DNS-over-TLS mode. `yes` is preferred for full validation.                                   |
| `common_dnssec`               | `bool`                         | —               | Enforce local DNSSEC validation. The DNS server must support DNSSEC.                         |
| `common_domain`               | `str`                          | —               | Domain / FQDN of the current machine.                                                        |

---

### PAM & Login

| Variable                                  | Type        | Default | Description                                                                               |
| ----------------------------------------- | ----------- | ------- | ----------------------------------------------------------------------------------------- |
| `common_login_password_min_length`        | `int`       | `12`    | Minimum password length enforced via PAM.                                                 |
| `common_os_hardening_interactive_timeout` | `int` (sec) | `600`   | Idle shell session timeout before automatic logout. Requires `common_os_hardening: true`. |

---

### DNF

All DNF variables are **ignored on ostree-based systems**.

| Variable                            | Type                   | Default   | Description                                                                                                                                   |
| ----------------------------------- | ---------------------- | --------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `common_dnf_nodocs`                 | `bool`                 | `true`    | Skip documentation installation.                                                                                                              |
| `common_dnf_install_weak_deps`      | `bool`                 | `false`   | Install weak/optional dependencies.                                                                                                           |
| `common_dnf_keepcache`              | `bool`                 | `false`   | Retain the package download cache.                                                                                                            |
| `common_dnf_fastestmirror`          | `bool`                 | `false`   | Use the fastest-mirror plugin. Overrides server-managed mirror selection.                                                                     |
| `common_dnf_automatic_upgrade_type` | `default` / `security` | `default` | Scope of unattended updates — `security` to limit to CVE patches only.                                                                        |
| `common_dnf_automatic_on_shutdown`  | `bool`                 | `false`   | Run `dnf-automatic` at shutdown instead of on a timer.                                                                                        |
| `common_dnf_automatic_restart`      | `bool`                 | `true`    | Reboot after updates when required. Disabled if `common_dnf_automatic_on_shutdown` is `true`.                                                 |
| `common_dnf_proxy`                  | `str`                  | —         | Proxy URL: `<scheme>://<host>[:port]`.                                                                                                        |
| `common_dnf_proxy_auth_method`      | `str`                  | —         | Authentication method for the proxy.                                                                                                          |
| `common_dnf_proxy_username`         | `str`                  | —         | Proxy username.                                                                                                                               |
| `common_dnf_proxy_password`         | `str`                  | —         | Proxy password.                                                                                                                               |
| `common_dnf_sslcacert`              | `path`                 | —         | CA certificate file for SSL verification (e.g. for HTTPS proxy).                                                                              |
| `common_os_target_release`          | `str`                  | —         | Target Fedora release for `dnf system-upgrade`. When current release is `target - 1`, the upgrade runs automatically. Non-ostree Fedora only. |

---

### OS Hardening

All options require `common_os_hardening: true` unless noted.

| Variable                                            | Type                            | Default | Description                                                                                                            |
| --------------------------------------------------- | ------------------------------- | ------- | ---------------------------------------------------------------------------------------------------------------------- |
| `common_os_hardening`                               | `bool`                          | `true`  | Apply the OS hardening baseline (sysctl, kernel cmdline, module rules, GPG).                                           |
| `common_os_hardening_fips`                          | `bool`                          | `false` | Configure FIPS cryptography policies. **See warnings below.**                                                          |
| `common_os_hardening_disable_user_namespaces`       | `bool`                          | `false` | Disable user namespaces. **See warnings below.**                                                                       |
| `common_os_hardening_disable_kernel_module_loading` | `bool`                          | `false` | Permanently lock kernel module loading after apply. **See warnings below.**                                            |
| `common_os_hardening_kernel_ia32_emulation`         | `bool`                          | `false` | When `false`, disables x86 32-bit emulation on x86-64 (reduces attack surface).                                        |
| `common_os_hardening_localpkg_gpgcheck`             | `bool`                          | `true`  | Require GPG signatures on local RPM packages. **See warnings below.**                                                  |
| `common_kernel_lockdown`                            | `integrity` / `confidentiality` | —       | Enable kernel lockdown. `integrity` prevents modification; `confidentiality` also blocks extraction of kernel secrets. |

---

### SSH Hardening

| Variable                    | Type   | Default | Description                                                                                                                                                                   |
| --------------------------- | ------ | ------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `common_ssh_hardening`      | `bool` | `true`  | Apply hardened `sshd_config`.                                                                                                                                                 |
| `common_ssh_authorized_key` | `str`  | —       | SSH public key to add to `~/.ssh/authorized_keys`. When set alongside `common_ssh_hardening: true`, disables password authentication. Generate with: `ssh-keygen -t ed25519`. |

---

### Admin User

| Variable                | Type   | Default             | Description                                                              |
| ----------------------- | ------ | ------------------- | ------------------------------------------------------------------------ |
| `common_admin_user`     | `str`  | **required**        | Username to create/ensure. Added to `wheel` automatically.               |
| `common_admin_uid`      | `int`  | —                   | UID for the admin user.                                                  |
| `common_admin_group`    | `str`  | `common_admin_user` | Primary group name. Defaults to the username.                            |
| `common_admin_gid`      | `int`  | —                   | GID for the admin group.                                                 |
| `common_admin_shell`    | `path` | `/bin/bash`         | Login shell.                                                             |
| `common_admin_home_dir` | `path` | `/home/<user>`      | Home directory. On ostree systems defaults to `/var/home/<user>`.        |
| `common_admin_password` | `str`  | —                   | Hashed password (yescrypt). Generate with: `mkpasswd --method=yescrypt`. |

---

### Hardware

| Variable                                | Type                          | Default | Description                                                                                                                                       |
| --------------------------------------- | ----------------------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| `common_allow_bluetooth`                | `bool`                        | `false` | Allow Bluetooth. Requires `common_os_hardening: true` to take effect.                                                                             |
| `common_allow_thunderbolt`              | `bool`                        | `false` | Allow Thunderbolt and FireWire.                                                                                                                   |
| `common_allow_usb`                      | `bool`                        | `true`  | Allow USB. When `false`, adds `nousb` to kernel cmdline.                                                                                          |
| `common_cpu_vulnerabilities_mitigation` | `auto` / `off` / `auto,nosmt` | `auto`  | CPU vulnerability mitigations. `auto` = all enabled; `off` = disabled (performance); `auto,nosmt` = disable SMT when required (highest security). |

---

### GRUB / Boot

| Variable                            | Type        | Default | Description                                                                     |
| ----------------------------------- | ----------- | ------- | ------------------------------------------------------------------------------- |
| `common_grub_auto_hide`             | `bool`      | `false` | Hide GRUB menu automatically when there is only one boot entry.                 |
| `common_grub_hidden_timeout`        | `int` (sec) | `0`     | GRUB hidden timeout.                                                            |
| `common_grub_timeout`               | `int` (sec) | `1`     | GRUB menu timeout.                                                              |
| `common_grub_save_default`          | `bool`      | `false` | Use the last selected entry as the default on next boot.                        |
| `common_grub_password`              | `str`       | —       | If specified, set a GRUB boot password.                                         |
| `common_grub_cmdline_linux_default` | `str`       | —       | Space-separated extra kernel options appended via `GRUB_CMDLINE_LINUX_DEFAULT`. |

---

### NTP / PTP

NTP/PTP tasks are delegated to `fedora.linux_system_roles.timesync` and only run when `common_ntp_servers` or `common_ptp_domains` is defined.

| Variable                                | Type                    | Default  | Description                                                                        |
| --------------------------------------- | ----------------------- | -------- | ---------------------------------------------------------------------------------- |
| `common_ntp_provider`                   | `chrony` / `ntp`        | `chrony` | NTP daemon to install and configure.                                               |
| `common_ntp_servers`                    | `list[dict]`            | —        | List of NTP servers. See sub-keys below.                                           |
| `common_ptp_domains`                    | `list[dict]`            | —        | List of PTP domains. See sub-keys below.                                           |
| `common_dhcp_ntp_servers`               | `bool`                  | `false`  | Accept NTP servers from DHCP.                                                      |
| `common_ntp_step_threshold`             | `float`                 | `1.0`    | Minimum clock offset that triggers a step correction. `0` disables stepping.       |
| `common_ntp_max_distance`               | `int`                   | —        | Maximum root distance accepted from NTP servers (`0` = provider default).          |
| `common_ntp_min_sources`                | `int`                   | `1`      | Minimum selectable sources required before synchronising.                          |
| `common_ntp_ip_family`                  | `IPv4` / `IPv6` / `all` | `all`    | Restrict NTP to a specific IP family.                                              |
| `common_ntp_hwts_interfaces`            | `list[str]`             | —        | Interfaces to enable hardware timestamping on. `*` enables all capable interfaces. |
| `common_chrony_custom_settings`         | `list[str]`             | —        | Raw `chrony.conf` lines for settings not covered above.                            |
| `common_transactional_update_reboot_ok` | `bool`                  | `true`   | On transactional-update systems, permit automatic reboot after NTP changes.        |

**`common_ntp_servers` dict keys:**

| Key        | Type   | Default  | Description                                            |
| ---------- | ------ | -------- | ------------------------------------------------------ |
| `hostname` | `str`  | required | Hostname or IP address of the NTP server.              |
| `minpoll`  | `int`  | `6`      | Minimum polling interval (power of 2, seconds).        |
| `maxpoll`  | `int`  | `10`     | Maximum polling interval (power of 2, seconds).        |
| `iburst`   | `bool` | `false`  | Fast initial synchronisation burst.                    |
| `pool`     | `bool` | `false`  | Treat each resolved address as a separate server.      |
| `nts`      | `bool` | `false`  | Enable Network Time Security (requires chrony >= 4.0). |
| `prefer`   | `bool` | `false`  | Prefer this source over others.                        |
| `trust`    | `bool` | `false`  | Trust this source over untrusted sources.              |
| `xleave`   | `bool` | `false`  | Enable interleaved mode.                               |
| `filter`   | `int`  | `1`      | Number of NTP measurements per clock update.           |

**`common_ptp_domains` dict keys:**

| Key          | Type                     | Default  | Description                                             |
| ------------ | ------------------------ | -------- | ------------------------------------------------------- |
| `number`     | `int`                    | required | PTP domain number.                                      |
| `interfaces` | `list[str]`              | required | Network interfaces in this domain.                      |
| `delay`      | `float`                  | —        | Assumed maximum network delay to grandmaster (seconds). |
| `transport`  | `UDPv4` / `UDPv6` / `L2` | `UDPv4`  | Network transport.                                      |
| `udp_ttl`    | `int`                    | `1`      | TTL for UDP transports.                                 |
| `hybrid_e2e` | `bool`                   | `false`  | Enable unicast end-to-end delay requests.               |

---

### Network: Firewall & MAC

| Variable                          | Type                              | Default  | Description                                                                                     |
| --------------------------------- | --------------------------------- | -------- | ----------------------------------------------------------------------------------------------- |
| `common_trusted_firewalld_source` | `list[str]`                       | —        | Restrict SSH access to these CIDR sources only (e.g. `["192.168.1.0/24"]`).                     |
| `common_random_mac`               | `bool`                            | `true`   | Master switch for MAC randomisation. When `false`, the two options below are ignored.           |
| `common_random_mac_wifi`          | `random` / `stable` / `permanent` | `random` | Wi-Fi MAC mode: `random` = new address each association, `stable` = per-network stable address. |
| `common_random_mac_ethernet`      | `random` / `stable` / `permanent` | `stable` | Ethernet MAC mode. `permanent` uses the hardware address.                                       |

---

### Guest Agents

| Variable             | Type   | Default | Description                               |
| -------------------- | ------ | ------- | ----------------------------------------- |
| `common_guest_qemu`  | `bool` | `false` | Install and enable `qemu-guest-agent`.    |
| `common_guest_incus` | `bool` | `false` | Install and enable the Incus guest agent. |

---

### Fail2ban

| Variable                 | Type  | Default          | Description                                                                      |
| ------------------------ | ----- | ---------------- | -------------------------------------------------------------------------------- |
| `common_fail2ban_action` | `str` | `%(action_mwl)s` | Default fail2ban action. The default bans the IP and emails root with full logs. |

---

### FS-Cache

| Variable          | Type   | Default | Description                                                                                             |
| ----------------- | ------ | ------- | ------------------------------------------------------------------------------------------------------- |
| `common_fs_cache` | `bool` | `false` | Install and enable `cachefilesd` for NFS/SMB client-side caching. Add `fsc` to mount options to use it. |

---

### NFS Mounts

| Variable           | Type         | Default | Description                               |
| ------------------ | ------------ | ------- | ----------------------------------------- |
| `common_nfs_mount` | `list[dict]` | —       | NFS shares to mount. See dict keys below. |

**`common_nfs_mount` dict keys:**

| Key     | Type   | Required | Description                                                                                                        |
| ------- | ------ | -------- | ------------------------------------------------------------------------------------------------------------------ |
| `path`  | `path` | yes      | Local mount point.                                                                                                 |
| `src`   | `str`  | yes      | NFS share to mount (e.g. `192.168.1.10:/exports/data`).                                                            |
| `opts`  | `str`  | no       | Mount options (see `fstab(5)`).                                                                                    |
| `owner` | `str`  | no       | User owning the mount point.                                                                                       |
| `group` | `str`  | no       | Group owning the mount point.                                                                                      |
| `mode`  | `str`  | no       | Permission mode (e.g. `0755`).                                                                                     |
| `state` | `str`  | no       | `mounted` (default), `present` (fstab only), `unmounted`, `absent`, `absent_from_fstab`, `remounted`, `ephemeral`. |

---

### SMB / CIFS Mounts

| Variable           | Type         | Default | Description                                                       |
| ------------------ | ------------ | ------- | ----------------------------------------------------------------- |
| `common_smb_mount` | `list[dict]` | —       | CIFS/SMB shares to mount. Same dict format as `common_nfs_mount`. |

---

### Mail / Postfix

Mail tasks only run when `common_mail_smtp_host` is defined. The role delegates to `fedora.linux_system_roles.postfix`.

| Variable                           | Type               | Default     | Description                                                                 |
| ---------------------------------- | ------------------ | ----------- | --------------------------------------------------------------------------- |
| `common_mail_smtp_host`            | `str`              | —           | SMTP relay server hostname. Setting this enables the mail subtask.          |
| `common_mail_smtp_port`            | `int`              | `465`       | SMTP port: `25` (SMTP), `465` (SMTPS), `587` (Submission).                  |
| `common_mail_smtp_tls`             | `TLS` / `STARTTLS` | —           | TLS mode: `TLS` for SMTPS (port 465), `STARTTLS` for Submission (port 587). |
| `common_mail_smtp_user`            | `str`              | —           | SMTP authentication username.                                               |
| `common_mail_smtp_password`        | `str`              | —           | SMTP authentication password for `common_mail_smtp_user`.                   |
| `common_mail_smtp_inet_interfaces` | `str`              | `127.0.0.1` | Interface(s) Postfix listens on for local submissions.                      |
| `common_mail_smtp_send_to`         | `str`              | —           | Redirect all `root` mail to this email address.                             |

---

### Monitoring (Netdata)

These variables are defined in `defaults/main.yml` but are not yet present in `argument_specs.yml`.

| Variable                        | Type   | Default | Description                                            |
| ------------------------------- | ------ | ------- | ------------------------------------------------------ |
| `common_netdata_enable`         | `bool` | `false` | Install and configure Netdata monitoring agent.        |
| `common_netdata_cloud_only`     | `bool` | `false` | Configure Netdata for cloud-only (no local dashboard). |
| `common_netdata_ephemeral_node` | `bool` | `false` | Treat this node as ephemeral in Netdata Cloud.         |
| `common_netdata_claim_token`    | `str`  | —       | Netdata Cloud claim token (optional).                  |
| `common_netdata_claim_rooms`    | `str`  | —       | Netdata Cloud room IDs to claim into (optional).       |

---

## Warnings

> **FIPS (`common_os_hardening_fips: true`)** — Keep an existing SSH session open before applying. The FIPS policy change can invalidate in-use algorithms and prevent _new_ SSH connections from being established. Verify connectivity before closing the maintenance session.

> **User namespaces (`common_os_hardening_disable_user_namespaces: true`)** — Disables the Linux user namespace feature. This breaks Docker, Podman (rootless), and any systemd unit using `PrivateUsers=`. Do not enable on container hosts.

> **Kernel module loading (`common_os_hardening_disable_kernel_module_loading: true`)** — Prevents loading any kernel modules after the setting is applied. This is effectively irreversible without a reboot and will break DKMS, akmods, and any runtime module loading.

> **Local GPG check (`common_os_hardening_localpkg_gpgcheck: true`, default)** — Requires all locally installed RPMs to carry a valid GPG signature. This blocks `akmods` (unsigned kernel modules). Disable this variable if you use akmods or other unsigned local packages.

---

## Example Playbook

```yaml
- name: Apply homelab common baseline
  hosts: all
  gather_facts: true

  roles:
    - role: annie444.homelab.common
      vars:
        common_admin_user: alice
        common_admin_uid: 1000
        common_admin_password: "$y$j9T$..." # mkpasswd --method=yescrypt
        common_ssh_authorized_key: "ssh-ed25519 AAAA... alice@laptop"

        common_hostname: "{{ inventory_hostname }}"
        common_domain: home.example.com

        common_dns_servers:
          - "9.9.9.9#dns.quad9.net"
          - "149.112.112.112#dns.quad9.net"
        common_dns_over_tls: "yes"
        common_dnssec: true

        common_ntp_servers:
          - hostname: time.cloudflare.com
            iburst: true
            nts: true

        common_mail_smtp_host: smtp.example.com
        common_mail_smtp_port: 587
        common_mail_smtp_tls: STARTTLS
        common_mail_smtp_user: alerts@example.com
        common_mail_smtp_send_to: admin@example.com

        common_guest_qemu: true
```

---

## Role Idempotency

**Idempotent:** Yes. All tasks use idempotent Ansible modules (`ansible.builtin.user`, `ansible.builtin.template`, `ansible.builtin.service`, etc.). Re-running the role on an already-configured host produces no changes.

## Role Atomicity

**Atomic:** No. Tasks are applied sequentially across 19+ subtask files. A failed task mid-run leaves the system partially configured. There is no rollback-on-failure mechanism.

## Rollback Capabilities

**Not supported.** OS hardening sysctl changes and FIPS policy changes require manual reversal (`fips-mode-setup --disable`, manual `/etc/sysctl.d/` removal). Kernel cmdline changes require manual `grubby` commands or re-running the role with corrected variables.

---

## Dependencies

The role delegates to the following `fedora.linux_system_roles` sub-roles at runtime. Install the collection before running:

```bash
ansible-galaxy collection install fedora.linux_system_roles
```

| Sub-role                             | When used                                                    |
| ------------------------------------ | ------------------------------------------------------------ |
| `fedora.linux_system_roles.journald` | When any `common_journald_*` variable is defined             |
| `fedora.linux_system_roles.timesync` | When `common_ntp_servers` or `common_ptp_domains` is defined |
| `fedora.linux_system_roles.firewall` | Always (firewall subtask runs unconditionally)               |
| `fedora.linux_system_roles.postfix`  | When `common_mail_smtp_host` is defined                      |

---

## License

GPL-3.0-or-later

## Author

Analetta Ehler ([@annie444](https://github.com/annie444))
