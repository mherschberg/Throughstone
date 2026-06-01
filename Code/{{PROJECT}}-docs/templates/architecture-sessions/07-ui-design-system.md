# {{PROJECT}} — UI / Design System (Session 1.7)

> **How to run:** Tell your agent *"run session 1.7"*. It interviews you one decision at a
> time, then writes `architecture/07-ui-design-system.md` and updates `prompts/STEP-index.md`.
> Reads `overview.md` and `architecture/03-*` (for the client-surfaces answer) first.
>
> **No UI?** If session 1.3 said this is API-only / a CLI with no styled UI, skip this
> session — note "N/A, no UI" in the index and move on.
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
- One decision at a time; **show, don't tell** — where possible, generate a small rendered
  HTML page (or component sketch) with realistic {{PROJECT}} content so choices are visual,
  not hex codes in text. **Wait** for the answer.
- Reuse the client-surfaces answer from 1.3 to decide which platform branches apply.
- Recommend sensible defaults; flag accessibility and localization implications.

## Decisions to make (in order)

### Foundations (shared across all surfaces)
1. **Design principles.** 2–4 adjectives for the look & feel (e.g. "trustworthy, modern,
   data-dense") and what they imply.
2. **Color.** Brand/primary, semantic (success/warning/error/info), and a grayscale ramp.
3. **Typography.** Font families (UI + mono if needed) and a type scale.
4. **Spacing & layout.** Base spacing unit and density (compact vs. comfortable).
5. **Shape & elevation.** Corner radius; borders vs. shadows.

### Components
6. **Core components.** Buttons (variants/sizes), form inputs, tables/lists, modals/dialogs,
   cards, navigation, toasts/notifications, empty & loading states.
7. **Navigation pattern.** Web: sidebar vs. top nav. Mobile: tab bar vs. nav stack +
   gestures. Desktop: menus/toolbars. (Use the surfaces from 1.3.)

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
Write `architecture/07-ui-design-system.md` (use `templates/architecture-doc.md`). Body:
- **Design principles**
- **Tokens** — color, typography, spacing, shape (exact values; CSS custom properties)
- **Components** — specs with variants
- **Navigation, theme, icons, responsive/device, accessibility, internationalization, motion, data-viz**
- **Implementation stack** and any **platform-specific** notes

Fill the **Decision Summary**, record **Open Questions**, start the **Version Log**. Update
`prompts/STEP-index.md`: mark 1.7 done.

## Next
Once 1.7 is marked done, the next action is the lowest open STEP-1 substep — normally **1.8 (Infrastructure & deployment)**. Tell the user to **start a fresh chat** and run it (*"run session 1.8"*); if the index shows a different next open substep (sessions can be skipped or added), run that instead. See the next-action resolver in `METHOD.md` §10.

**Begin now — in this same reply.** "run session N.M" is your go-ahead, not a request for acknowledgement: don't say "ready when you are", don't recap this file, don't ask whether to start. Read `overview.md` (and any earlier architecture docs) silently. Then, in this one reply: **(1)** tell the user — in the one or two sentences from **What this session does** above — what you're about to cover (plain language); then **(2)** immediately **ask decision 1**, calibrated to the recorded experience level. That orientation plus the first question is your entire first reply — nothing more.
