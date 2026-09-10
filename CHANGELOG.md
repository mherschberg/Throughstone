# Changelog

All notable changes to Throughstone are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this
project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). Versions here
refer to the **Throughstone scaffold** (the method, templates, runbooks, and tooling), not to
any project built with it.

## [Unreleased]

### Added
- **A runbook for splitting a repository** — `runbooks/splitting-repos.md`. The method used to say
  splitting was "standard git," which is not something you can act on: the recipe you find
  elsewhere makes the extracted repo *new*, with its history rewritten by `git filter-repo`, a
  tool that never ships with git and needs Python on every install route. The runbook writes down
  a different mechanic — clone the whole repo and delete forward — so nothing is rewritten, both
  sides keep the full history, and `git blame`, `git log --follow` and every commit SHA your
  project has recorded keep working in the new repo on day one. It covers both cases behind one
  routing block: splitting a code repo in two (Part 1), and converting a mono-repo-for-now workspace
  to multi-repo (Part 2). **The routing is not a free choice**: Part 1 assumes the workspace root is
  not itself a repository, so a mono-repo-for-now project runs Part 2 first and then Part 1 if it
  still wants one. **Do the whole split on one machine in one sitting** — it turns on local state no
  repository carries, so it cannot be handed over half-done. Tracking it as a STEP is the method's
  convention rather than an obligation, and the runbook names the two Part 2 steps to skip together
  if you would rather not — Part 1 needs no equivalent. Part 2 also deletes the workspace-root registry row on its way through, since the root
  stops being a repository at that step. It asks three questions before you start and the rest at the step that needs them;
  every one but the mapping itself has a default, so answering "use your judgement" still produces
  a correct split. The one real cost is stated plainly in the file: every new repo inherits every
  blob the origin ever committed, including deleted ones, and an appendix covers purging first when
  that matters.

  Shipping with it: **the rule telling you to split before adding a second contributor is gone.**
  It gave two reasons and neither survived. The STEP-number push-race works exactly the same in a
  mono repo with a shared remote — what a team needs is shared remotes, not several of them — and
  the overlap warning's mono fallback was already written, in the very section that clause cited.
  How many repos you have follows your architecture, not your headcount. The solo-to-team section
  of `runbooks/collaboration.md` now has a mono path of its own, including the warning not to run
  `scripts/setup-workspace.sh` in a mono clone; `METHOD.md` §7 and `prompts/README.md` moved with
  it, the first gaining the mono→multi special case (that STEP is branchless, and its number is
  reserved on trunk) and the second replacing its per-kind list of thin STEPs with two families.
- **Repo rows record how each repo arrived, and a split-out repo records where it came from.**
  `registries/repos.yml` gains **`added_as:`** (`created` | `adopted`) — whether Throughstone made
  the repo or took on one that was already there. It is a stamp for a human reader, written once
  when the repo is registered and never changing afterwards: **nothing reads it and nothing decides
  from it.** `type:` is documentation in the same way, and gains `mono` for the workspace root of a mono-repo-for-now project. A repo split out of
  another one can also carry an optional **`provenance:`** block recording where it came from and
  where the two histories part company; it is written at the split and nothing maintains it after.
  **Nothing else is tracked per repo.** A row is an inventory entry, never a status board: the work
  of bringing a repo in is *done* at the time rather than recorded as a status, anything missed is
  found later by looking at the repo, and a case the registry does not cover is raised to a person
  rather than answered by inventing a field.
  The header also states three rules for anything that reads or rewrites the file, because the
  scripts that read it match line prefixes and know nothing about YAML: every value is a single-line
  scalar; a rewrite anchors on the whole row block rather than a bare line prefix; and **a `#` on a
  value line is part of the value, not a comment**, so `- name:`, `location:` and `remote:` must
  carry nothing after the value. That last one has a concrete failure behind it — the readers strip a
  closing quote only at end of line, so a trailing `# note` on a `remote:` line ends up inside the
  clone URL.

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
  it. The existing mode is unchanged in what it writes, including every case where it refuses to
  overwrite a file it did not write. One argument-handling change rides along: a second positional
  argument used to be discarded silently, and now exits 2.

- **The doctor gained a `--check-in` flag, and the periodic check-in is where the repo registry gets
  checked.** `scripts/check.sh` took no options at all; it now takes `--check-in`, which turns on the
  checks that belong to the periodic check-in rather than to every run — today, one. Check 10 reads
  `registries/repos.yml` and makes two mechanical checks and only those two. **A row with no
  `location:` fails the run**, because nothing can find that repo and guessing a path is worse than
  asking — **and so does a row the doctor cannot read**: it finds a row by its `- name:` line, counts
  the list's entries apart from that, and fails when the two disagree rather than pass over a repo
  it never saw. **A repo that no recorded remote covers is a warning**, because as far as the project knows
  that work lives on exactly one laptop. A row is covered by its own `remote:`, or by the root
  repository's when it lives inside it — in a mono-repo-for-now project the row whose `location` is
  `.` is the one real repository and the folder rows below it are backed up by whatever backs it up,
  so only the root row is ever named. The warning is designed to recur: a project may legitimately
  start local for a while, nothing records that decision, and the reminder coming back every check-in
  is the point rather than a defect.
  **The doctor is deliberately the only place that checks the registry on a schedule, and that is
  the design** — `scripts/setup-workspace.sh` still guards a `location:`'s shape at clone time,
  because that one can put a repository somewhere it does not belong. The registry changes only
  when a repo is created, adopted or split out — a rare action — while the doctor runs constantly
  during STEPs. So a plain `./doctor.sh check` now prints a tenth section that reads
  `skipped — run with --check-in`, and the generated CI workflow never passes the flag: a typo in the
  registry has no business failing a build on every push. `runbooks/check-in.md` is what passes it,
  where a person is already looking, and it says what to do with each finding — a `[FAIL]` gets
  fixed, a `[WARN]` gets a decision rather than a reflex fix. `scripts/check.sh` also gains its first
  test, `tests/check-repo-registry.sh`, and the flag is listed in `./doctor.sh --help`, in the
  command list and in the examples.

- **A runbook for registering a repository** — `runbooks/register-repo.md`, the one procedure for
  bringing a repo into a project, whether Throughstone creates it or takes on one that already
  exists. Everything that changes the set of repositories a project has goes through it, the split
  included. Five steps: write its `registries/repos.yml` row, give it a README, apply the
  licensing artifacts, record it in the Architecture Overview, and commit once per repository.
  **Which README a repo gets is decided by what is in the repo, not by how the repo arrived** — a
  repo with no README is stamped from `templates/repo-readme-template.md`, one that already has a
  README keeps it and gains a short `## Role in <project>` section, and no repo ends up with two.
  Licensing shows its two artifacts separately, because they answer different questions: a repo the
  method created follows the project's own posture, while an adopted repo gets `LICENSE-THROUGHSTONE`
  for the Throughstone-authored material in it and never a project `LICENSE` or `LICENSING.md` —
  choosing a licence for code the method did not write is not the method's to do. The per-posture detail that used to sit in
  `METHOD.md` §7 now lives here, next to the step that performs it.
  The row and the Architecture Overview entry are **always both attempted, neither is rolled back,
  and whatever did not land is reported** — the run ends with a written report, one block per
  repository, in which `✓` means the end state was reached *by this run* rather than merely
  attempted. Nothing aborts: a repo that is missing, dirty, read-only, or nested inside another work
  tree is reported and the run carries on, which is what makes the action safe to re-run and what
  stops a failure being quietly skipped. It commits once per repository, naming paths explicitly and
  never `git add -A`, so untracked work sitting in someone's repo is never swept into a commit.
  `METHOD.md` §7 states the standard the runbook works to: **registering a repo makes it known and
  connected — never good.** A repo whose README is thin is registered as it stands; improving it is
  ordinary forward work, and only a genuinely risky shortfall becomes a `registries/risks.yml` row.

### Changed
- **The two local-profile settings each do one job.** The kickoff records an experience level and
  a communication style, and the docs had quietly welded them together: `METHOD.md` told an agent
  that Level 3 means "keep it terse and decision-focused", and its Level 1-2 twin bundled
  explaining *what* a question asks (vocabulary) with explaining *why* it matters (verbosity) into
  one clause. That pairing was then paraphrased into the sixteen architecture-session templates,
  the planning session, the kickoff prompt and the public README, and half a dozen more files
  named the two settings without saying what either one did. The
  effect was that a saved communication style had no defined behaviour anywhere — no document said
  what Terse, Normal or Explanatory makes an agent do — while the level silently decided verbosity
  on its own, so "level 3 plus Explanatory", an expert who wants the reasoning spelled out, was
  unrepresentable. The two now have one job each, and say so in the same words wherever an agent
  is told to read them: the **experience level** sets how much technical background you can assume — which terms,
  concepts and options need explaining — and the **communication style** sets how much reasoning
  comes with a decision. Both are rough guides for an agent to use judgment against, not rules to
  measure. Each of the three values on both dials is defined, and every site that
  already told an agent to read the style now says what reading it should change. `METHOD.md` §4's
  worked examples were rebuilt so that each set asks the *same* question with the *same*
  recommendation and moves only the one dial it names; two of them used to change the decision
  itself between levels, which taught the coupling the section says it removes. Two behaviours that were riding on the level are lifted out of it:
  leading with a recommended default no longer depends on the level, and a request to clarify is
  answered in kind, so asking "why does that matter?" gets more reasoning rather than a drop into
  beginner vocabulary. **If you have a saved profile, this changes what your sessions sound
  like**. Level 3 used to force terseness, so level 3 plus Terse is what reproduces it; Levels 1-2
  used to force a why-explanation, so pick at least Normal to keep that. Because the communication
  style had no defined behaviour before, other old combinations have no exact equivalent.
- **Onboarding asks the local-profile questions instead of restating them.** `ONBOARDING.md` §3
  carried its own copy of both questions and a byte-identical duplicate of the profile file's
  shape, even though `BOOTSTRAP-PROMPT.md` Stage 0 is the declared owner of both and twenty-four
  other files already cite it. The copy had drifted: it gave two of the three override-precedence
  branches, omitted the rule requiring an agent to tell the user they can ask for an explanation,
  and sat ahead of the step that says to read `METHOD.md` — so an agent onboarding a second
  contributor wrote their profile having never read the calibration rule. §3 now points at Stage 0
  for the wording, the labels, the file shape and the precedence, and at `METHOD.md` §4 for what
  the answers change. The kickoff's two questions are phrased as what the agent actually says,
  which is what lets one copy serve both the kickoff and a contributor joining later.
- **The check-in is scheduled, not calculated.** `scripts/status.sh` used to work out whether a
  check-in was due from two facts it reconstructed on every run: *how often* — the
  `<!-- CHECK-IN-CADENCE: N -->` setting in `overview.md`, plus a default, plus a window of five
  STEPs either side — and *when the last one was*, taken from the most recent `Done` STEP whose
  Title began `Check-in`. Both existed only so a script could recover something nobody had written
  down, and each forced a contract on the documents: six passages had to name the setting so the
  prose and the helper could not quote different numbers, and four had to state the title rule so a
  check-in row would be countable at all. Neither contract served a reader, and both had to be
  policed by tests.

  **`overview.md` carries one recorded fact instead**: `<!-- NEXT-CHECK-IN: … -->`, holding either a
  STEP number (`STEP-45`) or a date (`2026-11-15`). Whoever schedules a check-in writes it — the
  planning session as it lays out a phase, the check-in itself before it closes, or the user at any
  moment. **The user answers in their own terms** (*"in about three STEPs"*, *"after the launch"*,
  *"remind me in November"*) and the agent turns that into a STEP number or a date. `status.sh`
  reports it as due once that point is reached and keeps saying so until someone moves it. Anything
  it cannot read — a mangled value, or no line at all — reads as *none scheduled*, which is the
  nudge to set one and the floor this advice can never fall below. Nothing validates the line and
  nothing enforces it: it stays advice, and §10 rule 7 still never becomes the next action.

  **What went with it.** The cadence setting and its default; the DUE/OVERDUE windows and the
  arithmetic around them; the doctor check that validated the setting (which renumbers the
  repo-registry check from 11 to 10); and the `Check-in` title rule as a machine contract — it
  survives in the documents as a plain roadmap convention, policed by nothing. New projects are
  seeded `STEP-20`, a starting suggestion rather than a rule. One hazard survives and stays
  guarded: a hand-written `STEP-08` is forced to base 10, because `$(( ))` reads a leading zero as
  octal — the shape that used to abort the whole resolver. The date form needs no arithmetic at
  all.
- **STEP-1 takes the same branch in every repository it writes into.** STEP-1 work takes the
  `step-0001-architecture` branch in **every** repository it writes into — previously the docs hub
  and `prompts/` in a multi-repo project, or the root repo in mono-repo-for-now, which left a
  repository that already existed and had been brought into the project with no branch rule at
  all.
- **A registered repo now always lives inside the workspace.** 1.7 documented the opposite:
  `METHOD.md` §7 and the `registries/repos.yml` header both said a `location:` **may** point outside
  the `Code/*` shell — an absolute path, or any other arbitrary path — for a repo referenced where it
  already sits, and `scripts/setup-workspace.sh` used that value verbatim. The cost of that was never
  paid by the person who wrote the row, on whose machine the path resolves. It was paid by **every other contributor, on every new
  machine, for the life of the project** — and paid silently, because a path that happened to be
  writable simply placed the repository outside the workspace at exit 0, reported as an ordinary
  clone, while one that did not resolve took the whole run down.
  A `location:` is now **a path relative to the workspace root, identical on every machine; it never
  begins with `/` or `~`, and no segment of it is `..`.** Anything else is skipped rather than cloned into, and
  reported when the row carries a `remote:` for the cloner to act on. Usually that is a `Code/*` sibling, but any contained path works — `prompts/` is a
  shipped row that is not under `Code/`. **A repo that genuinely cannot move keeps its place behind a
  symlink:** put one at the repo's workspace-relative location pointing at the real checkout, and
  register that path. The registry stays portable, every other contributor clones the real thing into
  that path from the row's `remote:`, and the repo itself is untouched — no repo's code is ever rewritten and none is forced to
  move. `setup-workspace.sh` follows the link, finds the checkout and leaves it alone.
  The test is textual on purpose, because the value reaches `git` **literally: no shell expansion and
  no YAML interpretation happen**, so `~/lib` and `$HOME/lib` are directory names rather than paths to
  a home directory. `~` gets its own arm for that reason — it used to clone *successfully* into a
  literal `~` folder under the workspace root and report it as an ordinary clone. The guard also runs
  **before** the already-checked-out test, and the order is the point: on the one machine where a bad
  path does resolve — the machine best placed to fix the row — the run used to print `exists:` and say
  nothing at all about the location.
- **The interactive setup no longer licenses your project open source by default.** `init.sh` asks
  whether the project is open source or proprietary, and that question used to default to
  open source, with the license question after it defaulting to MIT — so two bare Enters granted
  everyone an irrevocable license to the project's code without the user ever naming one. The
  project-type question now defaults to **proprietary**, which writes no project
  `LICENSE` at all and leaves the decision to be made deliberately later. The open-source
  sub-question no longer defaults to MIT either: once open source is the posture, which licence it
  is has to be typed. (That half came later in this same cycle — see the wizard-answers entry
  below — and is recorded here rather than as its own reversal, since no release ever shipped the
  in-between state.)
  Nothing changes for `--license=…` or `--non-interactive`, which have always required the posture
  to be stated. Existing projects are unaffected — their posture is already recorded in
  `.throughstone/project-license`.
- **The website's process section is three steps, not four, and says the method covers the whole
  lifecycle.** The four-step flow led with *Initialize* — running the setup wizard — which put a
  tooling step where a reader is trying to understand the method, and pushed *Check-ins* off the
  end. It now reads **Design first → Build in STEPs → Check-ins**, with initialization described
  where you actually install. A new *Beyond the build* note under the flow, and a rewritten opening
  to the operational-discipline section, say outright that the architecture sessions and runbooks
  plan for deployment, monitoring, releases and incidents, which the site previously only implied.
  Site copy only — no method or scaffold change.
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
- **The Cross-Cutting Review now settles a doc-versus-code contradiction by reading the code, and
  says which decisions may never get an ADR.**
  `templates/architecture-sessions/14-cross-cutting-review.md` is the closing pass of the
  architecture STEP: it reads everything the other thirteen sessions produced and checks it hangs
  together. It was written for docs describing a system nobody has built yet, so on a project that
  already has code — one brought into the method, or a repository registered in place — three of
  its six checks had nothing to say about the one thing that can settle an argument. Three rules
  close that, and none of them changes what the review does on a project with no code yet.

  **Consistency (check 2)**: where code exists, a contradiction is settled by reading the code
  rather than by re-deciding it — the code is authoritative for what the system *does*, the docs
  for what it is *meant* to do. A doc that misread consistent code is an ordinary doc fix, with no
  decision to take and no row to file. The two outcomes that leave a real gap behind — two
  patterns genuinely both live in the code, or a doc states an intent the project never actually
  decided on — each file a `registries/risks.yml` row, because the periodic check-in already
  re-reads every open row and a gap left in a document nobody opens again only widens. One case
  is deliberately carved out and sent to `runbooks/check-in.md` instead: where the doc records a
  decision the project really took and the code has drifted from it, the code is the defect, and
  rewriting the doc to match would bless the drift. The classification turns on what the doc
  meant, which the doc often does not say, so **where you cannot tell, file the row**: an extra
  row the next check-in closes costs little, and an intention deleted by a doc fix is not
  recoverable. Being unsure what the *code* does is the opposite case — **re-read it before
  filing a risk**, so the register never carries debt invented out of our own misreading.

  **Foreclosure (check 4)**: the walk over the "Forecloses / tradeoff" entries is unchanged and
  gains one forward question — does the architecture, as designed or as already built, support
  what the Phasing & Roadmap doc commits to later, or is rework needed before that phase starts?

  **Decision coverage (check 5)**: still write the ADRs that are missing, and a decision made
  *during* the review is contemporaneous and gets an ordinary one. What is ruled out is
  reconstructing history — a choice made before the project kept ADRs, whose reasons nobody
  available knows, is recorded in the architecture doc and left there. An ADR is a dated record of
  *why*, and a guessed rationale is worse than no ADR.

  `METHOD.md` §3 moves with it. Architecture docs are the single source of truth for the
  **intended** design; the sentence used to say "the current design", which read as though a doc
  outranked the code on a question of fact, while `runbooks/check-in.md` has always reconciled the
  two in both directions.
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
- **The process docs now name the registration action instead of describing a registry row.** Six
  shipped files still told an agent to go write a `registries/repos.yml` row by hand, or swept "all
  repos" as though every one of them were on the machine. `AGENTS.md`, the substep prompt template
  and `runbooks/collaboration.md` §8 now say *register it* and point at `runbooks/register-repo.md`;
  none of them knows a field name any more, so they stay correct when the fields change — which is
  the exact way the previous attempt at this rotted.
  Two files change what they actually do. **The check-in's repo-README sweep is now driven by the
  README itself.** It sweeps each repo present on this machine and lets that repo's README say how
  much of it is ours: a README stamped from the template is reviewed whole, one carrying a
  `## Role in <project>` section is reviewed only down to the next `##` with the rest of somebody
  else's file left alone, and one with neither marker is not edited at all — there it re-asks the
  single question a README has to answer for the project, whether someone standing in that repo can
  still find their way back. The "do the setup steps still work from a clean checkout" check
  survives only on a README we stamped; anywhere else it is a judgement about their repo rather
  than about our connection to it. A registry row and its Architecture Overview entry are treated as
  **one** thing that drifts — re-run the registration, never edit either by hand — and the check-in
  now says plainly that licensing is settled once for the whole project and never re-asked per
  repository. **`runbooks/collaboration.md` §9's solo-to-team remote setup is scoped to repos
  that have no remote yet**: as written it would have created a second remote for a repository
  that already had one and pushed its history there.
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
  One new guard rides along on the create branch: if the
  path already holds files this project did not put there, the step stops and asks rather than
  scaffolding over them. The session also tells the planner to make sure the phase contains a STEP
  that does the creating or registering, since a later phase that only extends what already exists
  can leave a repo named by the architecture and owned by nobody. A greenfield first run is
  unchanged: nothing is registered and no location holds a repository, so every repo is created
  exactly as it is today.

- **The check-in STEP may now make a small corrective fix rather than only filing one.** It read
  *"a review + verification STEP, not feature work. It writes no application code"* — while Part 2
  tells the operator to run the suite and deal with what it finds, which is a contradiction the
  moment the failure is a one-line fix. The contract is now *"it writes no new features"*: it fixes
  docs, files bugs, proves the tests pass, **and may make a small corrective code or test fix to
  clear a failure it found**. Anything larger is still a bug STEP of its own.
- **The check-in advises and proposes; it never becomes the next action.** `METHOD.md`
  §10 is a first-match-wins list, and rule 7 — the check-in — sat between "plan the next
  STEP" and "the phase is complete". `scripts/status.sh` never implemented it, so a project past
  its check-in got an imperative on one line and `plan STEP-41` on the next, which reads like the
  tool contradicting itself. The resolution is not a new resolver branch.
  Rule 7's own wording puts the check-in "at the next sensible breakpoint", and a rule that fired
  the moment a project went past the point would fire mid-feature — the one place §5 says not to
  put one. So §10 now says plainly that rule 7 is the exception to first-match-wins: the check-in
  is reported *alongside* the next action and never in place of it, it never blocks work, and no
  rule below it is skipped because one is due. `status.sh` prints it that way — when the scheduled
  point is reached it offers a Check-in STEP under the next action, marked as advice, and the next
  action itself is untouched. `prompts/README.md` no longer describes a due Check-in STEP as
  something the resolver answers with, and `tests/status-next-check-in.sh` holds both halves of the
  contract so a gate cannot creep back in.
- **The planning session now asks whether it is planning against code somebody else wrote, and
  runs that code's tests before anything is built on it.** Before it proposes the STEP sequence it
  puts one question to you — *is any of the code this phase builds on code this project did not
  write, that no check-in has yet run over?* — and if the answer is yes, it puts a check-in titled
  `Check-in: baseline` at the front of the phase, whose job is `runbooks/check-in.md` run once,
  end to end, both substeps. The runbook itself is unchanged, a failing inherited suite included.
  It goes ahead of the scaffold STEP, so the suite is measured on the code as you took it on,
  before the method has written a README section or a licence notice into it.

  Nothing ran that suite before the project started building on top of it. STEP-1 writes documents
  and runs nothing, which is correct when there is no code yet; but a project whose architecture
  names a repository that already exists registers it where it sits rather than scaffolding into
  it, and then finished STEP-1 holding a full set of architecture documents describing a baseline
  **nobody had checked against a green build** — and started adding features on it. The periodic
  check-in would have reached that suite eventually, twenty STEPs of new work later, with the
  inherited baseline and everything built on top of it already mixed together.

  **It asks instead of working the answer out.** The registry records how each repo arrived, and
  reading that was the obvious implementation, but it is not readable at the moment the decision
  has to be made: on the path where the planning session is what takes the repository on, the row
  is written later, by the STEP this session is in the middle of outlining. A project can also be
  set up around a codebase that was already there, and a repo can be taken on in a phase long
  after the first. The person in the chair knows the answer in every case, so the session asks
  them — nothing reads how a repo arrived, and that rule is unchanged.

  **The question carries its own stop**, which is why there is no second rule to keep in step with
  it: it asks about code no check-in has run over yet, so a project re-planning a later phase does
  not spend a whole STEP re-baselining code the check-ins have already swept, and a repository taken
  on in phase 3 still gets its one run even though the roadmap is full of earlier check-ins.

### Fixed
- **A doctor check that read nothing no longer passes.** Four of the checks `scripts/check.sh` runs
  every time read rows out of a table or templates out of a folder, and each printed a clean PASS
  when it found nothing there. Emptying `prompts/STEP-index.md` and `adr/README.md` passed the
  duplicate-STEP, duplicate-ADR and status checks and ended the run `0 fail(s), 0 warning(s)`, where
  deleting the same two files warned four times; renaming the STEP table's `Status` header passed
  the status check over a STEP-1 marked `Bogus`, which with the header intact fails; and removing
  `templates/architecture-sessions/` passed the conditional-template check as having nothing to
  check. Each of those now warns. The status check counts STEP rows apart from the header it reads
  their statuses under, so a header renamed in one phase table of several is caught too, as
  `read the status of 1 of 2 STEP row(s)`. **Where nothing is a normal state, it still passes** — a
  project with no ADR yet, whose registry table is still there, or one that deleted its optional
  conditional templates on purpose — so a fresh project still ends `0 fail(s), 0 warning(s)`. The
  STEP, ADR and status checks' pass lines now say how many rows they read, as
  `all statuses valid (1 STEP row(s), 14 substep row(s))`, so a zero shows even where it is
  allowed. The new findings are warnings: a run that exited 0 before still does.
- **The workspace setup no longer clones from a registry it cannot fully read.**
  `scripts/setup-workspace.sh` finds a row by its `- name:` line, so a row written any other way —
  starting on a bare `-`, or with another field first — was not read, and its fields landed on the
  row above it: that repo was never cloned and nothing said so, or one repo's remote was cloned into
  another repo's location. It now counts the list's entries apart from the rows it reads, and when
  the two disagree it clones nothing and says to fix the row; the workspace's pointer files are
  still written.
- **A broken link in an imported document no longer keeps the link check red for good.**
  `./doctor.sh links` checked every Markdown file in the docs hub except `templates/`, and that
  included `inputs/` — the documents brought in from outside the method, which it keeps as they
  arrived and, once superseded, moves to `inputs/archive/` rather than editing. A copied spec with
  a relative link to a path the workspace does not have failed the check, nothing the method
  allows could clear it, and moving the file to the archive changed nothing. `scripts/links.sh`
  now skips `inputs/` and everything under it, and its printed scope says so; a link *to* an input
  from a file it does check is still checked. `AGENTS.md`, `ONBOARDING.md`, `inputs/README.md` and
  `runbooks/splitting-repos.md` each gain a sentence saying imported documents are not
  link-checked.
- **Seven documents still glued `private` and `proprietary` into one word, and two of them
  described a wizard question that no longer exists.** 1.8 split the two deliberately —
  `private` is who can see the repository, `proprietary` is what the code is licensed under, and
  they are independent, since a private repo can carry MIT and a public repo can be proprietary.
  That cleanup reached `init.sh`'s tokens, flags and on-screen labels but not the prose around
  them. `templates/licenses/README.md` and the root `README.md` both told you `init.sh` asks
  whether the project is *open source or private/proprietary*; it asks *Open source* or
  *Proprietary*, and prints a line saying visibility is a separate question asked later, so those
  two were describing a prompt the wizard does not show. The remaining five were the fused pair
  used as the name of the licensing posture, in the licence banners of `METHOD.md` and the docs
  hub's `README.md`, twice more in the two files above, and in one `init.sh` comment. All seven
  now say `proprietary` where they mean the licence and `private` only where they mean
  visibility. Nothing changed about what is licensed, what the wizard does, or what any project
  already records in `.throughstone/project-license`.
- **A repo the method did not create could be read as needing an `.env.example`.** The planning
  session's scaffolding sentence scoped its `.gitignore` to "each new code repo" and, in the same
  breath, `templates/env-example.txt` to "each repo" — two items in one sentence, scoped two ways,
  which reads as a distinction someone meant. The branch it sits in only ever handles repos being
  created, and the branch beside it already refuses `.env.example` outright, so nothing was
  actually writing into somebody's existing repository; what was wrong was a sentence that said
  otherwise. It now says "each new code repo" for both. The two lines carrying it were the widest
  in the file at 130 and 124 columns, which is the reason it survived this long, and they are
  rewrapped to the file's own width.
- **The method now has a rule for the one thing it can do to a repo that cannot be undone.**
  `METHOD.md` §7 sets out what the method does to a repo — stamps a README, applies the project's
  licensing posture, writes a registry row — and every one of those writes a file, which the next
  commit can take back. Publishing one is the exception, and §7 did not mention repository
  visibility at all; the nearest thing to a rule was a note in `templates/planning-session.md`
  telling you to choose private or public deliberately rather than infer it from the license,
  which is how to choose and not whose choice it is. **Making a repo public takes an explicit
  instruction from the user naming that repo** — a license, a public sibling repo, a remote, or a
  project that calls itself open source is not that instruction, and neither is silence. It is
  absolute because publishing cannot be taken back: a repo that goes public exposes its whole
  history at once — the key that was committed and removed a week later, the customer name in a
  fixture — and forks, mirrors and crawlers have it before anyone notices, while setting the repo
  private again recovers none of it. The rule reads the same for every repo however it arrived:
  not one wording for a repo the method created and another for one it adopted, and nothing
  consults `added_as:` to pick between them. A default applies at one moment and no other — when a
  repo is being stood up: create it **private**, widening being a separate decision made
  deliberately later, the words `runbooks/splitting-repos.md` already uses at the step that gives
  a new repo its remote. The sentence is written into `METHOD.md` §7,
  `templates/planning-session.md` and `templates/repo-readme-template.md`, in the same words in
  each. Nothing gained a field, a flag or a check. It is doctrine rather than
  machinery, and the instruction it names comes from the user, ahead of the run.
- **That rule now reaches the two places that could actually make a repo public.** Stating it in
  `METHOD.md` and the templates left out the registration runbook, which is where a repository is
  brought into a project, and the check-in, which is where the doctor reports that a repo has no
  remote and somebody acts on it. Both told you to push a repo somewhere, neither said anything
  about visibility, and they are the pages open at the moment a remote gets created. All three now
  say that **a remote created for a repo that has none is created private**, widening being a
  separate decision made deliberately later. The registration runbook adds what a public answer has
  to come from; the doctor's fix line and the check-in keep the short form, because the moment they
  describe is a repository being stood up rather than one being published. The doctor's line also
  stops conflating two situations it never told apart: it reads the registry file and not git, so
  a row with no `remote:` can mean the repo has one that nobody wrote down — record it — or that it
  has none — create it, private, or accept the risk deliberately. Unchanged in force, and now
  saying what it always scoped to: the registry's `remote:` field is still never created and never
  repointed *by registration*, which records what is there.
- **A project that has finished its architecture STEP is no longer sent back into it — forever.**
  `./doctor.sh status` answers "what do I do next?" by walking `METHOD.md` §10's rules in order and
  stopping at the first match. The rule about open STEP-1 substeps sat above the point where the
  helper read the STEP-1 row's own status, so a STEP-1 marked `Done` over any session row still
  `Planned` was reported as *"Architecture (STEP-1) in progress"* with the open session as the next
  action. Because that rule stops the walk, this was not a wrong answer at one moment: it was the
  answer from then on. A STEP `In progress` five STEPs later printed the identical line, and the
  work actually in flight was invisible to the helper. The STEP-1 row now decides, in both
  directions — the close-out rule already read it that way, since substeps all final under a row
  that is still open means closing STEP-1 *is* the work, and this is the same rule facing the other
  way: the row says architecture is over, so no open substep is resolvable and the rules below
  answer instead. A baseline that closes STEP-1 without running every session is a legitimate
  state, not a mistake to route back into. §10 said none of this and now says it, in the rule and
  in the quick-resolver table above it.
- **Two rules now say what they left to inference.** `runbooks/check-in.md` says to tell the agent
  *"run the check-in"*, while `METHOD.md` §10 says an in-progress STEP runs only the substep you
  ask for by name — and a check-in has two substeps. Nothing said whether that phrase authorised
  both or only planned the STEP. It runs both, end to end: the substeps are fixed, the runbook is
  their prompt, and there is nothing to approve between them. Both documents now say so, and §10
  marks it as the one STEP invoked whole.
- **A substep is no longer mistaken for a conditional architecture session it has nothing to do
  with.** When `scripts/status.sh` points you at an optional architecture session, it suggests the
  by-name phrase to invoke it with — and it worked out which session by searching the label for a
  keyword, anywhere in the text. So a substep called `Authoring conventions & style guide` was
  advised as *"run the identity-auth session"*, because *auth* sits inside *Authoring*, and
  `Desktop publishing pipeline` was pointed at the native-app session. Anchoring alone would not
  have fixed the second — that label genuinely does begin with *desktop* — so the match is now
  against the session's own name rather than a loose keyword. A label matching none of them falls
  back to the generic "invoke it by name", which was always correct advice. Anchoring
  also cost one keyword on the way past: the privacy session had matched a bare `compliance`
  anywhere in a label, which is now gone — `privacy` and `data governance` still match, at the
  start of the label.
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
- **A backup the wizard could not create is now reported, and the exit status says so.** `init.sh`
  offers to create Git remotes and push to them. When a push was refused — the repository exists but
  the account cannot write to it, credentials have expired — what happened next was decided by where
  each call sat relative to `set -e` rather than by any decision. A mono-repo run ended right there, with the project
  already generated and committed and the closing instructions never printed — whether it was handed
  a remote URL or asked the wizard to create one. A multi-repo run carried on and **exited 0**,
  telling a caller reading the status that a backup exists when it does not; `--non-interactive` is documented as being for scripts and CI, so that
  status is a contract. Both layouts now finish the same way: the failure is recorded rather than
  left to steer control flow by accident, the closing instructions print regardless — the project is
  complete, and those instructions are what is needed to finish the backup by hand — and the run then
  names the repositories whose backup did not complete and exits non-zero. The report is careful
  about what it claims. A command that stopped tells you it did not finish, not how far it got, so it
  gives the three commands that settle where the run actually stopped instead of asserting nothing
  was pushed, it names the repositories as they exist on your host and maps each to the local repo it
  backs up — per layout, since which names can appear is layout-decided — and it asks you to record
  the URL on that repo's row *if it is not already there*, which is true of both failures that reach
  it. A refused push of the registry commit is a failure on the same terms: it used to print a
  parenthetical and return success, so the run said `Done.` and exited 0 with the remote's copy of
  `registries/repos.yml` listing no remotes at all, which is a registry a teammate would clone
  nothing from. **The exit status changes from 0 to non-zero for this case, in
  both layouts** — always in multi, and in mono whenever the run got a remote at all.
- **The closing note no longer tells every project that deleting `init.sh` is free.** It read "You
  can delete this init.sh now — it has done its job" in both layouts, and it is only true in one. In
  a multi-repo workspace the root is not a repository, so the file is on disk and deleting it is the
  whole of it. In a mono-repo project the root *is* the project's repository and the first commit
  takes `init.sh` in, so deleting it removes the working copy and leaves the file in the history for
  good. The behaviour is deliberate and unchanged — excluding the file from that commit would leave
  every generated project with a dirty working tree, and the next ordinary `git add -A` would commit
  it anyway — so the note now says whichever is true, and `init.sh` records why it is left in place
  and why the script does not delete itself. The retained copy is a snapshot of the generator, with this
  run's slug substituted into it. It is not a version stamp: it names no version, and the licence posture, ADR authority, trunk
  branch and layout are each recorded elsewhere.
- **The wizard's layout and collaboration menus accept the words they offer.** Each question had two
  answer paths that did not agree. A flag went through a normalising `case` that took the friendly
  word or the number and rejected anything else; a typed answer was assigned raw, and every check
  downstream compares against `1` or `2`. So the word the menu itself printed did not work. Typing
  `mono` did not cleanly build the wrong layout — it built a hybrid, because one branch is written
  `if layout is 1 … else …`, so the stray value took the mono side of that single decision and the
  multi side of every other, leaving `prompts/` a repository of its own and the scaffold licence
  notice at a workspace root that layout never clones. Typing `team` built a solo project whose ADR
  register never records who accepts an ADR. Both exited 0 and said nothing. Each answer now goes
  through one normaliser, the shape `--license` already used: a bad flag stays fatal, a bad typed
  answer is re-asked, the way the slug question always has been. That makes true what `init.sh` says
  of itself at the top — validation happens at the call sites, so flags, env vars and interactive
  answers share the same checks.
- **An answer the setup wizard does not understand is no longer read as "no".** `init.sh` asks
  three yes/no questions, and the helper behind them accepted only `y`, `Y` and `yes` — everything
  else fell to a catch-all that meant no. So `YES`, `Yes`, `1` and `true` each silently declined,
  most consequentially at "Set up online Git remotes now?", where declining is the answer you
  cannot correct without doing the work by hand afterwards. The licence and visibility menus re-ask on an answer they do not
  recognise, and the slug question always has; this one did not, and the inconsistency was more of
  the defect than the vocabulary was. It now re-asks in the same voice as its siblings, and the
  words it accepts are the ones `--remotes=` and `--registries=` already took, from one shared
  check, so a typed answer and a flag value cannot drift apart.
  **A required answer left blank is re-asked too.** `--non-interactive` refuses a missing
  description; the interactive path accepted one, which made the friendlier route the one that
  let an empty value through — into `AGENTS.md`, `templates/planning-session.md` and every
  architecture session template. A blank copyright holder did the same to an open-source project,
  shipping `Copyright (c) 2026 ` with nothing after it in every generated repo, with the doctor
  reporting no failures. An exhausted answer stream takes the advertised default at a yes/no
  question and exits 2 with the missing prompt named at a required one. The questions that go
  through `ask` rather than `yesno` or `want` were not covered by that and are fixed in the entry
  below.
- **The setup wizard no longer acts on an answer nobody gave, and says what it discarded.** Four
  of its questions offered the answer you get by leaning on Enter, and each of the four is fixed
  at the moment the project is created or reaches off this machine: the open-source licence menu
  handed out MIT, an irrevocable grant nobody named; the repo layout menu picked multi; the
  solo/team menu picked solo, which writes an ADR register naming the reader as its own acceptance
  authority; and the remote setup menu picked *create repositories on GitHub under your account*.
  None of the four has a default now — blank and whitespace are not answers to them, and the
  question comes back. An unrecognised answer at the remote menu is re-asked too, rather than
  ending the run, which is how every other menu here already behaved. Three defaults were weighed
  in the same pass and deliberately kept, because accepting one by accident costs a setting rather
  than a project: the project-type question (proprietary, which licenses nobody), GitHub
  visibility (private), and who accepts ADRs. The `main` trunk branch keeps its value too, and
  nobody is ever asked about it, so there is nothing there to fat-finger.

  **End of input ends the run.** `ask` ignored `read`'s exit status, so an unattended run — an
  agent, a script, `< /dev/null` — was handed an unlimited supply of empty answers. At the slug
  question, which re-asks until the answer is valid and where blank never is, that was not a wrong
  result but no result: measured at 94KB of the same re-ask notice in twelve seconds before it was
  killed. A question with a default now takes that default at end of input, the way `yesno` and
  `want` already did; a question without one stops the run and names the answer it is missing. The
  fix is a precondition for the removals above, since a question made to insist on an answer
  inherits that loop.

  **A repository that is already under `prompts/` is refused.** The fresh-template guard only ever
  read the workspace root, and the multi layout initializes a second durable repo one directory
  down. Measured: `git init`, a commit, and `git branch -M` ran inside a repository that was
  already there, leaving it two commits deep with its branch renamed from `work` to `main`, and
  the run exited 0. It is refused before the destructive boundary now, by the same check that
  refuses the other five shapes, and refusing leaves that repository byte-for-byte as it was found.

  **A flag that cannot apply is named rather than dropped in silence.** Each layout reads the
  remote-URL flags that match its shape, so one of the two sets is always unusable: a mono project
  has one repository and no use for `--docs-remote` or `--prompts-remote`, and a multi project has
  two and no use for `--remote-url`. Passing the wrong set produced a project whose remotes
  contradicted the command that created it, with nothing in the run admitting the difference. Each
  now prints a line of the form `note: ignoring --docs-remote — mono layout has one repo` and the
  run continues. Refusing was considered and rejected: a wrapper passing one harmless extra flag
  should not fail, and being told is the whole of what was missing.

  **The same goes for an answer that cannot apply.** A mono project's one repository is the
  workspace root, so when that folder already has an empty Git origin there is nothing for
  "create a repository on GitHub" to create — the origin is reused instead. That is the right
  outcome, since replacing a remote you attached yourself would be the real surprise. Saying
  nothing about it was not: `gh` was never called, the owner question simply did not appear, and
  the substitution surfaced only as a line calling the result a reuse, printed after the point
  where the run stops being reversible. It is now named where it happens, before that point, with
  the URL that will be used and the fact that stopping there costs nothing.

  **And the slug question's refusal now describes the rule it enforces.** The pattern requires a
  first character that is a letter; the refusal read "lowercase letters, digits, hyphens only",
  which `3d-printer` obeys and the pattern still rejects. On the flag path that costs a minute. At
  the prompt it costs more, because the question re-asks and the reader has been told to correct
  something already correct, with nothing in the message leading anywhere that works. One string
  serves both paths and now names the whole pattern. What is accepted has not changed.

  **The layout menu says what each layout does to the folder you are standing in.** Multi-repo
  leaves the workspace root a per-machine shell with no repository at all, so a file put there
  afterwards is tracked by nothing and backed up by nowhere. The menu said only that `prompts/`
  and the docs hub "become separate repos", which never said separate from *what* — separate from
  each other, or separate from a root repo that still exists? The `README` states it twice and the
  wizard stated it nowhere, which is the wrong way round, because the wizard is where the choice
  is made and cannot be revisited. Both options now name their own consequence.

  **`private` and `proprietary` no longer mean the same thing.** The licence question offered
  "Private / proprietary" and a question twenty lines later offers "1) Private" for who can see the
  repository — the same word for two unrelated settings, in one run. They are independent: a private
  repo can carry MIT, and a public repo can be proprietary. Read the first question as being about
  visibility and you answer it, and get a project licensed to nobody. `proprietary` is now the
  licence word everywhere — the menu label, the flag value, and the internal token, which had stayed
  `private` while `.throughstone/project-license` already wrote `Proprietary` — and `private` refers
  to repository visibility and nothing else. The licence question also says, in one line, that
  visibility is asked separately later.

  `--license=private` still works and still produces exactly the same project, so a wrapper that has
  always passed it does not break; it prints a deprecation notice naming `--license=proprietary` and
  will be removed in a future release. Deprecating rather than refusing, for the same reason an
  unusable flag is named rather than refused. `--visibility=private` is untouched.

  **The mono-repo + team caveat now turns on the two answers it is about.** Choosing that
  combination makes the overlap warning useless — it is repo-granular, and there is one repo — and
  the note saying so sat inside the branch that *asks* who accepts ADRs. Its real condition was how
  that one unrelated value arrived: measured on three identical mono + team projects, typing the
  ADR authority printed the note, passing `--adr-authority` did not, and `--non-interactive` did
  not. Same project, same limitation, one warning. It now prints for all three, and for neither
  neighbouring combination. It also says that nothing has been created yet and the run can still be
  stopped — which was already true and which nothing on screen admitted.

  The line above it had the same defect and is fixed with it: **every team is now told that team
  collaboration relies on shared remotes**, not only the teams that happened to type their ADR
  authority rather than pass it.

  **And `--adr-authority` on a solo project is named rather than dropped.** A solo project records
  the author as the authority — the register is stamped `_solo author_` and the question is never
  asked — so a supplied authority has nothing to attach to. It used to exit 0 with no mention of the
  flag at all. It now prints `note: ignoring --adr-authority — a solo project records you as the
  authority`, and a team project passing the same flag still gets exactly what it asked for, in
  silence. `INIT_ADR_AUTHORITY` is the same story.

  **"Use existing remote URLs" now says what those URLs have to be.** Each repository must already
  exist, be empty, and be reachable with your credentials — three requirements you used to discover
  by refusal, after typing both URLs. Nothing is lost when that happens, because the check runs
  before the run touches anything; what is lost is the whole interview, since there is no resume and
  one pasted string sends you back to the project name. The requirements were already written down,
  but only on the branch taken when `gh` is missing — so the wizard explained itself exactly where it
  could not offer the easier option, and not where it could.

  **And the closing note agrees with the layout menu about what is actually saved.** Telling a
  multi-repo reader that the workspace root is not a repository — which the menu now does — left the
  closing line *"your project is saved locally with Git"* contradicting it a few screens later, in
  the same run. Between a warning and a reassurance a reader takes the reassurance, which is the
  wrong one here. The line is now per-layout, the way the `init.sh`-deletion note beside it already
  was: a mono project is told everything in the folder is in its repository, and a multi project is
  told which two repositories hold the committed work and that files at the root are in neither.
  Both now also say the work was **committed**, which neither of them used to mention at all.
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
- **A mistyped argument to a helper is no longer silently ignored.** `scripts/check.sh`,
  `scripts/status.sh`, `scripts/links.sh` and `scripts/setup-workspace.sh` read no arguments at all,
  so anything passed to them was discarded without a word — `./doctor.sh status --check-in` ran an
  ordinary status report and exited 0, and a flag aimed at the wrong helper looked like it had
  worked. The dispatcher's own `help` arm did the same: `./doctor.sh help --nonsense` printed the
  help text and exited 0, treating the argument as understood. All four now report the argument and
  exit 2, so one entry point behaves one way. Every valid invocation is untouched, `--check-in`
  included. **If you drive these from a wrapper or a CI step that passes a stray argument, it will
  now fail rather than be ignored.**
- **The architecture STEP's close-out is no longer skipped.** `scripts/status.sh` decided STEP-1
  was finished by counting substeps, and ignored the STEP-1 row's own status. But the row is what
  records completion: the Cross-Cutting Review has to run and STEP-1 has to be archived to
  `prompts/` before the row goes `Done` — "once the review is clean", as the review session itself
  puts it. So the window between the last substep going `Done` and the row being flipped is not a
  glitch, it is where the close-out work lives, and a review with open findings sits in it by
  design. In that window the resolver reported "Architecture (STEP-1) complete" and sent you
  straight to the planning session, contradicting an index that still said `In progress` — while
  `METHOD.md` §10 ends by making the index authoritative for which STEP is next. It now names the
  close-out as the next action and quotes the row status back to you, and it is unchanged when the
  row reads `Done`, `Deferred` or `Abandoned`, or when there is no STEP-1 row at all.
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
  requested. The flags that validate their value — `--slug`, `--layout`, `--license`,
  `--collab`, `--remotes`, `--trunk-branch` — refused, but only by accident; the free-text ones
  (`--desc`, `--holder`, `--adr-authority`, `--owner`, the remote URLs) took it silently. Every space-form flag now
  checks its value before using it, and says which flag is short and what to write instead. The
  `--flag=value` form is untouched, so a value that genuinely begins with `--` is still sayable.
- **The last few "run this" instructions run.** `METHOD.md` told you to run `scripts/check.sh`
  after renaming a session and offered `scripts/status.sh` as the shortcut a resuming agent runs
  first; `UPDATING-THROUGHSTONE.md` said to run `scripts/check.sh` in two places. None of those
  exists from the workspace root, where the reader is — each exited 127. They now name
  `./doctor.sh check` and `./doctor.sh status`, which sit at the root and are the front door the
  dispatcher advertises. Deliberately unchanged: the many sentences in hub documents that *name* a
  helper rather than tell you to run one, such as `UPDATING-THROUGHSTONE.md`'s own references to
  `scripts/status.sh` and `scripts/check.sh` when it is describing them rather than invoking them.
  A document inside the hub writes the hub's own contents hub-local, and those are references, not
  commands.
- **`AGENTS.md` keeps the promise it opens with, and the ADR duplicate scan finds duplicates.**
  `AGENTS.md` told its reader that its paths are relative to the workspace root — then wrote
  roughly twenty of them relative to the docs hub instead. The costly one was a command: an agent is told to scan the ADR register for duplicate
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
- **The tools print paths you can open.** A path a tool prints follows the reader, not the tool.
  `scripts/status.sh` — the helper a resuming agent runs *first* — named `overview.md`,
  `BOOTSTRAP-PROMPT.md`, `templates/planning-session.md`, `templates/release-notes-template.md` and
  `METHOD.md` from inside the docs hub while answering someone standing at the workspace root, and
  it never derived the hub's location relative to that root at all. It also told you to run
  `scripts/check.sh`, which fails from there; it now names `./doctor.sh check` and
  `./doctor.sh status`, the front door the dispatcher advertises. `scripts/check.sh` had the same
  split personality inside a single run — check 1 headed itself `prompts/STEP-index.md` from the
  workspace root while checks 2 and 10 named `adr/README.md` and `overview.md` from inside the hub —
  and so did several of its fix hints. Every path those two scripts print, and every path
  `scripts/setup-workspace.sh` prints, is now written from the workspace root, so you can open what
  it names without working out which base it meant. The setup wizard's two prompts that named a file
  inside the docs hub now name it in full, using your project's real name.
- **Instructions in the docs now work from the directory they tell you to stand in.** Two of them
  did not, and one is on the path anyone walks regularly: the first line of the periodic check-in
  told you to run `scripts/check.sh`, which fails from the workspace root where you actually are,
  and so did the setup a new contributor is told to run. Each now names the script the way
  `scripts/setup-workspace.sh`'s own usage header always has: from the workspace root, in full.

  Behind them, the path convention in `METHOD.md` §7 sorted documents into two piles — top-level
  agent-facing docs, and `templates/` — and put `runbooks/` in neither, which is where most of the
  unfollowable instructions lived. It now turns on what a path is *for*. A shell command is written
  from where the text stands you, the workspace root unless the text says otherwise; everything else
  follows the file it is written in, which inside the docs hub means relative to the hub. It also
  settles what "relative to the hub" is measured from, what a bare `status.sh` or `architecture/`
  means, where the placeholder rule lives, and that a Markdown link target follows Markdown rather
  than either convention — so a sweep cannot quietly break your links.
  `AGENTS.md` had copied the old wording into its own header and drifted from it; it now states
  where its paths are relative to and points at the rule instead of restating it, and `ONBOARDING.md`
  gains the same one-line declaration.
- **One repository you cannot clone no longer costs you the whole workspace.**
  `scripts/setup-workspace.sh` is what every developer after the first runs to assemble the project
  on their machine. It used to clone the repos `registries/repos.yml` gives a `remote:` *before*
  writing the workspace root's `AGENTS.md`, `CLAUDE.md` and `doctor.sh`, so a clone that failed
  aborted the run before it reached those files and the contributor ended up with **no workspace at
  all** — over a repository they may not even need. Four situations did it, all measured: a remote nobody on
  the team can reach, a stray folder or half-finished clone already sitting where a repo should go, a
  `location:` left behind as an absolute path from the first developer's machine, and — less
  ordinarily — a registry file the parser could not read at all. A failed clone is now reported and the run
  continues; the pointer files are written before the clone step rather than after it; the parser
  feeds the loop directly so its own exit status cannot take the run down; and the closing line says
  how many repos did not arrive instead of reporting plain success. `ONBOARDING.md` and `AGENTS.md`
  both described the old order and now describe the new one. A `location:` beginning with `-`
  also used to reach `git` as an option and kill the run — the clone arguments now sit behind `--`. Fix a bad `remote:` or `location:`, or clone that repo by hand, and re-run — repos
  already cloned are left alone.
- **`init.sh` could destroy a repository it was run inside.** Unpacking the template into a
  repository you already had — the natural thing to try when you want Throughstone in a project
  that exists — and running `./init.sh` there deleted that repository's `.git` outright, every
  commit with it, at exit code 0 and with no warning — along with anything you kept in `tests/`,
  `docs/`, `.github/` or a root `README.md`, which the bootstrap removes as template-only files. The bootstrap is one-time and destructive by design — it removes the template's own git
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
  repo's `main` branch" — which the rewritten `runbooks/collaboration.md` §9 expressly tells a mono
  project *not* to do — a mono workspace has one repository and so one remote, not several, and
  the rows below the root are folders inside it rather than repos to clone. The tip is now
  layout-conditional: mono is told to check what origin it already has, push the root repo's trunk
  to it or create one empty repo for it, and record that URL on the single `location: "."` row. The
  multi tip is rewritten too — it names the two repositories, adds the `git remote add origin <url>`
  step it had been missing, and writes the registry path in full. The mono + team kickoff note stopped citing the repealed
  split-before-a-teammate rule in the same change — the observation under it still holds
  and is still printed, but it now points at the fallback `collaboration.md` §4 prescribes rather
  than telling you to split.
- **The STEP-authoring recipe numbered two different steps `5`.** `prompts/README.md` walks you
  through authoring a STEP in numbered steps, and both *Write the substep prompts* and *Update
  `prompts/STEP-index.md`* were `5.`, so the list ran 1-2-3-4-5-5-6 and "step 6" named two things.
  Renumbered to 1 through 7, and the file's own "see the recipe, step 6" cross-reference — which
  pointed at the completion step — moved with it.
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
  migration step.
- **A mono-repo project's registry left out the only repository it had.** `registries/repos.yml`
  calls itself the source of truth for which repos exist, and in a mono-repo-for-now project it
  listed the docs hub and `prompts/` — both folders — while the workspace root, the project's one
  actual repository and the only git work tree in it, had no row at all. `init.sh` now seeds that
  row: `location: "."`, `type: mono` and `added_as: created`. When the wizard sets up a remote it
  records that URL on the row too, once the trunk branch has actually been pushed — without it the
  project's own backup would be reported at every check-in as backing up nothing. Nothing reads the
  row on the ordinary path; at check-in it is what tells the registry check that the folder rows
  below it live inside one repository, so that a mono project is asked about one remote rather than
  three. Prose describing a mono project's registry rows as folders inside the single repo has been
  corrected wherever it appeared — the registry header, the setup script's closing tip and the
  solo-to-team runbook. Existing projects are not rewritten; `UPDATING-THROUGHSTONE.md` carries the
  row as a migration step.

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
