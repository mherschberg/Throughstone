#!/usr/bin/env bash
#
# Regression coverage for mono-repo reuse of an existing root origin.

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-mono-origin-test.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

# copy_template DEST - copy HEAD plus current working-tree changes, without Git metadata.
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

# bare_remote PATH [BRANCH] - create a bare fixture remote whose HEAD names BRANCH (default
# `main`, the trunk init.sh generates unless a case asks for another). `git init --bare` alone
# leaves HEAD at `init.defaultBranch`, and where that is unset -- CI, and any machine nobody has
# configured -- that is `refs/heads/master`: a branch the pushed content never reaches. Cloning
# such a remote still exits 0 and still creates `.git`, so a clone-based assertion passes over a
# working tree with nothing in it. Name the branch at creation, the way a real host does.
bare_remote() {
  git init --bare -q -b "${2:-main}" "$1"
}

# path_without_gh - echo a PATH that has everything the current one has, except gh.
#
# The case below is named for a machine that has not installed gh, and it used to get there with
# PATH="/usr/bin:/bin". That only hides gh where gh lives somewhere else - a Homebrew machine,
# which is where this suite was written. On a GitHub runner gh IS /usr/bin/gh, so the reset left
# it in plain sight and the case silently ran the opposite branch: init.sh sees gh, keeps the
# github provider, and reuses the origin from there instead of from the no-gh fallback. Same end
# state, so every assertion still passed. Mirroring the search path and dropping the one entry is
# the only reset that does not depend on where a particular machine installed things.
path_without_gh() {
  local mirror="$TMP_ROOT/no-gh-bin" dir
  rm -rf "$mirror"
  mkdir -p "$mirror"
  local IFS=:
  for dir in $PATH; do
    unset IFS
    [ -d "$dir" ] && ln -s "$dir"/* "$mirror/" 2>/dev/null
    IFS=:
  done
  unset IFS
  rm -f "$mirror/gh"
  printf '%s\n' "$mirror"
}

commit_all() {
  git -c user.name="Throughstone Test" \
    -c user.email="throughstone-test@example.invalid" \
    commit -qm "$1"
}

run_non_empty_origin_case() {
  local name="mono-template-origin"
  local seed="$TMP_ROOT/$name-seed"
  local work="$TMP_ROOT/$name"
  local remote="$TMP_ROOT/$name-origin.git"

  copy_template "$seed"
  (
    cd "$seed"
    git init -q
    git add -A
    commit_all "Template-created commit"
    git branch -M main
    bare_remote "$remote"
    git remote add origin "$remote"
    git push -q -u origin main
  )
  git clone -q -b main "$remote" "$work"

  (
    cd "$work"
    ./init.sh \
      --non-interactive \
      --slug="$name" \
      --desc="Mono origin reuse test" \
      --license=private \
      --layout=mono \
      --collab=solo \
      --remotes=no
  ) >"$TMP_ROOT/$name.out" 2>&1

  [ "$(git -C "$work" rev-list --count main)" -eq 1 ]
  if git -C "$work" remote get-url origin >/dev/null 2>&1; then
    echo "FAIL: non-empty template origin was reused automatically" >&2
    return 1
  fi
  grep -Fq "existing root origin already has Git history and was not reused" \
    "$TMP_ROOT/$name.out"
  grep -Fq "$remote" "$TMP_ROOT/$name.out"
}

run_empty_origin_case() {
  local name="mono-empty-origin"
  local work="$TMP_ROOT/$name"
  local remote="$TMP_ROOT/$name-origin.git"
  local remote_refs

  copy_template "$work"
  bare_remote "$remote"
  (
    cd "$work"
    git init -q
    git remote add origin "$remote"
    ./init.sh \
      --non-interactive \
      --slug="$name" \
      --desc="Mono empty origin reuse test" \
      --license=private \
      --layout=mono \
      --collab=solo \
      --remotes=no
  ) >"$TMP_ROOT/$name.out" 2>&1

  [ "$(git -C "$work" remote get-url origin)" = "$remote" ]
  grep -Fq "remote: reused existing origin ($remote)" "$TMP_ROOT/$name.out"
  # --remotes=no means attach the origin, not publish to it, and nothing above can tell the
  # difference: the reused URL is still attached and the message is still printed whether or not
  # anything was uploaded. Replacing the MK_REMOTES guard in reuse_root_origin with `if true` sent
  # the whole project to the user's remote against their answer and left this case green. The
  # remote itself is the only witness -- it was created empty and has to have stayed that way.
  remote_refs="$(git --git-dir="$remote" for-each-ref)"
  [ -z "$remote_refs" ] || {
    echo "FAIL: --remotes=no pushed to the reused origin" >&2
    printf '%s\n' "$remote_refs" >&2
    return 1
  }
}

run_empty_origin_push_without_gh_case() {
  local name="mono-empty-origin-push"
  local work="$TMP_ROOT/$name"
  local remote="$TMP_ROOT/$name-origin.git"
  local root_row remote_refs no_gh_path
  no_gh_path="$(path_without_gh)"

  copy_template "$work"
  bare_remote "$remote"
  # A bare repository keeps no record of its ref updates unless asked to. The push assertion below
  # needs that record: it is what tells a branch that arrived here during the run apart from one
  # the run's final push delivered.
  git --git-dir="$remote" config core.logAllRefUpdates true
  (
    cd "$work"
    git init -q
    git remote add origin "$remote"
    PATH="$no_gh_path" ./init.sh \
      --non-interactive \
      --slug="$name" \
      --desc="Mono empty origin push test" \
      --license=private \
      --layout=mono \
      --collab=solo \
      --remotes=yes
  ) >"$TMP_ROOT/$name.out" 2>&1

  # The precondition, asserted rather than assumed. init.sh says so on startup when gh is out of
  # reach, and without this line a PATH reset that stopped working would leave the case quietly
  # exercising the branch it exists to avoid -- which is exactly what it did on Linux.
  grep -Fq "Note: 'gh' not found" "$TMP_ROOT/$name.out" || {
    echo "FAIL: init.sh could still see gh, so this case did not run without it" >&2
    return 1
  }
  [ "$(git -C "$work" remote get-url origin)" = "$remote" ]
  grep -Fq "remote: reused existing origin ($remote)" "$TMP_ROOT/$name.out"
  # The closing line the user reads. The push behind it is asserted at the end of this case; on
  # its own this is satisfied by the success arm printing while the push inside it does nothing.
  grep -Fq "pushed: $remote" "$TMP_ROOT/$name.out"

  # A mono project records its one repository's remote on the row whose location is ".", and the
  # check-in flags that row until it does. Nothing else in the suite reads a remote back out of a
  # mono registry -- the multi read-back lives in tests/init-license-validation.sh -- so deleting
  # the write left every case green while every generated mono project reported its own repo as
  # backed up nowhere.
  root_row="$(awk '/^[[:space:]]*-[[:space:]]*name:/ { n++ } n == 1' \
    "$work/Code/$name-docs/registries/repos.yml")"
  printf '%s\n' "$root_row" | grep -Fq 'location: "."' || {
    echo "FAIL: the first registry row is not the workspace root" >&2
    printf '%s\n' "$root_row" >&2
    return 1
  }
  printf '%s\n' "$root_row" | grep -Fq "remote: \"$remote\"" || {
    echo "FAIL: the workspace-root row did not record the remote it pushed to" >&2
    printf '%s\n' "$root_row" >&2
    return 1
  }
  # The recorded URL has to be one the branch reached, and reached at this commit. Asserting the
  # ref exists is not enough: recording happens before the second commit that carries it, so a
  # remote left behind at the initial commit still has a main to find.
  [ "$(git --git-dir="$remote" rev-parse refs/heads/main)" = "$(git -C "$work" rev-parse HEAD)" ] || {
    echo "FAIL: the recorded remote does not hold the local trunk" >&2
    echo "      local $(git -C "$work" rev-parse HEAD) / remote $(git --git-dir="$remote" rev-parse refs/heads/main)" >&2
    return 1
  }
  # Everything above describes the END state, and the end state is not this case's doing:
  # commit_registry_remotes pushes the same branch to the same origin after reuse_root_origin
  # does, so replacing the reuse push with `true` leaves main here at the right commit with every
  # assertion above green. What the later push cannot account for is the branch having arrived
  # once already. A second reflog entry for the trunk exists only if it did -- the value is not
  # compared, because how many commits separate the two pushes is init.sh's business, not this
  # test's.
  git --git-dir="$remote" rev-parse --verify --quiet "refs/heads/main@{1}" >/dev/null || {
    echo "FAIL: the trunk reached the reused origin only once, so nothing here covers the" >&2
    echo "      reuse push -- only the registry push that follows it" >&2
    return 1
  }
  # And it must have arrived alone. A run that quietly published a second branch to a remote the
  # user already owned would satisfy every assertion above.
  remote_refs="$(git --git-dir="$remote" for-each-ref --format='%(refname)' refs/heads)"
  [ "$remote_refs" = "refs/heads/main" ] || {
    echo "FAIL: the reused origin should carry refs/heads/main and nothing else" >&2
    echo "      it carries: ${remote_refs:-<no branches>}" >&2
    return 1
  }
}

run_non_empty_origin_case
run_empty_origin_case
run_empty_origin_push_without_gh_case

echo "init.sh mono origin reuse: PASS"
