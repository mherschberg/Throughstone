#!/usr/bin/env bash
#
# Regression coverage for init.sh license validation and generated license posture.

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-license-test.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

# copy_template DEST — build an init.sh fixture from HEAD, then overlay current worktree
# changes. The overlay keeps uncommitted bootstrap/comment-pass edits under test, while leaving
# Git metadata behind so init.sh sees the same shape as a downloaded template.
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

  # Ignored files are invisible to the Git archive/diff harness. Seed one maintainer-only path
  # explicitly so successful bootstraps prove generated projects remove it with tests/.
  mkdir -p "$dest/.test-fixtures"
  printf '%s\n' "maintainer-only ignored fixture" > "$dest/.test-fixtures/sentinel.txt"
}

# Successful bootstraps must remove maintainer-only test assets from generated projects.
assert_maintainer_tests_removed() {
  local name="$1" work="$2"

  [ ! -d "$work/tests" ] || {
    echo "FAIL: $name retained maintainer-only tests/" >&2
    return 1
  }
  [ ! -d "$work/.test-fixtures" ] || {
    echo "FAIL: $name retained maintainer-only .test-fixtures/" >&2
    return 1
  }
}

# Early validation failures must stop before the destructive bootstrap boundary that removes
# tests/ and ignored maintainer fixtures.
assert_maintainer_tests_retained() {
  local name="$1" work="$2"

  [ -d "$work/tests" ] || {
    echo "FAIL: $name removed tests/ before destructive bootstrap work" >&2
    return 1
  }
  [ -f "$work/.test-fixtures/sentinel.txt" ] || {
    echo "FAIL: $name removed .test-fixtures/ before destructive bootstrap work" >&2
    return 1
  }
}

# run_interactive_case NAME INPUT EXPECTED_TEXT — exercise the prompt path for an open-source
# license. Verifies project LICENSE files, retained Throughstone notices, LICENSING.md summary
# text, idempotent application to a future code repo, and no-overwrite conflict behavior.
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

  # Project LICENSE belongs to project-authored content in both generated repos.
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
  # LICENSE-THROUGHSTONE is separate: it documents retained scaffold material and must exist
  # even when the project license is different.
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

  # Future code repos inherit the docs hub's project posture plus the Throughstone notice.
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

  # Existing conflicting files must fail before being overwritten.
  printf 'different license\n' > "$work/Code/$name-api/LICENSE"
  set +e
  "$work/Code/$name-docs/scripts/apply-project-license.sh" \
    "$work/Code/$name-api" >"$TMP_ROOT/$name-code-license-conflict.out" 2>&1
  conflict_status=$?
  set -e
  [ "$conflict_status" -eq 1 ]
  grep -Fq "refusing to overwrite different project license" \
    "$TMP_ROOT/$name-code-license-conflict.out"

  # A fresh target with a conflicting project LICENSE should remain otherwise untouched.
  mkdir -p "$work/Code/$name-conflict"
  printf 'different license\n' > "$work/Code/$name-conflict/LICENSE"
  set +e
  "$work/Code/$name-docs/scripts/apply-project-license.sh" \
    "$work/Code/$name-conflict" >"$TMP_ROOT/$name-fresh-conflict.out" 2>&1
  conflict_status=$?
  set -e
  [ "$conflict_status" -eq 1 ]
  [ ! -e "$work/Code/$name-conflict/LICENSE-THROUGHSTONE" ]

  assert_maintainer_tests_removed "$name" "$work"
}

# run_flag_case NAME LICENSE EXPECTED_TEXT — preserve non-interactive license normalization
# for automation callers.
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
  assert_maintainer_tests_removed "$name" "$work"
}

# run_private_case NAME ARGS... — proprietary projects should not get a project LICENSE.
# They still retain LICENSE-THROUGHSTONE and LICENSING.md because generated repos include
# Throughstone-authored scaffold material.
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

  assert_maintainer_tests_removed "$name" "$work"
  ! grep -Fq "Copyright holder" "$TMP_ROOT/$name.out"
}

# run_mono_case — mono mode keeps both the root project LICENSE and the docs-hub canonical
# copy needed by apply-project-license.sh for future code repos.
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
  assert_maintainer_tests_removed "$name" "$work"
}

# run_visibility_case NAME VISIBILITY — verify GitHub repo creation receives the requested
# visibility flag for both generated multi-repo remotes.
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
  assert_maintainer_tests_removed "$name" "$work"
}

# run_public_proprietary_case — public source visibility with a proprietary posture must warn,
# and the interactive path must allow the user to cancel before any remote or destructive work.
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
  assert_maintainer_tests_removed "$name" "$work"

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
  assert_maintainer_tests_retained "$cancel_name" "$cancel_work"
  [ ! -s "$gh_log" ]
}

# run_missing_canonical_license_case — posture metadata prevents silent open-source-to-private
# drift if the docs hub's canonical project LICENSE disappears later.
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
  assert_maintainer_tests_removed "$name" "$work"
}

# run_private_mono_case — the single repo retains and explains Throughstone's notice at root
# without creating a project LICENSE for proprietary code.
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
  assert_maintainer_tests_removed "$name" "$work"
}

# run_invalid_visibility_case — reject bad visibility before destructive bootstrap work or
# remote creation.
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
  assert_maintainer_tests_retained "$name" "$work"
  [ ! -s "$gh_log" ]
  grep -Fq "invalid --visibility 'internal'" "$TMP_ROOT/$name.out"
}

# run_manual_multi_remote_case — manual remotes should be recorded in the repo registry and
# receive the initial generated commits without using the gh stub.
run_manual_multi_remote_case() {
  local name="manual-multi-remotes"
  local work="$TMP_ROOT/$name"
  local docs_remote="$TMP_ROOT/$name-docs.git"
  local prompts_remote="$TMP_ROOT/$name-prompts.git"

  copy_template "$work"
  git init --bare -q "$docs_remote"
  git init --bare -q "$prompts_remote"
  (
    cd "$work"
    ./init.sh \
      --non-interactive \
      --slug="$name" \
      --desc="Manual remote setup test" \
      --license=private \
      --layout=multi \
      --collab=team \
      --adr-authority="consensus of maintainers" \
      --remotes=yes \
      --remote-provider=manual \
      --docs-remote="$docs_remote" \
      --prompts-remote="$prompts_remote"
  ) >"$TMP_ROOT/$name.out" 2>&1

  [ "$(git -C "$work/Code/$name-docs" remote get-url origin)" = "$docs_remote" ]
  [ "$(git -C "$work/prompts" remote get-url origin)" = "$prompts_remote" ]
  git --git-dir="$docs_remote" rev-parse --verify refs/heads/main >/dev/null
  git --git-dir="$prompts_remote" rev-parse --verify refs/heads/main >/dev/null
  grep -Fq "remote: \"$docs_remote\"" "$work/Code/$name-docs/registries/repos.yml"
  grep -Fq "remote: \"$prompts_remote\"" "$work/Code/$name-docs/registries/repos.yml"
  assert_maintainer_tests_removed "$name" "$work"
}

# --- Interactive license selection -------------------------------------------
# Prompted open-source choices cover explicit input, defaults, and reprompting. The reprompt
# case protects early validation: invalid answers should not cross into bootstrap work.
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

# --- Private / proprietary behavior ------------------------------------------
# Interactive and flag paths both mean "proprietary project posture", not merely private
# GitHub visibility; project LICENSE files must be absent.
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

# --- Flag-based license normalization ----------------------------------------
# Friendly CLI spellings should normalize to canonical license IDs and template text.
run_flag_case \
  "license-bsd" \
  "BSD-3" \
  "BSD 3-Clause License"

# --- Mono-repo license behavior ----------------------------------------------
# Mono mode keeps root-facing license files while preserving docs-hub authority for future
# code repos.
run_mono_case
run_private_mono_case

# --- GitHub visibility behavior ----------------------------------------------
# Visibility is remote metadata. It must not change the selected project-license posture.
run_visibility_case "visibility-public" "public"
run_visibility_case "visibility-private" "private"

# --- Public proprietary warning / cancel behavior -----------------------------
# A public proprietary repo is allowed only after warning; cancellation must leave the template
# intact and avoid remote creation.
run_public_proprietary_case

# --- Remote setup and missing canonical license behavior -----------------------
run_invalid_visibility_case
run_manual_multi_remote_case
run_missing_canonical_license_case

# --- Invalid inputs fail before destructive bootstrap work ---------------------
# Bad license input and missing license templates are detected before template files,
# maintainer tests, or ignored fixtures are removed.
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
assert_maintainer_tests_retained "license-invalid-flag" "$invalid_work"
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
assert_maintainer_tests_retained "license-missing-template" "$missing_template_work"
grep -Fq "project license template is missing" "$TMP_ROOT/license-missing-template.out"

echo "init.sh license choice validation: PASS"
