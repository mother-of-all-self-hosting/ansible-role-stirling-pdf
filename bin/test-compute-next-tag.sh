#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Slavi Pantaleev
#
# SPDX-License-Identifier: AGPL-3.0-or-later

# Exercises bin/compute-next-tag.sh against throwaway git repositories.
#
# Usage: bin/test-compute-next-tag.sh
#
# Every scenario creates a repository in a temporary directory, gives it role
# files and a release history, and then replays a series of merges through the
# real script, tagging as it goes just like the autotag workflow does. This
# repository is never touched and no network access is needed.

set -euo pipefail

script_under_test="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/compute-next-tag.sh"

failures=0
workdir=''

cleanup() {
	cd /
	if [ -n "$workdir" ]; then
		rm -rf "$workdir"
		workdir=''
	fi
}

trap cleanup EXIT

# The fixture mirrors the shape of the real defaults/main.yml: the Renovate
# annotation that decides which line gets bumped, the leaf variable itself
# (carrying the image variant suffix), and the Jinja-derived variables around
# it. A refactor that makes the script read one of the derived variables
# instead of the leaf would make several scenarios below fail.
write_defaults() {
	local version="$1"

	cat > defaults/main.yml <<-EOF
		# renovate: datasource=docker depName=docker.io/stirlingtools/stirling-pdf versioning=docker
		stirling_pdf_version: ${version}

		stirling_pdf_container_image: "{{ stirling_pdf_container_image_registry_prefix }}stirlingtools/stirling-pdf:{{ stirling_pdf_container_image_tag }}"
		stirling_pdf_container_image_tag: "{{ stirling_pdf_version }}"
		stirling_pdf_container_image_registry_prefix: "{{ stirling_pdf_container_image_registry_prefix_upstream }}"
	EOF
}

# Starts a scenario with a repository at Stirling PDF 1.5.0-fat which has
# already seen two releases of it (v1.5.0-0 and v1.5.0-1).
scenario() {
	echo "$1"

	cleanup
	workdir="$(mktemp -d)"

	mkdir -p "$workdir/bin" "$workdir/defaults" "$workdir/tasks" "$workdir/templates"
	cp "$script_under_test" "$workdir/bin/"
	cd "$workdir"

	git init -q -b main .
	git config user.email 'test@example.com'
	git config user.name 'Test'
	git config commit.gpgsign false

	write_defaults '1.5.0-fat'
	printf 'placeholder\n' > tasks/main.yml
	printf 'placeholder\n' > templates/env.j2
	printf 'placeholder\n' > README.md

	git add -A
	git commit -qm 'Initial commit'

	local release_number
	for release_number in 0 1; do
		git tag "v1.5.0-$release_number"
	done
}

# Applies a change, commits it, and tags whatever the script says it should be.
# Prints the tag, or nothing when the script decided against a release.
merge() {
	local change="$1" tag

	eval "$change"
	git add -A
	git commit -qm 'Merge'

	tag="$(bin/compute-next-tag.sh 2>/dev/null)"

	if [ -n "$tag" ]; then
		git tag "$tag"
	fi

	printf '%s' "$tag"
}

# Like merge(), but for changes after which the script is expected to refuse to
# compute anything at all. Prints the exit code instead of a tag.
merge_expecting_refusal() {
	local change="$1" exit_code=0

	eval "$change"
	git add -A
	git commit -qm 'Merge'

	bin/compute-next-tag.sh >/dev/null 2>&1 || exit_code="$?"

	printf '%s' "$exit_code"
}

expect() {
	local description="$1" expected="$2" actual="$3"

	if [ "$actual" = "$expected" ]; then
		printf '  ok   | %s -> %s\n' "$description" "${actual:-no release}"
	else
		printf '  FAIL | %s -> expected %s, got %s\n' "$description" "${expected:-no release}" "${actual:-no release}"
		failures=$((failures + 1))
	fi
}

bump_version="write_defaults 1.6.0-fat"
revert_version="write_defaults 1.5.0-fat"
switch_variant="write_defaults 1.5.0-ultra-lite"
drop_variant="write_defaults 1.6.0"
break_version="write_defaults '{{ some_other_variable }}'"
edit_task="printf 'a task\n' >> tasks/main.yml"
edit_template="printf 'a line\n' >> templates/env.j2"
edit_readme="printf 'documentation\n' >> README.md"
edit_script="printf '# a comment\n' >> bin/compute-next-tag.sh"

# The two merge orders below apply the same updates and must each end up with
# every update released exactly once, whichever order they arrive in.

scenario 'A version bump merged before other role changes'
expect 'version bump' v1.6.0-0 "$(merge "$bump_version")"
expect 'task edit'    v1.6.0-1 "$(merge "$edit_task")"
expect 'template'     v1.6.0-2 "$(merge "$edit_template")"

scenario 'A version bump merged after other role changes'
expect 'task edit'    v1.5.0-2 "$(merge "$edit_task")"
expect 'version bump' v1.6.0-0 "$(merge "$bump_version")"

scenario 'Commits that do not affect the role'
expect 'README'   ''       "$(merge "$edit_readme")"
expect 'a script' ''       "$(merge "$edit_script")"
expect 'a task'   v1.5.0-2 "$(merge "$edit_task")"

scenario 'Release numbers past 9'
for release_number in 2 3 4 5 6 7 8 9 10; do
	git tag "v1.5.0-$release_number"
done
expect 'a task' v1.5.0-11 "$(merge "$edit_task")"

scenario 'Reverting to an already released version'
merge "$bump_version" > /dev/null
# The role is now identical to what v1.5.0-1 already published, so there is
# nothing new to release.
expect 'a revert' ''       "$(merge "$revert_version")"

scenario 'Reverting to an already released version, with a change'
merge "$bump_version" > /dev/null
expect 'a revert' v1.5.0-2 "$(merge "$revert_version && $edit_task")"

# The image variant suffix is not part of the release, so switching it is an
# ordinary role change against the same Stirling PDF version - it must roll the
# counter rather than start a `v1.5.0-ultra-lite-…` series of its own.
scenario 'Switching the image variant'
expect 'variant switch' v1.5.0-2 "$(merge "$switch_variant")"

scenario 'A version pinned without a variant suffix'
expect 'variant dropped' v1.6.0-0 "$(merge "$drop_variant")"

# A refactor pointing the script at one of the Jinja-derived variables, or a
# version that stops being a plain literal, must fail loudly rather than tag
# something like `v{{-0`.
scenario 'A version that is not a plain literal'
expect 'refusal exit code' 1 "$(merge_expecting_refusal "$break_version")"

if [ "$failures" -gt 0 ]; then
	echo >&2 "$failures scenario(s) behaved unexpectedly"
	exit 1
fi

echo 'All scenarios behaved as expected'
