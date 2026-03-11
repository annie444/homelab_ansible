# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

The `annie444.homelab` Ansible Galaxy collection. It targets **Fedora 41/42/43** and **RHEL/EL 9/10** and is published to Ansible Galaxy. Requires `ansible-core >= 2.15`.

The collection currently ships one role: `annie444.homelab.common` — a comprehensive system hardening and baseline configuration role.

## Commands

All Python tooling uses `uv`. Install dependencies for a specific workflow with `uv sync --locked --only-group <group>`.

### Linting

```bash
uv sync --dev
uv run ansible-lint
```

### Tests (tox-ansible)

Generate the test matrix (lists available environments):

```bash
uv sync --dev --all-extras
uv run -m tox --ansible --gh-matrix --matrix-scope sanity --conf tox-ansible.ini
uv run -m tox --ansible --gh-matrix --matrix-scope unit --conf tox-ansible.ini
```

Run a specific tox environment (e.g. `sanity-py3.13-2.17`):

```bash
uv sync --dev --all-extras
uv run -m tox --ansible -e sanity-py3.13-2.17 --conf tox-ansible.ini
uv run -m tox --ansible -e unit-py3.13-2.17 --conf tox-ansible.ini
```

Run integration tests (requires RHEL secrets in CI environment):

```bash
uv run -m tox --ansible -e integration-py3.13-2.17 --conf tox-ansible.ini -- -vvv
```

### Molecule (end-to-end role testing)

Requires Podman with the ability to run privileged containers (systemd as PID 1 inside the container needs `--privileged`, `SYS_ADMIN`, and the `/sys/fs/cgroup` bind-mount):

```bash
uv sync --dev --all-extras
cd extensions
uv run molecule test -s integration_common
```

For iterative development:

```bash
cd extensions
uv run molecule converge -s integration_common
uv run molecule verify -s integration_common
uv run molecule destroy -s integration_common
```

The `integration_common` scenario targets both `common-fedora42` and `common-fedora43` hosts simultaneously, using `registry.fedoraproject.org/fedora-bootc:42` and `fedora-bootc:43` images. The `default/` scenario directory holds the shared playbooks (converge, verify, create, destroy, cleanup) that all scenarios reference. Molecule dependencies (`community.general`, `containers.podman`) are installed automatically via the galaxy dependency step.

### Changelog

```bash
uv sync --dev --all-extras
uv run antsibull-changelog lint          # validate fragments
uv run antsibull-changelog release       # generate CHANGELOG.md from fragments
```

Changelog fragments go in `changelogs/fragments/`. The output file is `CHANGELOG.md`. Every PR requires a changelog fragment unless labelled `skip-changelog`.

### Build

```bash
uv sync --dev --all-extras
uv run ansible-galaxy collection build -v --force
```

### Pre-commit (prek)

Pre-commit hooks are configured in `prek.toml` (not `.pre-commit-config.yaml`). Hooks run: `prettier` (YAML/TOML formatting), `ruff-check`/`ruff-format` (Python), `isort`, `update-docs` (regenerates collection docs from role metadata), and standard checks (trailing whitespace, merge conflicts, etc.).

## Architecture

### Collection layout

```
annie444/homelab/           ← Galaxy namespace/name
├── roles/common/           ← The only role; see below
├── plugins/
│   ├── filter/sample_filter.py
│   ├── action/sample_action.py
│   └── ...                 ← other plugin stubs
├── extensions/
│   ├── ee/                 ← ansible-builder Execution Environment definitions
│   │   ├── fedora-41/42/, rhel-9/10/
│   │   └── requirements.yml
│   ├── molecule/
│   │   ├── default/        ← shared converge/verify/create/destroy playbooks
│   │   └── integration_common/  ← inventory for integration scenario
│   └── eda/rulebooks/      ← Event-Driven Ansible rulebook stub
├── meta/runtime.yml        ← requires_ansible: ">=2.15.0"
├── changelogs/             ← antsibull-changelog config + fragments
├── tox-ansible.ini         ← skips py<3.10 and ansible<2.14
└── pyproject.toml          ← uv dependency groups: build, changelog, dev, ee, lint, matrix, scripts, test
```

### `common` role task flow

`roles/common/tasks/main.yml` orchestrates everything via `include_tasks`. Execution order:

1. Hostname → Journald (delegates to `fedora.linux_system_roles.journald`) → CA certs
2. DNS (systemd-resolved, DoT/DNSSEC) → PAM (password policy)
3. DNF configuration + OS upgrade (skipped on ostree)
4. Firewall (firewalld) → Auditd → OS hardening → SSH hardening
5. Admin credentials (user/group/password/authorized key)
6. NTP/PTP (delegates to `fedora.linux_system_roles`) → GRUB
7. FS-cache → NFS/SMB mounts → Guest agents (Incus/QEMU) → Fail2ban → Mail (postfix relay)

Each subtask file maps 1:1 to a topic: `audit.yml`, `ca-certificates.yml`, `dns.yml`, `dnf.yml`, `dnf-upgrade.yml`, `fail2ban.yml`, `firewall.yml`, `fs-cache.yml`, `grub.yml`, `guest.yml`, `hardening-os.yml`, `hardening-ssh.yml`, `mail.yml`, `mount-nfs.yml`, `mount-smb.yml`, `ntp.yml`, `pam.yml`, `admin-credentials.yml`.

### Role variable conventions

- All variables are prefixed `common_`.
- `roles/common/meta/argument_specs.yml` is the authoritative source of documented variables and their types/defaults.
- `roles/common/defaults/main.yml` sets runtime defaults (can be overridden by inventory).
- `common_ostree` is an internal computed fact (`ansible_pkg_mgr == 'atomic_container'`) that gates all DNF tasks.
- `common_admin_user` is the only **required** variable.

### Supported platforms

Fedora 41, 42, 43 and EL (RHEL) 9, 10. Tested with ansible-core 2.17+. The `tox-ansible.ini` skips Python <3.10 and ansible-core <2.14.

### CI overview

- `tests.yml`: changelog lint → build/galaxy-importer → ansible-lint → dynamic tox matrix → sanity/unit/integration
- `tag.yml`: triggered on `v*.*.*` tags; builds collection tarball and creates a GitHub Release
- `release.yml`: triggered on GitHub Release publish; publishes to Ansible Galaxy
- Integration jobs run in the `rhel` GitHub environment (requires `RHEL_USERNAME`/`RHEL_PASSWORD` secrets)
