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

# first_registry_row FILE — print the first repo row block. Rows start at column-2 `- name:`;
# the commented example row is indented behind a `#` and so is never picked up.
first_registry_row() {
  awk '/^[[:space:]]*-[[:space:]]*name:/ { n++ } n == 1' "$1"
}

# run_registry_mono_case — registries/ always ships and the deprecated flag only warns; the mono
# layout additionally gets the two things its single-repo shape needs — a registry row for the
# workspace root, which is the only repository it has, and the method-check workflow somewhere
# GitHub will actually read it.
run_registry_mono_case() {
  local name="registry-mono"
  local work="$TMP_ROOT/$name"
  local reg root_row field

  copy_template "$work"
  (
    cd "$work"
    ./init.sh \
      --non-interactive \
      --slug="$name" \
      --desc="Registry seeding test" \
      --license=bsd-3 \
      --holder="Throughstone Test" \
      --layout=mono \
      --collab=team \
      --adr-authority="the CTO" \
      --registries=no \
      --remotes=no
  ) >"$TMP_ROOT/$name.out" 2>&1

  # The flag is accepted, ignored, and says so. It used to delete the whole directory, taking the
  # risk and security-review registers with it — both cited unconditionally by the generated docs.
  grep -Fq -- "--registries=no is ignored" "$TMP_ROOT/$name.out" || {
    echo "FAIL: $name did not warn that --registries=no is ignored" >&2
    return 1
  }
  for field in repos.yml risks.yml security-reviews.yml; do
    [ -f "$work/Code/$name-docs/registries/$field" ] || {
      echo "FAIL: $name pruned registries/$field" >&2
      return 1
    }
  done

  # The workspace root leads the inventory. Generated with --remotes=no, so nothing recorded a
  # remote on that row; with no `remote:` the clone parser in setup-workspace.sh passes over it.
  reg="$work/Code/$name-docs/registries/repos.yml"
  root_row="$(first_registry_row "$reg")"
  for field in "name: \"$name\"" 'location: "."' 'type: mono' 'added_as: created'; do
    printf '%s\n' "$root_row" | grep -Fq "$field" || {
      echo "FAIL: $name workspace-root row is missing $field" >&2
      printf '%s\n' "$root_row" >&2
      return 1
    }
  done
  if printf '%s\n' "$root_row" | grep -Fq 'remote:'; then
    echo "FAIL: $name workspace-root row carries remote:" >&2
    return 1
  fi

  # A workflow nested under Code/<project>-docs/ never triggers when the workspace root is the
  # repository. The hub keeps its copy: that is what gives the hub CI of its own after a split.
  cmp -s "$work/.github/workflows/method-check.yml" \
    "$work/Code/$name-docs/.github/workflows/method-check.yml" || {
    echo "FAIL: $name did not place the docs hub's method-check.yml at the workspace root" >&2
    return 1
  }
  git -C "$work" ls-files --error-unmatch .github/workflows/method-check.yml >/dev/null 2>&1 || {
    echo "FAIL: $name left the root method-check.yml out of the initial commit" >&2
    return 1
  }

  # The new row must change nothing the shipped tooling reports. check.sh exits 0 on warnings, so
  # assert the summary line rather than the status.
  ( cd "$work" && bash "Code/$name-docs/scripts/check.sh" ) >"$TMP_ROOT/$name-check.out" 2>&1 || true
  grep -Fq "0 fail(s), 0 warning(s)" "$TMP_ROOT/$name-check.out" || {
    echo "FAIL: $name doctor was not clean with the workspace-root row present" >&2
    cat "$TMP_ROOT/$name-check.out" >&2
    return 1
  }

  assert_maintainer_tests_removed "$name" "$work"
}

# run_registry_multi_case — the same flag in the other layout: still ignored, still warns, and
# neither of the mono-only additions appears. The workspace root is not a repository here.
run_registry_multi_case() {
  local name="registry-multi"
  local work="$TMP_ROOT/$name"

  copy_template "$work"
  (
    cd "$work"
    ./init.sh \
      --non-interactive \
      --slug="$name" \
      --desc="Registry seeding test" \
      --license=apache-2.0 \
      --holder="Throughstone Test" \
      --layout=multi \
      --collab=solo \
      --registries=no \
      --remotes=no
  ) >"$TMP_ROOT/$name.out" 2>&1

  grep -Fq -- "--registries=no is ignored" "$TMP_ROOT/$name.out" || {
    echo "FAIL: $name did not warn that --registries=no is ignored" >&2
    return 1
  }
  [ -f "$work/Code/$name-docs/registries/repos.yml" ] || {
    echo "FAIL: $name pruned registries/ in multi-repo layout" >&2
    return 1
  }
  if grep -Fq 'location: "."' "$work/Code/$name-docs/registries/repos.yml"; then
    echo "FAIL: $name seeded a workspace-root row in multi-repo layout" >&2
    return 1
  fi
  [ ! -e "$work/.github" ] || {
    echo "FAIL: $name created a workspace-root .github in multi-repo layout" >&2
    return 1
  }

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

# Open source chosen explicitly, then the license sub-prompt's default taken: still MIT.
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

# Answering nothing at all must not license the project. The project-type question defaults to
# private/proprietary precisely so that a user who presses Enter has granted nobody anything; an
# open-source default would hand out an irrevocable license they never named.
run_private_case \
  "license-bare-enter" \
  bash -c \
  "printf '\n' | ./init.sh --slug=license-bare-enter --desc='License validation test' --layout=multi --collab=solo --remotes=no"

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

# --- registries/ always ships ------------------------------------------------
# The directory carries the repo inventory and the risk / security-review registers, all of which
# the generated docs cite unconditionally. --registries survives as a deprecated no-op.
run_registry_mono_case
run_registry_multi_case

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

# A deprecated flag still validates its value, and does it in both layouts. The check used to run
# only in mono-repo mode, so a multi-repo caller could pass anything and be silently ignored.
registry_invalid_work="$TMP_ROOT/registry-invalid-flag"
copy_template "$registry_invalid_work"
set +e
(
  cd "$registry_invalid_work"
  ./init.sh \
    --non-interactive \
    --slug="registry-invalid-flag" \
    --desc="Registry validation test" \
    --license=private \
    --layout=multi \
    --registries=maybe \
    --collab=solo \
    --remotes=no
) >"$TMP_ROOT/registry-invalid-flag.out" 2>&1
registry_invalid_status=$?
set -e

[ "$registry_invalid_status" -eq 2 ]
[ -d "$registry_invalid_work/Code/{{PROJECT}}-docs" ]
assert_maintainer_tests_retained "registry-invalid-flag" "$registry_invalid_work"
grep -Fq "invalid --registries 'maybe'" "$TMP_ROOT/registry-invalid-flag.out"

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

# --- --notice-only: the Throughstone notice, and nothing else -----------------
# A repository the method did not create needs a notice for our material, but its own licensing
# is not ours to state. Every abort arm below fires on ordinary adopted repos in the default
# mode — including on an open-source project, so it is not a proprietary-posture edge — and this
# mode must clear all of them without ever touching the target's LICENSE.
#
# Both fixtures are reused from earlier cases so the two layouts and two non-MIT postures are
# both exercised: license-private-flag is Proprietary and multi-repo, license-mono is Apache-2.0
# and mono. Neither is an all-default configuration.
notice_priv="$TMP_ROOT/license-private-flag"
notice_open="$TMP_ROOT/license-mono"
notice_priv_script="$notice_priv/Code/license-private-flag-docs/scripts/apply-project-license.sh"
notice_open_script="$notice_open/Code/license-mono-docs/scripts/apply-project-license.sh"
notice_priv_hub="$notice_priv/Code/license-private-flag-docs"
[ -x "$notice_priv_script" ] || {
  echo "FAIL: notice-only fixture is missing; did the cases above get reordered? $notice_priv_script" >&2
  exit 1
}
[ -x "$notice_open_script" ] || {
  echo "FAIL: notice-only fixture is missing; did the cases above get reordered? $notice_open_script" >&2
  exit 1
}

# adopted_repo PATH — a repository the method did not create: it states its own license, which
# is the thing the default mode refuses to work alongside.
adopted_repo() {
  rm -rf "$1"
  mkdir -p "$1"
  printf 'MIT License\n\nCopyright (c) 2020 Another Team\n' > "$1/LICENSE"
  printf 'their license\n' > "$1/.license-fingerprint"
  cp "$1/LICENSE" "$1/.license-fingerprint"
}

# A proprietary project meeting an adopted repo that has its own LICENSE — `exit 1` in the
# default mode, because a proprietary project refuses to stand beside a target LICENSE at all.
notice_target="$TMP_ROOT/notice-adopted-proprietary"
adopted_repo "$notice_target"
"$notice_priv_script" --notice-only "$notice_target" >"$TMP_ROOT/notice-priv.out" 2>&1
cmp -s "$notice_priv_hub/LICENSE-THROUGHSTONE" "$notice_target/LICENSE-THROUGHSTONE"
cmp -s "$notice_target/.license-fingerprint" "$notice_target/LICENSE"
[ ! -e "$notice_target/LICENSING.md" ]
grep -Fq "Throughstone license:" "$TMP_ROOT/notice-priv.out"

# Idempotent: a second run has nothing to do and says so.
"$notice_priv_script" --notice-only "$notice_target" >"$TMP_ROOT/notice-priv-again.out" 2>&1
grep -Fq "already present, left as it is" "$TMP_ROOT/notice-priv-again.out"
cmp -s "$notice_target/.license-fingerprint" "$notice_target/LICENSE"
[ ! -e "$notice_target/LICENSING.md" ]

# The default mode still refuses that same repo. --notice-only is an added mode, not a
# loosening of the one that exists.
set +e
"$notice_priv_script" "$notice_target" >"$TMP_ROOT/notice-default-still-aborts.out" 2>&1
notice_default_status=$?
set -e
[ "$notice_default_status" -eq 1 ]
grep -Fq "project is proprietary, but target already has LICENSE" \
  "$TMP_ROOT/notice-default-still-aborts.out"

# An open-source project meeting the same repo — `exit 1` in the default mode for a different
# reason, which is what shows the abort is about the target's license, not the project's posture.
notice_open_target="$TMP_ROOT/notice-adopted-open"
adopted_repo "$notice_open_target"
"$notice_open_script" --notice-only "$notice_open_target" >"$TMP_ROOT/notice-open.out" 2>&1
cmp -s \
  "$notice_open/Code/license-mono-docs/LICENSE-THROUGHSTONE" \
  "$notice_open_target/LICENSE-THROUGHSTONE"
cmp -s "$notice_open_target/.license-fingerprint" "$notice_open_target/LICENSE"
[ ! -e "$notice_open_target/LICENSING.md" ]
set +e
"$notice_open_script" "$notice_open_target" >"$TMP_ROOT/notice-open-default.out" 2>&1
notice_open_status=$?
set -e
[ "$notice_open_status" -eq 1 ]
grep -Fq "refusing to overwrite different project license" "$TMP_ROOT/notice-open-default.out"

# A notice that is already there is left exactly as it is, whatever it says. This is the state
# an idempotent re-run meets after the notice text changes, and the default mode aborts on it.
notice_stale="$TMP_ROOT/notice-stale"
rm -rf "$notice_stale"
mkdir -p "$notice_stale"
printf 'An older Throughstone notice.\n' > "$notice_stale/LICENSE-THROUGHSTONE"
"$notice_priv_script" --notice-only "$notice_stale" >"$TMP_ROOT/notice-stale.out" 2>&1
grep -Fxq "An older Throughstone notice." "$notice_stale/LICENSE-THROUGHSTONE"
grep -Fq "already present, left as it is" "$TMP_ROOT/notice-stale.out"
set +e
"$notice_priv_script" "$notice_stale" >"$TMP_ROOT/notice-stale-default.out" 2>&1
notice_stale_status=$?
set -e
[ "$notice_stale_status" -eq 1 ]
grep -Fq "refusing to overwrite different Throughstone license" "$TMP_ROOT/notice-stale-default.out"

# The mode reads no posture. With the posture file gone the default mode cannot run at all,
# and --notice-only is unaffected — which is what makes it usable from a caller that has not
# asked, and never will ask, what the project's license is.
notice_noposture="$TMP_ROOT/notice-no-posture"
rm -rf "$notice_noposture"
mkdir -p "$notice_noposture"
mv "$notice_priv_hub/.throughstone/project-license" "$TMP_ROOT/posture-stash"
"$notice_priv_script" --notice-only "$notice_noposture" >"$TMP_ROOT/notice-noposture.out" 2>&1
cmp -s "$notice_priv_hub/LICENSE-THROUGHSTONE" "$notice_noposture/LICENSE-THROUGHSTONE"
set +e
"$notice_priv_script" "$notice_noposture" >"$TMP_ROOT/notice-noposture-default.out" 2>&1
notice_noposture_status=$?
set -e
[ "$notice_noposture_status" -eq 1 ]
grep -Fq "missing project-license posture" "$TMP_ROOT/notice-noposture-default.out"
mv "$TMP_ROOT/posture-stash" "$notice_priv_hub/.throughstone/project-license"

# Nothing to copy is a warning, not a failure: a caller registering a repository must not be
# stopped by the notice.
notice_nosource="$TMP_ROOT/notice-no-source"
rm -rf "$notice_nosource"
mkdir -p "$notice_nosource"
mv "$notice_priv_hub/LICENSE-THROUGHSTONE" "$TMP_ROOT/notice-stash"
set +e
"$notice_priv_script" --notice-only "$notice_nosource" >"$TMP_ROOT/notice-nosource.out" 2>&1
notice_nosource_status=$?
set -e
mv "$TMP_ROOT/notice-stash" "$notice_priv_hub/LICENSE-THROUGHSTONE"
[ "$notice_nosource_status" -eq 0 ]
[ ! -e "$notice_nosource/LICENSE-THROUGHSTONE" ]
grep -Fq "notice not written" "$TMP_ROOT/notice-nosource.out"

# The flag reads in either position, and a caller's mistake is still a usage error rather than
# a path: a misspelled flag must not be taken for a target directory.
notice_order="$TMP_ROOT/notice-flag-after"
rm -rf "$notice_order"
mkdir -p "$notice_order"
"$notice_priv_script" "$notice_order" --notice-only >"$TMP_ROOT/notice-order.out" 2>&1
[ -f "$notice_order/LICENSE-THROUGHSTONE" ]
[ ! -e "$notice_order/LICENSING.md" ]

set +e
"$notice_priv_script" --notice_only "$notice_order" >"$TMP_ROOT/notice-badflag.out" 2>&1
notice_badflag_status=$?
"$notice_priv_script" "$notice_order" "$notice_order" >"$TMP_ROOT/notice-twotargets.out" 2>&1
notice_twotargets_status=$?
"$notice_priv_script" --notice-only "$TMP_ROOT/notice-does-not-exist" >"$TMP_ROOT/notice-nodir.out" 2>&1
notice_nodir_status=$?
"$notice_priv_script" >"$TMP_ROOT/notice-noargs.out" 2>&1
notice_noargs_status=$?
set -e
[ "$notice_badflag_status" -eq 2 ]
grep -Fq "unknown option: --notice_only" "$TMP_ROOT/notice-badflag.out"
[ "$notice_twotargets_status" -eq 2 ]
grep -Fq "unexpected extra argument" "$TMP_ROOT/notice-twotargets.out"
[ "$notice_nodir_status" -eq 2 ]
grep -Fq "target directory does not exist" "$TMP_ROOT/notice-nodir.out"
[ "$notice_noargs_status" -eq 2 ]
grep -Fq "[--notice-only] TARGET_REPO" "$TMP_ROOT/notice-noargs.out"

echo "init.sh license choice validation: PASS"
