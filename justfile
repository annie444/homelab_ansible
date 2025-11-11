# Just scripts work best with ZSH
# However, some systems may not have ZSH installed by default.
# You can change this to bash or another shell if needed.
# The default (if not set) is `/bin/sh -cu`, which on macos >= 10.25
# is `zsh` anyway. On Linux systems it's usually `bash`, except for
# Ubuntu 22.04+ which uses `dash`. If you change this, ensure that
# the shell you choose supports POSIX syntax at minimum.

set shell := ["zsh", "-cu"]

# Required CLI tools

zsh := require('zsh')
crudini := require('crudini')
uv := require('uv')
jq := require('jq')
ssh := require('ssh')
git := require('git')
sed := if os() == 'macos' { if which('gsed') != "" { require('gsed') } else { require('sed') } } else { require('sed') }

# These are just here to ensure availability in the environment
# E.g. would fail early on Windows unless in WSL.

head := require('head')
awk := require('awk')
grep := require('grep')
cat := require('cat')
mkdir := require('mkdir')
cd := require('cd')

# Ansible executables

ansible := clean(join(justfile_directory(), '.venv/bin/ansible'))
ansible-inventory := clean(join(justfile_directory(), '.venv/bin/ansible-inventory'))
ansible-playbook := clean(join(justfile_directory(), '.venv/bin/ansible-playbook'))

# Ansible configuration files

ansible_basedir := clean(join(justfile_directory(), 'local_test'))
ansible_cfg := clean(join(ansible_basedir, 'ansible.cfg'))
inventory_filename := shell(crudini + ' --get ' + ansible_cfg + ' defaults inventory')
inventory_file := clean(join(ansible_basedir, inventory_filename))

# Ansible default arguments

ansible_inventory_arg := '--inventory ' + inventory_file
ansible_playbook_dir_arg := '--playbook-dir ' + ansible_basedir
ansible_default_args := ansible_playbook_dir_arg + ' ' + ansible_inventory_arg

# Determine the first host in the inventory

ansible_first_host := shell(ansible-inventory + ' ' + ansible_default_args + ' --list | ' + jq + ' -r ".[].hosts[]?" | ' + head + ' -n 1')
export FIRST_HOST := env('ANSIBLE_HOST', ansible_first_host)

# Environment information

git_root := shell(git + ' rev-parse --show-toplevel')

# Shell configurations

debug := '''
declare -a JUST_ARGS=()
if [ -n "${DEBUG:-}" ]; then
  set -x
  JUST_ARGS+=("--verbose")
else
  JUST_ARGS+=("--quiet")
fi
alias just='just "${JUST_ARGS[@]}"'
'''
activate_source := join(justfile_directory(), '.venv/bin/activate')

[private]
default:
    @just --list

# Set up the development environment
[group("dev")]
env:
    cd {{ git_root }}
    {{ uv }} sync --all-groups
    source {{ activate_source }}

# Query Ansible variables for the first host in the inventory.

# (Use `ANSIBLE_HOST` to override)
[group("dev")]
vars query='':
    #!/usr/bin/env bash
    {{ debug }}
    ANSIBLE_OUTPUT=$({{ ansible }} {{ ansible_default_args }} \
      --become --module-name ansible.builtin.setup \
      "$FIRST_HOST" | {{ awk }} 'NR > 1 { print }')
    echo "{
    $ANSIBLE_OUTPUT" | {{ jq }} '.ansible_facts{{ query }}'

test_playbook := "test"
test_playbook_file := test_playbook + ".yml"
test_playbook_absolute := clean(join(ansible_basedir, test_playbook_file))
test_playbook_relative := replace(test_playbook_absolute, git_root + "/", "")

[doc("Reset the test script")]
[group("dev")]
reset-test:
    #!/usr/bin/env bash
    {{ debug }}
    if ! {{ grep }} -q 'test.yml' {{ git_root }}/.gitignore; then
      echo {{ test_playbook_relative }} >> {{ git_root }}/.gitignore
    fi
    {{ cat }} << EOF > {{ test_playbook_absolute }}
    ---
    - name: Ansible test
      hosts: localhost
      gather_facts: true
      tasks:
        - name: Set the test var
          ansible.builtin.set_fact:
            test_var: "Hello, World!"

        - name: Debug the test var
          ansible.builtin.debug:
            var: test_var
    # vim: set ft=yaml.ansible:
    EOF

[doc("Run the test script")]
[group("dev")]
test:
    @just ansible {{ test_playbook }}

[doc("Run an Ansible playbook (auto appends `.yml` to the playbook name)")]
[group("dev")]
ansible playbook:
    #!/usr/bin/env bash
    {{ debug }}
    cd {{ ansible_basedir }}
    {{ ansible-playbook }} {{ ansible_inventory_arg }} {{ playbook }}.yml

[doc("Run a command in the development environment on the local machine")]
[group("dev")]
cmd target cmd become_user='root':
    #!/usr/bin/env bash
    {{ debug }}
    FIRST_HOST=$(just group-first-host '{{ target }}' 2>/dev/null || echo '{{ target }}')
    SSH_USER=$({{ ssh }} -G "$FIRST_HOST" | {{ awk }} '/^user / { print $2 }')
    ARGS=$(just args {{ quote(cmd) }})
    declare -a BECOME_ARGS=()
    just info "Running command as {{ become_user }} with login user $SSH_USER"
    match "{{ become_user }}"
      "${SSH_USER}":
        just debug "No become needed, SSH user matches become user."
      "root":
        just debug "Become needed. No become user needed, default user is already root."
        BECOME_ARGS+=("--become")
      _:
        just debug "Become needed, SSH user differs from become user and become user is not root."
        BECOME_ARGS+=("--become" "--become-user" "{{ become_user }}")
    end
    ANSIBLE_CMD+=("{{ target }}")
    {{ ansible }} {{ ansible_default_args }} "${BECOME_ARGS[@]}" \
      --module-name ansible.builtin.shell --args "$ARGS" "{{ target }}"

[private]
args cmd:
    #!/usr/bin/env -S uv run --script
    import json
    import shlex
    import sys
    command = {
      "cmd": '{{ cmd }}',
      "executable": "/usr/bin/bash",
    }
    print(json.dumps(command), file=sys.stderr)
    print(json.dumps(command))

[private]
group-first-host group:
    {{ ansible-inventory }} {{ ansible_inventory_arg }} --graph {{ group }} | \
      {{ grep }} '|--' | {{ grep }} -v '@' | {{ head }} -n 1 | \
      {{ awk }} '{ print $NF }' | {{ sed }} -E 's/^([|]*)--//g'

[private]
debug msg:
    #!/usr/bin/env bash
    if [[ -n "${DEBUG:-}" ]]; then
      echo -e "{{ style('debug') }}DEBUG:{{ NORMAL }}{{ msg }}"
    fi

[private]
info msg:
    @echo -e "{{ CYAN }}INFO:{{ NORMAL }}{{ msg }}"

[private]
warning msg:
    @echo -e "{{ style('warning') }}WARNING:{{ NORMAL }}{{ msg }}"

[private]
command msg:
    @echo -e "{{ style('command') }}{{ msg }}{{ NORMAL }}"
