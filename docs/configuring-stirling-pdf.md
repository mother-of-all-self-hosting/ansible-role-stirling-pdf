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

# Setting up Borg Web UI

This is an [Ansible](https://www.ansible.com/) role which installs [Borg Web UI](https://github.com/karanhudia/borg-ui) to run as a [Docker](https://www.docker.com/) container wrapped in a systemd service.

Borg Web UI is an unofficial web interface for [BorgBackup](https://borgbackup.readthedocs.io/).

See the project's [documentation](https://docs.borgui.com/) to learn what Borg Web UI does and why it might be useful to you.

>[!NOTE]
> Please note that `2.0.0` has introduced a separation into "pro" and "peasant" editions.
>
> See: <https://github.com/karanhudia/borg-ui/commit/db800f90dce74c35ae3e7d53aa2622c9cd73b5d9>

## Adjusting the playbook configuration

To enable Borg Web UI with this role, add the following configuration to your `vars.yml` file.

**Note**: the path should be something like `inventory/host_vars/mash.example.com/vars.yml` if you use the [MASH Ansible playbook](https://github.com/mother-of-all-self-hosting/mash-playbook).

```yaml
########################################################################
#                                                                      #
# borg_ui                                                              #
#                                                                      #
########################################################################

borg_ui_enabled: true

########################################################################
#                                                                      #
# /borg_ui                                                             #
#                                                                      #
########################################################################
```

### Set the hostname

To enable the Borg Web UI instance you need to set the hostname as well. To do so, add the following configuration to your `vars.yml` file. Make sure to replace `example.com` with your own value.

```yaml
borg_ui_hostname: "example.com"
```

After adjusting the hostname, make sure to adjust your DNS records to point the domain to your server.

### Set a random string

You also need to set a random string used for session management. To do so, add the following configuration to your `vars.yml` file. The value can be generated with `pwgen -s 64 1` or in another way.

```yaml
borg_ui_environment_variables_secret_key: YOUR_SECRET_KEY_HERE
```

### Configuring initial admin password (optional)

You can set an initial password for the administrator by adding the following configuration to your `vars.yml` file:

```yaml
borg_ui_environment_variables_initial_admin_password: ADMIN_PASSWORD_HERE
```

>[!NOTE]
> If `borg_ui_environment_variables_initial_admin_password` is not specified, the administrator user will be created with the default password on the first startup. The default credentials can be checked at <https://docs.borgui.com/installation#start-borg-ui>.

### Configuring a Redis database (optional)

You can optionally enable a [Redis](https://redis.io/) database for the Borg Web UI instance. [Valkey](https://valkey.io/) can also be used instead.

To enable the Redis database for Borg Web UI, add the following configuration to your `vars.yml` file. Note that the role is by default configured to establish connection with the Redis database via the Unix socket.

```yaml
# Specify the path to the Redis Unix socket path on the host (bind-mount source)
borg_ui_redis_socket_path_host: ""
```

If TCP connection is preferred, connection via the Unix socket can be disabled by adding the following configuration to your `vars.yml` file:

```yaml
# Disable the connection to Redis via a Unix socket
borg_ui_redis_socket_enabled: false

borg_ui_redis_hostname: YOUR_REDIS_SERVER_HOSTNAME_HERE
```

Make sure to replace `YOUR_REDIS_SERVER_HOSTNAME_HERE` with your own value.

If you are looking for an Ansible role for Redis, you can check out [ansible-role-redis](https://github.com/mother-of-all-self-hosting/ansible-role-redis) maintained by the [Mother-of-All-Self-Hosting (MASH)](https://github.com/mother-of-all-self-hosting) team. The role for Valkey ([ansible-role-valkey](https://github.com/mother-of-all-self-hosting/ansible-role-valkey)) is available as well.

### Integrating with Prometheus (optional)

Borg Web UI can natively expose metrics to Prometheus.

If you are looking for an integration, you can check out the MASH playbook. See [this section of the documentation on the playbook](https://github.com/mother-of-all-self-hosting/mash-playbook/blob/main/docs/services/borg-ui.md#integrating-with-prometheus-optional) for more information.

### Extending the configuration

There are some additional things you may wish to configure about the service.

Take a look at:

- [`defaults/main.yml`](../defaults/main.yml) for some variables that you can customize via your `vars.yml` file. You can override settings (even those that don't have dedicated playbook variables) using the `borg_ui_environment_variables_additional_variables` variable

See [this page](https://docs.borgui.com/configuration) on the official documentation for details about how to customize the instance.

## Installing

After configuring the playbook, run the installation command of your playbook as below:

```sh
ansible-playbook -i inventory/hosts setup.yml --tags=setup-all,start
```

If you use the MASH playbook, the shortcut commands with the [`just` program](https://github.com/mother-of-all-self-hosting/mash-playbook/blob/main/docs/just.md) are also available: `just install-all` or `just setup-all`

## Usage

After running the command for installation, Borg Web UI becomes available at the specified hostname like `https://example.com`.

The default login credentials can be checked at <https://docs.borgui.com/installation#start-borg-ui>.

To back up directories, it is necessary for them to be mounted to the container by specifying them with `borg_ui_container_additional_volumes_custom`. The default path inside the container to be backed up is `/local`.

Using different paths requires for them to be specified with the `LOCAL_MOUNT_POINTS` environment variable. Refer to [this section](https://docs.borgui.com/usage-guide#choose-backup-sources) on the page for details.

## Troubleshooting

### Check the service's logs

You can find the logs in [systemd-journald](https://www.freedesktop.org/software/systemd/man/systemd-journald.service.html) by logging in to the server with SSH and running `journalctl -fu borg-ui` (or how you/your playbook named the service, e.g. `mash-borg-ui`).

#### Increase logging verbosity

If you want to increase the verbosity, add the following configuration to your `vars.yml` file:

```yaml
borg_ui_environment_variables_log_level: debug
```
