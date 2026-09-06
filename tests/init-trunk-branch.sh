#!/usr/bin/env bash
#
# Regression coverage for init.sh trunk branch selection.

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-trunk-test.XXXXXX")"
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

# bare_remote PATH [BRANCH] — create a bare fixture remote whose HEAD names BRANCH (default
# `main`, the trunk init.sh generates unless a case asks for another). `git init --bare` alone
# leaves HEAD at `init.defaultBranch`, and where that is unset — CI, and any machine nobody has
# configured — that is `refs/heads/master`: a branch the pushed content never reaches. Cloning
# such a remote still exits 0 and still creates `.git`, so a clone-based assertion passes over a
# working tree with nothing in it. Name the branch at creation, the way a real host does.
bare_remote() {
  git init --bare -q -b "${2:-main}" "$1"
}

# assert_only_branch GIT_DIR REF — the remote carries the trunk this run chose, and nothing else.
# It replaced a pair of "refs/heads/main is absent" checks that could not fail: these fixture
# remotes are created with no branches at all, so main was already absent before init.sh started
# and stayed absent with every push deleted. Comparing the whole branch list fails in both
# directions instead — when nothing was published, and when a run told to use a different trunk
# publishes main alongside it.
assert_only_branch() {
  local git_dir="$1" ref="$2" actual
  actual="$(git --git-dir="$git_dir" for-each-ref --format='%(refname)' refs/heads)"
  [ "$actual" = "$ref" ] || {
    echo "FAIL: $git_dir should carry $ref and nothing else" >&2
    echo "      it carries: ${actual:-<no branches>}" >&2
    return 1
  }
}

run_default_case() {
  local name="trunk-default"
  local work="$TMP_ROOT/$name"

  copy_template "$work"
  (
    cd "$work"
    ./init.sh \
      --non-interactive \
      --slug="$name" \
      --desc="Trunk branch default test" \
      --license=private \
      --layout=multi \
      --collab=solo \
      --remotes=no
  ) >"$TMP_ROOT/$name.out" 2>&1

  [ "$(git -C "$work/Code/$name-docs" symbolic-ref --short HEAD)" = "main" ]
  [ "$(git -C "$work/prompts" symbolic-ref --short HEAD)" = "main" ]
  grep -Fq '**shared trunk** (`main`)' \
    "$work/Code/$name-docs/runbooks/collaboration.md"
  ! grep -R '{{TRUNK_BRANCH}}' "$work/Code/$name-docs" "$work/prompts" >/dev/null
}

run_manual_remote_custom_case() {
  local name="trunk-master"
  local work="$TMP_ROOT/$name"
  local docs_remote="$TMP_ROOT/$name-docs.git"
  local prompts_remote="$TMP_ROOT/$name-prompts.git"

  copy_template "$work"
  # The fixtures have to be born on the trunk this case drives below, not on `main`. A remote
  # whose HEAD names a branch its content never reaches is the defect this whole idiom exists to
  # avoid, and it hides better here than anywhere: every assertion below still passes.
  bare_remote "$docs_remote" master
  bare_remote "$prompts_remote" master
  # A bare repository keeps no record of its ref updates unless asked to. The docs assertion below
  # needs that record to tell the push under test apart from the run's final registry push, which
  # lands on this same remote. The prompts remote needs no such thing — nothing pushes to it twice.
  git --git-dir="$docs_remote" config core.logAllRefUpdates true
  (
    cd "$work"
    ./init.sh \
      --non-interactive \
      --slug="$name" \
      --desc="Trunk branch manual remote test" \
      --license=private \
      --layout=multi \
      --collab=team \
      --adr-authority="consensus of maintainers" \
      --trunk-branch=master \
      --remotes=yes \
      --remote-provider=manual \
      --docs-remote="$docs_remote" \
      --prompts-remote="$prompts_remote"
  ) >"$TMP_ROOT/$name.out" 2>&1

  [ "$(git -C "$work/Code/$name-docs" symbolic-ref --short HEAD)" = "master" ]
  [ "$(git -C "$work/prompts" symbolic-ref --short HEAD)" = "master" ]
  # Only the prompts remote can be checked by asking whether the trunk is on it. The docs remote is
  # pushed to twice — once by setup_remote here, and again by commit_registry_remotes at the end of
  # the run, which sends the same branch to the same origin — so the later push repairs the end
  # state of the first: making setup_remote's push a --dry-run left the docs assertions green.
  # A second reflog entry for the docs trunk is what the later push cannot account for: it exists
  # only because the branch reached this remote once already. The value is not compared, because
  # how many commits separate the two pushes is init.sh's business, not this test's.
  git --git-dir="$docs_remote" rev-parse --verify --quiet "refs/heads/master@{1}" >/dev/null || {
    echo "FAIL: the docs trunk reached its remote only once, so nothing here covers" >&2
    echo "      setup_remote's push -- only the registry push that follows it" >&2
    return 1
  }
  git --git-dir="$prompts_remote" rev-parse --verify refs/heads/master >/dev/null
  assert_only_branch "$docs_remote" refs/heads/master
  assert_only_branch "$prompts_remote" refs/heads/master
  git --git-dir="$docs_remote" show master:registries/repos.yml \
    | grep -Fq "remote: \"$docs_remote\""
  grep -Fq '**shared trunk** (`master`)' \
    "$work/Code/$name-docs/runbooks/collaboration.md"
  # The chosen trunk name has to reach the closing text, which is the only instruction most
  # users get about backups. Match the whole clause rather than the bare word: "master" appears
  # elsewhere in that output for other reasons.
  grep -Fq "push the master branch to it" "$TMP_ROOT/$name.out"
}

run_mono_reused_origin_custom_case() {
  local name="trunk-mono"
  local work="$TMP_ROOT/$name"
  local remote="$TMP_ROOT/$name-origin.git"

  copy_template "$work"
  # Born on the trunk this case drives below, and a branch name with a slash in it is the reason
  # the case exists: `refs/heads/release/stable` is a ref path like any other.
  bare_remote "$remote" release/stable
  # See run_manual_remote_custom_case: the reuse push below is followed by a registry push to this
  # same origin, and only the remote's own record of its ref updates separates the two.
  git --git-dir="$remote" config core.logAllRefUpdates true
  (
    cd "$work"
    git init -q
    git remote add origin "$remote"
    ./init.sh \
      --non-interactive \
      --slug="$name" \
      --desc="Trunk branch mono origin reuse test" \
      --license=private \
      --layout=mono \
      --collab=solo \
      --trunk-branch=release/stable \
      --remotes=yes
  ) >"$TMP_ROOT/$name.out" 2>&1

  [ "$(git -C "$work" symbolic-ref --short HEAD)" = "release/stable" ]
  # Same masking as the multi case: commit_registry_remotes pushes this trunk to this origin again
  # at the end of the run, so replacing reuse_root_origin's push with `true` still left
  # release/stable here, at the right commit, with this case green. A second reflog entry for the
  # trunk is the part only the earlier push can account for.
  git --git-dir="$remote" rev-parse --verify --quiet "refs/heads/release/stable@{1}" >/dev/null || {
    echo "FAIL: the trunk reached the reused origin only once, so nothing here covers" >&2
    echo "      the reuse push -- only the registry push that follows it" >&2
    return 1
  }
  assert_only_branch "$remote" refs/heads/release/stable
  # The closing line the user reads. The push behind it is asserted above; on its own this is
  # satisfied by the success arm printing while the push inside it does nothing.
  grep -Fq "pushed: $remote" "$TMP_ROOT/$name.out"
}

run_invalid_case() {
  local name="$1"
  local branch_arg="$2"
  local work="$TMP_ROOT/$name"

  copy_template "$work"
  if (
    cd "$work"
    ./init.sh \
      --non-interactive \
      --slug="$name" \
      --desc="Invalid trunk branch test" \
      --license=private \
      --layout=multi \
      --collab=solo \
      --remotes=no \
      "$branch_arg"
  ) >"$TMP_ROOT/$name.out" 2>&1; then
    echo "FAIL: invalid trunk branch was accepted: $branch_arg" >&2
    return 1
  fi

  grep -Fq "init.sh: invalid --trunk-branch" "$TMP_ROOT/$name.out"
  [ -f "$work/README.md" ]
  [ -d "$work/Code/{{PROJECT}}-docs" ]
}

run_default_case
run_manual_remote_custom_case
run_mono_reused_origin_custom_case
run_invalid_case "trunk-empty" "--trunk-branch="
run_invalid_case "trunk-dotdot" "--trunk-branch=bad..name"
run_invalid_case "trunk-dash" "--trunk-branch=-bad"

echo "init.sh trunk branch selection: PASS"
