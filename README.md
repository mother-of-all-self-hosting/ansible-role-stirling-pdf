<!--
SPDX-FileCopyrightText: 2023 Slavi Pantaleev
SPDX-FileCopyrightText: 2024 Bergrübe
SPDX-FileCopyrightText: 2026 Suguru Hirahara

SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Warning
This role is no longer actively maintained. While Stirling-PDF itself continues to be actively developed, this role does not support Stirling-PDF v2 and no further updates are planned.

Consider using one of the following alternatives in the MASH-Playbook instead:

- [BentoPDF](https://github.com/mother-of-all-self-hosting/mash-playbook/blob/main/docs/services/bentopdf.md)
- [OmniTools](https://github.com/mother-of-all-self-hosting/mash-playbook/blob/main/docs/services/omnitools.md)

You can ignore this warning, by setting `stirling_pdf_show_warning = false`


# ansible-role-stirling_pdf
An ansible role developed for the MASH-Playbook to install Stirling PDF.
It is inspired by the following projects:

- [Mother of All Self Hosting - GotoSocial Role](https://github.com/mother-of-all-self-hosting/ansible-role-gotosocial)
- [Mother of All Self Hosting - Gitea Role](https://github.com/mother-of-all-self-hosting/ansible-role-gitea)

## Requirements

- Docker
- Ansible
- [MASH playbook](https://github.com/mother-of-all-self-hosting/mash-playbook)

## Usage
See the guide in  [MASH playbook](https://github.com/mother-of-all-self-hosting/mash-playbook/blob/main/docs/services/stirling-pdf.md) repo.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

If you encounter any problems or have any questions, please open an issue on GitHub.

## Development

You can optionally install a Git pre-commit hook (via [mise](https://mise.jdx.dev/) + [prek](https://prek.j178.dev/)) that runs formatting and linting checks before each commit. See [`.pre-commit-config.yaml`](./.pre-commit-config.yaml) for which hooks are to be executed.

To install the hook, run the [`just`](https://github.com/casey/just) command below:

```sh
just prek-install-git-pre-commit-hook
```
