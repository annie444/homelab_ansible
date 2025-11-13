# Annie444 Homelab Collection

This repository contains the `annie444.homelab` Ansible Collection.

<!--start requires_ansible-->
<!--end requires_ansible-->

## External requirements

Some modules and plugins require external libraries. Please check the
requirements for each plugin or module you use in the documentation to find out
which requirements are needed.

## Included content

<!--start collection content-->
<!--end collection content-->

## Using this collection

```bash
    ansible-galaxy collection install annie444.homelab
```

You can also include it in a `requirements.yml` file and install it via
`ansible-galaxy collection install -r requirements.yml` using the format:

```yaml
collections:
  - name: annie444.homelab
```

To upgrade the collection to the latest available version, run the following
command:

```bash
ansible-galaxy collection install annie444.homelab --upgrade
```

You can also install a specific version of the collection, for example, if you
need to downgrade when something is broken in the latest version (please report
an issue in this repository). Use the following syntax where `X.Y.Z` can be any
[available version](https://galaxy.ansible.com/annie444/homelab):

```bash
ansible-galaxy collection install annie444.homelab:==X.Y.Z
```

See
[Ansible Using Collections](https://docs.ansible.com/ansible/latest/user_guide/collections_using.html)
for more details.

## Release notes

See the
[changelog](https://github.com/ansible-collections/annie444.homelab/tree/main/CHANGELOG.rst).

## Testing changes locally

The collection now ships with two Incus/LXD Molecule scenarios
(`extensions/molecule/incus-fedora42` and `extensions/molecule/incus-fedora43`)
that exercise `annie444.homelab.common` end-to-end on Fedora 42/43.

To run them locally:

1. Install [Incus](https://linuxcontainers.org/incus/) and create a private bridge
   (for example `incusbr0`) plus a profile that enables `security.nesting` and
   `security.privileged`.
2. Ensure the Incus client is authenticated for your user and that the bridge is
   reachable from the host that runs Molecule.
3. Install the testing dependencies:
   ```bash
   uv sync --group test
   ```
4. Execute Molecule via tox (this automatically installs `molecule-plugins[lxd]`):
   ```bash
   tox -e fedora42-common
   tox -e fedora43-common
   ```

Both scenarios drive `annie444.homelab.common` end-to-end with systemd enabled
inside the container so that service-level interactions can be validated without
resorting to privileged Podman instances.

The repository now includes `.github/workflows/molecule-incus.yml`, which:

- Builds a test matrix that only targets roles touched in a PR (using
  `scripts/determine_changed_roles.sh`).
- Runs the tox/Molecule matrix on a self-hosted `self-hosted, linux, incus-runner`
  GitHub Actions runner.
- Posts live status updates (including a badge) back to the PR so reviewers can
  see which Fedora versions succeeded.

If you self-host the runner, make sure it has Incus installed and can reach the
images listed above.

## Roadmap

<!-- Optional. Include the roadmap for this collection, and the proposed release/versioning strategy so users can anticipate the upgrade/update cycle. -->

## More information

<!-- List out where the user can find additional information, such as working group meeting times, slack/matrix channels, or documentation for the product this collection automates. At a minimum, link to: -->

- [Ansible collection development forum](https://forum.ansible.com/c/project/collection-development/27)
- [Ansible User guide](https://docs.ansible.com/ansible/devel/user_guide/index.html)
- [Ansible Developer guide](https://docs.ansible.com/ansible/devel/dev_guide/index.html)
- [Ansible Collections Checklist](https://docs.ansible.com/ansible/devel/community/collection_contributors/collection_requirements.html)
- [Ansible Community code of conduct](https://docs.ansible.com/ansible/devel/community/code_of_conduct.html)
- [The Bullhorn (the Ansible Contributor newsletter)](https://docs.ansible.com/ansible/devel/community/communication.html#the-bullhorn)
- [News for Maintainers](https://forum.ansible.com/tag/news-for-maintainers)

## Licensing

GNU General Public License v3.0 or later.

See [LICENSE](https://www.gnu.org/licenses/gpl-3.0.txt) to see the full text.
