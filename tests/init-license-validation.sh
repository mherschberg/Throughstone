#!/usr/bin/env bash
#
# Regression coverage for init.sh interactive license validation.

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-license-test.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

# copy_template DEST — copy HEAD plus current working-tree changes, without Git metadata.
copy_template() {
  local dest="$1" file
  mkdir -p "$dest"
  git -C "$ROOT" archive HEAD | tar -x -C "$dest"
  while IFS= read -r -d '' file; do
    if [ -e "$ROOT/$file" ]; then
      mkdir -p "$dest/$(dirname "$file")"
      cp -p "$ROOT/$file" "$dest/$file"
      cmp -s "$ROOT/$file" "$dest/$file" || {
        echo "FAIL: working-tree file was not copied exactly: $file" >&2
        return 1
      }
    else
      rm -f "$dest/$file"
      [ ! -e "$dest/$file" ] || {
        echo "FAIL: working-tree deletion was not applied: $file" >&2
        return 1
      }
    fi
  done < <(
    {
      git -C "$ROOT" diff --name-only -z HEAD
      git -C "$ROOT" ls-files --others --exclude-standard -z
    }
  )
}

# run_interactive_case NAME INPUT EXPECTED_TEXT — bootstrap and verify both repo licenses.
run_interactive_case() {
  local name="$1" input="$2" expected_text="$3" conflict_status
  local work="$TMP_ROOT/$name"

  copy_template "$work"
  (
    cd "$work"
    printf '%s' "$input" | ./init.sh \
      --slug="$name" \
      --desc="License validation test" \
      --holder="Throughstone Test" \
      --layout=multi \
      --collab=solo \
      --remotes=no
  ) >"$TMP_ROOT/$name.out" 2>&1

  for license_file in \
    "$work/Code/$name-docs/LICENSE" \
    "$work/prompts/LICENSE"; do
    [ -f "$license_file" ] || {
      echo "FAIL: $name did not create $license_file" >&2
      return 1
    }
    grep -Fq "$expected_text" "$license_file" || {
      echo "FAIL: $license_file did not contain '$expected_text'" >&2
      return 1
    }
  done
  for notice_file in \
    "$work/Code/$name-docs/LICENSE-THROUGHSTONE" \
    "$work/prompts/LICENSE-THROUGHSTONE"; do
    [ -f "$notice_file" ] || {
      echo "FAIL: $name did not retain $notice_file" >&2
      return 1
    }
  done
  cmp -s \
    "$work/Code/$name-docs/LICENSE-THROUGHSTONE" \
    "$work/prompts/LICENSE-THROUGHSTONE"

  mkdir -p "$work/Code/$name-api"
  "$work/Code/$name-docs/scripts/apply-project-license.sh" \
    "$work/Code/$name-api" >"$TMP_ROOT/$name-code-license.out"
  cmp -s \
    "$work/Code/$name-docs/LICENSE" \
    "$work/Code/$name-api/LICENSE"
  cmp -s \
    "$work/Code/$name-docs/LICENSE-THROUGHSTONE" \
    "$work/Code/$name-api/LICENSE-THROUGHSTONE"
  [ -f "$work/Code/$name-api/LICENSING.md" ]
  grep -Fq "does not replace or alter the project license" \
    "$work/Code/$name-api/LICENSING.md"
  "$work/Code/$name-docs/scripts/apply-project-license.sh" \
    "$work/Code/$name-api" >"$TMP_ROOT/$name-code-license-repeat.out"

  printf 'different license\n' > "$work/Code/$name-api/LICENSE"
  set +e
  "$work/Code/$name-docs/scripts/apply-project-license.sh" \
    "$work/Code/$name-api" >"$TMP_ROOT/$name-code-license-conflict.out" 2>&1
  conflict_status=$?
  set -e
  [ "$conflict_status" -eq 1 ]
  grep -Fq "refusing to overwrite different project license" \
    "$TMP_ROOT/$name-code-license-conflict.out"

  mkdir -p "$work/Code/$name-conflict"
  printf 'different license\n' > "$work/Code/$name-conflict/LICENSE"
  set +e
  "$work/Code/$name-docs/scripts/apply-project-license.sh" \
    "$work/Code/$name-conflict" >"$TMP_ROOT/$name-fresh-conflict.out" 2>&1
  conflict_status=$?
  set -e
  [ "$conflict_status" -eq 1 ]
  [ ! -e "$work/Code/$name-conflict/LICENSE-THROUGHSTONE" ]

  [ ! -d "$work/tests" ] || {
    echo "FAIL: $name retained maintainer-only tests/" >&2
    return 1
  }
}

# run_flag_case NAME LICENSE EXPECTED_TEXT — preserve flag-path normalization behavior.
run_flag_case() {
  local name="$1" license="$2" expected_text="$3"
  local work="$TMP_ROOT/$name"

  copy_template "$work"
  (
    cd "$work"
    ./init.sh \
      --non-interactive \
      --slug="$name" \
      --desc="License validation test" \
      --license="$license" \
      --holder="Throughstone Test" \
      --layout=multi \
      --collab=solo \
      --remotes=no
  ) >"$TMP_ROOT/$name.out" 2>&1

  grep -Fq "$expected_text" "$work/Code/$name-docs/LICENSE"
  grep -Fq "$expected_text" "$work/prompts/LICENSE"
}

# run_private_case NAME ARGS... — private projects should not get a project LICENSE.
run_private_case() {
  local name="$1"
  shift
  local work="$TMP_ROOT/$name"

  copy_template "$work"
  (
    cd "$work"
    "$@"
  ) >"$TMP_ROOT/$name.out" 2>&1

  [ ! -e "$work/Code/$name-docs/LICENSE" ]
  [ ! -e "$work/prompts/LICENSE" ]
  [ -f "$work/Code/$name-docs/LICENSE-THROUGHSTONE" ]
  [ -f "$work/prompts/LICENSE-THROUGHSTONE" ]
  cmp -s \
    "$work/Code/$name-docs/LICENSE-THROUGHSTONE" \
    "$work/prompts/LICENSE-THROUGHSTONE"

  mkdir -p "$work/Code/$name-api"
  "$work/Code/$name-docs/scripts/apply-project-license.sh" \
    "$work/Code/$name-api" >"$TMP_ROOT/$name-code-license.out"
  [ ! -e "$work/Code/$name-api/LICENSE" ]
  cmp -s \
    "$work/Code/$name-docs/LICENSE-THROUGHSTONE" \
    "$work/Code/$name-api/LICENSE-THROUGHSTONE"
  [ -f "$work/Code/$name-api/LICENSING.md" ]
  grep -Fq "Project-authored content in this repository is proprietary" \
    "$work/Code/$name-api/LICENSING.md"
  grep -Fq "does not grant permission" "$work/Code/$name-api/LICENSING.md"

  [ ! -d "$work/tests" ]
  ! grep -Fq "Copyright holder" "$TMP_ROOT/$name.out"
}

# run_mono_case — mono mode keeps a canonical docs-hub copy for future code repos.
run_mono_case() {
  local name="license-mono"
  local work="$TMP_ROOT/$name"

  copy_template "$work"
  (
    cd "$work"
    ./init.sh \
      --non-interactive \
      --slug="$name" \
      --desc="License validation test" \
      --license=apache-2.0 \
      --holder="Throughstone Test" \
      --layout=mono \
      --collab=solo \
      --remotes=no
  ) >"$TMP_ROOT/$name.out" 2>&1

  cmp -s "$work/LICENSE" "$work/Code/$name-docs/LICENSE"
  [ -f "$work/Code/$name-docs/LICENSE-THROUGHSTONE" ]
  [ -f "$work/LICENSE-THROUGHSTONE" ]
  cmp -s \
    "$work/LICENSE-THROUGHSTONE" \
    "$work/Code/$name-docs/LICENSE-THROUGHSTONE"
  [ -f "$work/LICENSING.md" ]
  grep -Fq "licensed under Apache-2.0" "$work/LICENSING.md"
  grep -Fxq "Apache-2.0" "$work/Code/$name-docs/.throughstone/project-license"

  mkdir -p "$work/Code/$name-api"
  "$work/Code/$name-docs/scripts/apply-project-license.sh" \
    "$work/Code/$name-api" >"$TMP_ROOT/$name-code-license.out"
  cmp -s "$work/LICENSE" "$work/Code/$name-api/LICENSE"
  cmp -s \
    "$work/Code/$name-docs/LICENSE-THROUGHSTONE" \
    "$work/Code/$name-api/LICENSE-THROUGHSTONE"
}

# run_visibility_case NAME VISIBILITY — verify gh receives the requested remote visibility.
run_visibility_case() {
  local name="$1" visibility="$2"
  local work="$TMP_ROOT/$name"
  local stub_bin="$TMP_ROOT/$name-bin"
  local remote_root="$TMP_ROOT/$name-remotes"
  local gh_log="$TMP_ROOT/$name-gh.log"

  copy_template "$work"
  mkdir -p "$stub_bin" "$remote_root"
  cp "$ROOT/tests/fixtures/gh-stub.sh" "$stub_bin/gh"
  chmod +x "$stub_bin/gh"
  (
    cd "$work"
    PATH="$stub_bin:$PATH" \
      GH_LOG="$gh_log" \
      GH_REMOTE_ROOT="$remote_root" \
      ./init.sh \
        --non-interactive \
        --slug="$name" \
        --desc="Visibility validation test" \
        --license=mit \
        --holder="Throughstone Test" \
        --layout=multi \
        --collab=solo \
        --remotes=yes \
        --owner=throughstone-test \
        --visibility="$visibility"
  ) >"$TMP_ROOT/$name.out" 2>&1

  [ "$(grep -Fc -- "--$visibility" "$gh_log")" -eq 2 ]
  if [ "$visibility" = "public" ]; then
    if grep -Fq -- "--private" "$gh_log"; then
      echo "FAIL: public visibility case invoked gh with --private" >&2
      return 1
    fi
  else
    if grep -Fq -- "--public" "$gh_log"; then
      echo "FAIL: private visibility case invoked gh with --public" >&2
      return 1
    fi
  fi
}

# run_public_proprietary_case — public source visibility must warn about proprietary rights.
run_public_proprietary_case() {
  local name="visibility-public-proprietary"
  local work="$TMP_ROOT/$name"
  local cancel_name="visibility-public-proprietary-cancel"
  local cancel_work="$TMP_ROOT/$cancel_name"
  local stub_bin="$TMP_ROOT/$name-bin"
  local remote_root="$TMP_ROOT/$name-remotes"
  local gh_log="$TMP_ROOT/$name-gh.log"
  local cancel_status

  copy_template "$work"
  mkdir -p "$stub_bin" "$remote_root"
  cp "$ROOT/tests/fixtures/gh-stub.sh" "$stub_bin/gh"
  chmod +x "$stub_bin/gh"
  (
    cd "$work"
    PATH="$stub_bin:$PATH" \
      GH_LOG="$gh_log" \
      GH_REMOTE_ROOT="$remote_root" \
      ./init.sh \
        --non-interactive \
        --slug="$name" \
        --desc="Public proprietary warning test" \
        --license=private \
        --layout=multi \
        --collab=solo \
        --remotes=yes \
        --owner=throughstone-test \
        --visibility=public
  ) >"$TMP_ROOT/$name.out" 2>&1

  [ "$(grep -Fc -- "--public" "$gh_log")" -eq 2 ]
  grep -Fq "public visibility with a proprietary license" "$TMP_ROOT/$name.out"
  [ ! -e "$work/Code/$name-docs/LICENSE" ]
  [ ! -e "$work/prompts/LICENSE" ]
  grep -Fxq "Proprietary" "$work/Code/$name-docs/.throughstone/project-license"
  grep -Fq "Project-authored content in this repository is proprietary" \
    "$work/Code/$name-docs/LICENSING.md"

  copy_template "$cancel_work"
  : > "$gh_log"
  set +e
  (
    cd "$cancel_work"
    printf 'n\n' | \
      PATH="$stub_bin:$PATH" \
      GH_LOG="$gh_log" \
      GH_REMOTE_ROOT="$remote_root" \
      ./init.sh \
        --slug="$cancel_name" \
        --desc="Public proprietary cancellation test" \
        --license=private \
        --layout=multi \
        --collab=solo \
        --remotes=yes \
        --owner=throughstone-test \
        --visibility=public
  ) >"$TMP_ROOT/$cancel_name.out" 2>&1
  cancel_status=$?
  set -e

  [ "$cancel_status" -eq 2 ]
  grep -Fq "public proprietary repository creation cancelled" \
    "$TMP_ROOT/$cancel_name.out"
  [ -d "$cancel_work/Code/{{PROJECT}}-docs" ]
  [ -f "$cancel_work/README.md" ]
  [ ! -s "$gh_log" ]
}

# run_missing_canonical_license_case — metadata prevents silent open-source-to-private drift.
run_missing_canonical_license_case() {
  local name="license-missing-canonical"
  local work="$TMP_ROOT/$name"
  local target="$work/Code/$name-api"
  local status

  copy_template "$work"
  (
    cd "$work"
    ./init.sh \
      --non-interactive \
      --slug="$name" \
      --desc="Missing canonical license test" \
      --license=mit \
      --holder="Throughstone Test" \
      --layout=multi \
      --collab=solo \
      --remotes=no
  ) >"$TMP_ROOT/$name.out" 2>&1

  grep -Fxq "MIT" "$work/Code/$name-docs/.throughstone/project-license"
  rm "$work/Code/$name-docs/LICENSE"
  mkdir -p "$target"
  set +e
  "$work/Code/$name-docs/scripts/apply-project-license.sh" \
    "$target" >"$TMP_ROOT/$name-helper.out" 2>&1
  status=$?
  set -e

  [ "$status" -eq 1 ]
  grep -Fq "project posture is MIT, but the canonical license is missing" \
    "$TMP_ROOT/$name-helper.out"
  [ -z "$(find "$target" -mindepth 1 -print -quit)" ]
}

# run_private_mono_case — the single repo retains and explains Throughstone's notice at root.
run_private_mono_case() {
  local name="license-private-mono"
  local work="$TMP_ROOT/$name"

  copy_template "$work"
  (
    cd "$work"
    ./init.sh \
      --non-interactive \
      --slug="$name" \
      --desc="Private mono license test" \
      --license=private \
      --layout=mono \
      --collab=solo \
      --remotes=no
  ) >"$TMP_ROOT/$name.out" 2>&1

  [ ! -e "$work/LICENSE" ]
  [ -f "$work/LICENSE-THROUGHSTONE" ]
  cmp -s \
    "$work/LICENSE-THROUGHSTONE" \
    "$work/Code/$name-docs/LICENSE-THROUGHSTONE"
  grep -Fxq "Proprietary" "$work/Code/$name-docs/.throughstone/project-license"
  grep -Fq "does not grant permission" "$work/LICENSING.md"
}

# run_invalid_visibility_case — reject bad visibility before destructive bootstrap work.
run_invalid_visibility_case() {
  local name="visibility-invalid"
  local work="$TMP_ROOT/$name"
  local stub_bin="$TMP_ROOT/$name-bin"
  local remote_root="$TMP_ROOT/$name-remotes"
  local gh_log="$TMP_ROOT/$name-gh.log"
  local status

  copy_template "$work"
  mkdir -p "$stub_bin" "$remote_root"
  cp "$ROOT/tests/fixtures/gh-stub.sh" "$stub_bin/gh"
  chmod +x "$stub_bin/gh"
  set +e
  (
    cd "$work"
    PATH="$stub_bin:$PATH" \
      GH_LOG="$gh_log" \
      GH_REMOTE_ROOT="$remote_root" \
      ./init.sh \
        --non-interactive \
        --slug="$name" \
        --desc="Visibility validation test" \
        --license=mit \
        --holder="Throughstone Test" \
        --layout=multi \
        --collab=solo \
        --remotes=yes \
        --owner=throughstone-test \
        --visibility=internal
  ) >"$TMP_ROOT/$name.out" 2>&1
  status=$?
  set -e

  [ "$status" -eq 2 ]
  [ -d "$work/Code/{{PROJECT}}-docs" ]
  [ -f "$work/README.md" ]
  [ ! -s "$gh_log" ]
  grep -Fq "invalid --visibility 'internal'" "$TMP_ROOT/$name.out"
}

run_interactive_case \
  "license-mit" \
  $'1\nMIT\n' \
  "MIT License"

run_interactive_case \
  "license-default" \
  $'1\n\n' \
  "MIT License"

run_interactive_case \
  "license-reprompt" \
  $'invalid\n1\nnonsense\nApache-2.0\n' \
  "Apache License"

grep -Fq \
  "choose 1 for open source or 2 for private / proprietary" \
  "$TMP_ROOT/license-reprompt.out"
grep -Fq \
  "choose 1/mit, 2/bsd-3, or 3/apache-2.0" \
  "$TMP_ROOT/license-reprompt.out"

run_private_case \
  "license-private" \
  bash -c \
  "printf '2\n' | ./init.sh --slug=license-private --desc='License validation test' --layout=multi --collab=solo --remotes=no"

run_private_case \
  "license-private-flag" \
  ./init.sh \
  --non-interactive \
  --slug=license-private-flag \
  --desc="License validation test" \
  --license=private \
  --layout=multi \
  --collab=solo \
  --remotes=no

run_flag_case \
  "license-bsd" \
  "BSD-3" \
  "BSD 3-Clause License"

run_mono_case
run_private_mono_case

run_visibility_case "visibility-public" "public"
run_visibility_case "visibility-private" "private"
run_public_proprietary_case
run_invalid_visibility_case
run_missing_canonical_license_case

invalid_work="$TMP_ROOT/license-invalid-flag"
copy_template "$invalid_work"
set +e
(
  cd "$invalid_work"
  ./init.sh \
    --non-interactive \
    --slug="license-invalid-flag" \
    --desc="License validation test" \
    --license="not-a-license" \
    --holder="Throughstone Test"
) >"$TMP_ROOT/license-invalid-flag.out" 2>&1
invalid_status=$?
set -e

[ "$invalid_status" -eq 2 ]
[ -d "$invalid_work/Code/{{PROJECT}}-docs" ]
[ -d "$invalid_work/tests" ]
grep -Fq "invalid --license 'not-a-license'" "$TMP_ROOT/license-invalid-flag.out"

missing_template_work="$TMP_ROOT/license-missing-template"
copy_template "$missing_template_work"
rm "$missing_template_work/Code/{{PROJECT}}-docs/templates/licenses/MIT.txt"
set +e
(
  cd "$missing_template_work"
  ./init.sh \
    --non-interactive \
    --slug="license-missing-template" \
    --desc="License validation test" \
    --license=mit \
    --holder="Throughstone Test"
) >"$TMP_ROOT/license-missing-template.out" 2>&1
missing_template_status=$?
set -e

[ "$missing_template_status" -eq 1 ]
[ -d "$missing_template_work/Code/{{PROJECT}}-docs" ]
[ -f "$missing_template_work/README.md" ]
grep -Fq "project license template is missing" "$TMP_ROOT/license-missing-template.out"

echo "init.sh license choice validation: PASS"
