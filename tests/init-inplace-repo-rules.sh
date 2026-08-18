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
#
# `--` before the needle: a needle that starts with "-" (a Markdown list item, say) is otherwise
# read by grep as an option bundle, and grep exits non-zero on the usage error — so the assertion
# fails no matter what the file says, and a bite check on it proves nothing.
assert_contains() {
  local file="$1" needle="$2" message="$3"
  grep -Fq -- "$needle" "$file" || {
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
  if grep -Fq -- "$needle" "$file"; then
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
  local check_in="$docs/runbooks/check-in.md"
  local planning="$docs/templates/planning-session.md"

  # --- One rule, not five. README, CI, licensing, the notice, and remote/visibility are the same
  # rule applied to five artifacts: a repo the method did not create keeps what it already has.
  # Licensing had grown its own doctrine paragraph, which is how the same argument ended up
  # restated in file after file. The heading is pinned because it is what the consumers cite; drop
  # it and their pointers go stale silently.
  #
  # The COUNT is checked against the bullets rather than asserted as a literal. A literal is how
  # this went wrong once already: remote/visibility was added as a fifth bullet while the sentence
  # still said "not four", and the assertion pinned the stale number, so the test agreed with the
  # error instead of catching it. Counting the list means the next bullet either updates the
  # sentence or fails here.
  assert_contains "$docs/METHOD.md" \
    "**A repo the method did *not* create keeps what it already has.**" \
    "METHOD.md §7 lost the single rule the per-artifact consequences hang off"
  local claimed bullets
  claimed="$(sed -n 's/.*This is one rule, not \([a-z]*\)\..*/\1/p' "$docs/METHOD.md")"
  bullets="$(sed -n '/A repo the method did \*not\* create keeps/,/^Every write above/p' \
    "$docs/METHOD.md" | grep -c '^- \*\*')"
  case "$bullets" in
    3) expected=three ;; 4) expected=four ;; 5) expected=five ;;
    6) expected=six ;;  7) expected=seven ;; *) expected="(unhandled: $bullets)" ;;
  esac
  [ "$claimed" = "$expected" ] || {
    echo "FAIL: METHOD.md §7 says \"not $claimed\" but lists $bullets per-artifact bullets" >&2
    return 1
  }
  # Licensing is one of those consequences now, not a separate doctrine with its own rationale.
  assert_absent "$docs/METHOD.md" \
    "**The method records licensing; it never establishes licensing for code it did not create.**" \
    "METHOD.md §7 still gives licensing its own rule instead of one line under the general one"
  # Every write into such a repo goes through one gate, stated once for all the artifacts.
  assert_contains "$docs/METHOD.md" "proposed before it happens" \
    "METHOD.md §7 no longer gates every write into an in-place repo on proposing it first"
  # Only two of the five put a file in the repo. The gate read as though all five were proposals,
  # which made the decline rules below it parse oddly — declining CI or licensing is not a thing,
  # because the method never offered to do them. Naming the two keeps the gate about what it gates.
  assert_contains "$docs/METHOD.md" \
    "**Exactly two of those five put a file in the repo: the README addition, and the Throughstone" \
    "METHOD.md §7 does not say which of the five artifacts actually put a file in the repo"
  # Of those two, only the README addition is asked about. The notice follows automatically — it
  # marks material the owners just agreed to take, so asking again would be asking permission to
  # label what they already said yes to. Pinned because "two writes" reads as "two questions".
  assert_contains "$docs/METHOD.md" "owners. The notice follows from it automatically and is not" \
    "METHOD.md §7 turns the Throughstone notice into a second question of its own"
  # A remote changes only on request — the same answer for a created repo and an in-place one.
  # Stated only as "do not create a remote for one that has one", it implied you may create one for
  # a repo that has none, which is pushing somebody's code to a host they never picked. All three
  # verbs are named because forbidding only one of them is what produced that reading.
  assert_contains "$docs/METHOD.md" \
    "**A repo's remote changes only when the user asks: never created, repointed, or removed as a" \
    "METHOD.md §7 does not require a request before a repo's remote changes"
  assert_contains "$docs/METHOD.md" "missing one; it is a repo whose owners have not put it on a" \
    "METHOD.md §7 still reads a repo with no remote as missing one"
  assert_contains "$planning" "**A remote is created only when the user asks for one**" \
    "planning session does not require a request before a remote is created"
  # The fallback's case list is illustrative. It enumerated only README and licensing cases and
  # would need an edit per artifact added, which is how it fell behind two of them.
  assert_contains "$docs/METHOD.md" "**These are examples, not a" \
    "METHOD.md §7's fallback still reads as an exhaustive list of cases"
  assert_contains "$docs/METHOD.md" "a repo that is already public and whose owners hadn't" \
    "METHOD.md §7's fallback carries no case from the visibility rule"
  assert_contains "$readme_tpl" "license, notice, remote, or visibility" \
    "repo README template's fallback does not cover remote or visibility"
  # And a yes settles the TEXT, not how it reaches their trunk. Four files told an agent to write
  # the Role section and none said what happens next, so the obvious continuation was to commit on
  # whatever branch was out — usually main on a running system — and push. Both halves are pinned:
  # the commit is made and left, and nothing leaves the machine.
  assert_contains "$docs/METHOD.md" \
    "**An accepted write is committed and left there. It is never pushed.**" \
    "METHOD.md §7 does not say how an accepted write into an in-place repo lands"
  assert_contains "$docs/METHOD.md" "never \`git add -A\`, which would sweep up whatever the" \
    "METHOD.md §7 does not scope the commit to the files it names"
  assert_contains "$readme_tpl" "ON A YES, COMMIT IT ON A BRANCH AND STOP." \
    "repo README template does not carry the landing rule to the point of the write"
  assert_contains "$planning" "**On a yes, place the notice, then commit both on a branch and stop.**" \
    "planning session does not say how an accepted write into an in-place repo lands"
  # The commit covers the WRITE, not the PROPOSAL. Two things land on an accepted addition — the
  # README file, and the LICENSE-THROUGHSTONE / LICENSING.md the notice mode places — but only the
  # README is ever proposed, so a commit scoped to "the file(s) proposed" carried one of the two.
  # Measured: the branch held README.md alone and the two notice files sat untracked in the owners'
  # working tree after the agent had been told to stop, so the addition merged without the notice
  # that explains it and the next `git add -A` anyone ran swept them into an unrelated commit.
  # Pinned in all three files: an agent following any one of them alone must still land both.
  for f in "$docs/METHOD.md" "$readme_tpl" "$planning"; do
    assert_contains "$f" "commit every file the method just wrote into that repo" \
      "$(basename "$f") scopes the landing commit to the proposal, not to everything written"
  done
  assert_absent "$docs/METHOD.md" "commit **only the file(s) proposed**" \
    "METHOD.md §7 still scopes the landing commit to the file that was proposed"
  assert_absent "$readme_tpl" "file(s) you proposed (name them; never \`git add -A\`" \
    "repo README template still scopes the landing commit to the file that was proposed"
  assert_absent "$planning" "commit only the file you proposed, never" \
    "planning session still scopes the landing commit to the file that was proposed"
  # ORDER, not just scope. The notice mode has to run before the commit, or its two files are
  # written after the agent has stopped and there is nothing left to put them on a branch. Both
  # files that sequence the two steps say so; the planning session states them in order instead.
  assert_contains "$docs/METHOD.md" \
    "repository. Run it **before** the commit below, so the notice rides the same branch as the" \
    "METHOD.md §7 does not place the Throughstone notice before the landing commit"
  assert_contains "$readme_tpl" "Run it before the branch commit above, so" \
    "repo README template does not place the Throughstone notice before the landing commit"
  # ARCHITECTURE.md is a write at the root of somebody else's repository. It was stated unscoped in
  # §7's general repo paragraph, and the template comment suggesting it is inside the Overview
  # section — which an in-place repo with no README gets written from.
  assert_contains "$docs/METHOD.md" "a repo **the method creates** with real internal complexity" \
    "METHOD.md §7 still tells any repo with internal complexity to add an ARCHITECTURE.md"
  assert_contains "$docs/METHOD.md" \
    "\`architecture/\`, where the project's own docs live, not as a second new file at the root of a" \
    "METHOD.md §7 does not send an in-place repo's internal design to the docs hub instead"
  # The template is the file an agent has open while writing a README for an in-place repo that had
  # none, and its Overview comment called for an ARCHITECTURE.md unconditionally — so §7 said one
  # thing and the file in front of the agent said another. Scoping §7 alone would leave the
  # contradiction exactly where it does the damage.
  # Both branches lead with their scope, in the same caps-led shape as STAMP/AUGMENT above. The
  # affirmative used to open the paragraph with its qualifier fifteen words ahead of the verb, so
  # a reader hit "add an ARCHITECTURE.md at the repo root" while still holding the scope — which
  # is how this reads as a contradiction with the prohibition below it.
  assert_contains "$readme_tpl" "A REPO THIS METHOD CREATED, with real internal complexity, gets one" \
    "repo README template still calls for an ARCHITECTURE.md before naming which repos it means"
  assert_contains "$readme_tpl" "A REPO REGISTERED IN PLACE NEVER GETS ONE" \
    "repo README template does not rule out an ARCHITECTURE.md for an in-place repo"
  # A repo that brought its own ARCHITECTURE.md keeps it — read and link, never rewrite.
  assert_contains "$readme_tpl" "it is theirs: read it, link it from the" \
    "repo README template does not say an in-place repo's own ARCHITECTURE.md is left alone"

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
  # The check-in reads that rule back months later, so it needs the same two branches. A sweep that
  # knows only "augmented" looks for a Role section the write-from-template path never produces,
  # and either reports its absence as a gap — writing into the repo a second time — or files the
  # file under "declined" and stops checking the one README there the method is answerable for.
  assert_contains "$check_in" "check only that the \`Role in $name\` section" \
    "check-in README sweep does not scope the Role-section check to an augmented repo"
  assert_contains "$check_in" "**One that had none** carries a README the method" \
    "check-in README sweep has no branch for a README the method wrote for an in-place repo"
  assert_contains "$check_in" "**Overview** the same way, and still scaffold nothing else there" \
    "check-in README sweep does not check that written README the way a created repo's is checked"
  assert_absent "$check_in" "A repo **registered in place** owns its own README" \
    "check-in README sweep still says every in-place repo owns its own README"
  # A decline carries forward; a yes does not. The gate is per repo because the text is per repo,
  # but the QUESTION behind it is the same one every time — so a project with several in-place
  # repos put the same proposal to the same owners repo after repo, and someone who had already
  # said no got asked again for each remaining one. Both directions are pinned: that a decline can
  # be standing, and that permission is never what carries (a yes for one repo says nothing about
  # the next, whose text nobody has seen).
  assert_contains "$docs/METHOD.md" "**A decline may be standing.**" \
    "METHOD.md §7 re-asks every in-place repo's owners after they have already declined"
  assert_contains "$docs/METHOD.md" \
    "it is the answer that is being reused, never the permission" \
    "METHOD.md §7's standing decline does not rule out carrying a yes forward"
  assert_contains "$readme_tpl" "A DECLINE MAY BE STANDING." \
    "repo README template does not carry the standing-decline rule to the point of the write"
  assert_contains "$readme_tpl" "The permission is never what carries forward, only" \
    "repo README template's standing decline does not rule out carrying a yes forward"

  # --- Remote and visibility. The fifth artifact, and the only one whose failure cannot be
  # reverted: publishing hands a repo's whole history to forks, caches, and crawlers before anyone
  # notices, and setting it private again retrieves none of it. Every other rule here writes a file
  # that `git revert` undoes. It was also the one artifact §7 enumerated nothing for, which is the
  # exact shape of the original defect — a general "not scaffolded at all" followed by a list, read
  # as covering only what the list named.
  assert_contains "$docs/METHOD.md" "**Remote and visibility — its owners'.**" \
    "METHOD.md §7 has no rule for an in-place repo's remote and visibility"
  assert_contains "$docs/METHOD.md" \
    "**Nothing is made public without the user saying so, in words, for that thing.**" \
    "METHOD.md §7 does not state the publishing rule for every repo, created ones included"
  # Inference is the failure mode worth naming: a license, a sibling, or a self-description is not
  # an answer about visibility, and treating one as an answer is how a private repo gets published.
  assert_contains "$docs/METHOD.md" "Never infer it: not from an" \
    "METHOD.md §7's publishing rule does not rule out inferring public from a license or sibling"
  assert_contains "$readme_tpl" "NOTHING IS MADE PUBLIC WITHOUT THE USER SAYING SO." \
    "repo README template does not carry the publishing rule to the point of scaffolding"
  assert_contains "$planning" "take public only from an" \
    "planning session lets a repo be created public without an explicit go-ahead"
  assert_contains "$planning" "**Its remote and its visibility are its own too**" \
    "planning session's in-place paragraph says nothing about remotes or visibility"
  # The same paragraph scoped .gitignore to new repos and .env.example to "each repo" — the loose
  # half would have an agent writing into a repo the method did not create.
  assert_absent "$planning" "into each repo as its" \
    "planning session still copies .env.example into every repo, not only the ones it creates"

  # --- CI. The gate fails until configured, so there is no safe way to land it in a running repo.
  # The rule belongs on the artifact being copied, not only in the files that point at it.
  assert_contains "$ci_workflow" "Never into a repo REGISTERED IN PLACE" \
    "CI workflow template does not carry the never-install rule"
  assert_contains "$ci_readme" "Never install it into a repo registered in place" \
    "CI README does not carry the never-install rule"
  assert_contains "$readme_tpl" "never install it — that repo has its own CI" \
    "repo README template does not carry the never-install rule"
  # Four files send that repo's existing pipeline to the Test Strategy session to be recorded. The
  # session had no instruction to record it and no slot in its output to record it into, so the
  # record they promise had nowhere to land — and a Test Strategy doc listing only the repos the
  # method created reads as though the others have no CI, which is the reverse of why they were
  # left alone. Both halves pinned: the instruction, and the output row it writes into.
  assert_contains "$docs/templates/architecture-sessions/12-test-strategy.md" \
    "**A repo registered in place already has CI, and keeps it.**" \
    "the Test Strategy session does not tell you to record an in-place repo's pipeline"
  assert_contains "$docs/templates/architecture-sessions/12-test-strategy.md" \
    "- **Existing pipelines** — one row per repo **registered in place**" \
    "the Test Strategy session has no output slot for an in-place repo's pipeline"

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
  ! grep -R '{{PROJECT}}' "$readme_tpl" "$ci_workflow" "$ci_readme" "$repos" "$check_in" >/dev/null || {
    echo "FAIL: generated files still carry the {{PROJECT}} placeholder" >&2
    return 1
  }
}

# run_deprecated_registries_case — --registries=no no longer prunes anything, and this pins that.
# The flag's argument was that a self-contained mono-repo root has no sibling repos to inventory,
# which is an argument about repos.yml; the directory also holds risks.yml, the accepted risk
# register METHOD.md §7 requires, and security-reviews.yml, which the security-review runbooks
# read. Pruning removed all three and left the generated project's own docs citing files it did
# not have — 98 references across 24 files, none of them Markdown links, so links.sh and check.sh
# both called it clean. The flag is accepted and ignored so existing scripts keep working, and
# removed in a later release.
run_deprecated_registries_case() {
  local name="inplace-registries-flag"
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
  # All three registries survive the flag, and the one it was ever argued about is named first.
  for reg in repos.yml risks.yml security-reviews.yml; do
    [ -f "$docs/registries/$reg" ] \
      || { echo "FAIL: --registries=no pruned registries/$reg" >&2; return 1; }
  done
  # Ignoring a flag silently is its own defect: a user who passed it is expecting a pruned project.
  grep -Fq -- "--registries is deprecated and ignored" "$TMP_ROOT/$name.out" \
    || { echo "FAIL: --registries=no was ignored without saying so" >&2; return 1; }

  # The generated project must be link-clean the moment it exists.
  ( cd "$docs" && ./scripts/links.sh ) >"$TMP_ROOT/$name-links.out" 2>&1 || {
    echo "FAIL: generated project has broken links with registries/ pruned" >&2
    grep -E "FAIL\]" "$TMP_ROOT/$name-links.out" >&2
    return 1
  }
  assert_contains "$docs/README.md" '| [`registries/`](registries/README.md) |' \
    "docs hub README no longer indexes the registries/ directory it ships"

  # The declined-README fallback names the inventory row plainly now. It used to hedge that a
  # mono-repo project might not keep one, which was true only because this flag could delete it.
  assert_absent "$docs/METHOD.md" "where the project keeps an inventory" \
    "METHOD.md §7 still hedges that a project may not keep an inventory"
  assert_contains "$docs/METHOD.md" "architecture doc — and in the repo's \`repos.yml\` row." \
    "METHOD.md §7's declined-README fallback no longer names the inventory row"
  assert_contains "$docs/runbooks/check-in.md" 'and in its `repos.yml` row (`METHOD.md` §7).' \
    "check-in README sweep no longer names the inventory row plainly"
}

run_case
run_deprecated_registries_case

echo "init.sh registered-in-place repo rules: PASS"
