#!/usr/bin/env bash
#
# Regression coverage for upgrading a project: this tree's docs-hub scripts copied over the ones in
# a project the last release generated, which is how UPDATING-THROUGHSTONE.md updates them. The
# project's templates, overview and STEP index stay as that release wrote them.
#
# Each layout is generated twice under one slug, once by the last release and once by this tree,
# and both copies run this tree's scripts. They must agree: the same WARN and FAIL lines from
# check and check --check-in, the same next action from status, and the same findings from
# links. The pair is compared fresh, and again mid-project, with STEP-1 and its substeps Done and
# a STEP-2 In progress. A difference means an existing project would read differently after the
# upgrade than a new one does.
#
# When a release does change what an existing project must do, apply that release's migration
# step to the older project in migrate() below. The test then shows the step is enough.
#
# The last release is the newest v* tag in HEAD's history that is not on HEAD itself, so the
# checkout needs its tags. tests.yml checks out the full history for this.

set -uo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-upgrade-test.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

SLUG="upgrade"
DOCS="Code/$SLUG-docs"
failures=0
bad() { printf 'FAIL: %s\n' "$1" >&2; failures=$((failures + 1)); }

head_sha="$(git -C "$ROOT" rev-parse HEAD)"
RELEASE=""
while IFS= read -r tag; do
  [ "$(git -C "$ROOT" rev-parse "$tag^{commit}")" = "$head_sha" ] && continue
  RELEASE="$tag"
  break
done < <(git -C "$ROOT" tag --merged HEAD --list 'v[0-9]*' --sort=-v:refname)
if [ -z "$RELEASE" ]; then
  echo "FAIL: no release tag in HEAD's history. Fetch the tags (git fetch --tags) and run again." >&2
  exit 1
fi

# copy_template DEST — build a template fixture from HEAD, then overlay current worktree changes,
# so uncommitted edits are under test.
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

# generate DIR LAYOUT — run the init.sh already in DIR. The flags are ones every release since
# 2.0 accepts.
generate() {
  ( cd "$1" && ./init.sh --non-interactive --slug="$SLUG" --desc="Upgrade test" \
      --license=mit --holder="Throughstone Test" --layout="$2" --collab=solo --remotes=no
  ) >"$1.init.out" 2>&1 || {
    bad "init.sh failed in $1"
    sed -n '1,40p' "$1.init.out" >&2
    return 1
  }
}

# edit FILE PERL WHAT — apply a perl substitution and require that it changed the file, so a
# pattern that no longer matches cannot leave the two projects in different states.
edit() {
  cp "$1" "$TMP_ROOT/before"
  perl -pi -e "$2" "$1"
  cmp -s "$TMP_ROOT/before" "$1" && bad "fixture: $3 changed nothing in $1"
  return 0
}

# migrate WORK — what the release notes tell an existing project to do, beyond copying the
# scripts. Nothing yet.
migrate() {
  :
}

# advance WORK — take a fresh project to mid-project: the kickoff done, STEP-1 and every substep
# Done, and a STEP-2 In progress, written as a copy of the STEP-1 row so it fits that index's
# columns.
advance() {
  edit "$1/$DOCS/overview.md" 's/<!-- PROJECT-STATUS: not-started -->/<!-- PROJECT-STATUS: kickoff-complete -->/' \
    "marking the kickoff complete"
  edit "$1/prompts/STEP-index.md" '
    s/^(\| 1\.[0-9]+ \|[^|]*\| )Planned( \|)/${1}Done$2/;
    if (/^\| STEP-1 \| Architecture \|/) {
      s/ Planned / Done /;
      my $two = $_;
      $two =~ s/STEP-1 \| Architecture/STEP-2 | First feature/;
      $two =~ s/ Done / In progress /;
      $_ .= $two;
    }' "closing STEP-1 and opening STEP-2"
}

# findings WORK STATE — run this tree's scripts over WORK through its own doctor.sh, and keep what
# the two copies must agree on, one file per command.
findings() {
  local work="$1" out="$1.$2" rc
  ( cd "$work" && env -u CI ./doctor.sh check ) >"$out.check.raw" 2>&1; rc=$?
  { echo "exit $rc"; grep -E '\[(WARN|FAIL)\]' "$out.check.raw"; } >"$out.check"
  ( cd "$work" && env -u CI ./doctor.sh check --check-in ) >"$out.check-in.raw" 2>&1; rc=$?
  { echo "exit $rc"; grep -E '\[(WARN|FAIL)\]' "$out.check-in.raw"; } >"$out.check-in"
  ( cd "$work" && ./doctor.sh status ) >"$out.status.raw" 2>&1; rc=$?
  { echo "exit $rc"; sed -n '/^Next action:/,$p' "$out.status.raw"; } >"$out.status"
  ( cd "$work" && ./doctor.sh links ) >"$out.links.raw" 2>&1; rc=$?
  { echo "exit $rc"; grep -E '\[(WARN|FAIL)\]' "$out.links.raw"; } >"$out.links"
  grep -q '^Next action:' "$out.status.raw" || bad "$2: status printed no next action in $work"
}

# agree LAYOUT STATE — the older project must report what the new one does, command by command.
agree() {
  local cmd old="$TMP_ROOT/$1-old.$2" new="$TMP_ROOT/$1-new.$2"
  for cmd in check check-in status links; do
    diff -u "$new.$cmd" "$old.$cmd" >"$TMP_ROOT/diff" || {
      bad "$1, $2: '$cmd' over a $RELEASE project differs from a new project (- new, + $RELEASE)"
      cat "$TMP_ROOT/diff" >&2
    }
  done
}

for layout in mono multi; do
  old="$TMP_ROOT/$layout-old"
  new="$TMP_ROOT/$layout-new"
  mkdir -p "$old"
  git -C "$ROOT" archive "$RELEASE" | tar -x -C "$old"
  copy_template "$new"
  generate "$old" "$layout" || continue
  generate "$new" "$layout" || continue

  cp -p "$new/$DOCS/scripts/"* "$old/$DOCS/scripts/"
  migrate "$old"

  # The new project's default doctor run is clean, so agreeing with it means the older one is too.
  findings "$new" fresh
  grep -qx 'exit 0' "$new.fresh.check" && [ "$(wc -l <"$new.fresh.check")" -eq 1 ] \
    || bad "$layout: a new project's doctor run is not clean, so agreeing with it proves nothing"
  findings "$old" fresh
  agree "$layout" fresh

  advance "$new"
  advance "$old"
  findings "$new" mid
  grep -qx 'exit 0' "$new.mid.check" \
    || bad "$layout: the doctor fails a new project mid-project, so the fixture is not a state a project reaches"
  findings "$old" mid
  agree "$layout" mid
done

if [ "$failures" -gt 0 ]; then
  printf 'upgrade-from-last-release.sh: %d failure(s) against %s\n' "$failures" "$RELEASE" >&2
  exit 1
fi
echo "upgrade-from-last-release.sh: PASS against $RELEASE"
