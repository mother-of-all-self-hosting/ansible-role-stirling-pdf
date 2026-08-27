<!--
SPDX-FileCopyrightText: 2020 Aaron Raimist
SPDX-FileCopyrightText: 2020 Chris van Dijk
SPDX-FileCopyrightText: 2020 Dominik Zajac
SPDX-FileCopyrightText: 2020 Mickaël Cornière
SPDX-FileCopyrightText: 2020-2024 MDAD project contributors
SPDX-FileCopyrightText: 2020-2024 Slavi Pantaleev
SPDX-FileCopyrightText: 2022 François Darveau
SPDX-FileCopyrightText: 2022 Julian Foad
SPDX-FileCopyrightText: 2022 Warren Bailey
SPDX-FileCopyrightText: 2023 Alejandro AR
SPDX-FileCopyrightText: 2023 Antonis Christofides
SPDX-FileCopyrightText: 2023 Felix Stupp
SPDX-FileCopyrightText: 2023 Julian-Samuel Gebühr
SPDX-FileCopyrightText: 2023 Pierre 'McFly' Marty
SPDX-FileCopyrightText: 2024 Thomas Miceli
SPDX-FileCopyrightText: 2024-2026 Suguru Hirahara

SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Setting up Stirling PDF

This is an [Ansible](https://www.ansible.com/) role which installs [Stirling PDF](https://github.com/Stirling-Tools/Stirling-PDF) to run as a [Docker](https://www.docker.com/) container wrapped in a systemd service.

Stirling PDF is an online PDF converter and editor.

See the project's [documentation](https://github.com/Stirling-Tools/Stirling-PDF/blob/main/README.md) to learn what Stirling PDF does and why it might be useful to you.

## Adjusting the playbook configuration

To enable Stirling PDF with this role, add the following configuration to your `vars.yml` file.

**Note**: the path should be something like `inventory/host_vars/mash.example.com/vars.yml` if you use the [MASH Ansible playbook](https://github.com/mother-of-all-self-hosting/mash-playbook).

```yaml
########################################################################
#                                                                      #
# stirling_pdf                                                         #
#                                                                      #
########################################################################

stirling_pdf_enabled: true

########################################################################
#                                                                      #
# /stirling_pdf                                                        #
#                                                                      #
########################################################################
```

### Set the hostname

To enable the Stirling PDF instance you need to set the hostname as well. To do so, add the following configuration to your `vars.yml` file. Make sure to replace `example.com` with your own value.

```yaml
stirling_pdf_hostname: "example.com"
```

After adjusting the hostname, make sure to adjust your DNS records to point the domain to your server.

### Configuring HTTP Basic authentication

This role is configured to enable the HTTP Basic authentication on Traefik by default, considering the nature of the service. See [this page](https://doc.traefik.io/traefik/reference/routing-configuration/http/middlewares/basicauth/) on the Traefik's documentation for details.

You can use `htpasswd` to generate the user and password pair, which needs to be set to `stirling_pdf_container_labels_traefik_middleware_basic_auth_users`.

If another authentication service is used or authentication is not required at all, you can disable it by adding the following configuration to your `vars.yml` file:

```yaml
stirling_pdf_container_labels_traefik_middleware_basic_auth_enabled: false
```

### Extending the configuration

There are some additional things you may wish to configure about the service.

Take a look at:

- [`defaults/main.yml`](../defaults/main.yml) for some variables that you can customize via your `vars.yml` file. You can override settings (even those that don't have dedicated playbook variables) using the `stirling_pdf_environment_variables_additional_variables` variable

Note that the configuration file via `stirling_pdf_configuration_extension_yaml` is not encouraged, since Stirling PDF overrides it on the start. Every setting can be given as an environment variable by upper-casing its path, as Stirling PDF's own settings file explains (`security.initialLogin.username` becomes `SECURITY_INITIALLOGIN_USERNAME`).

## Installing

After configuring the playbook, run the installation command of your playbook as below:

```sh
ansible-playbook -i inventory/hosts setup.yml --tags=setup-all,start
```

If you use the MASH playbook, the shortcut commands with the [`just` program](https://github.com/mother-of-all-self-hosting/mash-playbook/blob/main/docs/just.md) are also available: `just install-all` or `just setup-all`

## Usage

After running the command for installation, Stirling PDF becomes available at the specified hostname like `https://example.com`.

## Troubleshooting

### Check the service's logs

You can find the logs in [systemd-journald](https://www.freedesktop.org/software/systemd/man/systemd-journald.service.html) by logging in to the server with SSH and running `journalctl -fu stirling-pdf` (or how you/your playbook named the service, e.g. `mash-stirling-pdf`).
