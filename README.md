<!--
SPDX-FileCopyrightText: 2023 Slavi Pantaleev
SPDX-FileCopyrightText: 2024 Bergrübe
SPDX-FileCopyrightText: 2026 Suguru Hirahara

SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Stirling PDF v1 Ansible role

>[!WARNING]
> This role is in maintenance mode. While Stirling PDF itself continues to be actively developed, this role is configured to install version 1 and will not support version 2, because it enforces Open Core license since [v2.0.0](https://github.com/Stirling-Tools/Stirling-PDF/releases/tag/v2.0.0).
>
> Version [1.6.0](https://github.com/Stirling-Tools/Stirling-PDF/releases/tag/v1.6.0) is upstream's last v1 release, so this role has a finite amount of upstream left to follow.

This is an [Ansible](https://www.ansible.com/) role which installs [Stirling PDF](https://github.com/Stirling-Tools/Stirling-PDF) to run as a [Docker](https://www.docker.com/) container wrapped in a systemd service.

This role *implicitly* depends on:

- [`com.devture.ansible.role.playbook_help`](https://github.com/devture/com.devture.ansible.role.playbook_help)
- [`com.devture.ansible.role.systemd_docker_base`](https://github.com/devture/com.devture.ansible.role.systemd_docker_base)

Check [`defaults/main.yml`](defaults/main.yml) for the full list of supported options. Refer to [this page](docs/configuring-stirling-pdf.md) for details about setting up the service with this role.

💡 For an Ansible playbook which integrates this role and makes it easier to use, see the [Mother-of-All-Self-Hosting Ansible playbook](https://github.com/mother-of-all-self-hosting/mash-playbook).

## Things worth knowing before exposing it

### There is no authentication by default

This role does not enable Stirling PDF's login, so **anyone who can reach the service can use it**, and can therefore upload documents to it and download whatever is in its working directories. If you publish it on a public hostname through the reverse proxy, put something in front of it.

Two ways to do that:

- HTTP Basic authentication at the reverse proxy, through `stirling_pdf_container_labels_traefik_middleware_basic_auth_enabled` and `stirling_pdf_container_labels_traefik_middleware_basic_auth_users`
- Stirling PDF's own login, through `stirling_pdf_environment_variables_additional_variables`:

  ```yaml
  stirling_pdf_environment_variables_additional_variables: |
    SECURITY_ENABLELOGIN=true
    SECURITY_INITIALLOGIN_USERNAME=your-username
    SECURITY_INITIALLOGIN_PASSWORD=your-password
  ```

  These environment variables take effect even though `security.enableLogin` in the settings file that Stirling PDF maintains under `{{ stirling_pdf_data_path }}/config/settings.yml` keeps saying `false` - environment variables override that file rather than rewrite it.

### It reports usage statistics by default

On a fresh installation Stirling PDF turns its analytics (PostHog and the Scarf pixel) on by itself, because the setting it ships defaults to "ask the administrator", which a container deployment cannot do. To turn it off:

```yaml
stirling_pdf_environment_variables_additional_variables: |
  SYSTEM_ENABLEANALYTICS=false
```

## Development

### pre-commit

You can optionally install a Git pre-commit hook (via [mise](https://mise.jdx.dev/) + [prek](https://prek.j178.dev/)) that runs formatting and linting checks before each commit. See [`.pre-commit-config.yaml`](./.pre-commit-config.yaml) for which hooks are to be executed.

To install the hook, run the [`just`](https://github.com/casey/just) command below:

```sh
just prek-install-git-pre-commit-hook
```

### Molecule

This role supports [Molecule](https://docs.ansible.com/projects/molecule/), an Ansible testing framework designed for developing and testing Ansible collections, playbooks, and roles.

Refer to [this page](./molecule/README.md) for details about how to utilize it.
