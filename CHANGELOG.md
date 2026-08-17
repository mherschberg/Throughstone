# Changelog

All notable changes to Throughstone are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this
project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). Versions here
refer to the **Throughstone scaffold** (the method, templates, runbooks, and tooling), not to
any project built with it.

## [Unreleased]

Work toward the **2.0** line, which adds **existing-codebase adoption** ("retcon"): a new project can
be stood up by reverse-engineering a running system instead of interviewing its architecture from
scratch. Entries accumulate here as the capability lands. The adoption capability is
**greenfield-inert** — a project stood up from scratch never enters it and behaves exactly as before.
**Changed** also carries a few fixes that are not adoption-specific: the session-template contract
(which leaves a normally-invoked session behaving identically) and robustness fixes that touch only
error/corruption and re-run paths, not normal operation.

### Added
- **Existing-codebase adoption front door** (`init.sh` → `RETCON-PROMPT.md`) — `init.sh` now opens with
  a new-vs-existing question (`--mode=new|existing`, or `INIT_MODE`; default `new`). On **existing**, it
  stands up the same scaffold as a greenfield project but in **adoption ("retcon") mode**: it sets
  `PROJECT-STATUS: retcon`, seeds the greenfield-identical STEP index, and drops a stub **STEP-1 PLAN**
  whose substeps are the inventory work. `scripts/status.sh` and `AGENTS.md` recognize the `retcon`
  status and route a fresh agent to a new **`RETCON-PROMPT.md`** resolver, which reverse-engineers the
  architecture baseline from the running code instead of interviewing it from scratch — running the
  intake, inventorying every repo/doc/resource, drafting a recon map you confirm, and writing the real
  STEP-1 plan. The per-session harvest→confirm and the land at a `Done STEP-1` baseline (equivalent to a
  greenfield one, from which the ordinary forward flow continues) arrive in the remaining 2.0
  increments. **Default mode is `new`**; a project stood up from scratch never enters this path and is
  unchanged.
- **`throughstone:` field on repo rows** (`registries/repos.yml`) — records how the method relates to
  each repo (`managed` today; `external` reserved for a later partial-adoption feature). Inert
  (nothing reads it yet) and read as `managed` when absent, so existing inventories are unaffected.
  Both the greenfield and adoption front doors write it identically, so their repo inventories match.
- **`license:` field on repo inventory rows** (`registries/repos.yml`) — records what each repo is
  licensed under, so the inventory shows the licensing picture across every repo at once, which no
  single `LICENSE` file can and which starts mattering as soon as a project's repos don't share one
  license. For a repo the method creates it is the bootstrap posture, which `init.sh` substitutes
  into the seed rows **and into the worked example beside them**, so the pattern an agent copies
  matches the project it is copying it into; for an adopted repo it is what that repo already
  says, recorded as found — an
  identifier and the file it came from, or `none stated`. It is a record, never an instruction: the
  repo's own license file stays authoritative, a missing value means "not recorded" so existing
  inventories are unaffected, and repos carrying different licenses is a normal inventory rather
  than an inconsistency to reconcile.
- **Recon-map report template** (`templates/reports/recon-map-report-template.md`, indexed in
  `reports/README.md`) — the point-in-time "birth certificate" an adoption produces at STEP-1:
  inventory, stack per repo, services, data stores, integrations, existing-docs classification,
  tests/CI, and a Coverage & Confidence ledger. The user confirms it before anything is built on it,
  and its confirmed inventory is frozen afterward. A greenfield project never produces one.
- **Pre-answer-sheet convention** (`templates/retcon-preanswer-sheet.md`) — the per-session working
  sheet an adoption's harvest writes: a drafted answer to each session decision, read from the running
  code and provenance-tagged, confirmed with the user before the clean `architecture/` doc is written.
  `init.sh` scaffolds an `Upcoming Prompts/retcon/` scratch home for these when adopting an existing
  codebase.
- **Adoption harvests the architecture sessions instead of interviewing them** (`RETCON-PROMPT.md`
  Stage 3). For each in-scope session, adoption reads the session template as reference data, drafts
  an answer to every decision **from the running code** into that session's pre-answer sheet, confirms
  each answer with you proportionate to confidence and consequence, then writes the clean
  `architecture/` doc from the shared doc template. Decisions the code cannot answer — intent, scope,
  what comes next — are asked directly, as greenfield would. Anything left unconfirmed is recorded as
  `Coverage: deferred` with a tracked risk rather than guessed into fact, and provenance stays in the
  working sheet, never in the architecture doc. Also true of the harvest:
  - **It never invents decision records.** A decision the harvest read out of your code is described
    in the doc's Decision Summary, never written up as an ADR — that would date and rationalize a
    choice nobody stated. If *you* make a decision during adoption, or tell it that one was made and
    what drove it, it says so and asks before recording an ADR.
  - **Sessions run one at a time and survive interruption.** Each session is harvested, confirmed, and
    written before the next begins, so every harvest reads its predecessors' confirmed docs instead of
    drafts. A session in progress resumes from its sheet — the confirmations you already gave are
    never re-asked or overwritten.
  - **Nothing is skipped silently.** A conditional session the map includes is tracked and harvested
    like any other, and a session whose area your system doesn't have (a UI session on an API-only
    service) is recorded `N/A` or `Deferred` with a reason read from the code.
  - **You decide what's in scope, and a UI that exists is described, not re-chosen.** A scan of a
    real system turns up things you don't want adopted — an abandoned service, a dead prototype —
    so the confirm gate settles each asset as adopted or excluded, and only the adopted ones become
    work; an excluded one stays recorded as found-and-dismissed. And where a new project's UI
    session offers you palettes and type scales to choose from, an adoption reads the ones your
    product already ships and writes them down.
  - **Your existing documents get used, not just filed.** Adoption copies every document it finds
    into `inputs/`, then the session covering that area acts on it: a finished spec or still-true
    design doc is **lifted** into `architecture/` as the living copy (the original stays as
    provenance), a PRD or research note is synthesized into the doc being written, decision records
    your team actually wrote are adopted into `adr/` with their original dates and registered there,
    a still-accurate runbook lands in `runbooks/`, and the
    `inputs-index.md` ledger records what has been superseded and what still holds. Where a document
    disagrees with the code, the code wins and the disagreement is written down as staleness rather
    than averaged away. Nothing is retired without you — a fully-superseded input is offered for
    archiving, never moved automatically.
  - **You still end up with a project brief.** A new project writes `overview.md` during the kickoff
    interview; an adopted one skips that interview, so the System Overview session writes the brief
    instead — from the answers it just confirmed with you, once its architecture doc is written. It is
    the file every later session, the planning session, and every check-in opens first.
  - **Roadmap planning runs last.** Every session but one has an as-built half to read; Phasing is
    purely forward, so adoption floats it to the end, after the rest of the baseline exists. It plans
    on the finished description of your system rather than ahead of it, names your next milestone, and
    fills the Phase-1 name the STEP index needs before the baseline can be archived. The sessions that
    normally read Phasing harvest from the code instead and carry the "does this still fit the
    roadmap?" question to the Cross-Cutting Review.
  - **A deferral is presented as a trade, not a checkbox.** When an area is too large to read
    exhaustively, adoption stops and tells you what deferring costs — this part of the baseline stays
    incomplete, and work leaning on it is less reliable until backfilled — before you choose. The
    warning then follows the gap: the doc's `Coverage:` line says what is missing, how big it is, and
    what it means for someone building on it (never a bare "deferred"), and a genuinely risky gap gets
    a `risks.yml` row the periodic check-in re-surfaces.
  - **Your repos' READMEs are added to, never overwritten.** A repo you already have has a README,
    usually its most-read file, so adoption does not stamp the Throughstone template over it.
    Everything in that template except the role one-liner is something a running system already
    documents — setup, tests, configuration — written by the people who operate it. What such a
    repo usually lacks is what adoption is producing: its place in the system. So it offers exactly
    that, a short `Role in <project>` section, shows you the text and where it would go, and waits
    for your yes. Declining is a complete answer — the same information is in the recon map, the
    repo's architecture doc, and its inventory row — and nothing else in the README is touched.
    What decides this is whether a README is already there, not that the repo was adopted: where a
    repo has none, adoption offers to write one from the template — that one file, since adopting
    a repo scaffolds nothing else in it. **You are told the shape of this before it starts, and
    asked once if you don't want it.** The recon map's new **Docs (as found)** column records, per
    repo, whether it explains its place in the system, so confirming the map also tells you what
    is coming — *"11 of your 14 repos have a README that doesn't say what it is within the system;
    3 have none"* — instead of proposals arriving one at a time from nowhere. That line is an
    observation, not a gate: nothing asks for a blanket yes before any text exists, because the
    text is what you are agreeing to. And a decline can stand for the rest, so you say no once
    rather than once per repo.
  - **An accepted README addition is committed on a branch and left for you.** Adoption told the
    agent to show you the text and wait for a yes, then said nothing about what happens to the
    file — so the obvious next move was a commit on whatever branch was checked out, which on a
    repo you already run is usually `main`, and a push to your remote. Your yes was about the
    text, not about how a change reaches your trunk; that is your review process, not the
    method's. It now makes a branch, commits **only the file it proposed** (never `git add -A`,
    which would sweep up work in progress), tells you the branch and commit, and stops — no push,
    no pull request, no merge. If that file already has uncommitted changes, it says so and leaves
    it alone. The same goes for a README written from the template where a repo had none: one
    file, on a branch — and never an `ARCHITECTURE.md` at your repo's root, which is where the
    template's Overview comment would otherwise point. That write-up goes in the docs hub.
  - **Your repos are never published, and their remotes are never touched.** Adoption said nothing
    about either — every repo it registers already lives somewhere and is already private or
    public, both decisions made before the project existed. It now says so outright: no remote is
    created for a repo that has one, no existing remote is repointed, and **no repository's
    visibility is changed, in either direction, for any reason.** The URL a repo already has is
    recorded in its inventory row so `scripts/setup-workspace.sh` can find it, and nothing about
    the repo itself is touched. If you ask for a repo to be published, that is a go-ahead for that
    repo and nothing else — never standing, never extended to a sibling. Adoption is where this
    matters most: many repos in flight across a codebase the method didn't write, and publishing
    is the one action here with no undo.
  - **Your CI is left alone, and the Throughstone notice follows what was actually added.**
    Adoption never installs Throughstone's CI workflow into a repo you already have — that gate
    fails until configured, so in a running system it would either replace the workflow gating your
    merges or redden every build until someone removed it. What each repo already runs was recorded
    in the recon map and is written up by the Test Strategy session; moving a repo onto the
    standard gate stays a decision you make later. And the Throughstone notice is placed only where
    Throughstone-authored material actually landed: if you accepted the `Role in <project>` README
    section, the repo gets `LICENSE-THROUGHSTONE` plus a `LICENSING.md` scoped to that material and
    disclaiming everything else — never a project `LICENSE`. If you declined, nothing was added, so
    nothing is claimed.
  - **Your repos' licensing is recorded, never set.** Adoption registers every repo where it already
    sits, so each one's licensing stays its owner's: the recon map records what each repo actually
    says — the identifier and the file it came from, `none stated` where nothing does, plus vendored
    third-party terms — and nothing writes a `LICENSE` into a repo you already had. The license you
    pick covers this method's own artifacts and anything it creates for you, so adopted repos
    carrying several different licenses is a normal result rather than an inconsistency to
    reconcile.
  - **The license question is asked after your codebase has been read, not before.** In adoption,
    `init.sh` no longer asks it at install time — at that point nobody has read your repos, so the
    question arrives with nothing to answer it from, and phrased as "open source or private?" it
    reads as being about the code you're bringing rather than about the docs hub being created.
    Adoption now leaves the choice open and asks once at the recon-map checkpoint, where each repo's
    licensing has just been recorded and is in front of you, offering what your repos say as the
    default. A new `scripts/set-project-license.sh` answers it in one command — the posture, the
    canonical `LICENSE`, and the files init left saying the license had not been chosen — and
    answers it once, refusing to change an answer already given. Until then no `LICENSE` is written
    and nothing is claimed. Where your repos differ from what you chose, you're told once, at that
    checkpoint, and nothing is reconciled or written into them. **Greenfield is unchanged** — it
    creates everything it licenses and has nothing to read first, so it still asks at setup, and
    `--license=NAME` still decides at install time in either mode.

### Changed
- **`status.sh` no longer guesses when the kickoff marker is missing.** If `overview.md` exists but
  carries no recognized `PROJECT-STATUS` value (`not-started` / `retcon` / `kickoff-complete` — a lost
  or corrupted marker), the helper now reports the status as **indeterminate** and points at the
  `AGENTS.md` "First action" decision, instead of confidently resolving the index (which on a bare seed
  could misreport "Run STEP-1.1" — wrong both for a pre-kickoff greenfield and for a retcon whose marker
  was lost). Normal operation, with a valid marker, is unchanged; this hardens greenfield and adoption
  alike.
- **`init.sh` refuses to run outside a fresh template checkout.** The one-time bootstrap is destructive
  (it removes `.git` and template-only files), so it now checks for the template sentinel in the root
  pointers before doing anything and stops with a clear message if it is absent — preventing a
  second run inside an already-initialized project (which could delete the generated repo's history)
  or a run on top of an unrelated repo. A first run on a fresh download is unaffected.
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
- **Where the create-vs-registered-in-place rules don't settle a case, the answer is now to ask
  rather than to improvise.** Everything the method does to a repo — stamp or augment its README,
  install CI or leave its pipeline alone, apply the project license or record what it already
  says, place the Throughstone notice or owe nothing — splits on whether the method created that
  repo. Those rules enumerate the cases the method has met, and a real project produces ones they
  don't reach: a repo the method created that another team has since taken over, a README that is
  half boilerplate, a repo whose own files disagree about its license, a notice
  `--notice-only` refuses to place after the README text has already landed. `METHOD.md` §7 and
  the repo README template now close with the same fallback — where it is genuinely unclear which
  side of that line a repo sits on, or what a rule means for it, **ask, and write nothing into
  that repo until there is an answer**. Not writing is recoverable; writing into a repo the method
  did not create is the failure those rules exist to prevent. It is stated as a fallback for cases
  the rules don't reach, explicitly not as a substitute for following them where they do or for
  fixing a gap once one is found. No effect on a repo the method creates, which is settled and
  unchanged.
- **The interactive project-type question now defaults to private / proprietary.** It defaulted to
  open source, so pressing Enter past it — and Enter again at the license menu, which pre-selects
  the first entry — stood a project up under MIT without the user ever naming a license. That is
  the wrong direction for a default to fail in: publishing code under a license nobody chose is not
  undone by editing a file afterwards, while a project that starts proprietary can be opened by its
  owner whenever they decide to. An open-source posture is now reached only by typing `1`, which
  matches what `--non-interactive` already required (an explicit `--license`, no default) and the
  private default already used for repository visibility. Nothing else changes: both answers behave
  exactly as before once given, `--license` is unaffected, and no generated project is rewritten.

### Fixed
- **`init.sh` would destroy an existing repository it was run inside.** Extract the download into
  your own repo and run it — the mistake adoption invites, since `--mode=existing` is aimed at the
  one population that has a repository — and the fresh-template guard saw the template's own
  sentinel, agreed it was fresh, and continued past the destructive boundary. In multi-repo layout
  that **deleted the repository's `.git`** outright; in mono-repo layout it replaced the history
  with a bootstrap commit, wrote a project `LICENSE` next to whatever terms the repo already
  stated, and added a `LICENSING.md` asserting that license over the whole repository — the exact
  claim `scripts/apply-project-license.sh` refuses, arriving by the one path that never calls it.
  The guard now also refuses a directory whose Git history is not the template's own, before
  anything is removed, and says where the code is meant to stay instead. A template in a plain
  folder, a cloned template, and the mono-repo empty-origin reuse flow (`git init` plus a remote,
  nothing committed yet) all initialize exactly as before.
- **Adoption's "run this from a fresh directory" notice only appeared when the mode was chosen at
  the prompt.** It lived inside the interactive branch, so `--mode=existing` and `INIT_MODE` — the
  two paths most likely to be scripted, and no less able to be run from the wrong place — printed
  nothing. It is now said once, however the mode arrived.
- **The record that justifies leaving an in-place repo's CI alone had nowhere to go.** The rules
  are settled: the starter gate in `templates/ci/code-repo-ci.yml` fails until configured, so it is
  never installed into a repo the method did not create — and four files (`METHOD.md` §7,
  `templates/ci/README.md`, the repo README template, and the upgrade notes) all say to record what
  that repo's pipeline runs **in the Test Strategy architecture doc** instead. The Test Strategy
  session was never told to record it and had no slot in its output to record it into, so the
  record they promise was left to an agent to invent a home for or skip. Skipped, the resulting doc
  describes only the repos the method created — which reads, to anyone later, as though the others
  have no CI at all, the exact opposite of why they were left alone. Session 12 now covers it in
  its CI-gates decision and carries an **Existing pipelines** output section (one row per repo
  registered in place: what its CI runs, where it's configured), with a note that a repo registered
  after the session first ran is added by editing the doc and bumping its version rather than
  re-running the session. The section is omitted when a project has no such repo, which is every
  project built from scratch.
- **`init.sh` would destroy an existing repository it was run inside, and had no guard at all.**
  Extract the download into your own repo and run it there — a natural thing to do, and more so
  since `METHOD.md` §7 began letting a repo be **registered in place**, which gives a user with an
  existing repo every reason to be holding the template near it. In multi-repo layout that
  **deleted the repository's `.git`** outright: no longer a repository, no replacement commit,
  nothing to recover without a remote. In mono-repo layout it replaced the history with a bootstrap
  commit, wrote a project `LICENSE` next to whatever terms the repo already stated, and added a
  `LICENSING.md` asserting that license over the whole repository — the exact claim
  `scripts/apply-project-license.sh` refuses, arriving by the one path that never calls it.
  `init.sh` now refuses before removing anything, in two cases: a checkout that is not a fresh
  template (the root pointers' sentinel is gone, so this is an already-initialized project), and a
  directory that already holds work of its own. That second case asks three questions rather than
  one, because a repository keeps work in more than one place and each of these is invisible to the
  check that catches the others: commits under `HEAD`; commits on branches or tags `HEAD` is not
  currently on (`git checkout --orphan` leaves `HEAD` unborn while every earlier commit stays on
  its branch, so a HEAD-only check reads a live repository as empty); and files staged but never
  committed. Any one of them refuses. A template in a plain folder, a cloned or committed template,
  a template staged but not yet committed, and the mono-repo empty-origin reuse flow (`git init`
  plus a remote, nothing committed yet) all initialize exactly as before, and each refusal now says
  which check fired.
- **The licensing backstop only looked at root filenames, so it missed most of the places the
  method itself says licensing lives.** `scripts/apply-project-license.sh` refuses a target that
  already states its own terms — the guard against handing a repo the method did not create a
  project `LICENSE` and a `LICENSING.md` asserting it over the whole repository. It checked root
  filenames (`COPYING`, `NOTICE`, `LICENSE.md`, …) and nothing else, while `METHOD.md` §7, the
  repo README template, and the recon map template all tell an agent that licensing also lives in
  **package metadata** and **vendored third-party terms**. So a GPL-3.0 npm package, an AGPL Rust
  crate, an Apache `pyproject.toml`, a monorepo licensing per package, and a vendored source tree
  all sailed past it: measured, each took the project's `LICENSE` plus a `LICENSING.md` naming the
  wrong license over someone else's code. The check now reads all three places — root filenames,
  the same names in nested trees, and a populated `license` field in root package metadata
  (`package.json` including the legacy array form, `pyproject.toml`, `setup.cfg`, `Cargo.toml`,
  `composer.json`, `*.gemspec`, `build.gradle`, `pom.xml`). Installed dependency trees
  (`node_modules/`, `.venv/`, `site-packages/`, `target/`, `vendor/bundle`) are skipped: those
  carry somebody else's licenses and say nothing about this repo, and a repo the method **did**
  create may well have them by the time the helper runs. It answers only "does this repo say
  anything about its licensing", never "which license", and it stays a backstop rather than the
  control — a repo that states nothing is indistinguishable from one just created, so the rule
  that the helper runs only on a repo the method creates is still what governs.
- **Declining `registries/` left the docs hub with a broken link on its first run.** A mono-repo
  project can answer no to the repo inventory, and `init.sh` removed the directory — but the docs
  hub `README.md` indexes every directory it ships, and its `registries/` row stayed. So the
  generated project failed `scripts/links.sh` before anyone had touched it. The row is now removed
  with the directory. Related, in the same configuration: the rules for a repo **registered in
  place** named the `repos.yml` row flatly as the place a declined README's information still
  lives, which is a promise a project without an inventory cannot keep. `METHOD.md` §7, the repo
  README template, and the check-in's README sweep now lead with the architecture doc and treat the
  row as conditional on the project keeping one.
- **The check-in's README sweep had no case for the README the method writes into a repo it did
  not create.** Where a repo **registered in place** has no README, the method writes one from the
  full template — that is the settled rule. The sweep in `runbooks/check-in.md` knew only two
  kinds: a repo the method created (check its Overview) and one registered in place, which "owns
  its own README" (check its `Role in <project>` section). A written-from-template README is
  neither. It has no `Role in <project>` heading — that section exists only on the augment path —
  so the sweep either reported its absence as a gap, proposing a second write into a repo the
  method didn't create, or filed the file under "declined" and stopped checking the one README
  there the method is answerable for. The sweep now branches on the same thing the writing rule
  branches on — whether a README was already there — and checks a written-from-template one the
  way a created repo's is checked. A declined addition is still not a gap to close.
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
- **A repo's remote and visibility had no rule, and publishing was never stated as needing a
  go-ahead.** §7 listed what the method does to a repo it did not create — README, CI, licensing,
  the Throughstone notice — and covered remotes and visibility only by the general "a repo
  registered in place is not scaffolded at all". A general statement followed by a list reads as
  covering the list; that is the same gap that once let the license helper assume every repo was
  one the method had scaffolded, and it left the one action here that cannot be reverted with
  nothing pinning it. **Remote and visibility are now stated as the repo's owners':** no remote is
  created for a repo that has one, no existing remote is repointed, no visibility is changed, and
  the URL the repo already has is recorded in its `remote:` field instead. **And a separate,
  broader rule now covers every repo, created ones included: nothing is made public without an
  explicit go-ahead** — never inferred from an open-source license, a public sibling repo, or a
  project describing itself as open source, and private wherever no answer was given. `init.sh`
  already defaulted to private and still does; no tooling changed. The planning session and the
  repo README template carry both rules to where the scaffolding actually happens.
- **The same proposal was put to a repo's owners once per repo, after they had already declined.**
  Every write into a repo registered in place is proposed before it happens, and the text differs
  per repo, so the gate itself is right. But the question behind it — do you want this in your
  repos at all? — is the same one every time, and nothing said whether a "no" covered that repo or
  the practice. A project with several in-place repos therefore re-asked someone who had answered.
  A decline now establishes which it is, and a standing one stops the proposals and records that
  those repos document themselves. It carries one way only: a yes is never reused, since the next
  repo's text is its own proposal and nobody has seen it yet. `METHOD.md` §7 and
  `templates/repo-readme-template.md` both say so, the latter being the file open at the moment of
  the write.
- **The project license could be applied to a repo the method didn't create.** `METHOD.md` §7 lets a
  repo be **registered in place** — referenced where it already sits instead of created under
  `Code/` — but every instruction around `scripts/apply-project-license.sh` was written for a repo
  the method had just scaffolded, and the helper itself checked only for a plain `LICENSE`. A repo
  stating its terms any other way — `COPYING`, `NOTICE`, `LICENSE.md`, `LICENSE-<id>` — would take
  the project's `LICENSE` and a `LICENSING.md` asserting that license over the entire repository,
  written from an answer given at install time about code the method never authored. The helper now
  refuses such a target before writing anything, and `METHOD.md` §7 states the rule the refusal
  enforces — **a repo the method did not create keeps what it already has**, licensing along with
  its README and its CI — with `AGENTS.md`, the planning session, and the repo README template all
  pointing at it. A repo the method creates carries none of those files, so nothing about
  scaffolding a new repo changes.
- **`.throughstone/project-license` was described more broadly than it acts.** It was called "the
  project-license posture" and "the authoritative selection" everywhere, but it only ever governs
  **Throughstone-authored and method-created material** — the docs hub, `prompts/`, and any repo
  the method creates. In a project built entirely from scratch those are the same set; in one that
  also references code it did not create they are not, and the wider reading is what sent the
  posture into repos it had no business licensing. `METHOD.md` §7, `AGENTS.md`, the planning
  session, the helper's own header, and both licensing banners now say the narrower thing, which
  is what was always true.
- **"Stamp a README into each repo" had no rule for a repo the method didn't create.**
  `templates/repo-readme-template.md` said to stamp a copy "into each code repo as it's created",
  and `METHOD.md` §7 said every repo's README is stamped from it "when the repo is scaffolded" —
  but §7 also lets a repo be **registered in place**, and such a repo already has a README, usually
  its most-read file and often linked from outside. Read literally, the instruction says to
  overwrite it. A repo registered in place is now **augmented** rather than stamped: add only a
  short `Role in <project>` section naming what the repo is within the system, propose it before
  writing into a repo the method didn't create, and leave every existing section alone — everything
  else in the template is something a working repo already documents, better, from having been run.
  A declined proposal is a complete outcome, since the same information lives in the architecture
  doc and the `repos.yml` row. The rule keys on whether a README already exists rather than on how
  the repo got here — where a registered-in-place repo has none, there is nothing to preserve, so
  its README is written from the full template: that one file, with nothing else about the repo
  scaffolded, and still proposed first. Two readers of that rule were corrected with it: `METHOD.md`
  §7's layout paragraph said service repos are stamped from the template full stop, and the
  check-in's README sweep assumed every repo README was stamped by the method at creation — so it
  would have reported an augmented repo, or one whose owner declined the addition, as a gap.
- **The CI gate could be installed into a repo the method didn't create.**
  `templates/ci/README.md` and the repo README template both said to drop
  `templates/ci/code-repo-ci.yml` into a repo's `.github/workflows/ci.yml` when scaffolding it —
  with no rule for a repo **registered in place**, which has its own CI. That file is deliberately
  **failing-until-configured**, so landing it in an existing repo either replaces the workflow that
  gates its merges or adds a second one that fails every build until somebody deletes it. It is
  now never installed into a registered-in-place repo; what that repo already runs is recorded in
  the Test Strategy doc instead, and moving it onto the standard gate is a change its owners make
  deliberately.
- **Four create-only instructions didn't say where they stop.** The rules for a repo **registered
  in place** are settled — augment its README rather than stamp it, never install the CI gate,
  never apply the project license, place the Throughstone notice only where the method's own
  material landed — but each was stated in the file that *defines* it and not in every file an
  agent has open while doing the work. Four such sites, all of them leaves:
  - The **repo README template** ended its in-place licensing rule at "do NOT run
    `apply-project-license.sh`" and never mentioned `--notice-only` — which is exactly what the
    repo is owed once the README addition the same template orders two paragraphs earlier is
    accepted. Read as written it forbade the call. On the branch where the owners **decline**,
    doing nothing was the right outcome, so it gave a correct result half the time and left no
    trace the other half.
  - **A repo with no README** is written from the template, and nothing told that path to leave
    out the **Licensing** section, which describes a repo the method created. Reachable and false
    rather than merely unhelpful: in a repo that already has its own `LICENSING.md`,
    `--notice-only` correctly refuses the differing file and writes neither it nor the notice — so
    the repo was left with a brand-new README asserting a `LICENSE-THROUGHSTONE` that isn't there.
    That section is now dropped on that path, as it already was when augmenting.
  - **`templates/ci/code-repo-ci.yml`** — the file actually being copied, and the last thing read
    before the copy — still said "stamp this into each code repo". Nothing contradicted it and the
    caveat sat one hop away in the two files that point at it, but the failure mode is replacing
    the workflow that gates someone's merges.
  - **`registries/repos.yml`**'s comment sits at the point where an agent writes a repo row, and
    said repos listed there "are stamped from `templates/repo-readme-template.md`" full stop —
    false for the registered-in-place row directly beneath it.

  A new maintainer test pins all four in the generated project.

### Added
- **`--notice-only` mode for `scripts/apply-project-license.sh`** — places `LICENSE-THROUGHSTONE`
  and a companion `LICENSING.md` in a repo the method did *not* create, for the one case such a
  repo needs it: the method left Throughstone-authored material behind (the `Role in <project>`
  README section, or a README written from the template for a repo that had none). That material
  is BSD-3-Clause and needs its notice, but the notice alone in someone else's repo invites the
  wrong conclusion — so the companion names only what it covers and explicitly disclaims the rest
  of the repository. It writes no project `LICENSE` and makes no claim about the repo's own code,
  which is why it is allowed on a target the full mode refuses. Nothing is owed, and nothing is
  written, when the owners declined the addition.

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
