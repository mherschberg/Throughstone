#!/usr/bin/env bash
#
# init.sh — one-time bootstrap wizard.
#
# Turns this downloaded template into your project: detaches it from the template's git
# origin, renames the {{PROJECT}} placeholder everywhere, and sets up your repo(s).
# Run it once, from the workspace root, right after downloading.
#
# Flow:
#   0. Parse flags/env and prove required tools can create commits.
#   1. Resolve every user choice: slug, license posture, layout, collaboration, remotes.
#   2. Cross the destructive bootstrap boundary: remove template history and template-only files.
#   3. Replace placeholders, seed generated-project state, and initialize repo(s).
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

# Small UI helpers. They only print/prompt; all validation happens at the call sites so flags,
# env vars, and interactive answers share the same checks.
say()  { printf '\n\033[1m%s\033[0m\n' "$*"; }
ask()  { local p="$1" d="${2:-}" a; if [ -n "$d" ]; then read -r -p "$p [$d]: " a; echo "${a:-$d}"; else read -r -p "$p: " a; echo "$a"; fi; }
yesno(){ local a; read -r -p "$1 [y/N]: " a; case "$a" in y|Y|yes) return 0;; *) return 1;; esac; }

# need_val FLAG VALUE — guard the space-separated form of a flag. `--desc --layout=mono` is a
# missing value, not a description: without this the value silently becomes "--layout=mono" and
# the swallowed flag falls back to its default, so the run builds something the caller did not
# ask for and every later check passes. Refused here rather than per-flag, because only the
# flags that happen to validate their value (--slug, --layout, --license) catch it by accident.
# The `--flag=value` form is untouched, so a value that really does begin with `--` stays sayable.
need_val() {
  case "${2-}" in
    "")  echo "init.sh: $1 needs a value (try './init.sh --help')" >&2; exit 2 ;;
    --*) echo "init.sh: $1 needs a value, but the next argument is another flag ('$2')." >&2
         echo "  If that was meant as the value, write it as '$1=$2'." >&2; exit 2 ;;
  esac
}

# want VALUE PROMPT [DEFAULT] — echo a preset VALUE if non-empty; otherwise prompt for it.
# In --non-interactive mode, fall back to DEFAULT, or exit with an error if there is none.
# This is the flag/env bridge: callers pass the already-parsed preset first, so command-line
# values win over env vars and both bypass prompting.
want() {
  local val="$1" prompt="$2" def="${3:-}"
  if [ -n "$val" ]; then printf '%s' "$val"; return; fi
  if [ "$NONINTERACTIVE" = "1" ]; then
    [ -n "$def" ] && { printf '%s' "$def"; return; }
    echo "init.sh: missing required value (--non-interactive): $prompt" >&2; exit 2
  fi
  ask "$prompt" "$def"
}

# normalize_license_choice INPUT — set NORMALIZED_LICENSE_CHOICE to a canonical value.
# The rest of the script branches on small stable IDs, while the public interface accepts the
# friendly spellings users are likely to type in flags, env vars, or prompts.
normalize_license_choice() {
  local input
  input="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  case "$input" in
    mit|1)                       NORMALIZED_LICENSE_CHOICE=1 ;;
    bsd|bsd-3|bsd-3-clause|2)   NORMALIZED_LICENSE_CHOICE=2 ;;
    apache|apache-2|apache-2.0|3) NORMALIZED_LICENSE_CHOICE=3 ;;
    proprietary|private)        NORMALIZED_LICENSE_CHOICE=private ;;
    *)                          return 1 ;;
  esac
}

# normalize_layout INPUT — set NORMALIZED_LAYOUT to 1 (multi) or 2 (mono).
# Same shape and the same reason as normalize_license_choice above: one vocabulary, whichever way
# the answer arrives. The prompt used to assign its answer raw, and downstream is not one test but
# many: most compare against "2", one compares against "1" and takes its else. So an unrecognised
# value did not pick the other layout, it picked a hybrid — measured, typing "mono" left prompts/
# a repository of its own with the scaffold licence notice absent, placed instead at the workspace
# root, which that layout never clones.
normalize_layout() {
  case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
    multi|multi-repo|1) NORMALIZED_LAYOUT=1 ;;
    mono|mono-repo|2)   NORMALIZED_LAYOUT=2 ;;
    *)                  return 1 ;;
  esac
}

# normalize_collab INPUT — set NORMALIZED_COLLAB to 1 (solo) or 2 (team). See normalize_layout:
# the same defect was here, and "team" typed at the prompt produced a solo project whose ADR
# register tells the reader they are the sole authority.
normalize_collab() {
  case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
    solo|1) NORMALIZED_COLLAB=1 ;;
    team|2) NORMALIZED_COLLAB=2 ;;
    *)      return 1 ;;
  esac
}

# validate_trunk_branch NAME — accept ordinary Git branch names, reject empty/pathological
# values before bootstrap removes the template history.
validate_trunk_branch() {
  local branch="$1"
  [ -n "$branch" ] || return 1
  case "$branch" in
    -*|HEAD) return 1 ;;
  esac
  git check-ref-format "refs/heads/$branch" >/dev/null 2>&1
}

# choose_license_interactively — prompt until the project type and license are valid.
# Proprietary is a project-license posture, not a GitHub visibility setting. Open-source
# projects choose a concrete permissive license template; proprietary projects intentionally
# skip project LICENSE creation later.
#
# The project-type question defaults to private/proprietary because that is the recoverable
# answer. Accepting it writes no project LICENSE at all, which anyone can change later by
# choosing a license deliberately; accepting an open-source default would grant everyone an
# irrevocable license to the project's code without the user ever having named one. The
# open-source sub-question keeps its MIT default — by the time it is asked, open source is an
# explicit choice and MIT is a reasonable one.
choose_license_interactively() {
  local project_type license_input

  while :; do
    echo "Is this project open source or private/proprietary?"
    echo "  1) Open source"
    echo "  2) Private / proprietary"
    project_type="$(ask 'Choose 1 or 2' '2')"
    case "$project_type" in
      1) break ;;
      2)
        LICENSE_CHOICE="private"
        return 0
        ;;
      *) echo "  -> choose 1 for open source or 2 for private / proprietary." ;;
    esac
  done

  while :; do
    echo "Open-source license:"
    echo "  1) MIT           (permissive, simplest)"
    echo "  2) BSD-3-Clause  (permissive + name-endorsement protection)"
    echo "  3) Apache-2.0    (permissive, with patent grant)"
    license_input="$(ask 'Choose 1, 2, or 3' '1')"
    if normalize_license_choice "$license_input" \
      && [ "$NORMALIZED_LICENSE_CHOICE" != "private" ]; then
      LICENSE_CHOICE="$NORMALIZED_LICENSE_CHOICE"
      return 0
    fi
    echo "  -> choose 1/mit, 2/bsd-3, or 3/apache-2.0."
  done
}

# preflight_git_commit — fail early when Git exists but cannot create commits.
# Bootstrap creates brand-new repos after deleting template history, so author identity must be
# valid before any destructive work begins.
preflight_git_commit() {
  local tmp out status
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-git-preflight.XXXXXX")"

  if out="$(
    {
      cd "$tmp" &&
      git init -q &&
      printf 'preflight\n' > .preflight &&
      git add .preflight &&
      git commit -qm "Throughstone git preflight"
    } 2>&1
  )"; then
    rm -rf "$tmp"
    return 0
  fi

  status=$?
  rm -rf "$tmp"
  echo "init.sh: Git is installed, but it cannot create commits with your current configuration." >&2
  [ -n "$out" ] && printf '%s\n\n' "$out" >&2
  cat >&2 <<'EOF'
Throughstone needs Git to save the initial project files. Git usually needs your
name and email address set once on this computer before it can make commits.

Common fix:
  git config --global user.name "Your Name"
  git config --global user.email "you@example.com"

Then rerun:
  ./init.sh

For more help, see Git's first-time setup guide:
  https://git-scm.com/book/en/v2/Getting-Started-First-Time-Git-Setup
EOF
  exit "$status"
}

# usage — document the automation surface. Flags override env vars; --non-interactive converts
# any still-missing required answer into an error instead of a prompt.
usage() {
  cat <<'USAGE'
init.sh — one-time Throughstone setup wizard.

Runs interactively by default. Pass flags (or set env vars) to pre-answer any
question; whatever you leave out is still prompted — unless --non-interactive is
set, in which case a missing required value is an error (useful for scripts/CI).

Usage: ./init.sh [options]

Options:
  --slug=SLUG            Project slug (lowercase kebab-case, e.g. acme-scheduler)
  --desc=TEXT           One-line description
  --license=NAME        mit | bsd-3 | apache-2.0 | private
  --holder=NAME         Copyright holder (required for open-source licenses)
  --layout=LAYOUT       multi | mono                    (default: multi)
  --registries=yes|no   Deprecated and ignored; registries/ always ships
  --collab=MODE         solo | team                     (default: solo)
  --adr-authority=TEXT  Who accepts ADRs (team only; default: consensus of maintainers)
  --trunk-branch=NAME   Generated repo trunk branch     (default: main)
  --remotes=yes|no      Set up remotes now              (default: no)
  --remote-provider=PROVIDER
                         github | manual                (default: github)
  --owner=OWNER         GitHub owner/org (github provider only)
  --remote-url=URL      Existing mono-repo remote URL    (manual provider)
  --docs-remote=URL     Existing docs repo remote URL    (manual provider, multi)
  --prompts-remote=URL  Existing prompts repo remote URL (manual provider, multi)
  --visibility=VALUE    private | public                (GitHub creation default: private)
  -y, --non-interactive Never prompt; error on any missing required value
  -h, --help            Show this help and exit

Env vars (flags take precedence): INIT_SLUG, INIT_DESC, INIT_LICENSE, INIT_HOLDER,
  INIT_LAYOUT, INIT_REGISTRIES, INIT_COLLAB, INIT_ADR_AUTHORITY, INIT_REMOTES,
  INIT_REMOTE_PROVIDER, INIT_OWNER, INIT_REMOTE_URL, INIT_DOCS_REMOTE,
  INIT_PROMPTS_REMOTE, INIT_VISIBILITY, INIT_TRUNK_BRANCH, INIT_NONINTERACTIVE.
USAGE
}

# --- 0. Parse flags / env (empty preset = "ask") ----------------------------
# Every input starts as an env-supplied preset and may be overwritten by a flag below. Empty
# means "not answered yet"; the question phase either prompts, applies a default, or errors in
# --non-interactive mode.
SLUG_IN="${INIT_SLUG:-}";       DESC_IN="${INIT_DESC:-}"
LICENSE_IN="${INIT_LICENSE:-}"; HOLDER_IN="${INIT_HOLDER:-}"
LAYOUT_IN="${INIT_LAYOUT:-}";   REGISTRIES_IN="${INIT_REGISTRIES:-}"
COLLAB_IN="${INIT_COLLAB:-}";   ADR_AUTHORITY_IN="${INIT_ADR_AUTHORITY:-}"
TRUNK_BRANCH_IN="${INIT_TRUNK_BRANCH:-}"; TRUNK_BRANCH_FLAG_SET=0
REMOTES_IN="${INIT_REMOTES:-}"; REMOTE_PROVIDER_IN="${INIT_REMOTE_PROVIDER:-}"
OWNER_IN="${INIT_OWNER:-}";     REMOTE_URL_IN="${INIT_REMOTE_URL:-}"
DOCS_REMOTE_IN="${INIT_DOCS_REMOTE:-}"; PROMPTS_REMOTE_IN="${INIT_PROMPTS_REMOTE:-}"
VISIBILITY_IN="${INIT_VISIBILITY:-}"
NONINTERACTIVE="${INIT_NONINTERACTIVE:-0}"

while [ $# -gt 0 ]; do
  case "$1" in
    --slug=*)          SLUG_IN="${1#*=}" ;;
    --slug)            need_val "$1" "${2-}"; SLUG_IN="$2"; shift ;;
    --desc=*)          DESC_IN="${1#*=}" ;;
    --desc)            need_val "$1" "${2-}"; DESC_IN="$2"; shift ;;
    --license=*)       LICENSE_IN="${1#*=}" ;;
    --license)         need_val "$1" "${2-}"; LICENSE_IN="$2"; shift ;;
    --holder=*)        HOLDER_IN="${1#*=}" ;;
    --holder)          need_val "$1" "${2-}"; HOLDER_IN="$2"; shift ;;
    --layout=*)        LAYOUT_IN="${1#*=}" ;;
    --layout)          need_val "$1" "${2-}"; LAYOUT_IN="$2"; shift ;;
    --registries=*)    REGISTRIES_IN="${1#*=}" ;;
    --registries)      need_val "$1" "${2-}"; REGISTRIES_IN="$2"; shift ;;
    --collab=*)        COLLAB_IN="${1#*=}" ;;
    --collab)          need_val "$1" "${2-}"; COLLAB_IN="$2"; shift ;;
    --adr-authority=*) ADR_AUTHORITY_IN="${1#*=}" ;;
    --adr-authority)   need_val "$1" "${2-}"; ADR_AUTHORITY_IN="$2"; shift ;;
    --trunk-branch=*)  TRUNK_BRANCH_IN="${1#*=}"; TRUNK_BRANCH_FLAG_SET=1 ;;
    --trunk-branch)    need_val "$1" "${2-}"; TRUNK_BRANCH_IN="$2"; TRUNK_BRANCH_FLAG_SET=1; shift ;;
    --remotes=*)       REMOTES_IN="${1#*=}" ;;
    --remotes)         need_val "$1" "${2-}"; REMOTES_IN="$2"; shift ;;
    --remote-provider=*) REMOTE_PROVIDER_IN="${1#*=}" ;;
    --remote-provider) need_val "$1" "${2-}"; REMOTE_PROVIDER_IN="$2"; shift ;;
    --owner=*)         OWNER_IN="${1#*=}" ;;
    --owner)           need_val "$1" "${2-}"; OWNER_IN="$2"; shift ;;
    --remote-url=*)    REMOTE_URL_IN="${1#*=}" ;;
    --remote-url)      need_val "$1" "${2-}"; REMOTE_URL_IN="$2"; shift ;;
    --docs-remote=*)   DOCS_REMOTE_IN="${1#*=}" ;;
    --docs-remote)     need_val "$1" "${2-}"; DOCS_REMOTE_IN="$2"; shift ;;
    --prompts-remote=*) PROMPTS_REMOTE_IN="${1#*=}" ;;
    --prompts-remote)  need_val "$1" "${2-}"; PROMPTS_REMOTE_IN="$2"; shift ;;
    --visibility=*)    VISIBILITY_IN="${1#*=}" ;;
    --visibility)      need_val "$1" "${2-}"; VISIBILITY_IN="$2"; shift ;;
    -y|--yes|--non-interactive) NONINTERACTIVE=1 ;;
    -h|--help)         usage; exit 0 ;;
    *) echo "init.sh: unknown option: $1 (try './init.sh --help')" >&2; exit 2 ;;
  esac
  shift
done
case "$NONINTERACTIVE" in 1|true|yes|y|Y) NONINTERACTIVE=1 ;; *) NONINTERACTIVE=0 ;; esac

# --- 0b. Preflight: required tools ------------------------------------------
# Stop before asking project questions if the local machine cannot perform the mechanical
# bootstrap. `git commit` is tested explicitly because install checks do not catch missing
# user.name/user.email.
missing=""
for tool in git perl; do command -v "$tool" >/dev/null 2>&1 || missing="$missing $tool"; done
if [ -n "$missing" ]; then
  echo "init.sh: missing required tool(s):$missing" >&2
  echo "  'git' and 'perl' are required; both ship on macOS and nearly every Linux." >&2
  exit 1
fi
preflight_git_commit
command -v gh      >/dev/null 2>&1 || echo "Note: 'gh' not found — GitHub repo creation is unavailable, but manual remote URLs still work."
command -v python3 >/dev/null 2>&1 || echo "Note: 'python3' not found — the later setup-workspace.sh will use its plain-shell fallback."

# --- 0c. Fresh-template guard -----------------------------------------------
# init.sh is one-time and destructive: section 2 removes .git and every template-only file. That
# is right for a freshly downloaded template and catastrophic anywhere else — unpacking the
# template into a repository that already exists and running it here deletes that repository's
# history outright, with no warning and no way back.
#
# Four checks, because no one of them covers the rest. The sentinel below travels with the files,
# so it cannot answer "whose repository is this?" — an extracted template brings AGENTS.md and
# CLAUDE.md along with it. Git is asked separately, and only when there is a .git here to lose: a
# checkout nested inside someone else's repository has nothing at $ROOT for section 2 to remove.
#
# Each check is paired with a case that must still proceed: a fresh unpacked template (no .git at
# all), a clone of Throughstone or of a "Use this template" repo (history that is the template's
# own), and `git init` beside an unpacked template to attach an empty origin (no commits, nothing
# staged). tests/init-fresh-template-guard.sh holds both halves.

# Every top-level entry Throughstone ships, pipe-delimited so entries with spaces stay intact.
# tests/init-fresh-template-guard.sh regenerates this from the template and fails if it drifts.
TEMPLATE_ROOT_ENTRIES='|.github|.gitignore|AGENTS.md|ARTIFACT-TRAIL.md|CHANGELOG.md|CLAUDE.md|CODE_OF_CONDUCT.md|CONTRIBUTING.md|Code|LICENSE|README.md|SECURITY.md|TRADEMARK.md|Upcoming Prompts|brand|docs|doctor.sh|init.sh|prompts|tests|'

# refuse_not_fresh REASON — stop before the destructive boundary, saying which check refused.
refuse_not_fresh() {
  echo "init.sh: this does not look like a fresh Throughstone template checkout." >&2
  echo "  $1" >&2
  echo "  init.sh is one-time and destructive (it removes .git and template-only files), so it will" >&2
  echo "  not run on an already-initialized project or on top of a repository that is not the" >&2
  echo "  template — either would delete history it cannot give back." >&2
  echo "  Download the template into a fresh, empty folder and run it there instead." >&2
  exit 2
}

# 1. The root pointers carry a THROUGHSTONE-TEMPLATE-GUARD block that step 3 strips during
#    initialization. It holds no {{PROJECT}} token, so — unlike the docs-hub directory name — it
#    is never rewritten by placeholder substitution and stays a stable sentinel. Its absence means
#    an already-initialized project, or a directory that was never the template.
if ! grep -qlF 'THROUGHSTONE-TEMPLATE-GUARD' "$ROOT/AGENTS.md" "$ROOT/CLAUDE.md" 2>/dev/null; then
  refuse_not_fresh "The root pointers carry no template marker."
fi

if [ -e "$ROOT/.git" ]; then
  if git rev-parse --verify -q HEAD >/dev/null 2>&1; then
    # 2. There is committed history, so it has to be the template's own. A clone of Throughstone
    #    and a "Use this template" repo both carry the sentinel at HEAD, because init.sh has not
    #    run yet to strip it. Someone else's history does not.
    git cat-file -p HEAD:AGENTS.md 2>/dev/null | grep -qF 'THROUGHSTONE-TEMPLATE-GUARD' \
      || refuse_not_fresh "This repository's committed history is not Throughstone's."
    # 3. The sentinel at HEAD is necessary but not sufficient: someone who committed the extracted
    #    template on top of their own history has it too, and their commits are still underneath.
    #    A checkout that really is the template tracks nothing the template does not ship.
    while IFS= read -r -d '' entry; do
      case "$TEMPLATE_ROOT_ENTRIES" in
        *"|$entry|"*) ;;
        *) refuse_not_fresh "This repository tracks '$entry', which Throughstone does not ship." ;;
      esac
    done < <(git ls-tree -z --name-only HEAD)
  else
    # 4. No commits here yet. `git init` beside an unpacked template is a supported way to attach
    #    an empty origin, so an unborn HEAD is fine by itself — but only if the repository really
    #    is empty. A ref means commits survive on some other branch (`git checkout --orphan`
    #    inside a live repo leaves exactly this shape), and a populated index means files were
    #    staged and never committed.
    if [ -n "$(git for-each-ref --count=1)" ]; then
      refuse_not_fresh "This repository has branches or tags carrying history."
    fi
    if [ -n "$(git ls-files)" ]; then
      refuse_not_fresh "This repository has staged files that were never committed."
    fi
  fi
fi

say "Throughstone — setup"

# --- 1. Questions (flags/env pre-answer; otherwise prompt) -------------------
# Validation-before-destruction invariant: all user input, project-license posture, repo
# layout, collaboration metadata, Git remotes, and visibility are resolved before `.git` or
# template-only files are removed.
#
# Defaults are conservative for automation: multi-repo, solo, private GitHub visibility, and
# no remote creation unless requested.
# Project slug — validated kebab-case whether supplied or prompted.
SLUG="$SLUG_IN"
if [ -n "$SLUG" ]; then
  printf '%s' "$SLUG" | grep -Eq '^[a-z][a-z0-9-]*$' \
    || { echo "init.sh: invalid --slug '$SLUG' (lowercase letters, digits, hyphens only)." >&2; exit 2; }
elif [ "$NONINTERACTIVE" = "1" ]; then
  echo "init.sh: --slug is required in --non-interactive mode." >&2; exit 2
else
  while ! printf '%s' "$SLUG" | grep -Eq '^[a-z][a-z0-9-]*$'; do
    SLUG="$(ask 'Project slug (lowercase, kebab-case, e.g. acme-scheduler)')"
    printf '%s' "$SLUG" | grep -Eq '^[a-z][a-z0-9-]*$' || echo "  -> must be lowercase letters, digits, hyphens."
  done
fi
DESC="$(want "$DESC_IN" 'One-line description')"

# License — accept a friendly token from --license, else ask the two-part question. The durable
# result is PROJECT_LICENSE_ID, written later to .throughstone/project-license so generated
# helpers can distinguish proprietary projects from missing LICENSE files.
LICENSE_CHOICE=""
if [ -n "$LICENSE_IN" ]; then
  normalize_license_choice "$LICENSE_IN" \
    || { echo "init.sh: invalid --license '$LICENSE_IN' (mit | bsd-3 | apache-2.0 | private)." >&2; exit 2; }
  LICENSE_CHOICE="$NORMALIZED_LICENSE_CHOICE"
elif [ "$NONINTERACTIVE" = "1" ]; then
  echo "init.sh: --license is required in --non-interactive mode (mit | bsd-3 | apache-2.0 | private)." >&2; exit 2
else
  choose_license_interactively
fi
HOLDER=""
if [ "$LICENSE_CHOICE" != "private" ]; then
  HOLDER="$(want "$HOLDER_IN" 'Copyright holder (name or org)')"
fi
LICENSE_TEMPLATE_NAME=""
PROJECT_LICENSE_ID=""
case "$LICENSE_CHOICE" in
  1)
    LICENSE_TEMPLATE_NAME="MIT.txt"
    PROJECT_LICENSE_ID="MIT"
    ;;
  2)
    LICENSE_TEMPLATE_NAME="BSD-3-Clause.txt"
    PROJECT_LICENSE_ID="BSD-3-Clause"
    ;;
  3)
    LICENSE_TEMPLATE_NAME="Apache-2.0.txt"
    PROJECT_LICENSE_ID="Apache-2.0"
    ;;
  private)
    PROJECT_LICENSE_ID="Proprietary"
    ;;
  *)
    echo "init.sh: internal error: unsupported license choice '$LICENSE_CHOICE'." >&2
    exit 1
    ;;
esac
# Open-source projects depend on bundled templates; fail now rather than after the scaffold has
# been detached from its original history.
if [ -n "$LICENSE_TEMPLATE_NAME" ] \
  && [ ! -f "$ROOT/Code/{{PROJECT}}-docs/templates/licenses/$LICENSE_TEMPLATE_NAME" ]; then
  echo "init.sh: project license template is missing: Code/{{PROJECT}}-docs/templates/licenses/$LICENSE_TEMPLATE_NAME" >&2
  exit 1
fi

# Repo layout — multi (default) or mono. Multi-repo turns the root into a per-machine workspace
# shell with separate durable repos under prompts/ and Code/<project>-docs/. Mono keeps a single
# repo at the root for projects that are not ready to split yet.
# An unrecognised flag is fatal; an unrecognised typed answer is re-asked, the way the slug
# question above already works. Both go through normalize_layout, so the two paths cannot drift.
if [ -n "$LAYOUT_IN" ]; then
  normalize_layout "$LAYOUT_IN" \
    || { echo "init.sh: invalid layout '$LAYOUT_IN' (multi | mono) — from --layout or INIT_LAYOUT." >&2; exit 2; }
  LAYOUT="$NORMALIZED_LAYOUT"
elif [ "$NONINTERACTIVE" = "1" ]; then
  LAYOUT=1
else
  echo "Repo layout:"
  echo "  1) multi-repo now  (prompts/ and Code/${SLUG}-docs/ become separate repos)"
  echo "  2) mono-repo for now  (one repo at the workspace root; split later)"
  LAYOUT=""
  while [ -z "$LAYOUT" ]; do
    if normalize_layout "$(ask 'Choose 1 or 2' '1')"; then
      LAYOUT="$NORMALIZED_LAYOUT"
    else
      echo "  -> answer 1 or 2 (the words multi and mono work too)."
    fi
  done
fi

# registries/ always ships, in both layouts. It carries the repo inventory that
# setup-workspace.sh and remote recording read, plus the accepted-risk and security-review
# registers — and the docs hub, METHOD.md and several runbooks reference all three
# unconditionally, so a project without the directory cites files it does not have. The flag is
# still parsed so existing automation keeps working, and its value is still validated: an
# unrecognized one is an error in either layout, and `no` is ignored with a deprecation notice.
if [ -n "$REGISTRIES_IN" ]; then
  case "$(printf '%s' "$REGISTRIES_IN" | tr '[:upper:]' '[:lower:]')" in
    y|yes|true|1) : ;;
    n|no|false|0)
      echo "init.sh: --registries=no is ignored; registries/ always ships and is kept." >&2
      echo "         The flag is deprecated and will be removed in a future release." >&2 ;;
    *) echo "init.sh: invalid --registries '$REGISTRIES_IN' (yes | no)." >&2; exit 2 ;;
  esac
fi

# Solo vs. team. This does NOT create a behavioral mode: branch-per-STEP, STEP-number
# reservation, and overlap checks are practiced solo too (see runbooks/collaboration.md). The
# answer only affects prompt wording, remote guidance, and the ADR acceptance authority stamped
# into adr/README.md.
if [ -n "$COLLAB_IN" ]; then
  normalize_collab "$COLLAB_IN" \
    || { echo "init.sh: invalid collab '$COLLAB_IN' (solo | team) — from --collab or INIT_COLLAB." >&2; exit 2; }
  COLLAB="$NORMALIZED_COLLAB"
elif [ "$NONINTERACTIVE" = "1" ]; then
  COLLAB=1
else
  echo "Working solo for now, or collaborating with others from day one?"
  echo "  1) Solo for now  (team conventions switch on later; nothing here locks you in)"
  echo "  2) Team from day one"
  COLLAB=""
  while [ -z "$COLLAB" ]; do
    if normalize_collab "$(ask 'Choose 1 or 2' '1')"; then
      COLLAB="$NORMALIZED_COLLAB"
    else
      echo "  -> answer 1 or 2 (the words solo and team work too)."
    fi
  done
fi
ADR_AUTHORITY=""
if [ "$COLLAB" = "2" ]; then
  if [ -n "$ADR_AUTHORITY_IN" ]; then
    ADR_AUTHORITY="$ADR_AUTHORITY_IN"
  elif [ "$NONINTERACTIVE" = "1" ]; then
    ADR_AUTHORITY="consensus of maintainers"
  else
    echo "  In a team, significant ADRs land as Proposed and are flipped to Accepted by a"
    echo "  designated authority (recorded in adr/README.md so it's on disk, not folklore)."
    ADR_AUTHORITY="$(ask 'Who accepts ADRs? e.g. tech lead / consensus of maintainers / ADR review on PR' 'consensus of maintainers')"
    echo "  Heads-up: team collaboration relies on shared Git remotes so everyone clones"
    echo "  from the same place. You can still skip that now and add remotes later."
    if [ "$LAYOUT" = "2" ]; then
      echo "  NOTE: you picked mono-repo + team. That works — what a team needs is shared"
      echo "  remotes, not several repos. One thing to know: the overlap warning is"
      echo "  repo-granular, so it is meaningless when every STEP touches the one repo."
      echo "  Fall back to the PLAN's file/area notes — see runbooks/collaboration.md §4."
    fi
  fi
fi

# Generated repos default to a `main` trunk, but teams that still standardize on `master` or
# another branch name can stamp that convention into Git and the generated collaboration docs.
TRUNK_BRANCH="main"
if [ "$TRUNK_BRANCH_FLAG_SET" = "1" ] || [ -n "$TRUNK_BRANCH_IN" ]; then
  TRUNK_BRANCH="$TRUNK_BRANCH_IN"
fi
if ! validate_trunk_branch "$TRUNK_BRANCH"; then
  echo "init.sh: invalid --trunk-branch '$TRUNK_BRANCH' (valid Git branch name, e.g. main, master, trunk, release/stable)." >&2
  exit 2
fi

# Remember whether this download came from an existing project repo before we detach it. A
# non-Throughstone, empty root origin can be reused only in mono-repo mode, where the root
# remains the project repo. Multi-repo cannot reuse it because the root becomes a workspace
# shell and the durable repos are docs/prompts siblings.
ROOT_ORIGIN="$(git -C "$ROOT" remote get-url origin 2>/dev/null || true)"
ROOT_ORIGIN_IS_THROUGHSTONE=0
case "$ROOT_ORIGIN" in
  *github.com[:/]mherschberg/Throughstone|*github.com[:/]mherschberg/Throughstone.git)
    ROOT_ORIGIN_IS_THROUGHSTONE=1 ;;
esac
ROOT_ORIGIN_HAS_LOCAL_REFS=0
if [ -n "$ROOT_ORIGIN" ] \
  && git -C "$ROOT" for-each-ref --format='%(refname)' refs/remotes/origin | grep -q .; then
  ROOT_ORIGIN_HAS_LOCAL_REFS=1
fi
ROOT_ORIGIN_REUSABLE=0
ROOT_ORIGIN_REUSE_SKIP_REASON=""
if [ -n "$ROOT_ORIGIN" ] && [ "$ROOT_ORIGIN_IS_THROUGHSTONE" = "0" ]; then
  # Reuse only an origin that appears empty both locally and remotely. Existing refs mean it is
  # already someone's history and should not be overwritten by bootstrap output.
  if [ "$ROOT_ORIGIN_HAS_LOCAL_REFS" = "1" ]; then
    ROOT_ORIGIN_REUSE_SKIP_REASON="already has Git history"
  elif ROOT_ORIGIN_REMOTE_REFS="$(
    GIT_TERMINAL_PROMPT=0 git -C "$ROOT" ls-remote --heads --tags origin 2>/dev/null
  )"; then
    if [ -z "$ROOT_ORIGIN_REMOTE_REFS" ]; then
      ROOT_ORIGIN_REUSABLE=1
    else
      ROOT_ORIGIN_REUSE_SKIP_REASON="already has Git history"
    fi
  else
    ROOT_ORIGIN_REUSE_SKIP_REASON="could not be verified as empty"
  fi
fi
root_origin_can_be_reused() {
  [ "$ROOT_ORIGIN_REUSABLE" = "1" ]
}

# validate_empty_remote_url LABEL URL — fail before bootstrap mutates the checkout if a manual
# remote URL is unreachable or already has history. Manual remotes must be pre-created empty repos.
validate_empty_remote_url() {
  local label="$1" url="$2" refs
  [ -n "$url" ] || return 0
  if refs="$(GIT_TERMINAL_PROMPT=0 git ls-remote --heads --tags "$url" 2>/dev/null)"; then
    if [ -n "$refs" ]; then
      echo "init.sh: $label remote already has Git history and will not be overwritten:" >&2
      echo "  $url" >&2
      exit 2
    fi
    return 0
  fi
  echo "init.sh: could not verify $label remote as empty/reachable:" >&2
  echo "  $url" >&2
  echo "  Create an empty repo first, check your credentials, then rerun init.sh." >&2
  exit 2
}

# Remotes. GitHub automation creates repositories with `gh`; manual mode attaches and pushes to
# existing, empty/pushable Git URLs from any provider. Visibility is independent of the project
# license: private repos may use open-source licenses, and public repos still need an explicit
# project-license choice. A public proprietary repo is allowed only after an explicit warning
# because it publishes source without granting open-source reuse rights.
MK_REMOTES=0; REMOTE_PROVIDER=""; OWNER=""; REMOTE_URL=""; DOCS_REMOTE=""; PROMPTS_REMOTE=""
REMOTE_VISIBILITY=private
HAS_MANUAL_REMOTE_INPUT=0
[ -n "$REMOTE_URL_IN$DOCS_REMOTE_IN$PROMPTS_REMOTE_IN" ] && HAS_MANUAL_REMOTE_INPUT=1
if [ -n "$REMOTES_IN" ]; then
  case "$(printf '%s' "$REMOTES_IN" | tr '[:upper:]' '[:lower:]')" in
    y|yes|true|1) MK_REMOTES=1 ;;
    n|no|false|0) MK_REMOTES=0 ;;
    *) echo "init.sh: invalid --remotes '$REMOTES_IN' (yes | no)." >&2; exit 2 ;;
  esac
elif [ "$HAS_MANUAL_REMOTE_INPUT" = "1" ]; then
  MK_REMOTES=1
elif [ "$NONINTERACTIVE" != "1" ]; then
  echo "Online backup / sharing (optional):"
  echo "  Your project will be saved locally with Git."
  echo "  A Git remote is an online copy on GitHub, Bitbucket, GitLab, or another Git host."
  echo "  You can skip this now and add one later."
  if ! yesno "Set up online Git remotes now?"; then
    MK_REMOTES=0
  elif command -v gh >/dev/null 2>&1; then
    echo "Remote setup:"
    echo "  1) Create GitHub remotes now (via gh)"
    echo "  2) Use existing remote URLs (Bitbucket, GitLab, or another Git host)"
    case "$(ask 'Choose 1 or 2' '1')" in
      1) MK_REMOTES=1; REMOTE_PROVIDER_IN=github ;;
      2) MK_REMOTES=1; REMOTE_PROVIDER_IN=manual ;;
      *) echo "init.sh: invalid remote setup choice." >&2; exit 2 ;;
    esac
  else
    echo "  GitHub auto-creation needs the 'gh' CLI, which is not installed."
    echo "  If you already created empty repos online, you can paste their URLs now."
    if yesno "Use existing remote URLs now?"; then
      MK_REMOTES=1
      REMOTE_PROVIDER_IN=manual
    else
      MK_REMOTES=0
    fi
  fi
fi
if [ "$MK_REMOTES" = "1" ]; then
  if [ -n "$REMOTE_PROVIDER_IN" ]; then
    case "$(printf '%s' "$REMOTE_PROVIDER_IN" | tr '[:upper:]' '[:lower:]')" in
      github|gh) REMOTE_PROVIDER=github ;;
      manual|existing|url|urls) REMOTE_PROVIDER=manual ;;
      *) echo "init.sh: invalid --remote-provider '$REMOTE_PROVIDER_IN' (github | manual)." >&2; exit 2 ;;
    esac
  elif [ "$HAS_MANUAL_REMOTE_INPUT" = "1" ]; then
    REMOTE_PROVIDER=manual
  else
    REMOTE_PROVIDER=github
  fi
  if [ "$REMOTE_PROVIDER" = "github" ] && [ "$HAS_MANUAL_REMOTE_INPUT" = "1" ]; then
    echo "init.sh: manual remote URL flags require --remote-provider=manual." >&2
    exit 2
  fi
  if [ -n "$VISIBILITY_IN" ]; then
    case "$(printf '%s' "$VISIBILITY_IN" | tr '[:upper:]' '[:lower:]')" in
      private|1) REMOTE_VISIBILITY=private ;;
      public|2)  REMOTE_VISIBILITY=public ;;
      *) echo "init.sh: invalid --visibility '$VISIBILITY_IN' (private | public)." >&2; exit 2 ;;
    esac
  elif [ "$REMOTE_PROVIDER" = "github" ] && [ "$NONINTERACTIVE" != "1" ]; then
    echo "GitHub repository visibility:"
    echo "  1) Private"
    echo "  2) Public"
    while :; do
      case "$(ask 'Choose 1 or 2' '1')" in
        1) REMOTE_VISIBILITY=private; break ;;
        2) REMOTE_VISIBILITY=public; break ;;
        *) echo "  -> choose 1 for private or 2 for public." ;;
      esac
    done
  fi
  if [ "$REMOTE_PROVIDER" = "github" ]; then
    if ! command -v gh >/dev/null 2>&1; then
      if [ "$LAYOUT" = "2" ] && root_origin_can_be_reused; then
        REMOTE_PROVIDER=manual
      else
        echo "init.sh: --remotes=yes with --remote-provider=github needs the 'gh' CLI, which isn't installed." >&2
        echo "  For Bitbucket, GitLab, or another Git host, pre-create empty repos and pass --remote-provider=manual with remote URL flags." >&2
        exit 2
      fi
    fi
  fi
  if [ "$REMOTE_PROVIDER" = "github" ]; then
    if [ "$LAYOUT" = "2" ] && root_origin_can_be_reused; then
      OWNER=""
    else
      OWNER="$(want "$OWNER_IN" 'GitHub owner/org')"
    fi
  else
    if [ -n "$OWNER_IN" ]; then
      echo "init.sh: --owner is only used with --remote-provider=github." >&2
      exit 2
    fi
    if [ "$LAYOUT" = "2" ]; then
      if root_origin_can_be_reused && [ -z "$REMOTE_URL_IN" ]; then
        REMOTE_URL=""
      else
        REMOTE_URL="$(want "$REMOTE_URL_IN" 'Project repo remote URL')"
      fi
    else
      DOCS_REMOTE="$(want "$DOCS_REMOTE_IN" 'Docs repo remote URL')"
      PROMPTS_REMOTE="$(want "$PROMPTS_REMOTE_IN" 'Prompts repo remote URL')"
    fi
    validate_empty_remote_url "project" "$REMOTE_URL"
    validate_empty_remote_url "docs" "$DOCS_REMOTE"
    validate_empty_remote_url "prompts" "$PROMPTS_REMOTE"
  fi
elif [ "$HAS_MANUAL_REMOTE_INPUT" = "1" ]; then
  echo "init.sh: remote URL flags require --remotes=yes (or omit --remotes)." >&2
  exit 2
else
  if [ -n "$REMOTE_PROVIDER_IN" ]; then
    echo "init.sh: --remote-provider requires --remotes=yes." >&2
    exit 2
  fi
  if [ -n "$OWNER_IN" ]; then
    echo "init.sh: --owner requires --remotes=yes with --remote-provider=github." >&2
    exit 2
  fi
fi
if [ "$MK_REMOTES" = "1" ]; then
  if [ "$REMOTE_PROVIDER" = "github" ]; then
    :
  elif [ "$REMOTE_PROVIDER" = "manual" ]; then
    :
  else
    echo "init.sh: internal error: remote provider was not resolved." >&2
    exit 1
  fi
fi
if [ "$MK_REMOTES" = "1" ]; then
  if [ "$REMOTE_PROVIDER" = "manual" ] && [ -n "$VISIBILITY_IN" ]; then
    echo "  note: --visibility records your intent only; manual remotes must already have the desired host visibility."
  fi
fi
if [ "$MK_REMOTES" = "1" ]; then
  if [ "$REMOTE_PROVIDER" = "github" ] && [ -n "$DOCS_REMOTE_IN$PROMPTS_REMOTE_IN$REMOTE_URL_IN" ]; then
    echo "init.sh: remote URL flags are not used with --remote-provider=github." >&2
    exit 2
  fi
fi
if [ "$MK_REMOTES" = "1" ]; then
  if [ "$REMOTE_PROVIDER" = "manual" ]; then
    if [ "$LAYOUT" = "1" ] && { [ -z "$DOCS_REMOTE" ] || [ -z "$PROMPTS_REMOTE" ]; }; then
      echo "init.sh: manual multi-repo remotes need --docs-remote and --prompts-remote." >&2
      exit 2
    fi
    if [ "$LAYOUT" = "2" ] && ! root_origin_can_be_reused && [ -z "$REMOTE_URL" ]; then
      echo "init.sh: manual mono-repo remotes need --remote-url unless an empty root origin can be reused." >&2
      exit 2
    fi
  fi
fi
if [ "$MK_REMOTES" = "1" ] \
  && [ "$REMOTE_VISIBILITY" = "public" ] \
  && [ "$LICENSE_CHOICE" = "private" ]; then
  cat >&2 <<'WARNING'
WARNING: public visibility with a proprietary license publishes the source code but grants
no open-source reuse rights. LICENSE-THROUGHSTONE covers only retained Throughstone scaffold
material; it does not license the project's application code.
WARNING
  if [ "$NONINTERACTIVE" != "1" ] \
    && ! yesno "Continue with public proprietary repositories?"; then
    echo "init.sh: public proprietary repository creation cancelled." >&2
    exit 2
  fi
fi

# --- 2. Untether from the template origin -----------------------------------
# Destructive bootstrap boundary. Everything above this line is validation and choice
# resolution; everything below mutates the checkout into a generated project. Keep questions,
# license/layout/remotes validation, and public/proprietary warnings before this point.
say "Detaching from the template's git history..."
# Drop template history before creating project repos so the first generated commit contains
# only the user's initialized project state, not Throughstone's development history.
rm -rf "$ROOT/.git"
# The root LICENSE is the Throughstone scaffold's own license (BSD-3-Clause, © Mark A.
# Herschberg), not the generated project's license. Retained scaffold material (METHOD.md,
# templates/, runbooks/, scripts/) stays under it, and BSD-3 clause 1 requires preserving the
# notice. Relocate it as LICENSE-THROUGHSTONE below; open-source projects get their selected
# project LICENSE separately, while proprietary projects intentionally do not.
#
# README/CHANGELOG/TODO/ARTIFACT-TRAIL are Throughstone-template files: the front door, release
# history, maintainer backlog, and public explanation of the scaffold's output. After bootstrap
# they are stale project content, and in multi-repo mode they would be stray files at the non-repo
# workspace root. Drop them; generated-project context starts in the docs hub. Mono-repo projects
# can add their own versions later.
rm -f "$ROOT/README.md" "$ROOT/CHANGELOG.md" "$ROOT/TODO.md" "$ROOT/ARTIFACT-TRAIL.md"
# Community/health files describe the Throughstone template itself: contribution policy,
# security contact, code of conduct, and trademark posture. Carrying them forward would leak the
# template maintainer's contacts and assert Throughstone governance inside the user's project.
rm -f "$ROOT/CONTRIBUTING.md" "$ROOT/CODE_OF_CONDUCT.md" "$ROOT/SECURITY.md" "$ROOT/TRADEMARK.md"
# .github/ holds Throughstone's issue/PR templates, contact links, and contribution funnel.
# They point at the template repo's issues/discussions/security pages, not the generated
# project. Drop them so projects can add their own repository health files deliberately.
rm -rf "$ROOT/.github"
# .dev/ holds template-maintainer-only notes such as handoffs and design memos. It is not part
# of the generated project and should not leak into bootstrapped repos.
rm -rf "$ROOT/.dev"
# tests/ and .test-fixtures/ validate the scaffold and carry scaffold-maintainer test data.
# They are useful here, but not part of a user's project and would trip root-hygiene warnings in
# multi-repo workspaces.
rm -rf "$ROOT/tests" "$ROOT/.test-fixtures"
# brand/ (brief, logo, social card, landing-page source) and docs/ (the built GitHub Pages
# site) are Throughstone marketing assets. Drop them so generated repos do not inherit the
# template's trademark, public site, or branding.
rm -rf "$ROOT/brand" "$ROOT/docs"

# --- 3. Replace the {{PROJECT}} token + description -------------------------
say "Renaming {{PROJECT}} -> ${SLUG} ..."
# Replace placeholder contents before repo initialization so generated commits never contain
# unresolved scaffold tokens.
grep -rlF '{{PROJECT}}' . --exclude-dir=.git 2>/dev/null | while read -r f; do
  SLUG="$SLUG" perl -pi -e 's/\Q{{PROJECT}}\E/$ENV{SLUG}/g' "$f"
done
# Rename the docs hub before filling descriptions so later scans walk the generated path.
[ -d "Code/{{PROJECT}}-docs" ] && mv "Code/{{PROJECT}}-docs" "Code/${SLUG}-docs"

# Root pointers include a scaffold-only guard that tells agents not to start kickoff while
# {{PROJECT}} is unresolved. Generated projects remove that guard and keep only the handoff.
for f in AGENTS.md CLAUDE.md; do
  [ -f "$f" ] || continue
  perl -0pi -e 's/<!-- THROUGHSTONE-TEMPLATE-GUARD:BEGIN -->\n.*?<!-- THROUGHSTONE-TEMPLATE-GUARD:END -->\n\n//s' "$f"
done

DOCS="Code/${SLUG}-docs"
mkdir -p "$DOCS/.throughstone"
mkdir -p "$ROOT/.throughstone"
# The posture file is the durable license authority for generated helpers. It remains present
# even when proprietary projects intentionally have no project LICENSE.
printf '%s\n' "$PROJECT_LICENSE_ID" > "$DOCS/.throughstone/project-license"

# description: fill {{PROJECT_DESCRIPTION}} EVERYWHERE it appears (AGENTS.md + every
# architecture/planning-session "About" blurb) so no literal placeholder is left dangling.
# The one-liner is just a seed — the kickoff can later expand any of these from overview.md.
grep -rlF '{{PROJECT_DESCRIPTION}}' . --exclude-dir=.git 2>/dev/null | while read -r f; do
  DESC="$DESC" perl -pi -e 's/\Q{{PROJECT_DESCRIPTION}}\E/$ENV{DESC}/g' "$f"
done
# Fill generated collaboration docs with the actual initialized trunk branch. The scaffold
# keeps the placeholder only where generated-project text should name the branch.
grep -rlF '{{TRUNK_BRANCH}}' . --exclude-dir=.git 2>/dev/null | while read -r f; do
  TRUNK_BRANCH="$TRUNK_BRANCH" perl -pi -e 's/\Q{{TRUNK_BRANCH}}\E/$ENV{TRUNK_BRANCH}/g' "$f"
done

# Relocate the scaffold's BSD license into the docs hub (retained as attribution per BSD-3,
# next to the method files it covers — not deleted). Open-source project licenses are stamped
# separately into each repo in step 6; private projects get no project LICENSE.
[ -f "$ROOT/LICENSE" ] && mv "$ROOT/LICENSE" "$DOCS/LICENSE-THROUGHSTONE"
# LICENSE-THROUGHSTONE follows retained scaffold material. In multi-repo mode prompts/ is its
# own repo and contains Throughstone-authored seed content, so retain the scaffold notice there
# too; this is distinct from the project LICENSE stamped below for open-source projects. In
# mono-repo mode the root repo keeps the notice beside the generated project files.
if [ -f "$DOCS/LICENSE-THROUGHSTONE" ]; then
  if [ "$LAYOUT" = "1" ]; then
    cp "$DOCS/LICENSE-THROUGHSTONE" "prompts/LICENSE-THROUGHSTONE"
  else
    cp "$DOCS/LICENSE-THROUGHSTONE" "$ROOT/LICENSE-THROUGHSTONE"
  fi
fi

# --- 4. Stamp per-project options -------------------------------------------
# Nothing is pruned here. runbooks/ ships method-level runbooks (check-in, collaboration) that
# AGENTS.md and METHOD.md reference, and registries/ ships the repo inventory and the risk and
# security-review registers that the docs hub and those same runbooks cite unconditionally.

# Replace the visible ADR authority marker, not arbitrary prose. Solo records the default
# single-author posture; team records the selected acceptance authority for future handoffs.
if [ -f "$DOCS/adr/README.md" ]; then
  ADR_AUTHORITY_TEXT="_solo author_"
  if [ "$COLLAB" = "2" ] && [ -n "$ADR_AUTHORITY" ]; then
    ADR_AUTHORITY_TEXT="$ADR_AUTHORITY"
  fi
  ADR_AUTHORITY="$ADR_AUTHORITY_TEXT" perl -0pi -e \
    's/<!-- ADR-AUTHORITY -->.*?<!-- \/ADR-AUTHORITY -->/$ENV{ADR_AUTHORITY}/s' \
    "$DOCS/adr/README.md"
  if [ "$COLLAB" = "2" ] && [ -n "$ADR_AUTHORITY_TEXT" ]; then
    echo "  ADR authority: $ADR_AUTHORITY_TEXT"
  fi
fi

# --- 5. Create the project brief from the template --------------------------
# overview.md starts with PROJECT-STATUS: not-started, which tells AGENTS.md/status.sh to run
# the kickoff interview before ordinary STEP resolution.
if [ ! -f "$DOCS/overview.md" ]; then
  cp "$DOCS/templates/overview-template.md" "$DOCS/overview.md"
  echo "  created $DOCS/overview.md (fill it in)"
fi

# --- 5b. Seed the STEP index ------------------------------------------------
# prompts/STEP-index.md is the roadmap and the STEP-number registry of record — METHOD.md,
# AGENTS.md, the architecture sessions and repos.yml all point at it, so it must exist from
# the start. BOOTSTRAP-PROMPT.md then fills in STEP-1's row; the planning session adds the
# rest. ({{PROJECT}} in the template was already substituted in step 3.)
if [ ! -f "prompts/STEP-index.md" ]; then
  cp "$DOCS/templates/step-index-seed.md" "prompts/STEP-index.md"
  echo "  created prompts/STEP-index.md (seeded from template)"
fi

# --- 5c. Mono-repo-for-now layout files -------------------------------------
# In this layout the workspace root is the project's one repository, so two things multi-repo
# gets for free have to be placed here before the initial commit.
if [ "$LAYOUT" = "2" ]; then
  # The registry is the source of truth for which repos exist, and the only repository a mono
  # project has is the workspace root — so its row is seeded here. `added_as: created` is a
  # stamp for a human reader: nothing reads it and nothing decides from it.
  if [ -f "$DOCS/registries/repos.yml" ]; then
    SLUG="$SLUG" perl -0pi -e '
      my $row = qq{  - name: "$ENV{SLUG}"\n}
              . qq{    location: "."\n}
              . qq{    type: mono\n}
              . qq{    added_as: created\n}
              . qq{    description: "The workspace root: the one repository this project lives in until it is split."\n\n};
      s{^repos:\n}{repos:\n$row}m;
    ' "$DOCS/registries/repos.yml"
    echo "  registry: recorded the workspace root repo"
  fi
  # GitHub reads workflows only at a repository root, and step 2 removed .github along with the
  # template's own health files — so the method-check gate has never actually run in a mono
  # project. The docs hub keeps its own copy, which is what gives it CI after a split; the
  # workflow's run step finds the doctor in either layout.
  if [ -f "$DOCS/.github/workflows/method-check.yml" ]; then
    mkdir -p "$ROOT/.github/workflows"
    cp "$DOCS/.github/workflows/method-check.yml" "$ROOT/.github/workflows/method-check.yml"
    echo "  CI: method-check workflow placed at the workspace root"
  fi
fi

# --- 6. Initialise repo(s) --------------------------------------------------
# write_gitignore DIR — write the shared baseline ignore file for each generated repo.
# The contents are intentionally small: editor cruft, per-machine agent config, and local
# secrets. Project-specific ignores can be added after bootstrap.
write_gitignore() {
  cat > "$1/.gitignore" <<'GI'
# OS / editor cruft
.DS_Store
*.swp

# Per-machine agent config (not shared). Patterns rather than one filename: an editor's lock and
# autosave siblings (#settings.local.json#, settings.local.json~) are per-machine too, and a
# `git add -A` would otherwise commit them. Shared project config (.claude/settings.json) still commits.
.claude/*.local.json
.claude/#*#
.claude/*~

# Personal local Throughstone profile (not shared)
/.throughstone/local-user.md

# Local dev secrets — NEVER commit. Commit only .env.example (the documented key list).
.env
.env.*
!.env.example
.secrets/
GI
}

# stamp_license DIR — write the selected project LICENSE for open-source projects.
# Proprietary projects skip LICENSE creation; LICENSE-THROUGHSTONE remains separate and covers
# only retained scaffold material. In mono-repo mode the docs hub also keeps the canonical copy
# so apply-project-license.sh has the same source of truth as multi-repo projects.
stamp_license() {
  local src
  [ "$LICENSE_CHOICE" = "private" ] && return 0
  src="$DOCS/templates/licenses/$LICENSE_TEMPLATE_NAME"
  [ -f "$src" ] || {
    echo "init.sh: project license template disappeared during setup: $src" >&2
    return 1
  }
  YEAR="$(date +%Y)" HOLDER="$HOLDER" perl -pe \
    's/\Q{{YEAR}}\E/$ENV{YEAR}/g; s/\Q{{HOLDER}}\E/$ENV{HOLDER}/g' "$src" > "$1/LICENSE"
  echo "  license: $1/LICENSE"
  if [ "$LAYOUT" = "2" ] && [ "$1" = "." ]; then
    cp "$1/LICENSE" "$DOCS/LICENSE"
    echo "  canonical project license: $DOCS/LICENSE"
  fi
}

# write_licensing_summary DIR — make the project/Throughstone license boundary explicit.
# Every generated repo gets LICENSING.md so readers do not mistake LICENSE-THROUGHSTONE for the
# project's license grant.
write_licensing_summary() {
  if [ "$LICENSE_CHOICE" = "private" ]; then
    cat > "$1/LICENSING.md" <<'EOF'
# Licensing

Project-authored content in this repository is proprietary. No project `LICENSE` is
provided, and the presence of `LICENSE-THROUGHSTONE` does not grant permission to copy,
modify, or distribute the project's application code.

`LICENSE-THROUGHSTONE` applies only to retained Throughstone-authored scaffold material.
EOF
  else
    cat > "$1/LICENSING.md" <<EOF
# Licensing

Project-authored content in this repository is licensed under $PROJECT_LICENSE_ID. See
\`LICENSE\` for the full project license.

\`LICENSE-THROUGHSTONE\` applies only to retained Throughstone-authored scaffold material;
it does not replace or alter the project license.
EOF
  fi
}

# init_repo DIR — create one generated repo with baseline files and an initial trunk commit.
# Callers decide which directories are durable repos; this helper keeps their initial commit
# shape consistent.
# In the mono layout DIR is the workspace root, so `git add -A` takes in init.sh itself. That is
# deliberate, and it was weighed: excluding it would leave every newly generated project with a
# dirty working tree, and the next ordinary `git add -A` would commit it anyway. The script does
# not delete itself either — not because it cannot, since an unlinked script keeps running, but
# because reading a script while removing it is fragile, a run that failed partway would leave the
# user no copy, and the multi layout leaves the file on disk too. Keeping both layouts alike is
# the point.
#
# The committed copy has a second, smaller use, and it is worth stating narrowly. It is the
# generator's own source with this run's answers substituted into it, so it is a snapshot you can
# diff against another project's copy. It is not a version stamp — nothing in it names a release —
# and it is not a complete answer log: the licence posture is in .throughstone/project-license, the
# ADR authority in adr/README.md, the trunk branch in git, the layout in the shape of the tree.
# Nothing in a generated project records the scaffold version, which is a real gap and a separate
# question from this one.
#
# It is inert: the guard in section 0c looks for a marker that section 3 strips, so running this
# copy inside a finished project refuses and exits.
init_repo() {
  write_gitignore "$1"
  stamp_license "$1"
  write_licensing_summary "$1"
  ( cd "$1" && git init -q && git add -A && git commit -qm "Initial commit (bootstrapped)" \
    && git branch -M "$TRUNK_BRANCH"; )
  echo "  git repo: $1"
}

# record_registry_remote REPO_NAME REMOTE_URL — update registries/repos.yml after a remote is
# attached and pushed. Both layouts use it: multi for the docs and prompts repos, mono for the
# workspace-root row. It matches the row by name, so a pruned registry safely no-ops. Where the
# row carries no `remote:` yet, the line goes in after `location:` — the one field a row cannot
# lack, since the check-in fails a row without one — never after an optional field a reader is
# told is safe to drop.
record_registry_remote() {
  local repo="$1" remote="$2" reg="$DOCS/registries/repos.yml"
  [ -f "$reg" ] || return 0
  REPO="$repo" REMOTE="$remote" perl -0pi -e '
    my $remote = $ENV{REMOTE};
    my $qremote = $remote;
    $qremote =~ s/\\/\\\\/g;
    $qremote =~ s/"/\\"/g;
    s{(^[ \t]*-[ \t]*name:[ \t]*"\Q$ENV{REPO}\E"[^\n]*\n(?:(?!^[ \t]*-[ \t]*name:).)*?^[ \t]*remote:[^\n]*\n)}
     {
       my $block = $1;
       $block =~ s{^[ \t]*remote:[^\n]*\n}{    remote: "$qremote"\n}m;
       $block;
     }ems
    or
    s{(^[ \t]*-[ \t]*name:[ \t]*"\Q$ENV{REPO}\E"[^\n]*\n(?:(?!^[ \t]*-[ \t]*name:).)*?^[ \t]*location:[^\n]*\n)}
     {$1 . qq{    remote: "$qremote"\n}}ems;
  ' "$reg"
}

# commit_registry_remotes — persist registry remote URLs after the run's remotes exist. The repo
# holding the registry is already initialized and committed before this runs — the docs repo in
# multi, the workspace root in mono — so recording lands in a second commit, which is what keeps
# the file from claiming a remote URL before creation/push has actually succeeded.
commit_registry_remotes() {
  local reg="$DOCS/registries/repos.yml"
  [ "$MK_REMOTES" = "1" ] || return 0
  [ -f "$reg" ] || return 0
  if git -C "$DOCS" diff --quiet -- registries/repos.yml; then
    return 0
  fi
  ( cd "$DOCS" && git add registries/repos.yml && git commit -qm "Record bootstrap remotes" )
  echo "  registry: recorded bootstrap remotes"
  if git -C "$DOCS" remote get-url origin >/dev/null 2>&1; then
    # The repository this commit has to leave is the one that holds the registry: $DOCS in multi,
    # the workspace root in mono, where $DOCS is a folder inside it and cannot be pushed. A failure
    # here is a backup that did not complete like any other — the remote is left without the commit
    # that records the remotes, so its copy of repos.yml lists none of them.
    local reg_dir reg_name
    if [ "$LAYOUT" = "2" ]; then
      reg_dir="the workspace root"; reg_name="$SLUG"
    else
      reg_dir="$DOCS"; reg_name="${SLUG}-docs"
    fi
    ( cd "$DOCS" && git push -q origin "$TRUNK_BRANCH" && echo "  registry: pushed remote updates" ) \
      || { echo "  (could not push the registry commit; it is committed in ${reg_dir} and not yet sent)"
           note_remote_failure "$reg_name"; }
  fi
}

# REMOTE_FAILED_REPOS — the repos whose requested backup did not complete, accumulated as a
# space-separated list so the closing report can name them; in the multi layout either repo can
# fail alone. Read it exactly that way: a listed repo may still have an origin attached — what the
# list says is that the branch was not confirmed to be on it. Empty means every requested backup
# completed; it does not mean the wizard created every remote, since reuse_root_origin pushes to
# one that was already there.
#
# It exists because the two layouts disagreed about the same failure — one ended the run, the
# other carried on — purely because of where each call sits relative to errexit, and because the
# exit status told a caller the backup exists when it did not.
REMOTE_FAILED_REPOS=""

# note_remote_failure NAME — record a repo whose requested backup did not complete. Adding a name
# twice is possible: a repo whose first push failed keeps its attached origin, so the registry
# push at the end of the run fails against the same repo. The list is the set of repos to go and
# look at, so the second mention would only make the report read as though two things broke.
note_remote_failure() {
  case " $REMOTE_FAILED_REPOS " in
    *" $1 "*) return 0 ;;
  esac
  REMOTE_FAILED_REPOS="$REMOTE_FAILED_REPOS $1"
}

# setup_remote DIR REPONAME MANUAL_URL — create/attach and push a remote.
# GitHub mode creates a repo with gh. Manual mode attaches an existing remote URL from any Git
# host and pushes the initialized trunk branch. Either way MADE_REMOTE_URL is set only inside the
# success arm of the command that pushes, so a caller reading it is reading a URL the branch has
# reached.
setup_remote() {
  MADE_REMOTE_URL=""
  [ "$MK_REMOTES" = "1" ] || return 0
  if [ "$REMOTE_PROVIDER" = "manual" ]; then
    # Not a caller error: the mono fallback calls this with no URL on purpose. Validation only
    # demands --remote-url when the root origin cannot be reused, so a run that expected to reuse
    # one and then could not attach it arrives here with nothing to fall back to. That is a
    # requested backup that did not happen, so it is recorded like any other.
    [ -n "${3:-}" ] || { note_remote_failure "$2"; return 1; }
    if ( cd "$1" && git remote add origin "$3" && git push -u origin "$TRUNK_BRANCH" >/dev/null ); then
      MADE_REMOTE_URL="$3"
      echo "  remote: $3"
      return 0
    fi
    echo "  (could not complete the remote for $2 — the command stopped partway, so whether"
    echo "   origin is attached and whether the branch reached it are both unconfirmed. Check that"
    echo "   the remote exists, is empty, and accepts your credentials.)"
    note_remote_failure "$2"
    return 1
  fi
  if [ "$REMOTE_PROVIDER" = "github" ]; then
    if ( cd "$1" && gh repo create "$OWNER/$2" "--$REMOTE_VISIBILITY" --source=. --remote=origin --push >/dev/null ); then
      MADE_REMOTE_URL="$(git -C "$1" remote get-url origin 2>/dev/null || true)"
      echo "  remote: $OWNER/$2"
      return 0
    fi
    # gh creates and pushes in one command, so a failure here says nothing about which half ran.
    # "skipped" was the old wording and was wrong: the repository may well exist on the host.
    echo "  (could not create and push $OWNER/$2 — it may have been created; check your host)"
    note_remote_failure "$2"
    return 1
  fi
  echo "  (no remote for $2; unknown provider '$REMOTE_PROVIDER')"
  note_remote_failure "$2"
  return 1
}

# reuse_root_origin DIR — attach the preexisting empty root origin to a mono-repo project.
# Multi-repo never calls this: the root stops being a durable repo, so reusing its origin for
# docs or prompts would publish the wrong repository shape. Like setup_remote it reports the URL
# in MADE_REMOTE_URL, and only once the trunk branch is actually on it: an origin attached under
# --remotes=no has nothing pushed to it, so the work still lives on one machine.
reuse_root_origin() {
  MADE_REMOTE_URL=""
  root_origin_can_be_reused || {
    if [ -n "$ROOT_ORIGIN" ] \
      && [ "$ROOT_ORIGIN_IS_THROUGHSTONE" = "0" ] \
      && [ -n "$ROOT_ORIGIN_REUSE_SKIP_REASON" ]; then
      echo "  note: existing root origin $ROOT_ORIGIN_REUSE_SKIP_REASON and was not reused:"
      echo "        $ROOT_ORIGIN"
      echo "        Add a fresh remote, or replace that remote only after an explicit review."
    fi
    return 1
  }
  # Checked, not trusted to errexit: this function is called on the left of an ||, which turns
  # errexit off for its whole body. Without the check a failed attach fell straight through to the
  # success message below. Returning 1 hands the caller its fallback, which records the failure if
  # it cannot set up a remote either — so the outcome is reported once, not twice.
  ( cd "$1" && git remote add origin "$ROOT_ORIGIN" ) || {
    echo "  note: could not attach the existing origin ($ROOT_ORIGIN)"
    return 1
  }
  echo "  remote: reused existing origin ($ROOT_ORIGIN)"
  if [ "$MK_REMOTES" = "1" ]; then
    if ( cd "$1" && git push -u origin "$TRUNK_BRANCH" >/dev/null ); then
      MADE_REMOTE_URL="$ROOT_ORIGIN"
      echo "  pushed: $ROOT_ORIGIN"
    else
      echo "  (origin is attached, but the push did not complete; check it and push later)"
      note_remote_failure "$SLUG"
    fi
  fi
  return 0
}

say "Initialising git..."
if [ "$LAYOUT" = "2" ]; then
  # Mono-repo: the initialized project is the workspace root. Reuse an empty non-template root
  # origin when safe; otherwise create/use a fresh remote if requested.
  init_repo "."
  # The `|| true` is what keeps the run going, and each branch needs it for its own reason. In the
  # first, setup_remote is a plain command in an if-body, which errexit acts on wherever it sits.
  # In the second it is the final command of an `||` list, the one position in such a list errexit
  # still watches. Either way the run would end right here — after the project is generated and
  # committed, and before the closing instructions that say how to attach a remote later. Nothing
  # is swallowed by it: the helpers record the repo in REMOTE_FAILED_REPOS, which is reported at
  # the end and decides the exit status.
  if [ "$REMOTE_PROVIDER" = "manual" ] && [ -n "$REMOTE_URL" ]; then
    setup_remote "." "$SLUG" "$REMOTE_URL" || true
  else
    reuse_root_origin "." || setup_remote "." "$SLUG" "" || true
  fi
  # The workspace-root row was seeded in step 5c, before this repo had a remote. Record the URL
  # now that one exists, the way multi does for docs and prompts below — otherwise the row stays
  # blank and every check-in reports the project's one repository as backed up nowhere.
  if [ -n "$MADE_REMOTE_URL" ]; then
    record_registry_remote "$SLUG" "$MADE_REMOTE_URL"
  fi
  commit_registry_remotes
else
  # Multi-repo: initialize docs and prompts as siblings. The root is only a local workspace
  # shell, so any origin attached to the downloaded template cannot represent the generated
  # repos and is reported but not reused.
  if [ -n "$ROOT_ORIGIN" ] && [ "$ROOT_ORIGIN_IS_THROUGHSTONE" = "0" ]; then
    echo "  note: existing root origin is not reused in multi-repo mode; use --remotes=yes or add remotes to the docs/prompts repos later."
  fi
  init_repo "$DOCS"
  setup_remote "$DOCS" "${SLUG}-docs" "$DOCS_REMOTE" \
    && [ -n "$MADE_REMOTE_URL" ] && record_registry_remote "${SLUG}-docs" "$MADE_REMOTE_URL"
  init_repo "prompts"
  setup_remote "prompts" "${SLUG}-prompts" "$PROMPTS_REMOTE" \
    && [ -n "$MADE_REMOTE_URL" ] && record_registry_remote "prompts" "$MADE_REMOTE_URL"
  commit_registry_remotes
fi

# --- 7. Done ----------------------------------------------------------------
# Mono keeps ONE shared remote for the single root repo. registries/repos.yml records that repo
# and the folders inside it; no row in it is a repo to clone (runbooks/collaboration.md §9).
if [ "$LAYOUT" = "2" ]; then
  REMOTE_TIP="If you answered no to remotes, that skipped creating one and pushing to it — not
  attaching one: an empty origin this folder already had is kept rather than replaced, though
  attaching it can itself fail. So run 'git remote -v' first to see what you actually have, then
  either push the root repo's ${TRUNK_BRANCH} branch to what is there, or create one empty repo on
  your host and push to that. Then record that URL on the row in registries/repos.yml whose
  location is \".\", the same as any other repo — until it is there the check-in reports this
  project as backed up nowhere. The rows below it are folders inside that one repository, not
  repos to clone."
else
  REMOTE_TIP="If you did not set up remotes during init, do this for each of the two repos here,
  Code/${SLUG}-docs/ and prompts/: create an empty repo on your host, attach it from inside the
  local one with 'git remote add origin <url>', push the ${TRUNK_BRANCH} branch to it, and only
  then record that URL as remote: on that repo's row in Code/${SLUG}-docs/registries/repos.yml.
  Recording last is the point — that row is what tells a teammate where to clone from, so it
  should never name a remote the branch has not reached."
fi
# In mono the workspace root is the project's repository, so init.sh is in its first commit and
# deleting it is a change like any other. In multi the root is not a repo and the file is simply
# on disk. Say whichever is true rather than one sentence that is only true in one of them.
if [ "$LAYOUT" = "2" ]; then
  INIT_SH_TIP="You can delete this init.sh now — it has done its job. It is in your first
commit, so deleting the file is a change you would then commit; the copy already in that
commit stays either way. Keeping it costs nothing: it is inert, and it is a snapshot of the
generator that built this project."
else
  INIT_SH_TIP="You can delete this init.sh now — it has done its job. It is not part of any
repo here, so deleting the file is the whole of it."
fi
if [ -n "$REMOTE_FAILED_REPOS" ]; then
  say "Done — but the backup did not complete."
else
  say "Done."
fi
cat <<EOF

Next step:
  Start your AI agent (Claude Code, Codex, …) in THIS folder — set its working directory
  here, the way you normally launch it. Then send it one message:

      Read AGENTS.md and follow it.

  That's the whole handoff (same command for every project, every agent). It begins the
  kickoff on its own — greets you, creates your local communication profile in
  .throughstone/local-user.md, and helps you write the project brief ($DOCS/overview.md)
  right in the chat. Just describe your idea when it asks.

The agent will interview you, propose a roadmap, and start the architecture STEP.
${INIT_SH_TIP}

Recommended optional backup:
  You can start now; your project is saved locally with Git. For backup, sharing,
  and working from another computer, put the project on a Git host when you're ready.

  GitHub, Bitbucket, GitLab, and other Git hosts all work with the generated repos.
  ${REMOTE_TIP}

  GitHub:
    https://github.com/

  GitHub CLI (optional; lets Throughstone create GitHub remotes for you):
    https://cli.github.com/
EOF

# A remote the user asked for and did not get is a failure, and the exit status has to say so —
# --non-interactive is documented as being for scripts and CI, and a caller reading exit 0 would
# be told the backup exists. The closing instructions above are printed first regardless, because
# the project itself is complete and usable — this report is about the one thing that is not.
# Both layouts behave identically here.
if [ -n "$REMOTE_FAILED_REPOS" ]; then
  # Which names can appear here is decided by the layout, and so is where each one lives. Mono
  # only ever records the bare slug, and its one repository is the workspace root; prompts/ and
  # Code/<slug>-docs/ are folders inside it, not repos to stand in. Multi only ever records the
  # two sibling repos, and its workspace root is not a repository at all. Naming all three in
  # either layout offers one true mapping and two that send the reader nowhere.
  if [ "$LAYOUT" = "2" ]; then
    FAILED_REPO_MAP="Run these from the workspace root, the one repository this project has:"
  else
    FAILED_REPO_MAP="Run these from inside the local repo each name backs up — prompts/ for
  ${SLUG}-prompts, and Code/${SLUG}-docs/ for ${SLUG}-docs:"
  fi
  cat >&2 <<EOF

The remote backup did not complete for:$REMOTE_FAILED_REPOS

  Your project is complete and committed locally — nothing is missing from it and you can
  start work now.

  A failed command tells you it did not finish, not how far it got — so find out before you
  retry. The names above are the repositories on your host, not folders here.
  ${FAILED_REPO_MAP}

    git remote -v
      → is origin attached, and to the URL you meant?
    git ls-remote <that-url> ${TRUNK_BRANCH}
      → is the branch on the remote at all?
    git rev-parse ${TRUNK_BRANCH}
      → if it is, does that commit match the one the line above showed?

  Then do whichever part is left: create the repository on your host, attach it as origin, or
  push to it. Once the branch is there and the commits match, record that URL as remote: on this
  repo's row in Code/${SLUG}-docs/registries/repos.yml if it is not already there — while that
  field is missing, every check-in reports this repo as backed up nowhere.

EOF
  exit 1
fi
