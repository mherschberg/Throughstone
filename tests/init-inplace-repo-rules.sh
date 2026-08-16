#!/usr/bin/env bash
#
# Regression coverage for the create-vs-registered-in-place split in a generated project.
#
# METHOD.md §7 lets a repo be REGISTERED IN PLACE — referenced where it already sits instead of
# created under Code/. Almost everything the method does to a repo it creates is wrong for one it
# did not: stamping the README over the repo's most-read file, installing a failing-until-configured
# CI gate over the workflow that gates their merges, applying a project license to code the method
# never wrote. None of that is mechanically checkable — it is prose an agent reads and acts on — so
# what this test pins is that each instruction ships next to the work it governs. The rule is
# useless in METHOD.md alone if the file an agent has open while scaffolding still says otherwise.
#
# Every assertion reads the GENERATED project, not the template, and matches the SUBSTITUTED form:
# an assertion written against {{PROJECT}} would pass on a template that never got substituted.
#
# Keep every needle to ONE line. `grep -F` reads a newline in the pattern as OR, not as a multi-line
# match, so a needle spanning a wrap silently becomes "either half" — which passes on text that
# says neither thing in full.

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-inplace-test.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

# copy_template DEST — build an init.sh fixture from HEAD, then overlay current worktree
# changes so this test covers uncommitted bootstrap edits.
copy_template() {
  local dest="$1" file
  mkdir -p "$dest"
  git -C "$ROOT" archive HEAD | tar -x -C "$dest"
  while IFS= read -r -d '' file; do
    if [ -e "$ROOT/$file" ]; then
      mkdir -p "$dest/$(dirname "$file")"
      cp -p "$ROOT/$file" "$dest/$file"
    else
      rm -f "$dest/$file"
    fi
  done < <(
    {
      git -C "$ROOT" diff --name-only -z HEAD
      git -C "$ROOT" ls-files --others --exclude-standard -z
    }
  )
}

# assert_contains FILE NEEDLE MESSAGE — the generated file must state the rule.
assert_contains() {
  local file="$1" needle="$2" message="$3"
  grep -Fq "$needle" "$file" || {
    echo "FAIL: $message" >&2
    echo "       expected in $file: $needle" >&2
    return 1
  }
}

# assert_absent FILE NEEDLE MESSAGE — the superseded unconditional wording must be gone. Without
# this the old sentence could be reinstated alongside the new one and every positive assertion
# would still pass, which is how a rule ends up stated two ways in one file.
assert_absent() {
  local file="$1" needle="$2" message="$3"
  if grep -Fq "$needle" "$file"; then
    echo "FAIL: $message" >&2
    echo "       still present in $file: $needle" >&2
    return 1
  fi
}

run_case() {
  local name="inplace-rules"
  local work="$TMP_ROOT/$name"

  copy_template "$work"
  (
    cd "$work"
    ./init.sh \
      --non-interactive \
      --slug="$name" \
      --desc="Registered-in-place rule test" \
      --license=mit \
      --holder="Throughstone Test" \
      --layout=multi \
      --collab=solo \
      --remotes=no
  ) >"$TMP_ROOT/$name.out" 2>&1

  local docs="$work/Code/$name-docs"
  local readme_tpl="$docs/templates/repo-readme-template.md"
  local ci_workflow="$docs/templates/ci/code-repo-ci.yml"
  local ci_readme="$docs/templates/ci/README.md"
  local repos="$docs/registries/repos.yml"

  # --- The README. Stamp what the method creates; augment what it registers, keyed on whether the
  # file exists. The substituted section name doubles as the placeholder check.
  assert_contains "$readme_tpl" "STAMP this into a repo the method CREATES" \
    "repo README template lost the stamp rule for a created repo"
  assert_contains "$readme_tpl" "## Role in $name" \
    "repo README template does not name the substituted augment section"
  # A repo with no README gets the template minus Licensing — that section describes a created repo,
  # and pointing a repo the method did not license at files it does not have is the same defect the
  # augment branch already forbids.
  assert_contains "$readme_tpl" "every section except **Licensing**" \
    "repo README template does not drop Licensing when writing a missing README"
  assert_contains "$docs/METHOD.md" "every section but Licensing" \
    "METHOD.md §7 does not drop Licensing when writing a missing README"
  assert_absent "$docs/METHOD.md" "the full template — that creates the one file" \
    "METHOD.md §7 still orders the full template for a repo the method did not create"

  # --- CI. The gate fails until configured, so there is no safe way to land it in a running repo.
  # The rule belongs on the artifact being copied, not only in the files that point at it.
  assert_contains "$ci_workflow" "Never into a repo REGISTERED IN PLACE" \
    "CI workflow template does not carry the never-install rule"
  assert_contains "$ci_readme" "Never install it into a repo registered in place" \
    "CI README does not carry the never-install rule"
  assert_contains "$readme_tpl" "never install it — that repo has its own CI" \
    "repo README template does not carry the never-install rule"

  # --- The project license and the notice. The method records licensing; it never establishes it
  # for code it did not create — but where its own material lands, the notice is owed.
  assert_contains "$readme_tpl" \
    "Code/$name-docs/scripts/apply-project-license.sh --notice-only <this-repo-path>" \
    "repo README template does not tell an in-place repo to place the notice"
  assert_contains "$readme_tpl" "is in the repo and nothing is owed" \
    "repo README template does not keep the notice off a declined repo"

  # --- The inventory. This comment sits at the point where an agent writes a repo row, so it is
  # read more often than the header block above it.
  assert_contains "$repos" "a repo REGISTERED IN PLACE is listed" \
    "repo inventory comment does not distinguish a registered-in-place repo"
  assert_absent "$repos" "as the architecture names them and they" \
    "repo inventory comment still says every repo listed here is stamped"

  # --- The fallback. Every rule above enumerates cases, and three rounds of review each turned up
  # one nobody had enumerated. What an agent does with the next such case is the thing worth
  # pinning: ask, and write nothing meanwhile. It has to ship in the file being read at the moment
  # of the write, not only in the file that defines it.
  assert_contains "$docs/METHOD.md" "**When the rules above don't settle it, ask.**" \
    "METHOD.md §7 has no fallback for a case the create-vs-in-place rules do not reach"
  assert_contains "$docs/METHOD.md" \
    "ask, and write nothing into that repo until you have an answer" \
    "METHOD.md §7's fallback does not say to hold off writing while asking"
  assert_contains "$readme_tpl" \
    "ASK THE USER AND WRITE NOTHING UNTIL THEY ANSWER" \
    "repo README template does not carry the ask-when-unclear fallback"
  # The fallback must not read as permission to stop maintaining the rules themselves — that is how
  # a catch-all turns into a reason to leave the next gap unfixed.
  assert_contains "$docs/METHOD.md" "not a reason to leave a gap in them" \
    "METHOD.md §7's fallback does not rule itself out as a substitute for fixing the rules"

  # Nothing above may pass on an unsubstituted template.
  ! grep -R '{{PROJECT}}' "$readme_tpl" "$ci_workflow" "$ci_readme" "$repos" >/dev/null || {
    echo "FAIL: generated files still carry the {{PROJECT}} placeholder" >&2
    return 1
  }
}

# run_pruned_registries_case — a mono-repo project can decline registries/ entirely, and the rules
# above have to survive that. Two ways they did not. The docs hub README indexes every directory it
# ships, so pruning the directory but not its row left a link to a file that is not there — a hard
# links.sh failure on the generated project's first run, before anyone had touched it. And the
# rules named the repos.yml row flatly as the place a declined README's information still lives,
# which is a promise this configuration cannot keep.
run_pruned_registries_case() {
  local name="inplace-pruned"
  local work="$TMP_ROOT/$name"

  copy_template "$work"
  (
    cd "$work"
    ./init.sh \
      --non-interactive \
      --slug="$name" \
      --desc="Pruned registries test" \
      --license=mit \
      --holder="Throughstone Test" \
      --layout=mono \
      --registries=no \
      --collab=solo \
      --remotes=no
  ) >"$TMP_ROOT/$name.out" 2>&1

  local docs="$work/Code/$name-docs"
  [ ! -d "$docs/registries" ] || { echo "FAIL: --registries=no did not prune registries/" >&2; return 1; }

  # The generated project must be link-clean the moment it exists.
  ( cd "$docs" && ./scripts/links.sh ) >"$TMP_ROOT/$name-links.out" 2>&1 || {
    echo "FAIL: generated project has broken links with registries/ pruned" >&2
    grep -E "FAIL\]" "$TMP_ROOT/$name-links.out" >&2
    return 1
  }
  assert_absent "$docs/README.md" '| [`registries/`](registries/README.md) |' \
    "docs hub README still indexes a directory that was pruned"

  # The declined-README fallback must not promise a row this project has no file to hold.
  assert_contains "$docs/METHOD.md" "where the project keeps an inventory" \
    "METHOD.md §7 still names the repos.yml row unconditionally as the declined-README fallback"
  assert_contains "$docs/templates/repo-readme-template.md" "where the project keeps" \
    "repo README template still names the repos.yml row unconditionally"
  assert_contains "$docs/runbooks/check-in.md" 'and in its `repos.yml` row where' \
    "check-in README sweep still names the repos.yml row unconditionally"
}

run_case
run_pruned_registries_case

echo "init.sh registered-in-place repo rules: PASS"
