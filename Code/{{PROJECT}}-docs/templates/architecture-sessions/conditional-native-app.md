# {{PROJECT}} — Native App Architecture (Conditional Session)

> **Conditional.** Include this only if the Architecture Overview architecture doc says the project has a **mobile or
> desktop app** (not just a web UI). The kickoff slots it in as a substep (e.g. `1.7a`) and
> the index records its number. Run it by name: *"run the native-app session."* It writes
> `architecture/NN-native-app-architecture.md` (number assigned in the STEP-1 index when run
> there, or in the follow-up PLAN when run later) and updates `prompts/STEP-index.md`.
> It may also be scheduled later as its own follow-up STEP when a periodic check-in finds
> that a native client has become applicable. In that mode, use the follow-up STEP's status
> and review bookkeeping rather than reopening STEP-1.
> **Two separate numbers:** the *substep* number (e.g. `1.7a`) marks its place in STEP-1; the
> *doc file* number (`NN`) is the next free number **above the reserved core-doc block** — the
> standard sessions reserve a contiguous block at the front (the current core set is the session
> table in `METHOD.md` §4), and each conditional takes the next free number above that block
> if another conditional already claimed the first one — **not** the lowest unused number. (This session may run
> before the later core docs exist; still take the first free number above the core block, so a
> not-yet-run core session keeps its own reserved slot without a clash.) The substep number and the
> doc number don't have to match.
> Reads `overview.md`, the Architecture Overview architecture doc (`architecture/*-architecture-overview.md`)
> for surfaces, the Data Model architecture doc (`architecture/*-data-model.md`), the
> Security & Threat Model architecture doc (`architecture/*-security-threat-model.md`), and the UI / Design System architecture doc
> (`architecture/*-ui-design-system.md`) first, plus the active STEP PLAN in
> `Upcoming Prompts/` when this is a later follow-up.
> **Calibrate to experience.** Check the **Experience level** in `overview.md`: at Level 1–2 (no/basic coding background) explain each question's *what* and *why* in plain language — leading with a recommended default — before asking, and skip bare jargon. At any level, treat any confusion or request to clarify — in any words, not just those — as a cue to explain plainly, and tell the user up front they can ask. (`METHOD.md` §4.)

## About {{PROJECT}}
{{PROJECT_DESCRIPTION}}

## What this session does
Drawing on the architecture, data, and user-interface/design-system decisions, we'll cover the concerns unique to a
mobile or desktop app — app-store update lag, offline or flaky networks, and data living on a
device you don't control.

## Why this session matters
A native app raises concerns a web backend never does — and they're exactly the ones
web-trained developers miss. You can't just "deploy a fix" (the store reviews it; users run
old versions). The network drops. Data lives on a device you don't control. Deciding these
up front avoids painful reworks once the app is in users' hands.

## How this session works
- One decision at a time; **wait** for answers.
- Recommend defaults for the project's stage and flag what they foreclose.
- Most of this applies to both mobile and desktop; adapt wording to the actual targets.

## Decisions to make (in order)
1. **Platform strategy.** Native (Swift/Kotlin) vs. cross-platform (React Native, Flutter,
   .NET MAUI) vs. PWA/desktop-wrapper (Electron, Tauri). Which targets (iOS, Android,
   Windows, macOS), and the build/maintenance tradeoff.
2. **Offline & sync.** Does the app work offline? What data is available offline, how it
   syncs when back online, and how conflicts are resolved. *(The big one — decide early.)*
3. **On-device storage & state.** What's stored locally, in what (secure store vs. plain
   DB/files), and how app state is managed.
4. **Push notifications.** Needed? Provider (APNs/FCM), what triggers them, and permission
   handling.
5. **Device permissions & capabilities.** Camera, location, contacts, biometrics, etc. —
   which are used and how permission is requested/degraded if denied.
6. **Mobile/device security.** Secure storage for tokens/keys (Keychain/Keystore),
   transport security / certificate pinning, data-at-rest, and behavior on
   jailbroken/rooted devices.
7. **Distribution & release.** App Store / Play Store / direct or auto-update (desktop).
   Account for **review latency**, **forced-upgrade** strategy (how you retire old clients),
   phased rollout, and over-the-air updates if applicable.
8. **Device performance.** Battery, app/binary size, cold-start time, memory — targets and
   what could blow them.

## Output
Write `architecture/NN-native-app-architecture.md` (use `templates/architecture-doc-template.md`;
NN per the active STEP's index/PLAN). If the doc already exists, revise it in place and bump
its Version Log instead of creating a second native-app doc. Body covers each area above.
Fill the **Decision Summary** (the distribution/forced-upgrade and offline choices especially
belong here), record **Open Questions**, and capture significant platform/distribution
decisions as ADRs. Reconcile any affected architecture docs. If this is a later follow-up
STEP, add or update this doc's row in `architecture/README.md`. Update
the active PLAN to mark this substep done. In STEP-1 mode, also mark the lettered substep
done in `prompts/STEP-index.md`. In follow-up mode, keep the parent STEP `In progress` there
until its review and normal completion bookkeeping are finished.

## Next
If this session was slotted into STEP-1, mark its lettered substep done; the next action is
the lowest open STEP-1 substep in the index. If the Cross-Cutting Review discovered it, that
review remains open and must restart from the beginning after this session. If a periodic
check-in scheduled this as a later follow-up STEP, complete that STEP's normal review and
bookkeeping instead of modifying STEP-1; re-run the planning session before more
implementation work if these decisions change the remaining roadmap. Tell the user to
**start a fresh chat** for the next action from the resolver in `METHOD.md` §10.

**Begin now — in this same reply.** "run the native-app session" is your go-ahead, not a request for acknowledgement: don't say "ready when you are", don't recap this file, don't ask whether to start. Read `overview.md`, the relevant architecture docs, and any active follow-up PLAN silently; the PLAN determines the execution mode and output-doc number when this is not part of STEP-1. Then, in this one reply: **(1)** tell the user — in the one or two sentences from **What this session does** above — what you're about to cover (plain language); then **(2)** immediately **ask decision 1**, calibrated to the recorded experience level. That orientation plus the first question is your entire first reply — nothing more.
