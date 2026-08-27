#!/usr/bin/env bash
#
# Regression coverage for init.sh's record_registry_remote — the third thing that reads
# registries/repos.yml, and the only one that writes it.
#
# It finds the row to update by name, and it accepts less than the schema allows: a name written
# without double quotes is legal (scripts/check.sh reads all three spellings, and nothing in the
# schema requires quoting), but this pattern does not match it. The substitution then does nothing
# — and commit_registry_remotes decides whether anything happened by looking for a diff, so a write
# that wrote nothing reads as nothing to do. The remote is simply absent from the registry, and the
# first anyone hears of it is a teammate whose setup-workspace.sh cannot clone that repo.
#
# The guard under test does not make the pattern cleverer. It makes the silence audible. Both
# directions are covered, because a warning that is always printed is as useless as one that never
# is: the ordinary row must record its remote and stay quiet.

set -uo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-init-registry-remote.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

failures=0
bad() { printf 'FAIL: %s\n' "$1" >&2; failures=$((failures + 1)); }

# copy_template DEST — build a template fixture from HEAD, then overlay current worktree changes,
# so the fixture is the shape a user downloads and uncommitted edits are still under test.
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

# run_case NAME [MUTATOR] — bootstrap a multi-repo project with remotes, through the gh stub that
# makes local bare repositories. MUTATOR, if given, edits the template before init.sh runs.
# Sets INIT_STATUS, INIT_OUT, REG and DOCS_REMOTE_MARK.
run_case() {
  local name="$1" mutator="${2:-}"
  local work="$TMP_ROOT/$name" stub_bin="$TMP_ROOT/$name-bin"
  local remote_root="$TMP_ROOT/$name-remotes" gh_log="$TMP_ROOT/$name-gh.log"
  copy_template "$work"
  mkdir -p "$stub_bin" "$remote_root"
  cp "$ROOT/tests/fixtures/gh-stub.sh" "$stub_bin/gh"
  chmod +x "$stub_bin/gh"
  [ -z "$mutator" ] || "$mutator" "$work"
  (
    cd "$work"
    PATH="$stub_bin:$PATH" \
      GH_LOG="$gh_log" \
      GH_REMOTE_ROOT="$remote_root" \
      ./init.sh \
        --non-interactive \
        --slug="$name" \
        --desc="Registry remote recording test" \
        --license=bsd-3 \
        --holder="Throughstone Test" \
        --layout=multi \
        --collab=team \
        --remotes=yes \
        --owner=throughstone-test \
        --visibility=private
  ) >"$TMP_ROOT/$name.out" 2>&1
  INIT_STATUS=$?
  INIT_OUT="$(cat "$TMP_ROOT/$name.out")"
  REG="$work/Code/$name-docs/registries/repos.yml"
  # The stub names each bare repo after the repo it was asked to create.
  DOCS_REMOTE_MARK="$name-docs.git"
}

# unquote_docs_name WORK — write the docs row's name the one legal way this writer cannot match.
unquote_docs_name() {
  local reg="$1/Code/{{PROJECT}}-docs/registries/repos.yml"
  perl -0pi -e 's{^  - name: "(\{\{PROJECT\}\}-docs)"$}{  - name: $1}m' "$reg"
  grep -q '^  - name: {{PROJECT}}-docs$' "$reg" \
    || bad "fixture is not exercising the shape it claims: the docs row name is still quoted"
}

has()    { case "$INIT_OUT" in *"$1"*) return 0 ;; *) return 1 ;; esac; }
in_reg() { grep -Fq -- "$1" "$REG"; }

echo "An ordinary registry: the remote is recorded and nothing is warned about ..."
run_case ordinary
[ "$INIT_STATUS" -eq 0 ] || bad "ordinary: init.sh exited $INIT_STATUS"
in_reg "$DOCS_REMOTE_MARK" || bad "ordinary: the docs remote was not recorded in the registry"
has "no row named" && bad "ordinary: warned about a row it updated"

echo "A row name the writer cannot match: it says so instead of writing nothing in silence ..."
run_case unmatched unquote_docs_name
# The bootstrap must finish. The remotes already exist by this point, and aborting here would
# leave a project half-made over a row that can be fixed by hand in one line.
[ "$INIT_STATUS" -eq 0 ] || bad "unmatched: init.sh exited $INIT_STATUS; the guard must not abort"
has 'no row named "unmatched-docs" was updated' \
  || bad "unmatched: the silent no-op was not reported"
has "Add  remote:" || bad "unmatched: the warning does not say what to do about it"
in_reg "$DOCS_REMOTE_MARK" && bad "unmatched: fixture is wrong — the remote was recorded after all"
# The prompts row is untouched and still quoted, so it must still be recorded: the guard reports
# the row it could not find, not the whole step.
in_reg "unmatched-prompts.git" || bad "unmatched: the prompts remote should still have been recorded"

if [ "$failures" -eq 0 ]; then
  printf 'PASS: init.sh reports a registry row it could not record a remote into\n'
  exit 0
fi
printf 'FAILED: %d assertion(s)\n' "$failures" >&2
exit 1
