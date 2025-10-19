annie444.homelab common Role
========================

A brief description of the role goes here.

Requirements
------------

Any pre-requisites that may not be covered by Ansible itself or the role should be mentioned here. For instance, if the role uses the EC2 module, it may be a good idea to mention in this section that the boto package is required.

Role Variables
--------------

A description of the settable variables for this role should go here, including any variables that are in defaults/main.yml, vars/main.yml, and any variables that can/should be set via parameters to the role. Any variables that are read from other roles and/or the global scope (ie. hostvars, group vars, etc.) should be mentioned here as well.

Dependencies
------------

A list of other roles hosted on Galaxy should go here, plus any details in regards to parameters that may need to be set for other roles, or variables that are used from other roles.

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

```yaml
- name: Execute tasks on servers
  hosts: servers
  roles:
    - role: annie444.homelab.run
      run_x: 42
```

Another way to consume this role would be:

```yaml
- name: Initialize the run role from annie444.homelab
  hosts: servers
  gather_facts: false
  tasks:
    - name: Trigger invocation of run role
      ansible.builtin.include_role:
        name: annie444.homelab.run
      vars:
        run_x: 42
```

Role Idempotency
----------------

Designation of the role as idempotent (True/False)

Role Atomicity
----------------

Designation of the role as atomic if applicable (True/False)

Roll-back capabilities
----------------------

Define the roll-back capabilities of the role

Argument Specification
----------------------

Including an example of how to add an argument Specification file that validates the arguments provided to the role.

```
argument_specs:
  main:
    short_description: Role description.
    options:
      string_arg1:
        description: string argument description.
        type: "str"
        default: "x"
        choices: ["x", "y"]
```

License
-------

# TO-DO: Update the license to the one you want to use (delete this line after setting the license)
BSD

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).

## Argument Reference

### common

Role description.

|                                              Name                                               |             Type             | Required |      Default      |                                                                                                                                           Description                                                                                                                                           |
| ----------------------------------------------------------------------------------------------- | :--------------------------: | :------: | :---------------: | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| <a name="common_hostname"></a>`common_hostname`                                                 |            `str`             |    No    |                   | If specified, set hostname.                                                                                                                                                                                                                                                                     |
| <a name="common_journald_persistent"></a>`common_journald_persistent`                           |            `bool`            |    No    |      `false`      | boolean variable which governs where journald stores log file. When set to `true` the logs will be stored on disk in `/var/log/journal/`. Defaults to `false`, i.e. volatile journal storage.                                                                                                   |
| <a name="common_journald_max_disk_size"></a>`common_journald_max_disk_size`                     |            `int`             |    No    |                   | integer variable, in megabytes, that governs how much disk space can journal files occupy before some of them are deleted. No implicit value is configured by the role, hence default sizing calculation described in `man 5 journald.conf` applies.                                            |
| <a name="common_journald_max_file_size"></a>`common_journald_max_file_size`                     |            `int`             |    No    |                   | integer variable, in megabytes, describes the maximum size of single journal file. No implicit configuration is set up by the role.                                                                                                                                                             |
| <a name="common_journald_per_user"></a>`common_journald_per_user`                               |            `bool`            |    No    |                   | boolean variable, allows to configure whether journald should keep log data separate for each user, e.g. allowing unprivileged users to read system log from their own user services. Defaults to `true`. Note that per user journal files are available only when `journald_persistent: true`. |
| <a name="common_journald_compression"></a>`common_journald_compression`                         |            `bool`            |    No    |                   | boolean variable instructs journald to apply compression to journald data objects that are bigger than default 512 bytes. Defaults to `true`.                                                                                                                                                   |
| <a name="common_journald_sync_interval"></a>`common_journald_sync_interval`                     |            `int`             |    No    |                   | integer variable, in minutes, configures the time span after which journald synchronizes the currently used journal file to disk. By default role doesn't alter currently used value. This setting is only applicable for `journald_persistent: true`. You will get a warning if set otherwise. |
| <a name="common_journald_forward_to_syslog"></a>`common_journald_forward_to_syslog`             |            `bool`            |    No    |                   | boolean variable, control whether log messages received by the journal daemon shall be forwarded to a traditional syslog daemon. Defaults to `false`.                                                                                                                                           |
| <a name="common_journald_rate_limit_interval_sec"></a>`common_journald_rate_limit_interval_sec` |            `int`             |    No    |                   | integer variable, in seconds, configures the time interval within which only journald_rate_limit_burst messages are handled. See `man 5 journald.conf` for more information.                                                                                                                    |
| <a name="common_journald_rate_limit_burst"></a>`common_journald_rate_limit_burst`               |            `int`             |    No    |                   | integer variable, sets the upper limit of messages from a service which are handled within the time defined by `journald_rate_limit_interval_sec`. See `man 5 journald.conf` for more information.                                                                                              |
| <a name="common_journald_keep_free"></a>`common_journald_keep_free`                             |            `int`             |    No    |                   | integer variable in megabytes, sets the amount of filesystem space in megabytes that should be kept free if the system (persistent or volatile) is close to filling up. See `man 5 journald.conf` for more information                                                                          |
| <a name="common_journald_max_retention"></a>`common_journald_max_retention`                     |            `int`             |    No    |                   | integer variable, in minutes, sets how long journal entries can be retained before they are deleted. No implicit value is configured by the role.                                                                                                                                               |
| <a name="common_ca_certificates"></a>`common_ca_certificates`                                   |         `list[path]`         |    No    |                   | If specified, CA certificates to install in the system CA trust store. Must be a list of local path to PEM or DER formatted certificates.                                                                                                                                                       |
| <a name="common_dns_servers"></a>`common_dns_servers`                                           |         `list[str]`          |    No    |                   | List of DNS servers to use, if not set will use the default value generally provided by the DHCP server. If [`common_dns_over_tls`](#common_dns_over_tls) is `yes`, it is recommended to servers values to `address#server_name` to allow certificate validation.                               |
| <a name="common_dns_servers_fallback"></a>`common_dns_servers_fallback`                         |         `list[str]`          |    No    |                   | List of fallback DNS servers to use, if not set will use the default value generally provided by the DHCP server. If [`common_dns_over_tls`](#common_dns_over_tls) is `yes`, it is recommended to servers values to `address#server_name` to allow certificate validation.                      |
| <a name="common_dns_over_tls"></a>`common_dns_over_tls`                                         | `yes`, `no`, `opportunistic` |    No    | `"opportunistic"` | Enable DNS over TLS. `true` is recommended if DNS server support DNS over TLS because `opportunistic` mode is more vulnerable. `no` to enforce classical unencrypted DNS.                                                                                                                       |
| <a name="common_dnssec"></a>`common_dnssec`                                                     |            `bool`            |    No    |                   | If `true`, enforce DNSSEC validation locally, else use default configuration. The DNS server must support DNSSEC.                                                                                                                                                                               |
| <a name="common_domain"></a>`common_domain`                                                     |            `str`             |    No    |                   | Domain/FQDN of the current machine.                                                                                                                                                                                                                                                             |
| <a name="common_os_hardening"></a>`common_os_hardening`                                         |            `bool`            |    No    |      `true`       | If true, apply the OS hardening baseline.                                                                                                                                                                                                                                                       |
| <a name="common_login_password_min_length"></a>`common_login_password_min_length`               |            `int`             |    No    |       `12`        | Minimum password size                                                                                                                                                                                                                                                                           |
| <a name="common_dnf_automatic_on_shutdown"></a>`common_dnf_automatic_on_shutdown`               |            `bool`            |    No    |      `false`      | If `true`, trigger DNF automatic updates on system shutdown instead of using timer.  Ignored on Ostree based OS.                                                                                                                                                                                |
| <a name="common_dnf_automatic_restart"></a>`common_dnf_automatic_restart`                       |            `bool`            |    No    |      `true`       | If `true`, restart the host if required when performing DNF automatic updates. Disabled if [`common_dnf_automatic_on_shutdown`](#common_dnf_automatic_on_shutdown) is `true`.  Ignored on Ostree based OS.                                                                                      |
| <a name="common_dnf_automatic_upgrade_type"></a>`common_dnf_automatic_upgrade_type`             |    `default`, `security`     |    No    |    `"default"`    | The type of update installed by DNF automatic. Possibles values are `default` (All available updates) or `security` (Only security updates, may improve stability).  Ignored on Ostree based OS.                                                                                                |
| <a name="common_dnf_fastestmirror"></a>`common_dnf_fastestmirror`                               |            `bool`            |    No    |      `false`      | If `true`, If enabled a metric is used to find the fastest available mirror. This is often dynamically generated by the server to provide the best download speeds and enabling `fastestmirror` overrides this.  Ignored on Ostree based OS.                                                    |
| <a name="common_dnf_install_weak_deps"></a>`common_dnf_install_weak_deps`                       |            `bool`            |    No    |      `false`      | If `true`, configure DNF to install weak dependencies.  Ignored on Ostree based OS.                                                                                                                                                                                                             |
| <a name="common_dnf_keepcache"></a>`common_dnf_keepcache`                                       |            `bool`            |    No    |      `false`      | If `true`, configure DNF to keep the package cache.  Ignored on Ostree based OS.                                                                                                                                                                                                                |
| <a name="common_dnf_nodocs"></a>`common_dnf_nodocs`                                             |            `bool`            |    No    |      `true`       | If `true`, disable documentation installation.                                                                                                                                                                                                                                                  |
| <a name="common_dnf_proxy"></a>`common_dnf_proxy`                                               |            `str`             |    No    |                   | URL of a proxy server to connect through. The expected format of this option is `<scheme>://<ip-or-hostname>[:port]`. If you configured another host with the squid role, you may set this value to `http://<squid-host-ip-or-hostname>:<squid-port>`.  Ignored on Ostree based OS.             |
| <a name="common_dnf_proxy_auth_method"></a>`common_dnf_proxy_auth_method`                       |            `str`             |    No    |                   | If the proxy requires authentication, the authentication method to use.  Ignored on Ostree based OS.                                                                                                                                                                                            |
| <a name="common_dnf_proxy_password"></a>`common_dnf_proxy_password`                             |            `str`             |    No    |                   | If the proxy requires authentication, the password to use.  Ignored on Ostree based OS.                                                                                                                                                                                                         |
| <a name="common_dnf_proxy_username"></a>`common_dnf_proxy_username`                             |            `str`             |    No    |                   | If the proxy requires authentication, the username to use.  Ignored on Ostree based OS.                                                                                                                                                                                                         |
| <a name="common_dnf_sslcacert"></a>`common_dnf_sslcacert`                                       |            `path`            |    No    |                   | If specified, file containing the certificate authorities to verify SSL certificates. If not specified, use system defaults. Can be used to specify proxy certificate when used with [`common_dnf_proxy`](#common_dnf_proxy).  Ignored on Ostree based OS.                                      |


