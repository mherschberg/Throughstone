#!/usr/bin/env bash
#
# Regression coverage for init.sh license validation and generated license posture.

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-license-test.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

# run_with_deadline SECONDS CMD... — run CMD and exit 124 if it outlives the deadline.
#
# The wizard's failure mode when a prompt insists on an answer and the answer stream has run out
# is not a wrong result, it is no result: it re-asks forever. A test that only asserts the exit
# status hangs the whole suite instead of failing when that comes back. Written in perl because
# init.sh already requires perl, while `timeout` is GNU coreutils and absent from a stock macOS —
# the suite must fail on the machine of anyone who downloaded this template, not only on CI's.
run_with_deadline() {
  local secs="$1"; shift
  perl -e '
    my $secs = shift @ARGV;
    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if (!$pid) { exec { $ARGV[0] } @ARGV or die "exec: $!"; }
    $SIG{ALRM} = sub { kill 9, $pid; waitpid $pid, 0; exit 124 };
    alarm $secs;
    waitpid $pid, 0;
    my $st = $?;
    alarm 0;
    exit($st & 127 ? 128 + ($st & 127) : $st >> 8);
  ' "$secs" "$@"
}

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

# run_typed_layout_collab_case — the layout and collaboration answers typed at the prompt, in the
# vocabulary the menus offer. Both questions used to assign their answer raw while everything
# downstream compared against "1" or "2", so a typed word was neither: typing "mono" built a
# hybrid, and typing "team" built a solo project. Both now go through the same normaliser the
# flags use, and this is the only case that enters that branch at all — every other invocation in
# the suite passes --layout and --collab, which is the path that already normalised.
#
# The re-prompts are the cheap half. The assertions that matter are about the project that came
# out: a hybrid answers the hints identically.
run_typed_layout_collab_case() {
  local name="typed-layout-collab" status
  local work="$TMP_ROOT/$name"

  copy_template "$work"
  # The answer stream is exactly as long as the questions that should be asked, so any change that
  # consumes an answer meant for the next question, or refuses one that should be accepted, runs
  # it out early. Capture that rather than leaving it to errexit, which would kill the suite from
  # inside a subshell without writing down which case failed or why.
  set +e
  (
    cd "$work"
    # No trailing newline on the last answer. `read` fails on it exactly as it fails on an empty
    # stream, while still delivering "team" — someone who typed an answer and pressed Ctrl-D. The
    # status alone cannot tell those apart, so the value has to decide, and this is where that is
    # measured: if it did not, the run would stop here instead of recording a team project.
    printf 'bogus\n\nmono\nnope\n \nteam' | ./init.sh \
      --slug="$name" \
      --desc="Typed answer test" \
      --license=mit \
      --holder="Throughstone Test" \
      --adr-authority="tech lead" \
      --remotes=no
  ) >"$TMP_ROOT/$name.out" 2>&1
  status=$?
  set -e
  [ "$status" -eq 0 ] || {
    echo "FAIL: $name — the run did not finish (exit $status); an answer this stream carries was refused, or one was consumed by a question that should not have asked" >&2
    cat "$TMP_ROOT/$name.out" >&2
    return 1
  }

  # Two re-asks each, not one. The first is the unrecognised word; the second is the answer that
  # is not there — Enter at the layout question, a space at the collaboration one. Neither menu
  # offers a default any more, and counting the re-asks is the only way to see that: `read -p`
  # prints its prompt to a terminal only, so under a pipe there is no prompt text in the output to
  # read a default off. Enter and a space used to buy multi and solo here — a layout fixed at
  # creation, and an ADR register naming the reader as its own acceptance authority.
  [ "$(grep -c -F "answer 1 or 2 (the words multi and mono work too)" "$TMP_ROOT/$name.out")" = "2" ] || {
    echo "FAIL: $name — the layout question did not re-ask both an unrecognised answer and a blank one" >&2
    return 1
  }
  [ "$(grep -c -F "answer 1 or 2 (the words solo and team work too)" "$TMP_ROOT/$name.out")" = "2" ] || {
    echo "FAIL: $name — the collaboration question did not re-ask both an unrecognised answer and a whitespace one" >&2
    return 1
  }
  # The menu has to name what each layout does to this folder, at the moment the choice is made.
  # This is a wording assertion and only that: it proves the sentence is on screen, not that a
  # reader takes it in. What it describes is asserted for real just below, where this case
  # separates the layouts by what they actually build. Both halves, because a one-sided contrast
  # is what the old text had — "become separate repos" never said separate from what.
  grep -Fq "this folder is not itself a repo" "$TMP_ROOT/$name.out" || {
    echo "FAIL: $name — the multi option does not say the workspace root stops being a repository" >&2
    return 1
  }
  grep -Fq "everything here is tracked" "$TMP_ROOT/$name.out" || {
    echo "FAIL: $name — the mono option does not say what it tracks, so the contrast is one-sided" >&2
    return 1
  }
  # This case builds a mono project, so the closing line must be the mono one. The menu telling the
  # reader that root files are untracked and the ending telling them the project is saved leave a
  # contradiction for them to resolve, and they will believe the reassuring half — so the two have
  # to agree per layout. The multi half is asserted in run_saved_tip_multi_case.
  grep -Fq "everything in this" "$TMP_ROOT/$name.out" || {
    echo "FAIL: $name — a mono project's closing line does not say the whole folder is in the repo" >&2
    return 1
  }
  if grep -Fq "not in any repository" "$TMP_ROOT/$name.out"; then
    echo "FAIL: $name — a mono project was told files here are not in a repository" >&2
    return 1
  fi

  # "mono" has to mean the mono layout, not most of it. The hybrid's signature was prompts/ left
  # as a repository of its own while every other decision went the mono way, so these two
  # assertions together are what separates the layouts -- neither alone does.
  [ -d "$work/.git" ] || {
    echo "FAIL: $name did not make the workspace root a repository" >&2
    return 1
  }
  [ ! -d "$work/prompts/.git" ] || {
    echo "FAIL: $name left prompts/ a repository of its own — the hybrid build" >&2
    return 1
  }
  grep -Fq 'location: "."' "$work/Code/$name-docs/registries/repos.yml" || {
    echo "FAIL: $name did not seed the workspace-root registry row" >&2
    return 1
  }

  # "team" has to reach the one thing the answer decides. Solo stamps "_solo author_" on this
  # field; the flag's value only lands there if the typed answer was read as team. Match the
  # field and its value together: the line below it is a template comment offering "tech lead"
  # as an example, so a bare grep for the value passes in a solo project too — measured.
  grep -Fq '**Who accepts an ADR in this project:** tech lead' \
    "$work/Code/$name-docs/adr/README.md" || {
    echo "FAIL: $name did not record the ADR acceptance authority — typed 'team' read as solo" >&2
    grep -F 'Who accepts an ADR in this project' "$work/Code/$name-docs/adr/README.md" >&2
    return 1
  }
  assert_maintainer_tests_removed "$name" "$work"
}

# refusing_remote PATH — a bare repo that accepts no push. `git ls-remote` still answers, so
# init.sh's pre-boundary reachability check passes and the failure lands where these cases need
# it: after the project is generated and committed, which is the only place the two layouts ever
# disagreed about what to do next.
refusing_remote() {
  git init --bare -q "$1"
  printf '#!/bin/sh\nexit 1\n' >"$1/hooks/pre-receive"
  chmod +x "$1/hooks/pre-receive"
}

# run_remote_failure_multi_case — a backup the user asked for and did not get must not read as
# success. The prompts remote refuses every push and the docs remote works, so this also pins
# that only the repo that failed is named: sending someone to a repo that is fine is its own
# defect. Multi used to exit 0 here, which told a caller -- --non-interactive is documented as
# being for scripts and CI -- that the backup exists.
run_remote_failure_multi_case() {
  local name="remote-failure-multi"
  local work="$TMP_ROOT/$name"
  local docs_remote="$TMP_ROOT/$name-docs.git"
  local prompts_remote="$TMP_ROOT/$name-prompts.git"
  local status

  copy_template "$work"
  git init --bare -q "$docs_remote"
  refusing_remote "$prompts_remote"
  set +e
  (
    cd "$work"
    ./init.sh \
      --non-interactive \
      --slug="$name" \
      --desc="Remote failure test" \
      --license=mit \
      --holder="Throughstone Test" \
      --layout=multi \
      --collab=solo \
      --remotes=yes \
      --remote-provider=manual \
      --docs-remote="$docs_remote" \
      --prompts-remote="$prompts_remote"
  ) >"$TMP_ROOT/$name.out" 2>&1
  status=$?
  set -e

  [ "$status" -ne 0 ] || {
    echo "FAIL: $name exited 0 with a backup that did not complete" >&2
    return 1
  }
  # The project is finished, so the instructions for attaching a remote by hand are exactly what
  # the reader needs now and must survive the failure.
  grep -Fq "Next step:" "$TMP_ROOT/$name.out" || {
    echo "FAIL: $name suppressed the closing instructions" >&2
    return 1
  }
  grep -Fq "The remote backup did not complete for: $name-prompts" "$TMP_ROOT/$name.out" || {
    echo "FAIL: $name did not name the repo whose backup failed" >&2
    grep -F "did not complete for" "$TMP_ROOT/$name.out" >&2
    return 1
  }
  if grep -F "did not complete for" "$TMP_ROOT/$name.out" | grep -Fq "$name-docs"; then
    echo "FAIL: $name named the docs repo, whose push succeeded" >&2
    return 1
  fi
  # Where to stand is layout-decided. Multi can only ever list the two sibling repos, and its
  # workspace root is not a repository, so offering it sends the reader somewhere they cannot run
  # the commands below the sentence.
  grep -Fq "Code/$name-docs/ for $name-docs" "$TMP_ROOT/$name.out" || {
    echo "FAIL: $name did not say which folder each named repo backs up" >&2
    return 1
  }
  if grep -Fq "workspace root, the one repository" "$TMP_ROOT/$name.out"; then
    echo "FAIL: $name offered the workspace root, which is not a repository in this layout" >&2
    return 1
  fi
  # The registry is the half that must never overstate: the repo that pushed is recorded, the
  # one that did not is left with no remote for the check-in to flag.
  grep -Fq "remote: \"$docs_remote\"" "$work/Code/$name-docs/registries/repos.yml" || {
    echo "FAIL: $name did not record the remote that succeeded" >&2
    return 1
  }
  if grep -Fq "$prompts_remote" "$work/Code/$name-docs/registries/repos.yml"; then
    echo "FAIL: $name recorded a remote its branch never reached" >&2
    return 1
  fi
  assert_maintainer_tests_removed "$name" "$work"
}

# run_remote_failure_mono_case — the same failure through the other layout's code. Mono reaches
# it by reusing an origin the folder already had, so the push is inside reuse_root_origin rather
# than setup_remote, and it used to end the run outright: the project was generated and committed
# and the closing instructions never printed. The origin stays attached here, which is why the
# report is careful to say the push did not complete rather than that there is no remote.
run_remote_failure_mono_case() {
  local name="remote-failure-mono"
  local work="$TMP_ROOT/$name"
  local remote="$TMP_ROOT/$name-origin.git"
  local status root_row

  copy_template "$work"
  refusing_remote "$remote"
  set +e
  (
    cd "$work"
    git init -q
    git remote add origin "$remote"
    ./init.sh \
      --non-interactive \
      --slug="$name" \
      --desc="Remote failure test" \
      --license=mit \
      --holder="Throughstone Test" \
      --layout=mono \
      --collab=solo \
      --remotes=yes
  ) >"$TMP_ROOT/$name.out" 2>&1
  status=$?
  set -e

  [ "$status" -ne 0 ] || {
    echo "FAIL: $name exited 0 with a backup that did not complete" >&2
    return 1
  }
  grep -Fq "Next step:" "$TMP_ROOT/$name.out" || {
    echo "FAIL: $name suppressed the closing instructions" >&2
    return 1
  }
  grep -Fq "The remote backup did not complete for: $name" "$TMP_ROOT/$name.out" || {
    echo "FAIL: $name did not name the repo whose backup failed" >&2
    grep -F "did not complete for" "$TMP_ROOT/$name.out" >&2
    return 1
  }
  # The mirror of the multi case: mono only ever lists the bare slug, and prompts/ and
  # Code/<slug>-docs/ are folders inside the one repository rather than repos to stand in.
  grep -Fq "Run these from the workspace root" "$TMP_ROOT/$name.out" || {
    echo "FAIL: $name did not point the reader at the workspace root" >&2
    return 1
  }
  if grep -Fq "Code/$name-docs/ for" "$TMP_ROOT/$name.out"; then
    echo "FAIL: $name offered a folder inside the root repo as somewhere to stand" >&2
    return 1
  fi
  # Reused, so it is still attached -- the failure is the push, not the remote.
  [ "$(git -C "$work" remote get-url origin)" = "$remote" ] || {
    echo "FAIL: $name did not keep the origin it reused" >&2
    return 1
  }
  root_row="$(first_registry_row "$work/Code/$name-docs/registries/repos.yml")"
  if printf '%s\n' "$root_row" | grep -Fq 'remote:'; then
    echo "FAIL: $name recorded a remote its branch never reached" >&2
    printf '%s\n' "$root_row" >&2
    return 1
  fi
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

  # Every recorded remote must hold this project's trunk, at this project's commit. init.sh only
  # records a URL after gh reports success, and this is what gives that guarantee teeth: an
  # address in repos.yml proves nothing, and neither does an arbitrary branch on the far end.
  #
  # The count is asserted first and deliberately. A loop fed by grep runs zero times when the file
  # holds no rows, and passes -- so without this the whole check could succeed having examined
  # nothing at all.
  local recorded url rowname local_repo want_sha got_sha n=0
  while IFS= read -r recorded; do
    n=$((n + 1))
    url="${recorded#*remote: \"}"; url="${url%\"}"
    rowname="$(basename "${url%.git}")"
    case "$rowname" in
      "$name-docs") local_repo="$work/Code/$name-docs" ;;
      "$name-prompts") local_repo="$work/prompts" ;;
      *) echo "FAIL: $name recorded a remote for an unexpected repo: $url" >&2; return 1 ;;
    esac
    want_sha="$(git -C "$local_repo" rev-parse HEAD)"
    got_sha="$(git --git-dir="$url" rev-parse "refs/heads/$(git -C "$local_repo" symbolic-ref --short HEAD)" 2>/dev/null || true)"
    if [ "$got_sha" != "$want_sha" ]; then
      echo "FAIL: $name's remote $url does not hold $local_repo's trunk" >&2
      echo "      local $want_sha / remote ${got_sha:-<no such branch>}" >&2
      return 1
    fi
  done < <(grep '^    remote: ' "$work/Code/$name-docs/registries/repos.yml")
  if [ "$n" -ne 2 ]; then
    echo "FAIL: $name recorded $n remote(s) in repos.yml; expected 2 (docs and prompts)" >&2
    return 1
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
  # The matching must-proceed case for the ignored-flag note below: in the layout these two flags
  # are for, they are obeyed in silence. A note that fired here would be noise about work done.
  if grep -Fq "note: ignoring" "$TMP_ROOT/$name.out"; then
    echo "FAIL: $name — a flag the multi layout uses was reported as ignored" >&2
    grep -F "note: ignoring" "$TMP_ROOT/$name.out" >&2
    return 1
  fi
  assert_maintainer_tests_removed "$name" "$work"
}

# run_end_of_input_case — the run stops when the answers run out.
#
# An unattended run — an agent, a `< /dev/null`, a script whose answer stream is shorter than the
# question list — used to get an unlimited supply of empty answers, because ask discarded read's
# exit status. At a question with a default that silently built a whole project; at the slug
# question, whose loop re-asks until the answer is valid and where blank never is, it spun: the
# behaviour this case pins was measured at 94KB of the same notice in twelve seconds before it was
# killed. The slug question is the first one asked, so this is also the shortest path to it.
run_end_of_input_case() {
  local name="end-of-input" work status
  work="$TMP_ROOT/$name"

  copy_template "$work"
  set +e
  ( cd "$work" && run_with_deadline 60 ./init.sh </dev/null ) >"$TMP_ROOT/$name.out" 2>&1
  status=$?
  set -e

  [ "$status" -ne 124 ] || {
    echo "FAIL: $name — init.sh never stopped; it is looping on an exhausted answer stream" >&2
    tail -3 "$TMP_ROOT/$name.out" >&2
    return 1
  }
  [ "$status" -eq 2 ] || {
    echo "FAIL: $name — expected exit 2 when input ran out, got $status" >&2
    cat "$TMP_ROOT/$name.out" >&2
    return 1
  }
  # Naming the question is the difference between stopping and crashing: the message has to say
  # which answer is missing, because whoever is reading it did not see the prompt scroll past.
  grep -Fq "missing required value (input ended): Project slug" "$TMP_ROOT/$name.out" || {
    echo "FAIL: $name — the run stopped without naming the question it stopped at" >&2
    cat "$TMP_ROOT/$name.out" >&2
    return 1
  }
  # Stopping happens before the destructive boundary, so the checkout is still a template.
  [ -d "$work/Code/{{PROJECT}}-docs" ] || {
    echo "FAIL: $name — the template docs hub was renamed before the run stopped" >&2
    return 1
  }
  [ -f "$work/README.md" ]
  assert_maintainer_tests_retained "$name" "$work"
}

# run_remote_menu_case — the one question in the wizard that reaches outside this machine.
#
# "Remote setup" used to default to 1, so Enter meant "create real GitHub repositories under your
# account" — the only accidental answer here that leaves something to clean up on someone else's
# server. It now has no default and re-asks instead of exiting, and the same run proves the
# visibility default below it was kept: that one is cheap to accept by accident, because a repo
# nobody can read is one setting away from being right.
run_remote_menu_case() {
  local name="remote-menu" status
  local work="$TMP_ROOT/$name"
  local stub_bin="$TMP_ROOT/$name-bin"
  local remote_root="$TMP_ROOT/$name-remotes"
  local gh_log="$TMP_ROOT/$name-gh.log"

  copy_template "$work"
  mkdir -p "$stub_bin" "$remote_root"
  cp "$ROOT/tests/fixtures/gh-stub.sh" "$stub_bin/gh"
  chmod +x "$stub_bin/gh"
  : > "$gh_log"
  # The answer stream is exactly as long as the questions that should be asked, so a question
  # that gains a default consumes an answer meant for the next one and the stream runs out early.
  # The status is captured rather than left to errexit for that reason: that failure has to name
  # itself here, not kill the suite from inside a subshell with nothing written down.
  set +e
  (
    cd "$work"
    # y at "Set up online Git remotes now?", then the remote menu answered blank, then with a
    # word it does not know, then 1; then Enter at the visibility question, which still has a
    # default to take.
    printf 'y\n\nboth\n1\n\n' | \
      PATH="$stub_bin:$PATH" \
      GH_LOG="$gh_log" \
      GH_REMOTE_ROOT="$remote_root" \
      ./init.sh \
        --slug="$name" \
        --desc="Remote menu test" \
        --license=mit \
        --holder="Throughstone Test" \
        --layout=multi \
        --collab=solo \
        --owner=throughstone-test
  ) >"$TMP_ROOT/$name.out" 2>&1
  status=$?
  set -e
  [ "$status" -eq 0 ] || {
    echo "FAIL: $name — the run did not finish (exit $status); a question asked for an answer this stream does not carry, most likely the visibility default it was meant to keep" >&2
    cat "$TMP_ROOT/$name.out" >&2
    return 1
  }

  # The removal and the keep, measured in one run and only by behaviour: `read -p` prints its
  # prompt to a terminal only, so a pipe never sees the `[1]` that renders a default.
  #
  # Removed — the blank answer and the unrecognised one both come back as questions. Two, not one:
  # a menu that still defaulted would answer the blank itself and re-ask only "both".
  [ "$(grep -c -F "choose 1 to create GitHub remotes" "$TMP_ROOT/$name.out")" = "2" ] || {
    echo "FAIL: $name — Enter at the remote menu was taken as 'create GitHub repositories'" >&2
    cat "$TMP_ROOT/$name.out" >&2
    return 1
  }
  # Option 2's requirements are on screen with the option. They were already stated on the branch
  # taken when gh is missing, so the wizard explained itself only where it could not offer the
  # easier path; this run is the gh-installed one, where it did not. A wording assertion, and only
  # that — but the wording is the whole change.
  grep -Fq "must already exist, be empty, and be reachable" "$TMP_ROOT/$name.out" || {
    echo "FAIL: $name — the existing-URL option does not say what those URLs must be" >&2
    cat "$TMP_ROOT/$name.out" >&2
    return 1
  }
  # Kept — the visibility question got nothing but Enter, and private is what reached the host.
  # An open-source licence is chosen here for that assertion's sake: under a proprietary one, a
  # public answer trips the public/proprietary warning and cancels the run, so this case would go
  # red before ever reading the log and the line below would be measuring nothing.
  grep -Fq -- "--private" "$gh_log" || {
    echo "FAIL: $name — Enter at the visibility question did not create private repositories" >&2
    cat "$gh_log" >&2
    return 1
  }
  [ "$(git -C "$work/Code/$name-docs" remote get-url origin)" = "$remote_root/$name-docs.git" ]
  assert_maintainer_tests_removed "$name" "$work"
}

# run_ignored_flag_case — a flag that cannot apply is named, not obeyed and not refused.
#
# A mono project has one repository, so --docs-remote and --prompts-remote have nothing to attach
# to. They were dropped without a word, which left a project whose single remote contradicts the
# command that created it. Refusing instead would break a wrapper that passes the same flag set to
# every project, and the flags are harmless — so the run says what it discarded and carries on.
run_ignored_flag_case() {
  local name="ignored-flag"
  local work="$TMP_ROOT/$name"
  local remote="$TMP_ROOT/$name-project.git"
  local unused_docs="$TMP_ROOT/$name-docs.git"

  copy_template "$work"
  git init --bare -q "$remote"
  git init --bare -q "$unused_docs"
  (
    cd "$work"
    ./init.sh \
      --non-interactive \
      --slug="$name" \
      --desc="Ignored flag test" \
      --license=private \
      --layout=mono \
      --collab=solo \
      --remotes=yes \
      --remote-provider=manual \
      --remote-url="$remote" \
      --docs-remote="$unused_docs" \
      --prompts-remote="$unused_docs"
  ) >"$TMP_ROOT/$name.out" 2>&1

  grep -Fq "note: ignoring --docs-remote — mono layout has one repo" "$TMP_ROOT/$name.out" || {
    echo "FAIL: $name — --docs-remote was dropped without saying so" >&2
    cat "$TMP_ROOT/$name.out" >&2
    return 1
  }
  grep -Fq "note: ignoring --prompts-remote — mono layout has one repo" "$TMP_ROOT/$name.out" || {
    echo "FAIL: $name — --prompts-remote was dropped without saying so" >&2
    cat "$TMP_ROOT/$name.out" >&2
    return 1
  }
  # Named, not refused: the project is still built, and built against the URL that does apply.
  [ "$(git -C "$work" remote get-url origin)" = "$remote" ] || {
    echo "FAIL: $name — the mono repo did not attach --remote-url" >&2
    return 1
  }
  git --git-dir="$remote" rev-parse --verify refs/heads/main >/dev/null
  # Named, not obeyed: nothing was pushed to the repo the ignored flags pointed at.
  if git --git-dir="$unused_docs" rev-parse --verify refs/heads/main >/dev/null 2>&1; then
    echo "FAIL: $name — an ignored flag's remote was written to anyway" >&2
    return 1
  fi
  # The other direction, in the layout that uses it: --remote-url is this layout's own flag and
  # must not be reported as dropped. Each of the two cases carries both halves, so a note that
  # escapes the layout it belongs to is caught wherever it lands.
  if grep -Fq "ignoring --remote-url" "$TMP_ROOT/$name.out"; then
    echo "FAIL: $name — the flag this layout actually uses was reported as ignored" >&2
    return 1
  fi
  assert_maintainer_tests_removed "$name" "$work"
}

# run_ignored_flag_multi_case — the same rule in the other layout, which is the whole point of it.
#
# A multi project has two durable repos and no single one, so --remote-url has nothing to attach
# to; it was accepted, never read and never mentioned, exactly as --docs-remote was in mono. A
# rule that held in one layout only would be the same defect wearing the other hat.
run_ignored_flag_multi_case() {
  local name="ignored-flag-multi"
  local work="$TMP_ROOT/$name"
  local docs_remote="$TMP_ROOT/$name-docs.git"
  local prompts_remote="$TMP_ROOT/$name-prompts.git"
  local unused_root="$TMP_ROOT/$name-root.git"

  copy_template "$work"
  git init --bare -q "$docs_remote"
  git init --bare -q "$prompts_remote"
  git init --bare -q "$unused_root"
  (
    cd "$work"
    ./init.sh \
      --non-interactive \
      --slug="$name" \
      --desc="Ignored flag multi test" \
      --license=private \
      --layout=multi \
      --collab=solo \
      --remotes=yes \
      --remote-provider=manual \
      --docs-remote="$docs_remote" \
      --prompts-remote="$prompts_remote" \
      --remote-url="$unused_root"
  ) >"$TMP_ROOT/$name.out" 2>&1

  grep -Fq "note: ignoring --remote-url — multi layout has two repos" "$TMP_ROOT/$name.out" || {
    echo "FAIL: $name — --remote-url was dropped without saying so" >&2
    cat "$TMP_ROOT/$name.out" >&2
    return 1
  }
  # Named, not refused: both repos still got the URLs that do apply.
  [ "$(git -C "$work/Code/$name-docs" remote get-url origin)" = "$docs_remote" ] || {
    echo "FAIL: $name — the docs repo did not attach --docs-remote" >&2
    return 1
  }
  [ "$(git -C "$work/prompts" remote get-url origin)" = "$prompts_remote" ] || {
    echo "FAIL: $name — the prompts repo did not attach --prompts-remote" >&2
    return 1
  }
  # Named, not obeyed: nothing was pushed to the repo the ignored flag pointed at.
  if git --git-dir="$unused_root" rev-parse --verify refs/heads/main >/dev/null 2>&1; then
    echo "FAIL: $name — the ignored flag's remote was written to anyway" >&2
    return 1
  fi
  # And the mono layout's two notes must not fire here, where those flags are the ones in use.
  if grep -Fq "ignoring --docs-remote" "$TMP_ROOT/$name.out" \
    || grep -Fq "ignoring --prompts-remote" "$TMP_ROOT/$name.out"; then
    echo "FAIL: $name — a flag this layout actually uses was reported as ignored" >&2
    return 1
  fi
  assert_maintainer_tests_removed "$name" "$work"
}

# run_github_choice_discarded_case — an answer that cannot apply is named, the way a flag is.
#
# A mono project's one repository is the workspace root, so when that folder already has an empty
# origin there is nothing for "create a repository on GitHub" to create. Reusing the origin is the
# right outcome; not saying so was the defect. Measured before the fix: the run answered y and
# then 1 at the remote menu, never called `gh`, never asked for the owner, and reported the result
# only as a reuse — after the destructive boundary, and never as creation having been dropped.
#
# Both halves run here. Without a reusable origin the same answers must still create the repo and
# must not print the note; a note that fired there would be describing work the run actually did.
run_github_choice_discarded_case() {
  local name="github-choice-discarded" status
  local work="$TMP_ROOT/$name" plain="$TMP_ROOT/$name-plain"
  local stub_bin="$TMP_ROOT/$name-bin"
  local remote_root="$TMP_ROOT/$name-remotes"
  local gh_log="$TMP_ROOT/$name-gh.log"
  local theirs="$TMP_ROOT/$name-theirs.git"

  mkdir -p "$stub_bin" "$remote_root"
  cp "$ROOT/tests/fixtures/gh-stub.sh" "$stub_bin/gh"
  chmod +x "$stub_bin/gh"

  # --- reusable origin present: creation is discarded, and says so ---
  copy_template "$work"
  git init --bare -q "$theirs"
  ( cd "$work" && git init -q && git remote add origin "$theirs" )
  : > "$gh_log"
  set +e
  (
    cd "$work"
    # y at "Set up online Git remotes now?", 1 at the remote menu, Enter for visibility.
    printf 'y\n1\n\n' | \
      PATH="$stub_bin:$PATH" GH_LOG="$gh_log" GH_REMOTE_ROOT="$remote_root" \
      ./init.sh --slug="$name" --desc="Discarded choice test" --license=private \
        --layout=mono --collab=solo
  ) >"$TMP_ROOT/$name.out" 2>&1
  status=$?
  set -e
  [ "$status" -eq 0 ] || {
    echo "FAIL: $name — the run did not finish (exit $status)" >&2
    cat "$TMP_ROOT/$name.out" >&2
    return 1
  }
  # Both assertions read only what was printed before the destructive boundary, because "before"
  # is the whole claim: `reuse_root_origin` already names the same URL afterwards, and telling
  # someone where their project went once it is too late to stop is the defect, not the fix.
  # Measured — against the full log, deleting the URL line from the note changes nothing and the
  # mutation survives.
  sed -n "1,/Detaching from the template/p" "$TMP_ROOT/$name.out" > "$TMP_ROOT/$name.pre"
  grep -Fq "note: not creating a repository on GitHub" "$TMP_ROOT/$name.pre" || {
    echo "FAIL: $name — the GitHub-creation answer was discarded without saying so, or said too late" >&2
    cat "$TMP_ROOT/$name.out" >&2
    return 1
  }
  # The URL belongs in the note: it decides where the project ends up and nothing earlier shows it.
  grep -Fq "$theirs" "$TMP_ROOT/$name.pre" || {
    echo "FAIL: $name — the note did not name the origin that is used instead" >&2
    cat "$TMP_ROOT/$name.pre" >&2
    return 1
  }
  # Named, not obeyed: no repository was created on the host, and the existing origin is the one.
  [ ! -s "$gh_log" ] || {
    echo "FAIL: $name — a GitHub repository was created after all" >&2
    cat "$gh_log" >&2
    return 1
  }
  [ "$(git -C "$work" remote get-url origin)" = "$theirs" ] || {
    echo "FAIL: $name — the existing origin was not the one reused" >&2
    return 1
  }

  # --- no reusable origin: creation happens, and the note must stay quiet ---
  copy_template "$plain"
  : > "$gh_log"
  (
    cd "$plain"
    printf 'y\n1\n\n' | \
      PATH="$stub_bin:$PATH" GH_LOG="$gh_log" GH_REMOTE_ROOT="$remote_root" \
      ./init.sh --slug="$name-plain" --desc="Discarded choice control" --license=private \
        --layout=mono --collab=solo --owner=throughstone-test
  ) >"$TMP_ROOT/$name-plain.out" 2>&1
  if grep -Fq "note: not creating a repository on GitHub" "$TMP_ROOT/$name-plain.out"; then
    echo "FAIL: $name — the note fired on a run that did create the repository" >&2
    return 1
  fi
  grep -Fq "repo create" "$gh_log" || {
    echo "FAIL: $name — no repository was created where creation was the right outcome" >&2
    cat "$TMP_ROOT/$name-plain.out" >&2
    return 1
  }
  assert_maintainer_tests_removed "$name-plain" "$plain"
}

# run_slug_message_case — a refusal has to describe the rule it actually enforces.
#
# The slug pattern is `^[a-z][a-z0-9-]*$`, and the refusal read "lowercase letters, digits,
# hyphens only" — which `3d-printer` satisfies. Measured: the flag path exited 2 quoting that
# message back at a slug obeying it. At the prompt the same string is worse, because the loop
# re-asks and nothing in it leads to an answer that works.
#
# Both call sites share one string, so both are checked here — and the prompt run has to go on to
# build the project, which is the must-proceed half: a refusal that never accepts anything is not
# an improvement on one that explains itself badly.
run_slug_message_case() {
  local name="slug-message" status
  local flag_work="$TMP_ROOT/$name-flag" prompt_work="$TMP_ROOT/$name-prompt"
  local rule="must start with a lowercase letter"

  # --- the flag path stops, and names the rule ---
  copy_template "$flag_work"
  set +e
  (
    cd "$flag_work"
    ./init.sh --non-interactive --slug=3d-printer --desc="Slug message test" \
      --license=private --layout=multi --collab=solo --remotes=no
  ) >"$TMP_ROOT/$name-flag.out" 2>&1
  status=$?
  set -e
  [ "$status" -eq 2 ] || {
    echo "FAIL: $name — a slug starting with a digit was accepted (exit $status)" >&2
    cat "$TMP_ROOT/$name-flag.out" >&2
    return 1
  }
  grep -Fq "$rule" "$TMP_ROOT/$name-flag.out" || {
    echo "FAIL: $name — the refusal did not name the first-character rule it enforces" >&2
    cat "$TMP_ROOT/$name-flag.out" >&2
    return 1
  }
  # Refused before the destructive boundary, like every other slug problem.
  [ -d "$flag_work/Code/{{PROJECT}}-docs" ] || {
    echo "FAIL: $name — the run crossed the destructive boundary before refusing the slug" >&2
    return 1
  }

  # --- the prompt path re-asks, names the same rule, and then builds the project ---
  # The answer stream carries exactly one bad slug and one good one, so a rule that refuses the
  # good one runs the stream out and the wizard stops. Capture that instead of leaving it to
  # errexit, which would kill the suite from inside the subshell without naming this case.
  copy_template "$prompt_work"
  set +e
  (
    cd "$prompt_work"
    printf '3d-printer\nprinter-3d\n' | ./init.sh --desc="Slug message test" \
      --license=private --layout=multi --collab=solo --remotes=no
  ) >"$TMP_ROOT/$name-prompt.out" 2>&1
  status=$?
  set -e
  [ "$status" -eq 0 ] || {
    echo "FAIL: $name — the prompt run did not finish (exit $status); a slug this stream carries was refused" >&2
    cat "$TMP_ROOT/$name-prompt.out" >&2
    return 1
  }
  grep -Fq "$rule" "$TMP_ROOT/$name-prompt.out" || {
    echo "FAIL: $name — the re-ask did not name the first-character rule" >&2
    cat "$TMP_ROOT/$name-prompt.out" >&2
    return 1
  }
  # A digit anywhere but first is fine, which is the half the message has to leave standing.
  [ -d "$prompt_work/Code/printer-3d-docs" ] || {
    echo "FAIL: $name — the corrected slug was not accepted" >&2
    cat "$TMP_ROOT/$name-prompt.out" >&2
    return 1
  }
  assert_maintainer_tests_removed "$name-prompt" "$prompt_work"
}

# run_licence_vocabulary_case — one word, one meaning.
#
# The licence question called its own answer "Private / proprietary" while a question twenty lines
# later offers "1) Private" for repository visibility, which is unrelated: a private repo can carry
# MIT and a public repo can be proprietary. A reader who took the first question to be about
# visibility answered it and got a project licensed to nobody. `proprietary` is now the licence
# word everywhere — label, flag value and internal token — and `private` belongs to visibility.
#
# Three parts, because the rule is only true if all three hold: the question stops using the word,
# the new spelling works, and the old spelling keeps working while saying what to write instead.
# That last part is the must-proceed half — a vocabulary change that breaks every existing wrapper
# is not an improvement, and four other test files in this suite still pass --license=private.
run_licence_vocabulary_case() {
  local name="licence-vocabulary" status
  local ask_work="$TMP_ROOT/$name-ask"
  local old_work="$TMP_ROOT/$name-old" new_work="$TMP_ROOT/$name-new"

  # --- the question no longer spends "private" on licensing ---
  copy_template "$ask_work"
  (
    cd "$ask_work"
    printf '2\n' | ./init.sh --slug="$name-ask" --desc="Vocabulary test" \
      --layout=multi --collab=solo --remotes=no
  ) >"$TMP_ROOT/$name-ask.out" 2>&1
  if grep -Fqi "private" "$TMP_ROOT/$name-ask.out"; then
    echo "FAIL: $name — the licence question still spends the word 'private' on licensing" >&2
    grep -Fi "private" "$TMP_ROOT/$name-ask.out" >&2
    return 1
  fi
  grep -Fq "2) Proprietary" "$TMP_ROOT/$name-ask.out" || {
    echo "FAIL: $name — the licence question does not offer 'Proprietary' by name" >&2
    cat "$TMP_ROOT/$name-ask.out" >&2
    return 1
  }
  # And it says the two questions are different, which is the whole reason the reader went wrong.
  grep -Fq "Not the same as who can see the repository" "$TMP_ROOT/$name-ask.out" || {
    echo "FAIL: $name — nothing tells the reader visibility is a separate question" >&2
    return 1
  }
  grep -Fxq "Proprietary" "$ask_work/Code/$name-ask-docs/.throughstone/project-license" || {
    echo "FAIL: $name — answering 2 did not record the proprietary posture" >&2
    return 1
  }

  # --- the deprecated spelling still builds the same project, and says so once ---
  copy_template "$old_work"
  set +e
  (
    cd "$old_work"
    ./init.sh --non-interactive --slug="$name-old" --desc="Vocabulary test" \
      --license=private --layout=multi --collab=solo --remotes=no
  ) >"$TMP_ROOT/$name-old.out" 2>&1
  status=$?
  set -e
  [ "$status" -eq 0 ] || {
    echo "FAIL: $name — --license=private stopped working; every wrapper passing it would break" >&2
    cat "$TMP_ROOT/$name-old.out" >&2
    return 1
  }
  grep -Fxq "Proprietary" "$old_work/Code/$name-old-docs/.throughstone/project-license" || {
    echo "FAIL: $name — --license=private no longer means the proprietary posture" >&2
    return 1
  }
  # `--` before the pattern: without it grep reads a pattern starting with "--" as an option and
  # the assertion fails on a run that printed exactly the right thing. Measured, right here.
  grep -Fq -- "--license=private is deprecated" "$TMP_ROOT/$name-old.out" || {
    echo "FAIL: $name — the deprecated spelling was accepted without saying what to write instead" >&2
    cat "$TMP_ROOT/$name-old.out" >&2
    return 1
  }

  # --- the new spelling builds it too, and says nothing ---
  copy_template "$new_work"
  (
    cd "$new_work"
    ./init.sh --non-interactive --slug="$name-new" --desc="Vocabulary test" \
      --license=proprietary --layout=multi --collab=solo --remotes=no
  ) >"$TMP_ROOT/$name-new.out" 2>&1
  grep -Fxq "Proprietary" "$new_work/Code/$name-new-docs/.throughstone/project-license" || {
    echo "FAIL: $name — --license=proprietary did not record the proprietary posture" >&2
    return 1
  }
  if grep -Fq "deprecated" "$TMP_ROOT/$name-new.out"; then
    echo "FAIL: $name — the spelling being recommended warns about itself" >&2
    return 1
  fi
  assert_maintainer_tests_removed "$name-new" "$new_work"
}

# run_mono_team_caveat_case — a caveat turns on the answers it is about, not on how they arrived.
#
# Mono-repo plus team makes the overlap warning useless, because that warning is repo-granular and
# there is one repo. The note saying so used to sit inside the branch that asks who accepts ADRs,
# so its real condition was how that unrelated value was supplied. Measured on three identical
# mono + team projects: typing the authority printed the note, `--adr-authority` did not, and
# `--non-interactive` did not.
#
# Five runs: the three ways a mono + team project can be created, all of which must warn, and the
# two neighbouring combinations, neither of which may. Without the last two this case would pass
# for a note printed unconditionally, which is a different defect with the same symptom here.
run_mono_team_caveat_case() {
  local name="mono-team-caveat" n out
  local caveat="you picked mono-repo + team"

  # warns: the ADR authority typed, passed as a flag, and defaulted by --non-interactive
  for n in typed flag noninteractive; do
    out="$TMP_ROOT/$name-$n.out"
    copy_template "$TMP_ROOT/$name-$n"
    (
      cd "$TMP_ROOT/$name-$n"
      case "$n" in
        typed) printf '2\n2\ntech lead\n' | ./init.sh --slug="$name-$n" \
                 --desc="Caveat test" --license=proprietary --remotes=no ;;
        flag)  printf '2\n2\n' | ./init.sh --slug="$name-$n" \
                 --desc="Caveat test" --license=proprietary --remotes=no \
                 --adr-authority="tech lead" ;;
        *)     ./init.sh --non-interactive --slug="$name-$n" --desc="Caveat test" \
                 --license=proprietary --layout=mono --collab=team --remotes=no ;;
      esac
    ) >"$out" 2>&1
    grep -Fq "$caveat" "$out" || {
      echo "FAIL: $name — a mono + team project built via '$n' was not warned" >&2
      cat "$out" >&2
      return 1
    }
    # The line above the caveat had the same defect and is checked on the same three paths: why a
    # team needs shared remotes is advice about the collaboration answer, not about how the ADR
    # authority happened to arrive.
    grep -Fq "Heads-up: team collaboration relies on shared Git remotes" "$out" || {
      echo "FAIL: $name — a team project built via '$n' was not told a team needs shared remotes" >&2
      return 1
    }
    # Stopping is free at that point, and saying so is what gives the reader a way to act.
    grep -Fq "Nothing has been created yet" "$out" || {
      echo "FAIL: $name — the caveat ('$n') did not say the run can still be stopped" >&2
      return 1
    }
  done

  # must not warn: neither neighbouring combination has the limitation
  for n in mono-solo multi-team; do
    out="$TMP_ROOT/$name-$n.out"
    copy_template "$TMP_ROOT/$name-$n"
    (
      cd "$TMP_ROOT/$name-$n"
      case "$n" in
        mono-solo)  ./init.sh --non-interactive --slug="$name-$n" --desc="Caveat test" \
                      --license=proprietary --layout=mono --collab=solo --remotes=no ;;
        *)          ./init.sh --non-interactive --slug="$name-$n" --desc="Caveat test" \
                      --license=proprietary --layout=multi --collab=team --remotes=no ;;
      esac
    ) >"$out" 2>&1
    if grep -Fq "$caveat" "$out"; then
      echo "FAIL: $name — '$n' was warned about a limitation it does not have" >&2
      return 1
    fi
    # The team advice is scoped to teams, and the mono+team caveat to mono teams — so these two
    # runs pull in opposite directions and neither alone would catch a line that fires for all.
    case "$n" in
      mono-solo)
        if grep -Fq "Heads-up: team collaboration" "$out"; then
          echo "FAIL: $name — a solo project was given team advice" >&2
          return 1
        fi ;;
      multi-team)
        grep -Fq "Heads-up: team collaboration" "$out" || {
          echo "FAIL: $name — a multi-repo team was not told a team needs shared remotes" >&2
          return 1
        } ;;
    esac
  done
  assert_maintainer_tests_removed "$name-multi-team" "$TMP_ROOT/$name-multi-team"
}

# run_solo_adr_flag_case — a solo project records the author, so a supplied authority is dropped.
#
# `--collab=solo --adr-authority="the CTO"` used to exit 0 with the register stamped `_solo author_`
# and no mention of the flag at all — measured. That is the fifth instance of one pattern on this
# branch: the wizard accepting something it cannot use and saying nothing, leaving a project that
# disagrees with the command that made it. Named rather than refused, because a wrapper passing one
# flag set to every project should not fail over a value that costs nothing to drop.
#
# Both directions, since a note that fires everywhere is a different defect with the same symptom:
# solo with the flag must say so, and team with the same flag must obey it in silence.
run_solo_adr_flag_case() {
  local name="solo-adr-flag" status n out
  local note="note: ignoring --adr-authority"

  # Three runs. solo and team both pass the flag; quiet passes none, and is the run that keeps the
  # note off the common path — without it a note that fires for every solo project passes this
  # case, which is a different defect with the same symptom. Measured: a mutation dropping the
  # flag test survived until this run existed.
  for n in solo team quiet; do
    out="$TMP_ROOT/$name-$n.out"
    copy_template "$TMP_ROOT/$name-$n"
    set +e
    (
      cd "$TMP_ROOT/$name-$n"
      case "$n" in
        quiet) ./init.sh --non-interactive --slug="$name-$n" --desc="Solo flag test" \
                 --license=proprietary --layout=multi --collab=solo --remotes=no ;;
        *)     ./init.sh --non-interactive --slug="$name-$n" --desc="Solo flag test" \
                 --license=proprietary --layout=multi --collab="$n" \
                 --adr-authority="the CTO" --remotes=no ;;
      esac
    ) >"$out" 2>&1
    status=$?
    set -e
    [ "$status" -eq 0 ] || {
      echo "FAIL: $name — the '$n' run did not finish (exit $status); the flag was refused, not named" >&2
      cat "$out" >&2
      return 1
    }
  done

  # No flag, nothing to report: the ordinary solo run stays quiet.
  if grep -Fq -- "$note" "$TMP_ROOT/$name-quiet.out"; then
    echo "FAIL: $name — a solo project reported ignoring a flag nobody passed" >&2
    return 1
  fi

  # Solo: named, and not obeyed — the register still records the author.
  grep -Fq -- "$note" "$TMP_ROOT/$name-solo.out" || {
    echo "FAIL: $name — --adr-authority was dropped on a solo project without saying so" >&2
    cat "$TMP_ROOT/$name-solo.out" >&2
    return 1
  }
  grep -Fq "_solo author_" "$TMP_ROOT/$name-solo/Code/$name-solo-docs/adr/README.md" || {
    echo "FAIL: $name — a solo project did not record the author as the authority" >&2
    return 1
  }
  # Team: obeyed, and not named — this is the layout the flag is for.
  if grep -Fq -- "$note" "$TMP_ROOT/$name-team.out"; then
    echo "FAIL: $name — the flag was reported as ignored on a project that uses it" >&2
    return 1
  fi
  grep -Fq "the CTO" "$TMP_ROOT/$name-team/Code/$name-team-docs/adr/README.md" || {
    echo "FAIL: $name — a team project did not record the supplied authority" >&2
    return 1
  }
  assert_maintainer_tests_removed "$name-team" "$TMP_ROOT/$name-team"
}

# run_saved_tip_multi_case — the ending agrees with the layout menu about what is saved.
#
# The layout question tells a multi-repo reader that this folder is not a repository and files left
# here are not tracked. The closing section then said "your project is saved locally with Git",
# unconditionally, in the same run a few screens later. Two sentences, one contradiction, and the
# reassuring one is the one a reader believes — so the ending is now per-layout, the way the
# init.sh tip beside it already was. The mono half is asserted in run_typed_layout_collab_case.
run_saved_tip_multi_case() {
  local name="saved-tip-multi"
  local work="$TMP_ROOT/$name"

  copy_template "$work"
  (
    cd "$work"
    ./init.sh --non-interactive --slug="$name" --desc="Saved tip test" \
      --license=proprietary --layout=multi --collab=solo --remotes=no
  ) >"$TMP_ROOT/$name.out" 2>&1

  grep -Fq "both repositories here are committed locally" "$TMP_ROOT/$name.out" || {
    echo "FAIL: $name — the ending does not say which repositories hold the committed work" >&2
    cat "$TMP_ROOT/$name.out" >&2
    return 1
  }
  grep -Fq "Files at the workspace root are not in any repository" "$TMP_ROOT/$name.out" || {
    echo "FAIL: $name — the ending contradicts the layout menu about the workspace root" >&2
    return 1
  }
  # The sentence that caused the contradiction must be gone, not merely joined by a correction.
  if grep -Fq "your project is saved locally with Git" "$TMP_ROOT/$name.out"; then
    echo "FAIL: $name — the unqualified 'project is saved' claim is still printed in multi" >&2
    return 1
  fi
  assert_maintainer_tests_removed "$name" "$work"
}

# --- Interactive license selection -------------------------------------------
# Prompted open-source choices cover explicit input, defaults, and reprompting. The reprompt
# case protects early validation: invalid answers should not cross into bootstrap work.
run_interactive_case \
  "license-mit" \
  $'1\nMIT\n' \
  "MIT License"

# Open source chosen explicitly, then the licence sub-prompt answered blank, then answered with a
# space, then answered. The sub-prompt used to default to MIT, so both of those middle answers
# were an MIT grant nobody typed. The project this still builds is half the assertion: taking the
# default away has to leave the question answerable, not merely refusable.
run_interactive_case \
  "license-blank-reasked" \
  $'1\n\n \n1\n' \
  "MIT License"

# Two re-asks, not one: the blank answer and the whitespace one each have to come back. Counting
# is the whole assertion, because `read -p` prints its prompt only to a terminal — under a pipe
# there is no prompt text in the output to read a default off, so what the question offers can
# only be measured by what it does with an answer nobody gave.
[ "$(grep -c -F "choose 1/mit, 2/bsd-3, or 3/apache-2.0" "$TMP_ROOT/license-blank-reasked.out")" = "2" ] || {
  echo "FAIL: license-blank-reasked — Enter or a space at the licence question was taken as an answer" >&2
  cat "$TMP_ROOT/license-blank-reasked.out" >&2
  exit 1
}

run_interactive_case \
  "license-reprompt" \
  $'invalid\n1\nnonsense\nApache-2.0\n' \
  "Apache License"

grep -Fq \
  "choose 1 for open source or 2 for proprietary" \
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

# --- A remote the user asked for and did not get -------------------------------
# Both layouts must finish the project, print the closing instructions, name only what failed,
# record nothing they cannot back up, and exit non-zero.
run_remote_failure_multi_case
run_remote_failure_mono_case

# --- Typed answers, not just flags --------------------------------------------
run_typed_layout_collab_case
run_missing_canonical_license_case

# --- An answer nobody gave --------------------------------------------------------
# The wizard must not act on Enter where the answer is structural, must not act on an answer
# stream that has run out, and must say which flags it dropped. Each case pairs its refusal with
# the acceptance beside it: a project still gets built in every one of them.
run_end_of_input_case
run_remote_menu_case
run_ignored_flag_case
run_ignored_flag_multi_case
run_github_choice_discarded_case
run_slug_message_case
run_licence_vocabulary_case
run_mono_team_caveat_case
run_solo_adr_flag_case
run_saved_tip_multi_case

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
