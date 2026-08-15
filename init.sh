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
choose_license_interactively() {
  local project_type license_input

  while :; do
    echo "Is this project open source or private/proprietary?"
    echo "  1) Open source"
    echo "  2) Private / proprietary"
    project_type="$(ask 'Choose 1 or 2' '1')"
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
  --mode=MODE           new | existing                 (default: new)
                         "existing" adopts an existing codebase (retcon): same scaffold,
                         but the agent reverse-engineers the baseline instead of interviewing it.
  --slug=SLUG            Project slug (lowercase kebab-case, e.g. acme-scheduler)
  --desc=TEXT           One-line description
  --license=NAME        mit | bsd-3 | apache-2.0 | private
  --holder=NAME         Copyright holder (required for open-source licenses)
  --layout=LAYOUT       multi | mono                    (default: multi)
  --registries=yes|no   Keep registries/ (mono-repo only; default: yes; always kept
                         with --mode=existing, which records repos and risks there)
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

Env vars (flags take precedence): INIT_MODE, INIT_SLUG, INIT_DESC, INIT_LICENSE, INIT_HOLDER,
  INIT_LAYOUT, INIT_REGISTRIES, INIT_COLLAB, INIT_ADR_AUTHORITY, INIT_REMOTES,
  INIT_REMOTE_PROVIDER, INIT_OWNER, INIT_REMOTE_URL, INIT_DOCS_REMOTE,
  INIT_PROMPTS_REMOTE, INIT_VISIBILITY, INIT_TRUNK_BRANCH, INIT_NONINTERACTIVE.
USAGE
}

# --- 0. Parse flags / env (empty preset = "ask") ----------------------------
# Every input starts as an env-supplied preset and may be overwritten by a flag below. Empty
# means "not answered yet"; the question phase either prompts, applies a default, or errors in
# --non-interactive mode.
MODE_IN="${INIT_MODE:-}"
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
    --mode=*)          MODE_IN="${1#*=}" ;;
    --mode)            MODE_IN="${2:-}"; shift ;;
    --slug=*)          SLUG_IN="${1#*=}" ;;
    --slug)            SLUG_IN="${2:-}"; shift ;;
    --desc=*)          DESC_IN="${1#*=}" ;;
    --desc)            DESC_IN="${2:-}"; shift ;;
    --license=*)       LICENSE_IN="${1#*=}" ;;
    --license)         LICENSE_IN="${2:-}"; shift ;;
    --holder=*)        HOLDER_IN="${1#*=}" ;;
    --holder)          HOLDER_IN="${2:-}"; shift ;;
    --layout=*)        LAYOUT_IN="${1#*=}" ;;
    --layout)          LAYOUT_IN="${2:-}"; shift ;;
    --registries=*)    REGISTRIES_IN="${1#*=}" ;;
    --registries)      REGISTRIES_IN="${2:-}"; shift ;;
    --collab=*)        COLLAB_IN="${1#*=}" ;;
    --collab)          COLLAB_IN="${2:-}"; shift ;;
    --adr-authority=*) ADR_AUTHORITY_IN="${1#*=}" ;;
    --adr-authority)   ADR_AUTHORITY_IN="${2:-}"; shift ;;
    --trunk-branch=*)  TRUNK_BRANCH_IN="${1#*=}"; TRUNK_BRANCH_FLAG_SET=1 ;;
    --trunk-branch)    TRUNK_BRANCH_IN="${2:-}"; TRUNK_BRANCH_FLAG_SET=1; shift ;;
    --remotes=*)       REMOTES_IN="${1#*=}" ;;
    --remotes)         REMOTES_IN="${2:-}"; shift ;;
    --remote-provider=*) REMOTE_PROVIDER_IN="${1#*=}" ;;
    --remote-provider) REMOTE_PROVIDER_IN="${2:-}"; shift ;;
    --owner=*)         OWNER_IN="${1#*=}" ;;
    --owner)           OWNER_IN="${2:-}"; shift ;;
    --remote-url=*)    REMOTE_URL_IN="${1#*=}" ;;
    --remote-url)      REMOTE_URL_IN="${2:-}"; shift ;;
    --docs-remote=*)   DOCS_REMOTE_IN="${1#*=}" ;;
    --docs-remote)     DOCS_REMOTE_IN="${2:-}"; shift ;;
    --prompts-remote=*) PROMPTS_REMOTE_IN="${1#*=}" ;;
    --prompts-remote)  PROMPTS_REMOTE_IN="${2:-}"; shift ;;
    --visibility=*)    VISIBILITY_IN="${1#*=}" ;;
    --visibility)      VISIBILITY_IN="${2:-}"; shift ;;
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
# init.sh is a one-time bootstrap that crosses a destructive boundary below (it removes .git and
# template-only files). It must run from a fresh, unpacked template checkout — never a second time
# in an already-initialized project (a re-run would delete a mono repo's history, then fail), and
# never on top of an unrelated repo. The root pointers (AGENTS.md / CLAUDE.md) carry a
# THROUGHSTONE-TEMPLATE-GUARD block that step 3 strips during initialization; it is a stable
# sentinel because it contains no {{PROJECT}} token, so — unlike the docs-hub directory name — it
# is never rewritten by placeholder substitution (init.sh substitutes its own {{PROJECT}} too).
# Its absence means this is not a fresh template. Refuse now, before anything is deleted.
if ! grep -qlF 'THROUGHSTONE-TEMPLATE-GUARD' "$ROOT/AGENTS.md" "$ROOT/CLAUDE.md" 2>/dev/null; then
  echo "init.sh: this does not look like a fresh Throughstone template checkout." >&2
  echo "  init.sh is one-time and destructive (it removes .git and template-only files), so it will" >&2
  echo "  not run on an already-initialized project or an unrelated repo — that would delete history." >&2
  echo "  If you are starting over, re-download the template into a fresh, empty folder and run it there." >&2
  exit 2
fi

say "Throughstone — setup"

# --- 1. Questions (flags/env pre-answer; otherwise prompt) -------------------
# Validation-before-destruction invariant: all user input, project-license posture, repo
# layout, collaboration metadata, Git remotes, and visibility are resolved before `.git` or
# template-only files are removed.
#
# Defaults are conservative for automation: multi-repo, solo, private GitHub visibility, and
# no remote creation unless requested.

# New project vs. existing codebase. This is the one fork the installer makes: "new" is the
# greenfield kickoff; "existing" adopts a codebase that already exists (retcon). Both set up the
# same mechanical scaffold below — the only differences land at the end (section 5c): "existing"
# sets PROJECT-STATUS to `retcon` and drops a stub STEP-1 PLAN, then stops so an agent can
# reverse-engineer the baseline from the running code. It is asked, never auto-detected, because
# repo discovery is the agent's job, not the installer's.
if [ -n "$MODE_IN" ]; then
  case "$(printf '%s' "$MODE_IN" | tr '[:upper:]' '[:lower:]')" in
    new|greenfield|1)          MODE=new ;;
    existing|retcon|adopt|2)   MODE=existing ;;
    *) echo "init.sh: invalid --mode '$MODE_IN' (new | existing)." >&2; exit 2 ;;
  esac
elif [ "$NONINTERACTIVE" = "1" ]; then
  MODE=new
else
  echo "Is this a new project, or are you adopting Throughstone into an existing codebase?"
  echo "  1) New project        (greenfield — the agent interviews you to design it)"
  echo "  2) Existing codebase  (retcon — the agent reads your code and reverse-engineers the baseline)"
  while :; do
    case "$(ask 'Choose 1 or 2' '1')" in
      1) MODE=new; break ;;
      2) MODE=existing
         echo
         echo "  Adopting an existing codebase: keep running this from the downloaded Throughstone"
         echo "  folder (a fresh directory), NOT from inside your existing repo. Your code stays"
         echo "  where it is — the agent registers your repos in place later and never rewrites them."
         break ;;
      *) echo "  -> choose 1 for a new project or 2 for an existing codebase." ;;
    esac
  done
fi

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
#
# When adopting an existing codebase the question needs its scope said out loud. The repos being
# adopted already answer "open source or proprietary?" — possibly differently from each other —
# and a user reading the bare question reasonably thinks they are recording that fact about their
# code. They are not: this selection covers the documentation hub being created here and anything
# the method creates later, and their existing repos keep the licensing their owners set (the
# method records licensing, it never establishes it for code it did not create). The same scope
# governs the copyright-holder answer below, which is why the note precedes both.
LICENSE_CHOICE=""
if [ "$MODE" = "existing" ] && [ -z "$LICENSE_IN" ] && [ "$NONINTERACTIVE" != "1" ]; then
  echo
  echo "  The next two answers cover the documentation hub Throughstone is creating for you,"
  echo "  and any repo it creates later — NOT the code you're adopting. Your existing repos keep"
  echo "  whatever licensing they already have; the agent records what it finds, never changes it."
fi
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
if [ -n "$LAYOUT_IN" ]; then
  case "$(printf '%s' "$LAYOUT_IN" | tr '[:upper:]' '[:lower:]')" in
    multi|multi-repo|1) LAYOUT=1 ;;
    mono|mono-repo|2)   LAYOUT=2 ;;
    *) echo "init.sh: invalid --layout '$LAYOUT_IN' (multi | mono)." >&2; exit 2 ;;
  esac
elif [ "$NONINTERACTIVE" = "1" ]; then
  LAYOUT=1
else
  echo "Repo layout:"
  echo "  1) multi-repo now  (prompts/ and Code/${SLUG}-docs/ become separate repos)"
  echo "  2) mono-repo for now  (one repo at the workspace root; split later)"
  LAYOUT="$(ask 'Choose 1 or 2' '1')"
fi

# registries/ is always kept in multi-repo because setup-workspace.sh and remote recording use
# it as the sibling-repo inventory. Mono can prune it because the root repo is self-contained —
# EXCEPT when adopting an existing codebase, where the registries are working state rather than
# inventory: RETCON-PROMPT.md registers every adopted repo in repos.yml and seeds risks.yml from
# the confirmed recon map, so pruning them strands the adoption partway through with no
# instruction. Validate the flag either way, then override, so a bad value is still an error.
KEEP_REGISTRIES=1
if [ "$LAYOUT" = "2" ]; then
  if [ -n "$REGISTRIES_IN" ]; then
    case "$(printf '%s' "$REGISTRIES_IN" | tr '[:upper:]' '[:lower:]')" in
      y|yes|true|1) KEEP_REGISTRIES=1 ;;
      n|no|false|0) KEEP_REGISTRIES=0 ;;
      *) echo "init.sh: invalid --registries '$REGISTRIES_IN' (yes | no)." >&2; exit 2 ;;
    esac
  elif [ "$NONINTERACTIVE" != "1" ] && [ "$MODE" != "existing" ]; then
    yesno "Include registries/ (repo inventory; useful for multi-repo)?" || KEEP_REGISTRIES=0
  fi
  if [ "$MODE" = "existing" ] && [ "$KEEP_REGISTRIES" = "0" ]; then
    KEEP_REGISTRIES=1
    echo "  note: keeping registries/ — adopting an existing codebase records repos and risks there."
  fi
fi

# Solo vs. team. This does NOT create a behavioral mode: branch-per-STEP, STEP-number
# reservation, and overlap checks are practiced solo too (see runbooks/collaboration.md). The
# answer only affects prompt wording, remote guidance, and the ADR acceptance authority stamped
# into adr/README.md.
if [ -n "$COLLAB_IN" ]; then
  case "$(printf '%s' "$COLLAB_IN" | tr '[:upper:]' '[:lower:]')" in
    solo|1) COLLAB=1 ;;
    team|2) COLLAB=2 ;;
    *) echo "init.sh: invalid --collab '$COLLAB_IN' (solo | team)." >&2; exit 2 ;;
  esac
elif [ "$NONINTERACTIVE" = "1" ]; then
  COLLAB=1
else
  echo "Working solo for now, or collaborating with others from day one?"
  echo "  1) Solo for now  (team conventions switch on later; nothing here locks you in)"
  echo "  2) Team from day one"
  COLLAB="$(ask 'Choose 1 or 2' '1')"
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
      echo "  NOTE: you picked mono-repo + team. That works for STEP-number reservation (one"
      echo "  shared repo with a remote), but the overlap warning is repo-granular and so is"
      echo "  meaningless when every STEP touches the one repo. Plan to split into multi-repo"
      echo "  before the team grows — see METHOD.md §7 (\"Mono-repo for now\")."
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

# The repo inventory records what each repo is licensed under, so fill the seed rows with the same
# posture. These two repos are ones init.sh creates, so the posture IS their license. A repo
# registered in place later records what that repo already says instead (registries/repos.yml).
grep -rlF '{{PROJECT_LICENSE}}' . --exclude-dir=.git 2>/dev/null | while read -r f; do
  PROJECT_LICENSE_ID="$PROJECT_LICENSE_ID" perl -pi -e \
    's/\Q{{PROJECT_LICENSE}}\E/$ENV{PROJECT_LICENSE_ID}/g' "$f"
done

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

# --- 4. Prune optional pieces -----------------------------------------------
# runbooks/ is kept: it now ships method-level runbooks (check-in, collaboration) that
# AGENTS.md and METHOD.md reference.
[ "$KEEP_REGISTRIES" = "0" ] && rm -rf "$DOCS/registries" && echo "  pruned registries/"

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
  # The seeded PROJECT-STATUS marker is what AGENTS.md/status.sh route on — and the literal that
  # retcon's §5c flips. If the template's marker text ever drifts, that routing silently breaks
  # (and §5c's substitution would no-op), so verify the seed took before anything depends on it.
  grep -q '<!-- PROJECT-STATUS: not-started -->' "$DOCS/overview.md" || {
    echo "init.sh: overview.md is missing the seeded '<!-- PROJECT-STATUS: not-started -->' marker" >&2
    echo "        (overview-template.md may have drifted). Aborting before the project ships mis-routed." >&2
    exit 1; }
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

# --- 5c. Existing-codebase adoption (retcon) --------------------------------
# "existing" mode reuses the whole scaffold above (the STEP index stays the greenfield-identical
# seed — STEP-1 + 1.1–1.14, all Planned — so check.sh stays clean and status.sh's `retcon` branch
# is the only new resolver logic). It adds just two things, then stops: flip the status marker to
# `retcon`, and drop a stub STEP-1 PLAN whose substeps are the inventory work. All discovery — find
# & register repos, classify docs, build the recon map, harvest the sessions — is agent-driven
# behind RETCON-PROMPT.md, routed by the `retcon` status.
if [ "$MODE" = "existing" ]; then
  # Order matters here: seed the stub STEP-1 PLAN FIRST, then flip the status marker. The `retcon`
  # marker is a promise that the resolver (RETCON-PROMPT.md) has an in-flight PLAN to resolve —
  # RETCON-PROMPT.md reads that PLAN as a precondition and cannot rebuild it — so the marker must
  # never be set unless the PLAN it points at exists.
  #
  # Seed the stub STEP-1 PLAN at the SAME in-flight path greenfield uses, so the Cross-Cutting
  # Review and later check-ins find it where they look. Its substeps are the inventory work;
  # RETCON-PROMPT.md upgrades it by addition once the inventory is confirmed. {{PROJECT}} was
  # already substituted in step 3; fill {{DATE}} with the adoption date here.
  mkdir -p "$ROOT/Upcoming Prompts"
  # The stub template ships with the scaffold and step 3 never removes it, so a missing one means
  # the download is incomplete or corrupt. Abort loudly BEFORE flipping the marker rather than
  # shipping a `retcon` project with no PLAN — that state would route every agent to
  # RETCON-PROMPT.md and then dead-end it (nothing to resolve, and no way to regenerate the stub).
  if [ ! -f "$DOCS/templates/retcon-step-1-plan-stub.md" ]; then
    echo "init.sh: the retcon stub STEP-1 PLAN template is missing:" >&2
    echo "        $DOCS/templates/retcon-step-1-plan-stub.md" >&2
    echo "        Your scaffold download looks incomplete — re-download the Throughstone template" >&2
    echo "        and rerun ./init.sh. (The marker was not flipped; nothing routes to retcon yet.)" >&2
    exit 1
  fi
  TODAY="$(date +%Y-%m-%d)" perl -pe 's/\Q{{DATE}}\E/$ENV{TODAY}/g' \
    "$DOCS/templates/retcon-step-1-plan-stub.md" > "$ROOT/Upcoming Prompts/${SLUG}-STEP-1-PLAN.md"
  echo "  retcon: seeded stub STEP-1 PLAN (Upcoming Prompts/${SLUG}-STEP-1-PLAN.md)"
  # With the PLAN in place, flip the kickoff gate from the seeded `not-started` to `retcon` (see
  # overview-template.md). This flip is the single most load-bearing line in retcon: it is what
  # routes every agent and status.sh into adoption. A silent no-op (marker text drifted, so the
  # substitution matched nothing) would ship `not-started` and run the greenfield kickoff against
  # existing code — so verify it took, mirroring the precondition guard on the seeded overview
  # marker in §5.
  perl -pi -e 's/<!-- PROJECT-STATUS: not-started -->/<!-- PROJECT-STATUS: retcon -->/' "$DOCS/overview.md"
  grep -q '<!-- PROJECT-STATUS: retcon -->' "$DOCS/overview.md" || {
    echo "init.sh: failed to set the retcon PROJECT-STATUS marker in overview.md" >&2
    echo "        (overview-template.md may have drifted). Aborting so the project does not ship" >&2
    echo "        routed to the greenfield kickoff instead of retcon adoption." >&2
    exit 1; }
  echo "  retcon: PROJECT-STATUS set to 'retcon' (adopting an existing codebase)"
  # Scaffold the pre-answer-sheet scratch folder. RETCON-PROMPT.md's per-session harvest (Stage 3)
  # drops one transient sheet per in-scope session here; seeding it now gives that a home and makes
  # the AGENTS.md marker-loss fallback signal reliable from adoption start.
  mkdir -p "$ROOT/Upcoming Prompts/retcon"
  cat > "$ROOT/Upcoming Prompts/retcon/README.md" <<'RETCON_SCRATCH_README'
# Retcon scratch — pre-answer sheets

Transient working folder for **retcon adoption** (see `RETCON-PROMPT.md`). During the per-session
harvest, each in-scope architecture session gets a **pre-answer sheet** here — one drafted answer per
decision, with provenance tags — which the confirm pass consumes before the clean `architecture/`
doc is written. Start each sheet from your docs hub's `templates/retcon-preanswer-sheet.md`.

Scratch, not project history: these sheets are not committed, and they are discarded when STEP-1
lands. Their presence here (alongside the in-flight STEP-1 PLAN) is also how a fresh agent detects a
retcon in progress if the `PROJECT-STATUS` marker is ever lost.
RETCON_SCRATCH_README
  echo "  retcon: scaffolded pre-answer-sheet scratch (Upcoming Prompts/retcon/)"
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

# Per-machine agent config (not shared)
.claude/settings.local.json

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
init_repo() {
  write_gitignore "$1"
  stamp_license "$1"
  write_licensing_summary "$1"
  ( cd "$1" && git init -q && git add -A && git commit -qm "Initial commit (bootstrapped)" \
    && git branch -M "$TRUNK_BRANCH"; )
  echo "  git repo: $1"
}

# record_registry_remote REPO_NAME REMOTE_URL — update registries/repos.yml after a remote is
# attached and pushed. The registry is the multi-repo clone inventory, so mono-repo and pruned-registry
# setups can safely no-op.
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
    s{(^[ \t]*-[ \t]*name:[ \t]*"\Q$ENV{REPO}\E"[^\n]*\n(?:(?!^[ \t]*-[ \t]*name:).)*?^[ \t]*type:[^\n]*\n)}
     {$1 . qq{    remote: "$qremote"\n}}ems;
  ' "$reg"
}

# commit_registry_remotes — persist registry remote URLs after all multi-repo remotes exist.
# The docs repo is already initialized before this runs; recording in a second commit avoids
# claiming remote URLs before creation/push has actually succeeded.
commit_registry_remotes() {
  local reg="$DOCS/registries/repos.yml"
  [ "$MK_REMOTES" = "1" ] || return 0
  [ "$LAYOUT" = "1" ] || return 0
  [ -f "$reg" ] || return 0
  if git -C "$DOCS" diff --quiet -- registries/repos.yml; then
    return 0
  fi
  ( cd "$DOCS" && git add registries/repos.yml && git commit -qm "Record bootstrap remotes" )
  echo "  registry: recorded bootstrap remotes"
  if git -C "$DOCS" remote get-url origin >/dev/null 2>&1; then
    ( cd "$DOCS" && git push -q origin "$TRUNK_BRANCH" && echo "  registry: pushed remote updates" ) \
      || echo "  (could not push registry remote updates; push ${DOCS} manually later)"
  fi
}

# setup_remote DIR REPONAME MANUAL_URL — create/attach and push a remote.
# GitHub mode creates a repo with gh. Manual mode attaches an existing remote URL from any Git
# host and pushes the initialized trunk branch. MADE_REMOTE_URL is a small out-parameter used
# only by the multi-repo registry recorder.
setup_remote() {
  MADE_REMOTE_URL=""
  [ "$MK_REMOTES" = "1" ] || return 0
  if [ "$REMOTE_PROVIDER" = "manual" ]; then
    [ -n "${3:-}" ] || return 1
    if ( cd "$1" && git remote add origin "$3" && git push -u origin "$TRUNK_BRANCH" >/dev/null ); then
      MADE_REMOTE_URL="$3"
      echo "  remote: $3"
      return 0
    fi
    echo "  (could not push remote for $2; check that the remote exists, is empty, and accepts your credentials)"
    return 1
  fi
  if [ "$REMOTE_PROVIDER" = "github" ]; then
    if ( cd "$1" && gh repo create "$OWNER/$2" "--$REMOTE_VISIBILITY" --source=. --remote=origin --push >/dev/null ); then
      MADE_REMOTE_URL="$(git -C "$1" remote get-url origin 2>/dev/null || true)"
      echo "  remote: $OWNER/$2"
      return 0
    fi
    echo "  (skipped remote for $2)"
    return 1
  fi
  echo "  (skipped remote for $2; unknown provider '$REMOTE_PROVIDER')"
  return 1
}

# reuse_root_origin DIR — attach the preexisting empty root origin to a mono-repo project.
# Multi-repo never calls this: the root stops being a durable repo, so reusing its origin for
# docs or prompts would publish the wrong repository shape.
reuse_root_origin() {
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
  ( cd "$1" && git remote add origin "$ROOT_ORIGIN" )
  echo "  remote: reused existing origin ($ROOT_ORIGIN)"
  if [ "$MK_REMOTES" = "1" ]; then
    ( cd "$1" && git push -u origin "$TRUNK_BRANCH" >/dev/null \
      && echo "  pushed: $ROOT_ORIGIN" ) || echo "  (could not push existing origin; push manually later)"
  fi
  return 0
}

say "Initialising git..."
if [ "$LAYOUT" = "2" ]; then
  # Mono-repo: the initialized project is the workspace root. Reuse an empty non-template root
  # origin when safe; otherwise create/use a fresh remote if requested.
  init_repo "."
  if [ "$REMOTE_PROVIDER" = "manual" ] && [ -n "$REMOTE_URL" ]; then
    setup_remote "." "$SLUG" "$REMOTE_URL"
  else
    reuse_root_origin "." || setup_remote "." "$SLUG" ""
  fi
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
say "Done."
# The handoff command is identical in both modes ("Read AGENTS.md and follow it"); only what the
# agent does next differs — greenfield kickoff interview vs. retcon adoption of existing code.
if [ "$MODE" = "existing" ]; then
  cat <<EOF

Next step:
  Start your AI agent (Claude Code, Codex, …) in THIS folder — set its working directory
  here, the way you normally launch it. Then send it one message:

      Read AGENTS.md and follow it.

  That's the whole handoff (same command for every project, every agent). This project is set
  up to ADOPT your existing codebase (retcon): the agent reads the retcon front door
  (RETCON-PROMPT.md), asks a few intake questions (where your repos/docs are, how deep to go),
  then inventories your system and reverse-engineers the architecture baseline WITH you —
  confirming what it finds rather than interviewing from a blank page.

The agent builds a recon map of what you already have, then Throughstone-shaped architecture
docs describing it; forward work starts at STEP-2 once that baseline lands. It creates your
local communication profile in .throughstone/local-user.md along the way.
You can delete this init.sh now — it has done its job.
EOF
else
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
You can delete this init.sh now — it has done its job.
EOF
fi
cat <<EOF

Recommended optional backup:
  You can start now; your project is saved locally with Git. For backup, sharing,
  and working from another computer, put the project on a Git host when you're ready.

  GitHub, Bitbucket, GitLab, and other Git hosts all work with the generated repos.
  If you did not set up remotes during init, create empty repos on your host, add
  their URLs to registries/repos.yml, and push each local repo's ${TRUNK_BRANCH} branch.

  GitHub:
    https://github.com/

  GitHub CLI (optional; lets Throughstone create GitHub remotes for you):
    https://cli.github.com/
EOF
