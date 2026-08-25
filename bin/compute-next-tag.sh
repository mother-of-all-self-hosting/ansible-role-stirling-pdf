#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Slavi Pantaleev
#
# SPDX-License-Identifier: AGPL-3.0-or-later

# Prints the tag that the currently checked out commit should be released as,
# or nothing at all if it does not warrant a release.
#
# Usage: bin/compute-next-tag.sh
#
# Tags look like `v<Stirling PDF version>-<release>`:
#
# - if defaults/main.yml points at a Stirling PDF version that has never been
#   released, the release counter restarts at 0 (`v1.6.0-0`)
# - otherwise the counter is incremented (`v1.6.0-1`), but only if something
#   that actually affects the role has changed since the last release
#
# `stirling_pdf_version` carries the image variant suffix that the role pins
# (`1.5.0-fat`), which is a property of the image, not of the release being cut,
# so it is stripped before the tag is assembled.
#
# Determining the version from defaults/main.yml, rather than from the commit
# message of the pull request that got merged, makes the result independent of
# the order in which pull requests get merged, and lets any change to the role
# (bugfix, feature, dependency bump) release itself without a human tagging.

set -euo pipefail

repository_path="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd -- "$repository_path"

defaults_path='defaults/main.yml'

# Paths that shape the behavior of the role for its consumers. A commit
# touching only other paths (a README fix, CI configuration, Molecule tests)
# does not change what a playbook run does, and releasing it would only create
# churn in the repositories that consume this role.
role_defining_paths=(
	'defaults'
	'meta'
	'tasks'
	'templates'
)

version_with_variant="$(sed -nE 's|^stirling_pdf_version:[[:space:]]*"?([^"[:space:]]+)"?.*$|\1|p' "$defaults_path" | head -n1)"

if [ -z "$version_with_variant" ]; then
	echo >&2 "Could not determine the Stirling PDF version from $defaults_path"
	exit 1
fi

# `1.5.0-fat` -> `1.5.0`, `1.5.0-ultra-lite` -> `1.5.0`, `1.5.0` -> `1.5.0`
version="${version_with_variant%%-*}"

# Guards against a future refactor that makes the variable Jinja-derived
# (`{{ … }}`) or otherwise unparsable, which would silently produce a
# nonsensical tag instead of failing.
if ! [[ "$version" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
	echo >&2 "The Stirling PDF version read from $defaults_path is not a plain version number: $version_with_variant"
	exit 1
fi

tag_prefix="v${version}-"

# Of all releases of this version, the highest release number. Sorted
# numerically, so that -10 is recognized as newer than -9.
last_release="$(git tag --list "${tag_prefix}*" | sed -e "s|^${tag_prefix}||" | grep -E '^[0-9]+$' | sort -n | tail -n1 || true)"

if [ -z "$last_release" ]; then
	echo >&2 "Version $version has never been released"
	echo "${tag_prefix}0"
	exit 0
fi

previous_tag="${tag_prefix}${last_release}"

if git diff --quiet "$previous_tag" HEAD -- "${role_defining_paths[@]}"; then
	echo >&2 "Nothing affecting the role has changed since $previous_tag"
	exit 0
fi

echo >&2 "The role has changed since $previous_tag"
echo "${tag_prefix}$((last_release + 1))"
