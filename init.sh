#!/usr/bin/env bash
#
# init.sh — one-time bootstrap wizard.
#
# Turns this downloaded template into your project: detaches it from the template's git
# origin, renames the {{PROJECT}} placeholder everywhere, and sets up your repo(s).
# Run it once, from the workspace root, right after downloading.
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

say()  { printf '\n\033[1m%s\033[0m\n' "$*"; }
ask()  { local p="$1" d="${2:-}" a; if [ -n "$d" ]; then read -r -p "$p [$d]: " a; echo "${a:-$d}"; else read -r -p "$p: " a; echo "$a"; fi; }
yesno(){ local a; read -r -p "$1 [y/N]: " a; case "$a" in y|Y|yes) return 0;; *) return 1;; esac; }

# want VALUE PROMPT [DEFAULT] — echo a preset VALUE if non-empty; otherwise prompt for it.
# In --non-interactive mode, fall back to DEFAULT, or exit with an error if there is none.
want() {
  local val="$1" prompt="$2" def="${3:-}"
  if [ -n "$val" ]; then printf '%s' "$val"; return; fi
  if [ "$NONINTERACTIVE" = "1" ]; then
    [ -n "$def" ] && { printf '%s' "$def"; return; }
    echo "init.sh: missing required value (--non-interactive): $prompt" >&2; exit 2
  fi
  ask "$prompt" "$def"
}

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
  --license=NAME        mit | bsd-3 | apache-2.0 | proprietary
  --holder=NAME         Copyright holder (name or org)
  --layout=LAYOUT       multi | mono                    (default: multi)
  --registries=yes|no   Keep registries/ (mono-repo only; default: yes)
  --collab=MODE         solo | team                     (default: solo)
  --adr-authority=TEXT  Who accepts ADRs (team only; default: consensus of maintainers)
  --remotes=yes|no      Create GitHub remotes via gh    (default: no; needs gh)
  --owner=OWNER         GitHub owner/org (required when --remotes=yes)
  -y, --non-interactive Never prompt; error on any missing required value
  -h, --help            Show this help and exit

Env vars (flags take precedence): INIT_SLUG, INIT_DESC, INIT_LICENSE, INIT_HOLDER,
  INIT_LAYOUT, INIT_REGISTRIES, INIT_COLLAB, INIT_ADR_AUTHORITY, INIT_REMOTES,
  INIT_OWNER, INIT_NONINTERACTIVE.
USAGE
}

# --- 0. Parse flags / env (empty preset = "ask") ----------------------------
SLUG_IN="${INIT_SLUG:-}";       DESC_IN="${INIT_DESC:-}"
LICENSE_IN="${INIT_LICENSE:-}"; HOLDER_IN="${INIT_HOLDER:-}"
LAYOUT_IN="${INIT_LAYOUT:-}";   REGISTRIES_IN="${INIT_REGISTRIES:-}"
COLLAB_IN="${INIT_COLLAB:-}";   ADR_AUTHORITY_IN="${INIT_ADR_AUTHORITY:-}"
REMOTES_IN="${INIT_REMOTES:-}"; OWNER_IN="${INIT_OWNER:-}"
NONINTERACTIVE="${INIT_NONINTERACTIVE:-0}"

while [ $# -gt 0 ]; do
  case "$1" in
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
    --remotes=*)       REMOTES_IN="${1#*=}" ;;
    --remotes)         REMOTES_IN="${2:-}"; shift ;;
    --owner=*)         OWNER_IN="${1#*=}" ;;
    --owner)           OWNER_IN="${2:-}"; shift ;;
    -y|--yes|--non-interactive) NONINTERACTIVE=1 ;;
    -h|--help)         usage; exit 0 ;;
    *) echo "init.sh: unknown option: $1 (try './init.sh --help')" >&2; exit 2 ;;
  esac
  shift
done
case "$NONINTERACTIVE" in 1|true|yes|y|Y) NONINTERACTIVE=1 ;; *) NONINTERACTIVE=0 ;; esac

# --- 0b. Preflight: required tools ------------------------------------------
missing=""
for tool in git perl; do command -v "$tool" >/dev/null 2>&1 || missing="$missing $tool"; done
if [ -n "$missing" ]; then
  echo "init.sh: missing required tool(s):$missing" >&2
  echo "  'git' and 'perl' are required; both ship on macOS and nearly every Linux." >&2
  exit 1
fi
command -v gh      >/dev/null 2>&1 || echo "Note: 'gh' not found — the GitHub-remote step will be skipped (you can add remotes later)."
command -v python3 >/dev/null 2>&1 || echo "Note: 'python3' not found — the later setup-workspace.sh will use its plain-shell fallback."

say "Throughstone — setup"

# --- 1. Questions (flags/env pre-answer; otherwise prompt) -------------------
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

# License — accept a friendly token from --license, else ask the two-part question.
LICENSE_CHOICE=""
if [ -n "$LICENSE_IN" ]; then
  case "$(printf '%s' "$LICENSE_IN" | tr '[:upper:]' '[:lower:]')" in
    mit)                        LICENSE_CHOICE=1 ;;
    bsd|bsd-3|bsd-3-clause)     LICENSE_CHOICE=2 ;;
    apache|apache-2|apache-2.0) LICENSE_CHOICE=3 ;;
    proprietary|private)        LICENSE_CHOICE=proprietary ;;
    1|2|3)                      LICENSE_CHOICE="$LICENSE_IN" ;;
    *) echo "init.sh: invalid --license '$LICENSE_IN' (mit | bsd-3 | apache-2.0 | proprietary)." >&2; exit 2 ;;
  esac
elif [ "$NONINTERACTIVE" = "1" ]; then
  echo "init.sh: --license is required in --non-interactive mode (mit | bsd-3 | apache-2.0 | proprietary)." >&2; exit 2
else
  echo "Is this project open source or private/proprietary?"
  echo "  1) Open source"
  echo "  2) Private / proprietary"
  if [ "$(ask 'Choose 1 or 2' '1')" = "2" ]; then
    LICENSE_CHOICE="proprietary"
  else
    echo "Open-source license:"
    echo "  1) MIT           (permissive, simplest)"
    echo "  2) BSD-3-Clause  (permissive + name-endorsement protection)"
    echo "  3) Apache-2.0    (permissive, with patent grant)"
    LICENSE_CHOICE="$(ask 'Choose 1, 2, or 3' '1')"
  fi
fi
HOLDER="$(want "$HOLDER_IN" 'Copyright holder (name or org)')"

# Repo layout — multi (default) or mono.
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

# registries/ is always kept in multi-repo; only optional in mono-repo.
KEEP_REGISTRIES=1
if [ "$LAYOUT" = "2" ]; then
  if [ -n "$REGISTRIES_IN" ]; then
    case "$(printf '%s' "$REGISTRIES_IN" | tr '[:upper:]' '[:lower:]')" in
      y|yes|true|1) KEEP_REGISTRIES=1 ;;
      n|no|false|0) KEEP_REGISTRIES=0 ;;
      *) echo "init.sh: invalid --registries '$REGISTRIES_IN' (yes | no)." >&2; exit 2 ;;
    esac
  elif [ "$NONINTERACTIVE" != "1" ]; then
    yesno "Include registries/ (repo inventory; useful for multi-repo)?" || KEEP_REGISTRIES=0
  fi
fi

# Solo vs. team. This does NOT create a behavioral mode — branch-per-STEP and number
# allocation are practiced solo too (see runbooks/collaboration.md). It only decides whether
# to push for shared remotes now and records who accepts ADRs.
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
    echo "  Heads-up: team collaboration relies on shared remotes —"
    echo "  answer yes to the remotes question next so everyone clones from the same place."
    if [ "$LAYOUT" = "2" ]; then
      echo "  NOTE: you picked mono-repo + team. That works for STEP-number reservation (one"
      echo "  shared repo with a remote), but the overlap warning is repo-granular and so is"
      echo "  meaningless when every STEP touches the one repo. Plan to split into multi-repo"
      echo "  before the team grows — see METHOD.md §7 (\"Mono-repo for now\")."
    fi
  fi
fi

# GitHub remotes (needs gh). Default off; --remotes=yes requires gh and an owner.
MK_REMOTES=0; OWNER=""
if [ -n "$REMOTES_IN" ]; then
  case "$(printf '%s' "$REMOTES_IN" | tr '[:upper:]' '[:lower:]')" in
    y|yes|true|1) MK_REMOTES=1 ;;
    n|no|false|0) MK_REMOTES=0 ;;
    *) echo "init.sh: invalid --remotes '$REMOTES_IN' (yes | no)." >&2; exit 2 ;;
  esac
  if [ "$MK_REMOTES" = "1" ] && ! command -v gh >/dev/null 2>&1; then
    echo "init.sh: --remotes=yes needs the 'gh' CLI, which isn't installed." >&2; exit 2
  fi
elif [ "$NONINTERACTIVE" != "1" ] && command -v gh >/dev/null 2>&1 && yesno "Create GitHub remotes now (via gh)?"; then
  MK_REMOTES=1
fi
[ "$MK_REMOTES" = "1" ] && OWNER="$(want "$OWNER_IN" 'GitHub owner/org')"

# --- 2. Untether from the template origin -----------------------------------
say "Detaching from the template's git history..."
rm -rf "$ROOT/.git"
# The root LICENSE is the Throughstone scaffold's own license (BSD-3-Clause, © Mark A.
# Herschberg). The scaffold files you keep using (METHOD.md, templates/, runbooks/, scripts/)
# stay under it — BSD-3 clause 1 requires retaining the notice — so we DON'T delete it; it's
# relocated into the docs hub as LICENSE-THROUGHSTONE once the hub is renamed (step 3). Your own
# code is covered by the license you choose, stamped into each repo (step 6).
# README.md is Throughstone's own front-door (it documents init.sh and "Use this template").
# Once you've bootstrapped it's stale and template-specific, and in multi-repo mode it would be
# a stray file at the non-repo workspace root, against the hygiene rule (METHOD.md §7). Drop it;
# your project's context lives in the docs hub. (Mono-repo: add a project README yourself if you
# want one.)
rm -f "$ROOT/README.md"
# The community/health files (CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, TRADEMARK) describe the
# Throughstone *template* itself — its contribution policy, its trademark, its security contact.
# They must not carry into your project (e.g. they'd leak the maintainer's contact and assert
# Throughstone's trademark inside your repo). Drop them; add your own project's versions if you want.
rm -f "$ROOT/CONTRIBUTING.md" "$ROOT/CODE_OF_CONDUCT.md" "$ROOT/SECURITY.md" "$ROOT/TRADEMARK.md"
# .github/ holds the Throughstone repo's own issue/PR templates and contact links — they point
# at Throughstone's issues/discussions/security pages and its contribution funnel. They're not
# part of your project; drop them so your repo doesn't inherit them. Add your own .github/ if
# you want issue/PR templates for your project.
rm -rf "$ROOT/.github"
# .dev/ holds template-maintainer-only notes (handoffs, design memos) — not part of your
# project; drop it so internal notes don't leak into bootstrapped repos.
rm -rf "$ROOT/.dev"
# brand/ (Throughstone's brand brief, logo, social card, landing-page source) and docs/ (the
# built landing page served via GitHub Pages) are Throughstone's *own* marketing — they assert
# the Throughstone trademark and aren't part of your project. Drop them so your repo doesn't
# inherit Throughstone's branding or its GitHub Pages site.
rm -rf "$ROOT/brand" "$ROOT/docs"

# --- 3. Replace the {{PROJECT}} token + description -------------------------
say "Renaming {{PROJECT}} -> ${SLUG} ..."
# file contents: the {{PROJECT}} token
grep -rlF '{{PROJECT}}' . --exclude-dir=.git 2>/dev/null | while read -r f; do
  SLUG="$SLUG" perl -pi -e 's/\Q{{PROJECT}}\E/$ENV{SLUG}/g' "$f"
done
# directory name (rename BEFORE the description fill below, so its grep walks the new path)
[ -d "Code/{{PROJECT}}-docs" ] && mv "Code/{{PROJECT}}-docs" "Code/${SLUG}-docs"

DOCS="Code/${SLUG}-docs"

# description: fill {{PROJECT_DESCRIPTION}} EVERYWHERE it appears (AGENTS.md + every
# architecture/planning-session "About" blurb) so no literal placeholder is left dangling.
# The one-liner is just a seed — the kickoff can later expand any of these from overview.md.
grep -rlF '{{PROJECT_DESCRIPTION}}' . --exclude-dir=.git 2>/dev/null | while read -r f; do
  DESC="$DESC" perl -pi -e 's/\Q{{PROJECT_DESCRIPTION}}\E/$ENV{DESC}/g' "$f"
done

# Relocate the scaffold's BSD license into the docs hub (retained as attribution per BSD-3,
# next to the method files it covers — not deleted). Your project's own license is stamped
# separately into each repo in step 6.
[ -f "$ROOT/LICENSE" ] && mv "$ROOT/LICENSE" "$DOCS/LICENSE-THROUGHSTONE"

# --- 4. Prune optional pieces -----------------------------------------------
# runbooks/ is kept: it now ships method-level runbooks (check-in, collaboration) that
# AGENTS.md and METHOD.md reference.
[ "$KEEP_REGISTRIES" = "0" ] && rm -rf "$DOCS/registries" && echo "  pruned registries/"

# Team: record who accepts ADRs (replaces the "_solo author_" placeholder in adr/README.md).
if [ "$COLLAB" = "2" ] && [ -n "$ADR_AUTHORITY" ] && [ -f "$DOCS/adr/README.md" ]; then
  ADR_AUTHORITY="$ADR_AUTHORITY" perl -pi -e 's/\Q_solo author_\E/$ENV{ADR_AUTHORITY}/' "$DOCS/adr/README.md"
  echo "  ADR authority: $ADR_AUTHORITY"
fi

# --- 5. Create the project brief from the template --------------------------
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

# --- 6. Initialise repo(s) --------------------------------------------------
write_gitignore() { # dir
  cat > "$1/.gitignore" <<'GI'
# OS / editor cruft
.DS_Store
*.swp

# Per-machine agent config (not shared)
.claude/settings.local.json

# Local dev secrets — NEVER commit. Commit only .env.example (the documented key list).
.env
.env.*
!.env.example
.secrets/
GI
}
stamp_license() { # dir — write the chosen LICENSE, filling {{YEAR}}/{{HOLDER}}
  local src
  case "$LICENSE_CHOICE" in
    1)           src="$DOCS/templates/licenses/MIT.txt" ;;
    2)           src="$DOCS/templates/licenses/BSD-3-Clause.txt" ;;
    3)           src="$DOCS/templates/licenses/Apache-2.0.txt" ;;
    proprietary) src="$DOCS/templates/licenses/Proprietary.txt" ;;
    *) return 0 ;;
  esac
  [ -f "$src" ] || { echo "  (license source $src missing; skipped)"; return 0; }
  YEAR="$(date +%Y)" HOLDER="$HOLDER" perl -pe \
    's/\Q{{YEAR}}\E/$ENV{YEAR}/g; s/\Q{{HOLDER}}\E/$ENV{HOLDER}/g' "$src" > "$1/LICENSE"
  echo "  license: $1/LICENSE"
}
init_repo() { # dir
  write_gitignore "$1"
  stamp_license "$1"
  ( cd "$1" && git init -q && git add -A && git commit -qm "Initial commit (bootstrapped)" \
    && git branch -M main; )   # pin trunk to main (collaboration.md assumes a 'main' trunk)
  echo "  git repo: $1"
}
make_remote() { # dir reponame
  [ "$MK_REMOTES" = "1" ] || return 0
  ( cd "$1" && gh repo create "$OWNER/$2" --private --source=. --remote=origin --push >/dev/null \
    && echo "  remote: $OWNER/$2" ) || echo "  (skipped remote for $2)"
}

say "Initialising git..."
if [ "$LAYOUT" = "2" ]; then
  init_repo "."
  make_remote "." "$SLUG"
else
  init_repo "$DOCS";     make_remote "$DOCS" "${SLUG}-docs"
  init_repo "prompts";   make_remote "prompts" "${SLUG}-prompts"
fi

# --- 7. Done ----------------------------------------------------------------
say "Done."
cat <<EOF

Next step:
  Start your AI agent (Claude Code, Codex, …) in THIS folder — set its working directory
  here, the way you normally launch it. Then send it one message:

      Read AGENTS.md and follow it.

  That's the whole handoff (same command for every project, every agent). It begins the
  kickoff on its own — greets you, asks your experience level, and helps you write the
  project brief ($DOCS/overview.md) right in the chat. Just describe your idea when it asks.

The agent will interview you, propose a roadmap, and start the architecture STEP.
You can delete this init.sh now — it has done its job.
EOF
