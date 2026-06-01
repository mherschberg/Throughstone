# {{PROJECT}} — Native App Architecture (Conditional Session)

> **Conditional.** Include this only if session 1.3 said the project has a **mobile or
> desktop app** (not just a web UI). The kickoff slots it in as a substep (e.g. `1.7a`) and
> the index records its number. Run it by name: *"run the native-app session."* It writes
> `architecture/NN-native-app-architecture.md` (number assigned in the index) and updates
> `prompts/STEP-index.md`.
> **Two separate numbers:** the *substep* number (e.g. `1.7a`) marks its place in STEP-1; the
> *doc file* number (`NN`) is the next free number **above the reserved core-doc block** — the
> standard sessions reserve a contiguous block at the front (today `01–12`; the current core set
> is the session table in `METHOD.md` §4), and each conditional takes the next number above that
> block (today `13`, then `14`, …) — **not** the lowest unused number. (This session may run
> before the later core docs exist; still take the first number above the core block, so a
> not-yet-run core session keeps its own reserved slot without a clash.) The substep number and the
> doc number don't have to match.
> Reads `overview.md` and `architecture/03-*` (surfaces), `04-*`, `06-*`, `07-*` first.
> **Calibrate to experience.** Check the **Experience level** in `overview.md`: at Level 1–2 (no/basic coding background) explain each question's *what* and *why* in plain language — leading with a recommended default — before asking, and skip bare jargon. At any level, treat any confusion or request to clarify — in any words, not just those — as a cue to explain plainly, and tell the user up front they can ask. (`METHOD.md` §4.)

## About {{PROJECT}}
{{PROJECT_DESCRIPTION}}

## What this session does
Drawing on the architecture, data, and UI decisions, we'll cover the concerns unique to a
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
Write `architecture/NN-native-app-architecture.md` (use `templates/architecture-doc.md`;
NN per the index). Body covers each area above. Fill the **Decision Summary** (the
distribution/forced-upgrade and offline choices especially belong here), record **Open
Questions**, start the **Version Log**. Capture significant platform/distribution decisions
as ADRs. Update `prompts/STEP-index.md`: mark this substep done.

## Next
Once this substep is marked done, the next action is the lowest open STEP-1 substep in the index — its position depends on where this conditional was slotted. Tell the user to **start a fresh chat** and run it. When all STEP-1 substeps and the 1.13 review are done, the next action is *"run the planning session."* See the next-action resolver in `METHOD.md` §10.

**Begin now — in this same reply.** "run session N.M" is your go-ahead, not a request for acknowledgement: don't say "ready when you are", don't recap this file, don't ask whether to start. Read `overview.md` (and any earlier architecture docs) silently. Then, in this one reply: **(1)** tell the user — in the one or two sentences from **What this session does** above — what you're about to cover (plain language); then **(2)** immediately **ask decision 1**, calibrated to the recorded experience level. That orientation plus the first question is your entire first reply — nothing more.
