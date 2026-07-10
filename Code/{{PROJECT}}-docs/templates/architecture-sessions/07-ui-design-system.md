# {{PROJECT}} — UI / Design System (Session 1.7)

> **How to run:** Tell your agent *"STEP-1.7"* or *"session 1.7"*; a leading *"Run"* and
> `: UI / Design System` are optional (but the label helps chat titles). It interviews you one decision at a
> time, creates temporary visual option pages in `ui-design/`, then writes
> `architecture/07-ui-design-system.md` and updates `prompts/STEP-index.md`.
> Reads `overview.md` and the Architecture Overview architecture doc (`architecture/*-architecture-overview.md`)
> for the client-surfaces answer first — plus any
> conditional-session doc that shapes the UI (e.g. identity-auth for login/account/consent screens,
> or one added later), if it's been written.
>
> **No UI?** If the Architecture Overview architecture doc says this is API-only / a CLI with no styled UI, skip this
> session — note `Deferred` when a UI may arrive later, or `N/A` when the project has no UI by
> design, in the index and move on.
> **Calibrate to experience.** Check the **Experience level** in `overview.md`: at Level 1–2 (no/basic coding background) explain each question's *what* and *why* in plain language — leading with a recommended default — before asking, and skip bare jargon. At any level, treat any confusion or request to clarify — in any words, not just those — as a cue to explain plainly, and tell the user up front they can ask. (`METHOD.md` §4.)

## About {{PROJECT}}
{{PROJECT_DESCRIPTION}}

## What this session does
For the user-facing surfaces identified in 1.3, we'll set the interface's foundations — its
visual style and reusable building blocks — so the UI stays consistent as it grows. (Skip
this one if the project has no UI.)

## Why this session matters
A design system decided up front keeps the product visually consistent and saves you from
re-litigating colors and components on every screen. It's also where things developers
routinely skip get handled: **accessibility**, **internationalization**, and (for apps)
**platform conventions** — each far cheaper designed in now than bolted on later. The
foundations — color, type, spacing — are shared across web and mobile; platform-specific
patterns branch from there.

## How this session works
- One decision at a time; **show and tell**. For **every UI decision**, give a concise
  explanation of what the decision controls and why it matters, then generate a rendered HTML
  comparison page in a temporary `ui-design/` working folder with realistic {{PROJECT}}
  content before asking the user to choose. Do not make the user decide from text-only
  descriptions, hex codes, or abstract component names, and do not make them interpret visuals
  with no explanation.
- Present a small set of concrete options for each decision: target **3–4 options** where the
  design space supports it, and use **2 options** only where the choice is naturally binary
  or constrained (for example, top navigation vs. side navigation). Label each option clearly,
  show it in context, and include exact values where relevant.
- **Wait** for the user's answer after each visual option page before moving to the next
  decision. If a decision depends on an earlier answer, build the new HTML page using the
  selected earlier choices so the system accumulates coherently.
- Reuse the client-surfaces answer from the Architecture Overview architecture doc to decide which platform branches apply.
- Recommend sensible defaults; flag accessibility and localization implications.
- Keep each temporary visual page focused on one decision (or one tightly coupled decision group) and
  name files with a sortable prefix, e.g. `ui-design/01-design-principles.html`,
  `ui-design/02-color.html`, `ui-design/03-typography.html`.
- Treat `ui-design/` as a temporary session workspace, not a durable docs artifact. The final
  architecture doc records the selected choices and exact values; the HTML option pages do
  not need to be retained unless the user explicitly asks to keep them.

## Decisions to make (in order)

### Foundations (shared across all surfaces)
1. **Design principles.** 2–4 adjectives for the look & feel (e.g. "trustworthy, modern,
   data-dense") and what they imply. Show 3–4 visual mood directions with sample screens or
   component compositions, not just adjective lists.
2. **Color.** Brand/primary, semantic (success/warning/error/info), and a grayscale ramp.
3. **Typography.** Font families (UI + mono if needed) and a type scale.
4. **Spacing & layout.** Base spacing unit and density (compact vs. comfortable).
5. **Shape & elevation.** Corner radius; borders vs. shadows.

### Components
6. **Core components.** Buttons (variants/sizes), form inputs, tables/lists, modals/dialogs,
   cards, navigation, toasts/notifications, empty & loading states.
7. **Navigation pattern.** Web: sidebar vs. top nav. Mobile: tab bar vs. nav stack +
   gestures. Desktop: menus/toolbars. (Use the surfaces from the Architecture Overview architecture doc.)

### System-level
8. **Theme support.** Light, dark, or both — and how switching works.
9. **Iconography.** Icon set/library.
10. **Responsive / device strategy.** Web: breakpoints, mobile-web behavior. Native:
    device sizes, safe areas, orientation.
11. **Accessibility.** Pick a target to design against — **WCAG 2.1 AA** is the common
    default (and a legal requirement in many jurisdictions). Concretely: color-contrast
    ratios, visible focus states, full keyboard navigation, adequate touch-target sizes, alt
    text for meaningful images, labeled form fields, and screen-reader support (semantic
    HTML / ARIA / VoiceOver / TalkBack). Honor a reduced-motion preference (ties to decision
    13). Not optional — and far cheaper designed in now than retrofitted.
12. **Internationalization & localization.** Two separate questions. *Internationalization
    (i18n)* is whether the UI is **built to be translatable at all**: user-facing text pulled
    into a strings layer instead of hardcoded, layouts that tolerate longer translated text,
    locale-aware dates/numbers/currency, and — if you might ever need Arabic/Hebrew —
    right-to-left support. *Localization (l10n)* is **which languages/locales you actually
    ship** now. The trap is foreclosure: shipping English-only is fine, but *hardcoding*
    English everywhere is the expensive mistake — retrofitting i18n later means touching every
    screen. MVP default: ship one locale, but route user-facing text through a strings layer
    from day one so adding a language later is a translation job, not a rewrite. Decide RTL
    in or out deliberately.
13. **Motion & transitions**; **data visualization** (if charts).
14. **Implementation approach.** CSS framework / component library (web) or native toolkit;
    how tokens are defined (e.g. CSS custom properties).
15. **Platform conventions** (if mobile/desktop). Respect iOS HIG / Android Material /
    desktop OS conventions where they differ from web.

## Output
Use the generated `ui-design/*.html` pages as temporary working aids during the session. There
should be one HTML page per decision or tightly coupled decision group while the session is in
progress, each showing the options being presented and the exact values under consideration.
Do not treat these pages as durable output unless the user explicitly asks to keep them.

Write `architecture/07-ui-design-system.md` (use `templates/architecture-doc-template.md`). Body:
- **Design principles**
- **Tokens** — color, typography, spacing, shape (exact values; CSS custom properties)
- **Components** — specs with variants
- **Navigation, theme, icons, responsive/device, accessibility, internationalization, motion, data-viz**
- **Implementation stack** and any **platform-specific** notes

Fill the **Decision Summary**, record **Open Questions**, start the **Version Log**. Update
`prompts/STEP-index.md`: mark 1.7 done.

## Next
Once 1.7 is marked done, the next action is the lowest open STEP-1 substep in the index. Tell
the user to **start a fresh chat** and run that substep with a descriptive first message. For
a numbered core session, use `Run STEP-1.N: <Session label from the index>` (for example,
`Run STEP-1.8: Infrastructure & Deployment`). For a lettered conditional session, use
`Run STEP-1.Xa: <Conditional session label>` and the invocation by name from that
conditional's template. See the next-action resolver in `METHOD.md` §10.

**Begin now — in this same reply.** "STEP-1.N" or "session N.M", with or without a leading "Run" and with or without the session label, is your go-ahead, not a request for acknowledgement: don't say "ready when you are", don't recap this file, don't ask whether to start. Read `overview.md` (and any earlier architecture docs) silently. Then, in this one reply: **(1)** tell the user — in the one or two sentences from **What this session does** above — what you're about to cover (plain language); then **(2)** immediately **ask decision 1**, calibrated to the recorded experience level. That orientation plus the first question is your entire first reply — nothing more.
