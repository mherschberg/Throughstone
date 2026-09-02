# Changelog

All notable changes to Throughstone are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this
project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). Versions here
refer to the **Throughstone scaffold** (the method, templates, runbooks, and tooling), not to
any project built with it.

## [Unreleased]

> **Withdrawn (2026-08-19).** Work on how the method treats a repository it did **not** create —
> whether it applies a license, whether it stamps or augments a README, whether it installs CI, and
> where it records what it found — was developed on `main` between 2026-08-15 and 2026-08-19 and has
> been backed out. It was being built without a settled design, so it is being re-planned as its own
> piece of work and will return in a later release. If you cloned `main` during that window, your
> copy carries an unfinished version of it. **No tagged release was affected**; the latest release
> remains v1.7.1.

### Added
- **A runbook for splitting a repository** — `runbooks/splitting-repos.md`. The method used to say
  splitting was "standard git," which is not something you can act on: the recipe you find
  elsewhere makes the extracted repo *new*, with its history rewritten by `git filter-repo`, a
  tool that never ships with git and needs Python on every install route. The runbook writes down
  a different mechanic — clone the whole repo and delete forward — so nothing is rewritten, both
  sides keep the full history, and `git blame`, `git log --follow` and every commit SHA your
  project has recorded keep working in the new repo on day one. It covers both cases behind one
  routing block: splitting a code repo in two, and converting a mono-repo-for-now workspace to
  multi-repo. It asks three questions before you start and the rest at the step that needs them;
  every one but the mapping itself has a default, so answering "use your judgement" still produces
  a correct split. The one real cost is stated plainly in the file: every new repo inherits every
  blob the origin ever committed, including deleted ones, and an appendix covers purging first when
  that matters.
  Split-out repos can now record where they came from, in a `provenance:` block on their
  `registries/repos.yml` row.

  Shipping with it: **the rule telling you to split before adding a second contributor is gone.**
  It gave two reasons and neither survived. The STEP-number push-race works exactly the same in a
  mono repo with a shared remote — what a team needs is shared remotes, not several of them — and
  the overlap warning's mono fallback was already written, in the very section that clause cited.
  How many repos you have follows your architecture, not your headcount. The solo-to-team section
  of `runbooks/collaboration.md` now has a mono path of its own, including the warning not to run
  `scripts/setup-workspace.sh` in a mono clone; `METHOD.md` §7 and `prompts/README.md` moved with
  it, the first gaining the mono→multi special case (that STEP is branchless, and its number is
  reserved on trunk) and the second generalizing its thin-STEP note from the check-in alone to two
  families.
- **Repo rows record who owns each repo and what it already provides.** `registries/repos.yml`
  gains three per-row fields. **`origin:`** (`created` | `adopted`) says whether Throughstone made
  the repo or took on one that was already there — a fact, written once when the repo is
  registered, that never changes. **`control:`** (`managed` | `external`) says whether Throughstone
  may write into that repo: `managed` is a standing permission, asked once per repository and never
  per file, while `external` means the repo is recorded and referenced in full and never written
  into. Control is a state that changes over time rather than a fact about who created the repo, so
  a repo the method built can be handed over and a repo it never built can be placed under its
  care. **A missing `control:` reads as `external`**, because control is a permission and an
  unanswered permission is not granted — the repo is recorded, and nothing is written into it until
  somebody answers. **`provides:`** records how each of the three things a repo needs — a README, a
  stated licensing posture, a described CI gate — is actually met there, as a status (`ours`,
  `extended`, `theirs`, `N/A`, `gap`) and a note; `gap` and `N/A` must say why. It goes only on
  rows whose `location` is a repository, and never on a row the setup script seeds — a status
  written before anyone had looked at the repo would be a guess rather than a record. Two
  invariants hold across the pair: a `managed` repo has no `gap` — either the need is met, or the
  repo is `external` — and an `external` repo has no `ours` and no `extended`. The registry's
  header carries the whole schema, the default, and the five rules anything reading or rewriting
  that file has to follow, because it is read by scripts that match line prefixes and do not parse
  YAML. `mono` joins the `type:` enum for the workspace root of a mono-repo-for-now project.
  Existing rows are not rewritten — `UPDATING-THROUGHSTONE.md`'s 1.8 section covers adding the
  fields to a project you already have.

- **`apply-project-license.sh --notice-only <repo>`** — write the Throughstone notice into a
  repository and nothing else. The script's one mode writes three files keyed on the project's
  license posture: the notice, a `LICENSING.md` summary, and the project `LICENSE` for an
  open-source project. There was no way to ask for just the notice, which is what a repository the
  method did not create needs — Throughstone-authored material there should say what it is, but
  that project's own licensing is not ours to state. The new mode reads no posture, writes only
  `LICENSE-THROUGHSTONE`, never touches the target's `LICENSE` or `LICENSING.md`, and leaves a
  notice that is already there exactly as it is, whatever it says: a differing notice is the
  ordinary state a re-run meets after the notice text changes, not a conflict to resolve. If the
  notice cannot be written it says so and still returns success, so a caller is never stopped by
  it. The existing mode is unchanged, including every case where it refuses to overwrite a file it
  did not write.

- **The rule for a repository the method did not create, written down.** Repo rows have recorded who
  owns each repo and what it already provides since earlier in this release, and nothing said what any
  of it *meant* or how to do it — so registering a repository meant reconstructing a registry row from
  memory. `METHOD.md` §7 now carries the model. **Control is a permission**, granted once for a whole
  repository and never per file: `managed` means the method may write what its needs require into that
  repo without asking again, `external` means the repo is recorded and referenced in full and never
  written into, and an unanswered `control:` reads as `external`. The invariant follows — a repo the
  method controls has its needs met, so an unmet need can only sit on one it does not control. A repo
  has **three needs**: a README (someone standing in it can find their way back to the project), a CI
  gate that is *recorded* — including "nothing runs" — and a licensing posture that is recorded,
  including "nothing states one". One ladder runs per need and asks nothing, because permission was
  settled once. Only the README has rungs: a repo with no README gets one stamped, a repo whose README
  does not point back gets a short `## Role in <project>` section added to it, and no repo ever ends up
  with two READMEs. **The ladder never installs CI and never applies a license** — both are scaffolding
  the method writes when it *creates* a repo. Dropping the starter gate into a repository that already
  has one would replace the gate guarding its merges, and choosing a license for code the method did
  not write is not the method's to do; a managed repo with no CI at all is recorded as exactly that,
  which is not a shortfall to fix but a fact to know. Registering a repo makes it **known and
  connected — never conformant, and never good**: a thin README or a linter-only gate is recorded as
  what it is, and improving it is ordinary forward work.
- **A runbook for registering a repository** — `runbooks/register-repo.md`, carrying the procedure the
  model implies: the steps, the two checks before writing into a repository the method did not create
  (a clean work tree with an attached HEAD, and not nested inside another repository's work tree — both
  record what they found and skip, and neither aborts), what makes the action safe to re-run, the
  default when nobody answers, promotion and handover, and the exact wording of the question that asks
  whether the method may write into a repo. It maintains a repo's registry row and its entry in the
  Architecture Overview architecture doc **together** — they are one unit and neither moves without the
  other — so the Architecture Overview session now records a Repos section, and completes a document
  that already exists rather than overwriting it. Everything that changes the set of repositories a
  project has goes through this one procedure, which is why the files that used to describe a registry
  row can name the procedure instead.

### Changed
- **STEP-1 branches, and STEP projections, follow control rather than layout.** STEP-1 work takes the
  `step-0001-architecture` branch in **every** repository it writes into — previously the docs hub and
  `prompts/` in a multi-repo project, or the root repo in mono-repo-for-now, which left a repository
  that already existed and is now under the method's control with no branch rule at all. And a
  repository the method only *references* never appears in a STEP's Repos projection: a STEP is work
  the method does, in repositories it controls. The repo it references stays fully documented — a
  registry row, statuses, notes and an Architecture Overview entry — just never worked in.
- **The doctor now checks the repo registry, and a bad row fails the build.** `registries/repos.yml`
  records who owns each repo and what it already provides, and until now nothing read any of it. A
  row could say Throughstone controls a repo *and* that one of that repo's needs is unmet — a
  combination the file's own schema forbids — and the project would report clean. `scripts/check.sh`
  gains three checks. The first reads the file only, so it holds everywhere the doctor runs, CI
  included: statuses come from the closed set, `origin:` and `control:` do too, a `managed` repo has
  no `gap`, an `external` repo has no `ours` or `extended`, and `gap` and `N/A` say why. The second
  looks at disk: a row whose `location` is the root of a git work tree, and that Throughstone adopted
  rather than created, has to record what that repo provides — naming the individual missing entry
  rather than the row, because an entry is left out on purpose while the observation is still owed.
  Rows whose location is not on the machine running the doctor are skipped, counted, and said out
  loud, since silence about them is indistinguishable from a pass. Missing fields are a warning;
  fields that contradict each other are a failure.
  The third check is about the file's shape rather than its contents, and it closes a real hole: the
  scripts that read this registry match line prefixes and know nothing about YAML nesting, so a note
  written across several lines whose text happened to begin `location: /srv/acme/LICENSE` made
  `scripts/setup-workspace.sh` clone a repository into that path — exit 0, no warning. The registry's
  header has carried rules against this since the fields were added; three of the five are properties
  of the file and are now enforced. Values must be single-line, `provides:` entries must be flow
  mappings, no line inside a row may begin with a row-level field name, and row-level and nested
  names stay disjoint. Those fail rather than warn: a violation is a clone to the wrong folder, not
  a thin record. The two remaining rules constrain the scripts rather than the file and stay prose,
  because a checker reading the registry cannot see them.
  The reserved name sets are read from the registry header's own `reserved-row-level:` and
  `reserved-nested:` lines, so there is one list, it sits where the schema is, and removing or
  overlapping it fails loudly instead of quietly disarming the checks.
  `scripts/check.sh` also gains its first test.

- **The interactive setup no longer licenses your project open source by default.** `init.sh` asks
  whether the project is open source or private/proprietary, and that question used to default to
  open source, with the license question after it defaulting to MIT — so two bare Enters granted
  everyone an irrevocable license to the project's code without the user ever naming one. The
  project-type question now defaults to **private / proprietary**, which writes no project
  `LICENSE` at all and leaves the decision to be made deliberately later. The open-source
  sub-question keeps its MIT default: by the time it is asked, open source is an explicit choice.
  Nothing changes for `--license=…` or `--non-interactive`, which have always required the posture
  to be stated. Existing projects are unaffected — their posture is already recorded in
  `.throughstone/project-license`.
- **The README and website now tell you to clone the latest *release*, not `main`.**
  `git clone --branch v1.7.1 …` gives you the 1.7 release; `main` is where Throughstone itself is
  built and can carry unfinished work. The "Use this template" path is flagged as unable to be
  pinned to a release, since GitHub always copies the default branch.
- **A session template's go-ahead now fires on being *invoked*, not on being *read*.** Every
  `templates/architecture-sessions/*.md` closed with "Begin now — in this same reply", which treated
  the act of opening the file as the user's go-ahead. But session files are read by more than the
  agent running the session: the Cross-Cutting Review enumerates every conditional to check
  applicability, the periodic check-in re-evaluates them, and a reader that only wants a session's
  work list has no business starting an interview. The paragraph now opens **"If you were sent here
  to run this session…"** and closes by releasing a reader who wasn't — same behavior when a session
  is actually invoked, no reliance on the reader's own framing to resist the instruction otherwise.
- **One work-list heading across every session template.** `13-glossary.md` used "What to produce
  (work through these)" and `14-cross-cutting-review.md` used "What to check"; both now use
  **`## Decisions to make (in order)`**, like the other fifteen, with a note under the heading saying
  what that session's items actually are (term batches; checks that may surface a decision). Anything
  reading a session file now finds the work list under one name instead of learning a per-file name.
  `METHOD.md` §4 records the skeleton as part of the contract for adding a session, and a new
  maintainer test enforces it.
- **`registries/` now ships with every project, and `--registries` is deprecated.** The flag pruned
  the directory in mono-repo layout, on the reasoning that one self-contained repo has no siblings
  to inventory. But `registries/` is not only `repos.yml`: pruning it also took `risks.yml`, the
  accepted-risk and tech-debt register, and `security-reviews.yml`, the security-review ledger —
  two registers that reasoning never covered, and that the docs hub's own index, `METHOD.md` and
  several runbooks reference unconditionally. A project bootstrapped with `--registries=no` started
  life citing files it did not have, and `scripts/check.sh` called it clean. The directory now
  always ships, in both layouts, and the interactive mono-repo question offering to drop it is
  gone. `--registries` still parses, so an existing scripted bootstrap keeps working: `yes` is
  accepted silently, `no` keeps the directory and prints a deprecation notice, and an unrecognized
  value is an error. That last part is a small behavior change — the value used to be checked only
  in mono-repo layout, so `--registries=maybe --layout=multi` was silently accepted and now fails
  the way mono-repo already did.
- **The process docs now name the registration action instead of describing a registry row.** Eight
  shipped files still told an agent to go write a `registries/repos.yml` row by hand, or swept "all
  repos" as though every one of them were on the machine. `AGENTS.md`, the substep prompt template
  and `runbooks/collaboration.md` §8 now say *register it* and point at `runbooks/register-repo.md`;
  none of them knows a field name any more, so they stay correct when the fields change — which is
  the exact way the previous attempt at this rotted. The STEP plan template and the STEP index seed
  record that a repository the method only references never appears in a STEP's Repos projection.
  Two files change what they actually do. **The check-in's repo-README sweep is now driven by the
  row**: the whole file where the method wrote that README, only the `## Role in <project>` section
  where it augmented somebody else's, and nowhere else at all — there it edits nothing and re-asks
  the one question the README answers for the project, whether someone standing in that repo can
  still find their way back. The "do the setup steps still work from a clean checkout" check is
  deliberately dropped for repositories the project does not own, since that is a judgement about
  their repo rather than about our connection to it. The check-in also treats a registry row and its
  Architecture Overview entry as **one** thing that drifts — re-run the registration, never edit
  either by hand — and stops re-asking the licensing question per repository, which is settled once
  for the whole project. **`runbooks/collaboration.md` §9's solo-to-team remote setup is scoped to
  repositories the method created**: as written it would have created a second remote for a
  repository someone else owns and pushed their history into it.
  Three read-only sweeps — the check-in's full test run, the dependency audit, and the incident
  runbook's hunt for similar issues — asked for "all repos" and now ask for every repo you can
  reach, with the unreachable ones named. The failure that guards against is not missing a
  repository; it is a partial sweep that reads as a complete one.
- **The planning session stops judging a repository by its README.** Its repo-scaffolding step
  decided whether a repo the architecture names already existed by reading that repo's README — a
  repo counted as already there only if it had a registry row **and** a README whose role one-liner
  and Overview were filled in. That is a test of prose, and it failed in the direction that costs
  you something: **a real repository with a thin README was judged absent and scaffolded over**,
  which means a stack, a CI workflow, an `.env.example`, a `.gitignore` block and possibly a
  license written into somebody's existing work. The step now asks the two questions that actually
  answer it — is this repo already registered, and if not, is there a repository at that location,
  meaning a repository's own work-tree root rather than a folder that looks finished. Asking the
  registry first means a repo the project already knows about is never re-created, **including one
  that is registered but not cloned on this machine**, which a disk test on its own would report
  absent. Where no repository is found the step creates one exactly as before, with the whole
  scaffolding list unchanged. Where one is found, **no stack wiring, no CI, no `.env.example`, no
  `.gitignore` block and no project `LICENSE`** go into it, and it is registered instead — what
  does land there is the registration action's call. Either way it goes through that one action,
  which writes the registry row and the Architecture Overview entry together — a STEP's work, as
  the creating always was; the session decides and outlines, and writes only the STEP-index rows.
  A greenfield
  first run is unchanged:
  nothing is registered and no location holds a repository, so every repo is created exactly as it
  is today.

- **The check-in cadence advises and proposes; it never becomes the next action.** `METHOD.md`
  §10 is a first-match-wins list, and rule 7 — the check-in cadence — sat between "plan the next
  STEP" and "the phase is complete". `scripts/status.sh` never implemented it, so an overdue
  project got `OVERDUE; insert a Check-in STEP now` on one line and `plan STEP-41` on the next,
  which reads like the tool contradicting itself. The resolution is not a new resolver branch.
  Rule 7's own wording puts the check-in "at the next sensible breakpoint", and a rule that fired
  the moment a project went overdue would fire mid-feature — the one place §5 says not to put
  one. So §10 now says plainly that rule 7 is the exception to first-match-wins: the cadence is
  reported *alongside* the next action and never in place of it, it never blocks work, and no
  rule below it is skipped because a check-in is due. `status.sh` prints it that way — when the
  cadence is due or overdue it offers a Check-in STEP under the next action, marked as advice,
  and the next action itself is untouched. `OVERDUE (>25); insert a Check-in STEP now.` loses its
  imperative and becomes `OVERDUE (>25).`, with the proposal carrying the suggestion instead.
  `prompts/README.md` no longer describes a due Check-in STEP as something the resolver answers
  with. `tests/status-checkin-cadence.sh` now holds both halves of the contract, so a gate cannot
  creep back in.

### Fixed
- **Two rules now say what they left to inference.** `runbooks/check-in.md` says to tell the agent
  *"run the check-in"*, while `METHOD.md` §10 says an in-progress STEP runs only the substep you
  ask for by name — and a check-in has two substeps. Nothing said whether that phrase authorised
  both or only planned the STEP. It runs both, end to end: the substeps are fixed, the runbook is
  their prompt, and there is nothing to approve between them. Both documents now say so, and §10
  marks it as the one STEP invoked whole. Separately, §7's path convention said a reference
  "follows the file it is written in" and then defined that only for documents inside the docs
  hub, leaving `prompts/README.md` — the one document the scaffold ships outside it — without a
  stated base. It is the root of its own repository.
- **A substep is no longer mistaken for a conditional architecture session it has nothing to do
  with.** When `scripts/status.sh` points you at an optional architecture session, it suggests the
  by-name phrase to invoke it with — and it worked out which session by searching the label for a
  keyword, anywhere in the text. So a substep called `Authoring conventions & style guide` was
  advised as *"run the identity-auth session"*, because *auth* sits inside *Authoring*, and
  `Desktop publishing pipeline` was pointed at the native-app session. Anchoring alone would not
  have fixed the second — that label genuinely does begin with *desktop* — so the match is now
  against the session's own name rather than a loose keyword. A label matching none of them falls
  back to the generic "invoke it by name", which was always correct advice. This is the same
  defect as the check-in title match above, in the four remaining places it appeared.
- **A note written into a roadmap row no longer deletes the row.** `prompts/STEP-index.md` ships
  full of instructional HTML comments and invites you to annotate it, but `scripts/status.sh`
  skipped any *line* containing one. So a comment inside a row removed that row from everything
  the helper knows: `| STEP-2 | Build | | In progress | <!-- waiting on design --> |` made the
  STEP in flight invisible, and the helper answered as though nothing were being built. A note on
  the highest-numbered row was worse — it also lost the project's high-water mark, so a phase with
  `Planned` work left reported "Every STEP in the index is final". `scripts/check.sh` said nothing
  in either case, and nobody writing the note had any reason to expect it. Comments are now
  stripped from the line rather than taking the line with them. Example rows that sit wholly
  inside a comment block are still ignored, which is the only thing this behaviour was ever for.
- **The check-in cadence line no longer names the same STEP on both sides of the line.** With the
  default cadence of 20, a project 25 STEPs past its last check-in is overdue — that is what
  "OVERDUE at N+5" means. But `scripts/status.sh` printed `OVERDUE (>25)` while firing *at* 25,
  and the sentence one branch above called 15–25 the DUE window when 25 was already out of it.
  Both bounds now read as they behave: `DUE (you're in the 15–24 window)` and `OVERDUE (25+)`.
  The thresholds themselves are unchanged.
- **A STEP that merely mentions a check-in no longer counts as one.** `scripts/status.sh` measures
  the cadence from the last `Done` STEP it recognises as a check-in, and it recognised one by
  looking for the words *check* and *in* anywhere in the Title. So a bug STEP called `Fix the
  check-in report generator` at STEP-30 turned `OVERDUE, 26 STEPs ago` into `~14 STEPs of
  headroom` — and `runbooks/check-in.md`'s own Carry-forward step is exactly what produces bug
  STEPs named after the check-in that found them. `Add checkinventory endpoint` matched too. The
  mirror held as well: the clock depended on those words appearing in the Title, and that
  requirement was written down nowhere, so a descriptively-titled check-in was invisible to it.
  The contract is now stated — **the row's Title begins `Check-in`**, optionally followed by a
  scope (`Check-in: phase 1`) — in `METHOD.md` §5, `runbooks/check-in.md`,
  `templates/planning-session.md` and `prompts/README.md`, and the match is anchored to it. This
  is the same shape the method already used for `Conditional session: <topic>`, which
  `status.sh` has always matched anchored twelve lines above. Case is ignored and Markdown
  emphasis is allowed, because every document that states the rule writes the phrase in bold.
  An existing project whose check-in rows are titled some other way needs one rename each;
  `UPDATING-THROUGHSTONE.md` says which spellings still count and what it costs to skip it — the
  cadence line does not go quiet, it keeps measuring from whatever older row still qualifies, so
  the advice is wrong rather than absent.
- **An answer the setup wizard does not understand is no longer read as "no".** `init.sh` asks
  three yes/no questions, and the helper behind them accepted only `y`, `Y` and `yes` — everything
  else fell to a catch-all that meant no. So `YES`, `Yes`, `1` and `true` each silently declined,
  most consequentially at "Set up online Git remotes now?", where declining is the answer you
  cannot correct without doing the work by hand afterwards. Every other question in the wizard
  re-asks on an answer it does not recognise; this one did not, and the inconsistency was more of
  the defect than the vocabulary was. It now re-asks in the same voice as its siblings, and the
  words it accepts are the ones `--remotes=` and `--registries=` already took — through a single
  `normalize_yesno`, so a typed answer and a flag value cannot drift apart, the same way
  `normalize_layout` and `normalize_collab` already work.
  **A required answer left blank is re-asked too.** `--non-interactive` refuses a missing
  description; the interactive path accepted one, which made the friendlier route the one that
  let an empty value through — into `AGENTS.md`, `templates/planning-session.md` and every
  architecture session template. A blank copyright holder did the same to an open-source project,
  shipping `Copyright (c) 2026 ` with nothing after it in every generated repo, with the doctor
  reporting no failures. End of input still ends the run rather than looping: an exhausted answer
  stream takes the advertised default at a yes/no question and exits 2 with the missing prompt
  named at a required one.
- **The check-in report template has somewhere to record deferred coverage.** An architecture doc
  may deliberately leave part of its area unwritten, marked in its `Coverage:` field.
  `runbooks/check-in.md` treats that as a standing obligation — the deferral must be "resurfaced,
  not silently forgotten", so every check-in re-reads it, weighs it against what the system now
  does, and records one explicit disposition — and the runbook's own Output list names a
  **Deferred coverage** bullet as part of the report. The report template had no such section.
  The one place it said "Deferred" was a conditional-session disposition, which the runbook goes
  out of its way to distinguish. So the sweep the runbook mandates had nowhere to land, and the
  gap it exists to keep visible would rest on the same passive line in the same doc. The template
  now carries a **Deferred Coverage** table beside **Conditional Coverage**, in the runbook's own
  order, with the four things its Output bullet asks for: the doc, what its `Coverage:` field
  says, the disposition, and the follow-up STEP filed or retained.
- **`./doctor.sh --help` now mentions `--check-in`.** `scripts/check.sh` has two behaviours — the
  checks it makes on every run, and the extra ones the periodic check-in adds — and the flag that
  selects the second was named in the script's own header, in `METHOD.md`, in
  `runbooks/check-in.md` and in the generated CI workflow, but in no help text anywhere. Someone
  who came to the dispatcher to find out what it could do could not learn that half of `check`
  existed. It is now in the command list and in the examples.
- **A mistyped argument to a helper is no longer silently ignored.** `scripts/check.sh` has always
  rejected an option it does not know, with exit 2. `scripts/status.sh`, `scripts/links.sh` and
  `scripts/setup-workspace.sh` read no arguments at all, so anything passed to them was discarded
  without a word — `./doctor.sh status --check-in` ran an ordinary status report and exited 0, and
  a flag aimed at the wrong helper looked like it had worked. The dispatcher's own `help` arm did
  the same: `./doctor.sh help --nonsense` printed the help text and exited 0, treating the
  argument as understood. All four now report the argument and exit 2, so one entry point behaves
  one way. Every valid invocation is untouched, `--check-in` included.
- **A short check-in cadence no longer prints a negative window.** The check-in window is the
  project's `CHECK-IN-CADENCE` plus or minus 5, so a cadence of 5 or less put its left edge at
  zero or below: `scripts/status.sh` reported things like `DUE (you're in the -2–8 window)`, and
  it said so from the STEP the check-in happened on — a project that had just checked in was
  told it was due for another. The lower edge is now floored at 1. This only ever raises the
  threshold, so any cadence of 6 or more — which is every value the documentation uses — behaves
  exactly as before.
- **The architecture STEP's close-out is no longer skipped.** `scripts/status.sh` decided STEP-1
  was finished by counting substeps, and ignored the STEP-1 row's own status. But the row is what
  records completion: the Cross-Cutting Review runs, STEP-1 is archived to `prompts/`, and only
  then does the row flip to `Done` — "once the review is clean", as the review session itself puts
  it. So the window between the last substep going `Done` and the row being flipped is not a
  glitch, it is where the close-out work lives, and a review with open findings sits in it by
  design. In that window the resolver reported "Architecture (STEP-1) complete" and sent you
  straight to the planning session, contradicting an index that still said `In progress` — while
  `METHOD.md` §10 ends by making the index authoritative for which STEP is next. It now names the
  close-out as the next action and quotes the row status back to you, and it is unchanged when the
  row reads `Done`, `Deferred` or `Abandoned`, or when there is no STEP-1 row at all.
- **Scheduling a check-in no longer counts as having done one.** `scripts/status.sh` measures the
  check-in cadence from the highest-numbered STEP whose title looks like a check-in — but it
  ignored that row's status. So when the cadence line said `OVERDUE; insert a Check-in STEP now`
  and you did exactly that, the new `Planned` row immediately reported `0 STEPs ago — ~15 STEPs of
  headroom`, before the check-in had happened. Acting on the advice cleared the advice, and the
  sweep it exists to schedule could be postponed indefinitely without the cadence ever noticing.
  Only a `Done` check-in resets the clock now; `Planned` and `In progress` rows are the work, not
  the record of it.
- **A zero-padded check-in cadence no longer kills `./doctor.sh status`.** `overview.md`'s optional
  `<!-- CHECK-IN-CADENCE: N -->` marker is meant to be edited by hand. Writing `08` or `09` aborted
  `scripts/status.sh` outright — `[ 08 -gt 0 ]` reads base 10 and passed the guard, but `$(( 08 - 5 ))`
  reads octal and fails — so the whole next-action resolver printed nothing and exited 1. `010`
  did not fail; it silently meant 8, moving the check-in window from ~15–25 to ~3–13 with no
  indication. `scripts/check.sh` check 10 flagged both, but told the reader something untrue:
  "status.sh falls back to the default (20)", which it did not do. status.sh now reads the marker
  with check 10's own pattern, so a marker check 10 rejects is a marker status.sh ignores, and
  check 10's sentence is accurate.
- **A slug that cannot work is refused before anything is destroyed.** `init.sh` is one-time and
  destructive: from "Detaching from the template's git history" onward it has removed `.git` and
  started renaming. Two slug problems were only discovered after that point, by `mv` or `cp`
  failing. A slug of 251 characters passed the pattern check and then failed the rename with
  `File name too long`, leaving no `.git`, no `prompts/STEP-index.md` and a half-renamed tree —
  which `scripts/check.sh` still called `RESULT: OK`, and which `scripts/status.sh` answered with
  "run ./init.sh", advice that produced a *second* broken layer rather than recovering. An
  existing `Code/<slug>-docs` was worse than a collision: `mv` moved the template *inside* it, so
  the tree ended up at `Code/<slug>-docs/{{PROJECT}}-docs/`. Slug length and destination
  availability are now checked with the pattern, before the run touches anything, and the three
  copies of the pattern check are one function so the flag path and the interactive re-ask cannot
  drift apart. Slugs are capped at 64 characters — a practical ceiling well under both the 250 the
  filesystem allows and what any git host accepts.
- **A flag written without its value no longer eats the flag after it.** `init.sh` accepts both
  `--desc=text` and `--desc text`. In the space form it took whatever came next as the value
  without checking, so `--desc --layout=mono` set the description to `--layout=mono`, left
  `--layout` unset, and built a **multi-repo** project when mono was asked for — then wrote that
  bogus description into `AGENTS.md`, `templates/planning-session.md` and every architecture
  session template. Nothing caught it: the wizard exited 0 and `scripts/check.sh` reported
  `0 fail(s), 0 warning(s)`, because the tree it produced was a valid project, just not the one
  requested. Only the flags that happen to validate their value — `--slug`, `--layout`,
  `--license` — refused, and they refused by accident; the free-text ones (`--desc`, `--holder`,
  `--adr-authority`, `--owner`, the remote URLs) took it silently. Every space-form flag now
  checks its value before using it, and says which flag is short and what to write instead. The
  `--flag=value` form is untouched, so a value that genuinely begins with `--` is still sayable.
- **The last few "run this" instructions run.** `METHOD.md` told you to run `scripts/check.sh`
  after renaming a session and offered `scripts/status.sh` as the shortcut a resuming agent runs
  first; `UPDATING-THROUGHSTONE.md` said to run `scripts/check.sh` in three places. None of those
  exists from the workspace root, where the reader is — each exited 127. They now name
  `./doctor.sh check` and `./doctor.sh status`, which sit at the root and are the front door the
  dispatcher advertises. Deliberately unchanged: the many sentences in hub documents that *name*
  a helper rather than tell you to run one — `runbooks/check-in.md`'s note that
  `scripts/check.sh --check-in` makes two registry checks, and the like. A document inside the hub
  writes the hub's own contents hub-local, and those are references, not commands.
- **`AGENTS.md` keeps the promise it opens with, and the ADR duplicate scan finds duplicates.**
  `AGENTS.md` tells its reader that its paths are relative to the workspace root and that "every
  path below can be used as-is" — then wrote roughly twenty of them relative to the docs hub
  instead. The costly one was a command: an agent is told to scan the ADR register for duplicate
  numbers before every push, and from the workspace root that scan named a file that isn't there,
  so it printed nothing and exited 0 — indistinguishable from the clean result the surrounding
  prose describes. Two more copies of the same scan, in `runbooks/collaboration.md` and
  `adr/README.md`, failed the same silent way; a shell command is written from the workspace root
  in every document, hub-local ones included. All three now find a seeded duplicate. The prose
  paths follow: `overview.md`, `METHOD.md`, `registries/repos.yml`, `runbooks/register-repo.md`,
  `BOOTSTRAP-PROMPT.md`, `inputs/inputs-index.md`, the architecture overview, the three helper
  scripts and the ADR register are written in full, and the conditional-session templates now name
  the directory that holds them. What stays bare stays bare on purpose — `architecture/`,
  `inputs/` and `adr/` name areas rather than things to reach, which is what §7 says a bare name
  is for.
- **The rest of the tools print paths you can open.** The path convention says a path a tool
  prints follows the reader, not the tool, and the release above applied it to `scripts/check.sh`
  and `scripts/setup-workspace.sh` — the two scripts the rule happened to name. `scripts/status.sh`
  was not among them and never derived the docs hub's location at all, so the helper a resuming
  agent runs *first* named `overview.md`, `BOOTSTRAP-PROMPT.md`, `templates/planning-session.md`,
  `templates/release-notes-template.md` and `METHOD.md` from inside the hub while answering someone
  standing at the workspace root. It also told you to `run scripts/check.sh`, which fails from
  there; it now names `./doctor.sh check` and `./doctor.sh status`, the front door the dispatcher
  advertises. Three hints in `check.sh` and the mono half of the setup wizard's closing tip were
  the same shape — the wizard's multi half, four lines below, already wrote the full path. §7's
  clause no longer lists the two scripts it applies to: what a tool prints is read from where the
  reader is, which is true of every helper here and any added later.
- **Instructions in the docs now work from the directory they tell you to stand in.** Six of them
  did not. The first line of the periodic check-in told you to run `scripts/check.sh --check-in`,
  which fails from the workspace root where you actually are — and that one is on the path anyone
  walks regularly. So did the setup a new contributor is told to run, two of the split's pre-swap
  checks, its teammate-clone verification, and the sentence the split copies into a README handed
  to people still holding a clone of the old repo. Each now names the script the way
  `scripts/setup-workspace.sh`'s own usage header always has: from the workspace root, in full.
  Two warnings that name a script you must *not* run got the same treatment, because a warning has
  to identify the program unambiguously too.

  Behind them, the path convention in `METHOD.md` §7 sorted documents into two piles and put
  `runbooks/` in neither — which is where most of the unfollowable instructions lived. It now turns
  on what a path is *for*. A shell command is written from where the text stands you, the workspace
  root unless the text says otherwise; everything else follows the file it is written in, which
  inside the docs hub means relative to the hub. It also settles what "relative to the hub" is
  measured from, what a bare `status.sh` or `architecture/` means, and that a Markdown link target
  follows Markdown rather than either convention — so a sweep cannot quietly break your links.
  `AGENTS.md` had copied the old wording into its own header and drifted from it; it now states
  where its paths are relative to and points at the rule instead of restating it.
- **The doctor no longer answers in two directories at once.** `scripts/check.sh` does not change
  your working directory, so you read its output from wherever you ran it — normally the workspace
  root — but it named some files from there and others from inside the docs hub, occasionally
  within a single check: the repo-registry check headed itself with one form and then named the
  same hub the other way two lines below. Every path it prints, and every path
  `scripts/setup-workspace.sh` prints, is now written from the workspace root, so you can open what
  it names without working out which base it meant. The setup wizard's two prompts that named a
  file inside the docs hub now name it in full as well, using your project's real name.

  Also fixed: an agent following `AGENTS.md` was told to scan `adr/README.md` for duplicate ADR
  numbers before every push — a file that is not there from where the agent is standing. Its
  sibling scan of `prompts/STEP-index.md` was always correct, because `prompts/` really does sit at
  the workspace root.
- **One repository you cannot clone no longer costs you the whole workspace.**
  `scripts/setup-workspace.sh` is what every developer after the first runs to assemble the project
  on their machine: it clones the repos `registries/repos.yml` gives a `remote:`, then writes the
  workspace root's `AGENTS.md`, `CLAUDE.md` and `doctor.sh`. A clone that failed aborted the run
  before it reached those files, so the contributor ended up with **no workspace at all** — over a
  repository they may not even need. Three ordinary situations did it, all measured: a remote nobody
  on the team can reach, a stray folder or half-finished clone already sitting where a repo should
  go, and a `location:` left behind as an absolute path from the first developer's machine. A failed
  clone is now reported and the run continues; the pointer files are written before the clone step
  rather than after it; and the closing line says how many repos did not arrive instead of reporting
  plain success. Fix a bad `remote:` or `location:`, or clone that repo by hand, and re-run — repos
  already cloned are left alone.
- **A `location:` outside the workspace root is no longer cloned into.** An absolute path, or one
  reaching out with `..`, is now reported and skipped. It used to be used verbatim, so a registry
  naming a path that happened to be writable placed a repository *outside* the workspace silently,
  at exit 0 — and that is the ordinary shape whenever a repo is registered where it already lives
  instead of created as a `Code/*` sibling. A `location:` that stays inside the workspace root still
  clones exactly as before, including one outside the `Code/*` shell, and a repo already checked out
  where its `location:` points is still left untouched. A repo registered outside the workspace root
  is one each contributor clones onto their own machine, once; `METHOD.md` §7 and the registry
  header carry the narrower rule.
- **`init.sh` could destroy a repository it was run inside.** Unpacking the template into a
  repository you already had — the natural thing to try when you want Throughstone in a project
  that exists — and running `./init.sh` there deleted that repository's `.git` outright, every
  commit with it, at exit code 0 and with no warning. Your working files survived; your repository
  did not. The bootstrap is one-time and destructive by design — it removes the template's own git
  history and every template-only file — so it now establishes that it is looking at a fresh
  template checkout *before* it removes anything, and refuses with an explanation when it is not.
  The marker in the root pointers cannot answer that on its own, because an unpacked template
  brings those files along with it, so git is asked too — and only when there is a `.git` in the
  folder to lose. A checkout counts as fresh when its committed history is the template's own and
  it tracks nothing the template does not ship, or when it has no commits, no branches and nothing
  staged. Every documented setup route still works untouched: a fresh unpacked download, a clone of
  a release tag, a "Use this template" repo, and `git init` beside the template to attach an empty
  origin. Covered by `tests/init-fresh-template-guard.sh`, which derives the template's root-entry
  list from the template itself so the check cannot go stale.
- **A generated repo's ignore file named one per-machine agent file instead of matching the family.**
  Every repo `init.sh` creates ignored `.claude/settings.local.json` exactly, so an editor's lock or
  autosave sibling (`#settings.local.json#`, `settings.local.json~`) — per-machine files, all of
  them — was left untracked and swept in by a `git add -A`. Throughstone's own repository moved off
  the by-name rule for this reason and the generated one did not follow. Now matched by pattern.
  Shared project config (`.claude/settings.json`) is still committed, so this narrows what leaks
  without narrowing what a team can share.
- **`init.sh`'s closing backup tip was wrong for a mono-repo project.** It told every project to
  "create empty repos on your host, add their URLs to `registries/repos.yml`, and push each local
  repo's `main` branch" — which is what `runbooks/collaboration.md` §9 expressly tells a mono
  project *not* to do, since no row in that file is a repo to clone. The tip is now
  layout-conditional: mono is told to create one repo, push the root repo's trunk, and leave the
  registry rows alone. The mono + team kickoff note stopped citing the repealed
  split-before-a-teammate rule in the same change — the observation under it still holds
  and is still printed, but it now points at the fallback `collaboration.md` §4 prescribes rather
  than telling you to split.
- **`11-interface-contracts.md` punctuation drift.** Its go-ahead paragraph had ASCII hyphens where
  every sibling file had em dashes — identical wording otherwise. Now byte-identical to the rest.
- **Lifting a document into `architecture/` could fail the check that guards it.**
  `inputs/README.md` told you to add the `Version` / `Status` header when lifting a spec or finished
  design doc, but omitted the **Version Log** — which `scripts/check.sh` check 4 requires of every
  numbered architecture doc, and which a document written outside the method almost never arrives
  with. All three fields are now named at the point of the lift.
- **The STEP index's status legend didn't mention `N/A`.** A substep whose area structurally doesn't
  apply (the UI session on an API-only system) is marked `N/A` — accepted by `check.sh` and skipped
  by the next-action resolver — but the legend listed only the five STEP states, so the one place a
  reader checks before writing a status didn't describe a value the file legitimately contains.
- **A `Coverage:` line could be a bare word that told a later reader nothing.** The field records
  that a doc deliberately describes only part of its area, and every check-in resurfaces it for a
  decision — but `METHOD.md` §6 and the architecture doc template both showed it as a lone token
  (`deferred`), so the reader who meets it months later can't tell whether the gap blocks them, and
  the check-in has nothing to weigh. Both now require one sentence: what is missing, how big it is,
  and what it means for someone building on the doc, written as an ordinary bold header field
  (`**Coverage:** deferred — …`).
- **The deferred-coverage sweep looked for a string the docs don't contain.** `runbooks/check-in.md`
  told the check-in to enumerate architecture docs "carrying `Coverage: deferred`" — but the field is
  written like every other header field, so the literal phrase never appears, and now that its value
  is a sentence it is further still from matching. The sweep now reads the `Coverage:` **field** and
  takes anything other than `full`, which is what stops a deferral from quietly becoming permanent.
- **A mono-repo project's method-integrity gate had never run.** `method-check.yml` ships inside the
  docs hub, at `Code/<project>-docs/.github/workflows/`. In a multi-repo project the hub is its own
  repository, so that path is a repository root and the workflow is live the moment you push it. In
  a mono-repo-for-now project the workspace root is the repository and the hub is a folder inside
  it — and GitHub reads workflows only at a repository root, so nothing ever triggered and no run
  ever appeared to be missing. The manual copy was documented, but only in the workflow's own header
  comment and `templates/ci/README.md`, neither of which is where you look to find out whether your
  CI exists. `init.sh` now places the workflow at the workspace root when it creates a mono-repo
  project, and the docs hub keeps its own copy, which is what gives the hub CI of its own if the
  project later splits. `init.sh` runs once and never again, so nothing places the file in a project
  that already exists: `UPDATING-THROUGHSTONE.md`'s 1.8 section carries the one-file copy as a
  migration step, and says plainly that the first run is likely to report findings that have been
  accumulating unseen.
- **A mono-repo project's registry left out the only repository it had.** `registries/repos.yml`
  calls itself the source of truth for which repos exist, and in a mono-repo-for-now project it
  listed the docs hub and `prompts/` — both folders — while the workspace root, the project's one
  actual repository and the only git work tree in it, had no row at all. `init.sh` now seeds that
  row: `location: "."`, `type: mono`, `origin: created`, `control: managed`, and no `provides:`,
  which is the carve-out every seeded row gets. No script reads the row and no tooling behaves
  differently because of it — `scripts/check.sh`, `scripts/links.sh` and the clone parser in
  `scripts/setup-workspace.sh` were each measured against it, and the parser passes over the row
  because it carries no `remote:`. Prose describing a mono project's registry rows as folders
  inside the single repo has been corrected wherever it appeared — the registry header, the setup
  script's closing tip, the solo-to-team runbook and this file. Existing projects are not rewritten.

## [1.7.1] - 2026-08-10

A small follow-up that gives the **`inputs/` folder** (added in 1.7.0) a lifecycle, so brought-in
documents don't quietly go stale as the generated `architecture/` docs supersede them.
Greenfield-inert: a fresh project ships an empty ledger and behaves exactly as before.

### Added
- **Inputs index** (`Code/{{PROJECT}}-docs/inputs/inputs-index.md`) — a ledger that records, per
  input, which parts a generated `architecture/` / `adr/` doc has superseded and which still hold
  (section-level where the input's structure allows, whole-doc otherwise). It is written when an
  input is imported and when a session captures its content.
- **`inputs/archive/` retirement** — a fully-superseded input is *moved* there (a move, never an
  edit or a delete); sessions read `inputs/` but not `inputs/archive/`, so a captured document stops
  reading as current intent while it is kept for history.
- **Check-in inputs sweep** — the periodic check-in reconciles the ledger against the architecture
  docs, surfaces a newly-superseded input for a retire/keep decision (never auto-moving), and
  records the outcome in the check-in report.

### Changed
- **Inputs are point-in-time; `architecture/` is the living truth.** Where a generated
  `architecture/` or `adr/` doc covers the same ground as an input, the generated doc wins.
  Architecture-grade inputs are lifted into `architecture/` promptly — a PRD synthesized, a
  protocol/API spec or other finished doc copied or lightly reformatted — rather than left living in
  `inputs/`. The system-overview, architecture-overview, substep, and implementation-planning
  reminders now read live inputs (not `inputs/archive/`) and treat them as a starting point, not
  current truth.

## [1.7.0] - 2026-08-10

A **base-refactor** release that generalizes the method. It
removes assumptions baked in for brand-new, MVP-first projects, so the method also fits later
phases, re-runs, custom conventions, and existing codebases. **Two opt-outable default shifts**
(the doc-maturity ladder and the check-in cadence); nothing existing is force-migrated.

### Added
- Optional **`Coverage:`** field on architecture docs (`full` / `deferred` / `enumerated to
  depth N`) — records a deliberately partial area without abusing `Status`.
- **`inputs/` folder** (`Code/{{PROJECT}}-docs/inputs/`) — a durable home for documents *you*
  provide that inform the design: product specs / PRDs, prior or external architecture/design
  docs, protocol/API specifications, UI designs and mockups, prior-art research. The kickoff and
  every architecture session read the relevant inputs and build on them instead of re-deriving
  what you already know; a document handed to the agent in chat is saved into `inputs/` so it
  persists across the fresh-chat-per-session model. Not STEP-1-only — later phases and check-ins
  can add to it, and the implementation planning session and substep template point at it too.

### Changed
- **Method version → 1.0** (from `0.4 (beta)`): with the base-refactor generalizations in this
  release, the core method graduates from beta; the collaboration and scaffold-update layers keep
  maturing.
- **Architecture-doc metadata decoupled** into three independent header facts: **`Version`**
  (identity; `major` = a breaking architectural change, no longer a maturity "era", so a house
  version scheme is fine), **`Status`** (maturity), and optional **`Coverage`** (completeness).
  The **doc-maturity ladder is redefined `Draft → Current → Deprecated`**, retiring the `MVP` and
  `Stable` rungs; the periodic check-in no longer reconciles `Status: Deprecated` docs.
- **Periodic check-in resurfaces deferred coverage:** the check-in now runs a **deferred-coverage
  sweep** — every non-`Deprecated` architecture doc carrying `Coverage: deferred` gets an explicit
  disposition each check-in (backfill now / still defer / seed a `Planned` backfill STEP + a
  tracked `risks.yml` risk), and a thin architecture-only STEP finishes the doc when it's time. A
  `Deprecated` deferred doc is listed as retired, never backfilled. Greenfield-invisible unless a
  doc marks `Coverage: deferred`.
- **Phase 1 is a chosen first milestone, not always an MVP:** Phase 1 is now defined as *the first
  release-level milestone*, with its kind chosen at kickoff — **MVP / POC / prototype / v1**, MVP
  recommended but no longer assumed. The chosen name drives both the phase label
  (`## Phase 1 — <name>`) and the phase folder (`prompts/001-<phase-name>/`). The pre-named
  `prompts/001-mvp/` folder is **no longer shipped** — the phase folder is created at STEP-1
  archive time from the index heading's name (an MVP archives to `001-mvp/`, a POC to `001-poc/`),
  with no `status.sh` / `check.sh` change (they key on index rows, not folder names). Greenfield
  that takes the MVP suggestion is byte-identical; kickoff now asks one question instead of
  assuming.
- **Release/launch stage is a recorded project fact:** the method now separates a project's
  **release stage** — how widely and to whom the system ships (pre-launch → internal → closed /
  public beta → GA) — from Phase-1 *scope* (MVP / POC / v1) and doc *maturity* (Draft / Current /
  Deprecated); the three no longer collapse into "MVP." `overview.md` gains an optional **Release
  stage / launch target** line and kickoff asks it (leading with a pre-launch default). Architecture
  sessions now calibrate their **breadth** defaults (how big / how public) to the recorded stage +
  load and their **rigor** (security, privacy, availability) to blast radius / data sensitivity,
  instead of an assumed "MVP" — an early stage is never a license to lower rigor on a high-stakes
  system. Additive and opt-outable: the decisions and recommendations are unchanged if you take the
  default, and `check.sh` never reads the line. No `status.sh` / `check.sh` / STEP-grammar change.
- **Planning session scaffolds only unregistered repos:** the implementation planning session's
  repo-scaffolding work-item is now **existence-aware** — it scaffolds each repo the architecture
  names only if that repo isn't already registered in `registries/repos.yml` with a filled-in README;
  an already-registered repo is **left in place, not re-created**. It degrades gracefully when
  `repos.yml` is absent or has no code-repo rows (a mono-repo, or a greenfield first run) — nothing is
  registered, so every named repo scaffolds exactly as before. Because it keys on the repo's actual
  state (is it already registered?) rather than how the project began, it also stops a planning
  **re-run** from proposing to re-scaffold an existing repo. Greenfield
  first run is byte-identical; no `status.sh` / `check.sh` / STEP-grammar change.
- **Planning STEP-shape is milestone-relative:** the implementation planning session's STEP sequence
  is no longer written build-from-scratch. It now plans to **build or extend what the milestone needs,
  in dependency order, given what already exists** — scaffolding and the core data layer come first
  only when they don't exist yet (a first run), with the scaffold → data → capabilities → integration
  sequence kept as the worked example for that case; a re-run or a later phase starts from what's built
  and extends it. Like the existence-aware scaffolding above it keys on observable state (what's
  already built), so it also fixes a latent greenfield **re-run / later-phase** case where the old
  shape read as rebuild-from-scratch. Greenfield first run is byte-identical (nothing built → the same
  scaffold-first outline); no `status.sh` / `check.sh` / STEP-grammar change.
- **Planning session targets the first uncompleted phase:** the implementation planning session now
  plans **the first uncompleted phase** — the lowest-numbered roadmap phase whose STEPs aren't all
  complete (read from `prompts/STEP-index.md` + the Phasing & Roadmap doc) — instead of always
  **Phase 1**, defaulting to Phase 1 on the first run. On a later phase or a re-run it reads *that*
  phase's scope and outlines *its* STEPs, rather than being told to pull "Phase 1." Like the two
  planning-session changes above it keys on observable state (which phase is done), so it also fixes a
  latent greenfield **later-phase** case. Greenfield first run is byte-identical (the first uncompleted
  phase is Phase 1 → the same outline); no `status.sh` / `check.sh` / STEP-grammar change.
- **Check-in cadence is a project-selectable default:** the check-in rhythm — how often the roadmap
  interleaves a **Check-in STEP** — was a hardwired 10–20 STEP window (`status.sh` flagged DUE at 10,
  OVERDUE at 20). It is now a **project-selectable number N**, recommended **20**, recorded as an
  optional `<!-- CHECK-IN-CADENCE: N -->` line in `overview.md`; `status.sh` reads it (defaulting to 20
  when the line is absent) and flags a heads-up (DUE) at `N-5` and OVERDUE at `N+5`. This **deliberately
  recenters the default** notice window from DUE 10 / OVERDUE 20 onto the target 20 (→ **DUE 15 /
  OVERDUE 25**) — one of the two opt-outable default shifts noted above. Nothing is lost: 15 reproduces
  the previous window (DUE 10 / OVERDUE 20) and any rhythm is one number away (50 → DUE 45 / OVERDUE 55).
  The cadence stays a judgment-based guideline — only the default notice/overdue thresholds move, and
  the human still places each check-in at a sensible breakpoint. `check.sh` warns (never fails) if the
  marker is present but not a positive integer; no `status.sh` failure path and no STEP-grammar change.
- **Workspace model accepts a repo registered in place:** a repo may be registered in
  `registries/repos.yml` by a **`location:` outside the `Code/*` sibling shell** — an absolute or
  otherwise arbitrary path — so a repo that lives elsewhere is referenced where it sits instead of
  created as a `Code/*` sibling. `scripts/setup-workspace.sh` already honors `location:` verbatim
  (cloning from `remote:` into it, or referencing the repo in place when there's no remote), so this
  is a documentation clarification with no tooling change; branch-per-STEP and the overlap warning key
  on repo identity, not location, so an in-place repo participates unchanged. The `Code/*` sibling
  layout stays the default and greenfield is byte-unchanged.

## [1.6.0] - 2026-07-09

A **release-readiness and operational discipline** release: it adds a structured security
review framework, durable report artifacts, stronger STEP/test planning gates, better setup
tooling, and more approachable onboarding material for new Throughstone projects.

### Added
- **Security review framework** for generated projects: S0 Security Baseline, S1 Security
  Sweep, and S2 Security Audit runbooks/checklists; `registries/security-reviews.yml` for
  review cadence and change markers; and report templates for baseline, sweep, and audit
  outputs.
- **Durable reports structure** under `reports/` for check-in reports, incident postmortems,
  security reviews, and test-result summaries.
- **Test results summary template** for recording test, coverage, CI, and quality-gate
  outcomes.
- **Generated project onboarding guide** to help new contributors understand the scaffolded
  project structure and workflow.
- **`doctor.sh` dispatcher** with a single entry point for `status`, `check`, and `links`.
- **Local Markdown link checker** for durable Throughstone documentation.
- **Website publishing workflow/checks** and artifact-trail publication support.
- **Video resources** in the README covering setup, early sessions, conditional sessions,
  scaling, observability, glossary, post-architecture files, and STEP creation.

### Changed
- `METHOD.md` is now **Method version 0.4 (beta)**.
- STEP plans now require an explicit **test plan** for code-changing work, including test tier,
  run timing, command/gate, and substep coverage.
- The method now more clearly distinguishes small normal changes from work that should become a
  full STEP.
- Check-in guidance now records durable reports under `reports/` instead of burying review
  artifacts inside STEP folders.
- Incident postmortem handling is standardized around report templates and stable report paths.
- Security-sensitive work now points to the Security & Threat Model and risk register, while
  reserving S0/S1/S2 materials for explicit security review STEPs.
- Conditional sessions are more robustly documented, rechecked, and prioritized when discovered
  after STEP-1.
- README and site copy now explain Throughstone's fit, limits, AI-project positioning, setup,
  and workflow more clearly.
- Template filenames are normalized with explicit `*-template.md` naming where appropriate.

### Fixed
- `init.sh` now validates and propagates project license choices more reliably.
- Generated projects can choose a configurable trunk branch instead of assuming `main`.
- Mono-repo setup avoids reusing non-empty template-created origins unsafely.
- Bootstrap remote setup supports manual/non-GitHub Git hosts more clearly.
- ADR authority substitution is explicit and covered by regression tests.
- `status.sh` prioritizes late conditional-session follow-up STEPs correctly.
- Local documentation links are now mechanically checkable through `doctor.sh links`.

## [1.5.0] - 2026-06-06

A **risk visibility and release-notes workflow** release: it adds a canonical accepted risk /
technical debt register, introduces a reusable release-notes template, and tightens the
architecture-session flow around consciously deferred work before the release is merged or
tagged.

### Added
- **Accepted risk and technical debt register** (`registries/risks.yml`): a compact,
  machine-readable index for known accepted risks and deferred technical debt, with each row
  pointing to the durable source artifact that carries the full context.
- **Release notes template** (`templates/release-notes-template.md`): a lightweight milestone artifact
  focused on user-visible changes, action required, known issues, documentation, and technical
  references.
- Method and agent guidance requiring accepted risks to stay visible, with a source architecture
  section, ADR, issue/follow-up STEP, incident report, or check-in report created or referenced
  before a risk-register row is added.

### Changed
- `METHOD.md` is now **Method version 0.3 (beta)**.
- Conditional architecture sessions now record **Include**, **Deferred**, or **N/A** with a reason
  and revisit trigger.
- Conditional-session ownership is clearer: Native app is decided by Architecture Overview,
  Privacy/compliance by Data Model or Security, and Identity/auth by Security.
- STEP-1 bootstrap behavior is documented as a special case: `init.sh` reserves STEP-1, kickoff
  creates the STEP-1 PLAN, then flips it to `In progress` and uses `step-0001-architecture`
  wherever branch-per-STEP applies.
- Release/deploy and milestone-doc guidance now points agents to the release-notes template while
  keeping user-facing documentation optional and explicit.
- STEP index path wording now distinguishes workspace-root paths from docs-hub-relative paths.

### Fixed
- `status.sh` now stops resolving STEP-1 when a substep has an unrecognized status or when no
  runnable open substep can be derived.
- Malformed STEP-index state now points users toward `scripts/check.sh` instead of silently
  skipping ahead.

## [1.4.0] - 2026-06-03

A **scaffold-update process** release: it replaces the old "hand-copy upstream improvements"
guidance with a conservative update model for bootstrapped projects, and tightens bootstrap
and resume behavior before cutting the next tag.

### Added
- **Throughstone scaffold update guide** (`UPDATING-THROUGHSTONE.md`): an
  advisory-first process for comparing a project to a newer Throughstone release, classifying
  files by bucket, reporting risk/implications, and applying only reviewed scaffold/process
  changes.
- **Manifest + catalog model** for future updater tooling: project state would live in
  `Code/{{PROJECT}}-docs/.throughstone/manifest.yml`; release implications would live in an
  upstream update catalog; the updater itself stays stateless.
- **Three-way comparison rules** (`base` / `local` / `upstream`) and classifications:
  already-current, upstream-only, local-only, diverged, untracked, protected, and
  manifest-invalid, with baseline-unknown handling for projects that lack a trustworthy
  install-time manifest.
- **Mechanical risk signals** for updater reports, including script changes, git/remote-touching
  commands, CI changes, placeholder handling, status resolver changes, incomplete update groups,
  and dirty affected repos.

### Changed
- `METHOD.md` is now **Method version 0.2 (beta)** and points scaffold updates to the new
  guide instead of suggesting direct hand-copying.
- The docs hub and template README now make clear that Throughstone improvements do not apply
  automatically after bootstrap, project-owned state is protected, and even script updates need
  review.
- STEP plans and substep prompts now remind agents to calibrate implementation work to the
  user's recorded experience level, not only architecture-session interviews.
- README and website quickstarts now lead with the direct clone flow and clarify GitHub template
  setup.

### Fixed
- `status.sh` now ignores HTML-commented example STEP rows so the next-action resolver does not
  treat documentation examples as real roadmap state.
- Bootstrap no longer leaves Throughstone's root README and changelog in generated projects.
- Mono-repo bootstrap now reuses a non-Throughstone root `origin`, while multi-repo workspaces
  remain detached until the user chooses remotes.
- Successful bootstrap remotes are recorded in `repos.yml` so `setup-workspace.sh` can clone
  sibling repos later.
- The method-check workflow can locate `check.sh` in both multi-repo and mono-repo layouts.
- Session 1.1's conditional-session summary includes privacy/compliance alongside native app
  and identity/auth.

## [1.3.0] - 2026-06-01

A **coding-standards** release: it reframes the shipped standards as customizable starting
points, broadens per-language coverage (adds Java and C#, plus concurrency/async and Python
idioms), and introduces three cross-cutting standards — SQL, Shell, and API design — wired into
the method so each surfaces at the right moment.

### New cross-cutting standards
- **SQL** (`coding-standards/sql.md`): naming, formatting (sqlfluff), query practices,
  parameterized-query safety, schema/DDL, and migrations — secondary to the language docs where
  they conflict.
- **Shell / Bash** (`coding-standards/shell.md`): strict mode, quoting/safety, naming/layout,
  idioms, and error handling (Google Shell Style Guide + ShellCheck/shfmt); the shebang is
  framed as an explicit, recorded project decision.
- **API design** (`coding-standards/api.md`): an opinionated, customizable house style for
  REST/HTTP APIs — resource naming, methods/status codes, RFC 3339 UTC timestamps, money as
  integer minor units, RFC 9457 problem-details errors, idempotency, and rate limits — with
  three per-project forks flagged (field casing, pagination, versioning), each with an ADR
  pointer. Complements each API's versioned interface contract artifact from the Interface Contracts session.

### Expanded per-language coverage
- **Java** (`java.md`) and **C#** (`csharp.md`) standards added.
- **Concurrency / async** sections added to Python, Rust, and TypeScript.
- **Python**: a Language idioms section.

### Customizable by default
- Shipped standards reframed as **customizable starting-point drafts** — both the per-language
  headers and the README — so teams treat them as a draft to edit, not law to obey.
- The **all-languages documentation rule** broadened to **fields/properties** (docstrings where
  the language documents them, e.g. Java fields, C# properties), public and private.

### Wiring
- The cross-cutting standards are reconciled by the **Test Strategy session** and recorded in
  the Test Strategy architecture doc (kept only when each applies — a relational DB for SQL,
  shell scripts for Shell, an HTTP/REST boundary for API), listed in `coding-standards/README.md`
  and the `METHOD.md` hub gloss ("per-language plus cross-cutting"), and
  `templates/substep-prompt-template.md` nudges API-touching substeps to read `api.md`.

## [1.2.0] - 2026-06-01

A **discoverability & docs-hygiene** release: it indexes the runbook and registry folders, adds
the **secrets-rotation runbook** the operate-time set was missing, makes the **session set
flexible** for added/conditional sessions, and closes plain-language gaps the method's own L1/L2
standard exposed.

### New operate-time runbook
- **Secrets rotation** (`runbooks/secrets-rotation.md`): scheduled rotation (inventory, cadence,
  no-downtime overlap, verify-then-revoke) and a **revoke-first** response to a suspected leak
  that hands off to the incident runbook. Operationalizes the secrets & data protection posture
  from the Security & Threat Model architecture doc, mirroring how the dependency runbook
  operationalizes the dependency-risk posture.

### Discoverability & docs hygiene
- **README indexes** for `runbooks/` (all five — purpose, when each fires + trigger phrase,
  governing section; STEP-shaped vs. operational) and `registries/` (machine-readable state,
  pointing at `repos.yml`'s own header rather than duplicating the schema); docs-hub rows now link
  both indexes.
- **Conditional-session naming is shown, not just described:** the by-name → file mapping inline
  in METHOD §4, and a copyable lettered-row example in the STEP-index seed.
- **Plain-language glosses** for jargon flagged against the method's own L1/L2 standard:
  API / OpenAPI / GraphQL / protobuf (session 1.3) and the RPO/RTO acronyms (session 1.8).

### Flexible session set
- **Session numbering no longer hardcodes the current set:** the conditional-doc rule and
  `status.sh` review-detection adapt to added sessions; dependency-bearing sessions
  (Scaling & Performance, UI / Design System, Infrastructure & Deployment, Observability,
  Interface Contracts, and Test Strategy) read relevant conditional docs when present.
- **Glossary session** harvests terms from every architecture doc (including conditional docs above
  the core block), not a fixed range.
- **METHOD §4 "Adding a session" recipe** — conditional (zero-touch) vs. standard (renumber the
  Cross-Cutting Review) wire-in checklist.

## [1.1.0] - 2026-05-31

This release **broadens the architecture sessions**, adds the **operate-time runbooks** the
method was missing, and introduces a **mechanical tooling layer** (scripts + CI) that enforces
rules the method previously trusted to discipline.

### Broader architecture coverage
- **Resilience & disaster recovery** is now first-class in the Infrastructure & Deployment
  session (1.8):
  failure modes / single points of failure, an availability target, graceful degradation, and
  backups with RPO/RTO and restore-rehearsal.
- **Accessibility & internationalization** in the UI / Design System session (1.7): a concrete a11y target
  (WCAG 2.1 AA) plus a new i18n/l10n decision in the don't-foreclose spirit.
- **New conditional session — Privacy, compliance & data governance** for projects handling
  personal/regulated data (applicable regimes, data inventory, lawful basis/consent,
  retention/deletion, data-subject rights, residency & sub-processors).

### Stronger process discipline
- **Explicit conditional-session selection:** the kickoff now records a *Conditional sessions
  considered* table (Include / N-A + reason), so a skipped conditional is a deliberate, recorded
  choice — never a silent omission.
- **Milestone doc review:** at each phase/release the agent proactively raises release notes and
  end-user docs.
- **Documentation discipline** strengthened across the method; **testing guidance** sharpened
  (~80% coverage suggestion, per-step/substep test defaults).

### New operate-time runbooks
- **Release / Deploy / Rollback** — a rollback plan before you deploy, reversible migrations,
  staging-first, a post-deploy watch window.
- **Incident Response & Postmortem** — stabilize, then open an Incident STEP (RCA → find similar
  → fix & harden).
- **Dependencies & Supply Chain** — vet before adding (license / provenance / pin) and audit on
  the check-in cadence (vuln scan, lockfile hygiene, SBOM).

### Mechanical tooling (new)
- **`scripts/check.sh` — the "doctor":** flags *and suggests a fix for* duplicate STEP/ADR
  numbers, invalid statuses, missing architecture-doc frontmatter, and ADR registry/disk drift.
  Read-only; runnable in CI.
- **`scripts/status.sh` — next-action resolver:** prints "where you are · next action · check-in
  cadence" straight from disk; a resuming agent now runs it as its first action.
- **GitHub Actions CI starter:** a live method-integrity workflow (runs `check.sh`) plus a
  per-repo test-gate template.

### Other
- Maintainer contact moved to **hershey@throughstone.org**.
- A thin pointer **README at the docs-hub root**.

## [1.0.0] - 2026-05-31

Initial public release of the Throughstone scaffold — a starting structure for building
software **architecture-first** with an AI coding agent.

### Added
- **The method** (`METHOD.md`): the Phase → STEP → substep structure, architecture-first STEP-1
  (design docs + ADRs, no code), the two durable doc genres (architecture docs + ADRs),
  doc versioning, and the disk-derived next-action resolver.
- **Architecture sessions:** 13 core sessions (System Overview, Requirements & Non-Goals through Cross-Cutting Review)
  plus 2 conditional sessions (native app, identity & auth).
- **Runbooks:** the periodic check-in and multi-developer/agent collaboration.
- **Templates:** architecture docs, ADRs, STEP plans, substep prompts, repo READMEs, per-language
  coding standards, and the kickoff bootstrap.
- **Setup tooling:** the `init.sh` wizard and `setup-workspace.sh`; multi-repo and
  mono-repo-for-now layouts; license selection and stamping.
- **Brand assets** and the throughstone.org documentation site.

[1.7.1]: https://github.com/mherschberg/Throughstone/compare/v1.7.0...v1.7.1
[1.7.0]: https://github.com/mherschberg/Throughstone/compare/v1.6.0...v1.7.0
[1.6.0]: https://github.com/mherschberg/Throughstone/compare/v1.5.0...v1.6.0
[1.5.0]: https://github.com/mherschberg/Throughstone/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/mherschberg/Throughstone/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/mherschberg/Throughstone/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/mherschberg/Throughstone/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/mherschberg/Throughstone/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/mherschberg/Throughstone/releases/tag/v1.0.0
