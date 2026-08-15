# {{PROJECT}} — Pre-answer sheet: {{N.N — session name}}

**Session:** `{{templates/architecture-sessions/NN-....md}}`   <!-- the in-scope harvest session this
                                                                   sheet covers — any row in the PLAN's
                                                                   session table, including a lettered
                                                                   conditional (1.7b); 1.14 is the
                                                                   Cross-Cutting Review, not a harvest -->
**Harvested:** {{YYYY-MM-DD}}
**Sources read:** {{the confirmed recon map + which per-asset docs / inputs / code paths}}
**Status:** {{Harvested → Confirmed}}   <!-- Stamp Harvested once EVERY row has a drafted answer;
                                            Confirmed once the confirm pass has walked every row.
                                            Leave the placeholder until then: an unstamped sheet is
                                            how a resumed chat recognizes an interrupted harvest. -->

<!-- WHAT THIS IS. A pre-answer sheet is retcon's per-session hand-off: instead of interviewing a
     session cold, the harvest DRAFTS an answer to each of that session's decisions FROM REALITY
     (the confirmed recon map, the per-asset docs, and the running code), and the confirm pass then
     walks every decision with the user. One sheet per in-scope harvest session — `1.1`–`1.13` plus
     any lettered conditional the PLAN included (`1.14` is the Cross-Cutting Review + land, not a
     harvest) — keyed to that
     session's decision list — NOT a pre-written draft of the doc (a draft doc anchors the user and
     forces provenance into the final doc). Name the file from the substep id, letter and all:
     `Upcoming Prompts/retcon/1.7b-native-app.md`.

     IT EVOLVES. Seed the rows from the session template's decision list, but treat the sheet as a
     living working doc, not a fixed form: add rows as harvest and confirm surface decisions the
     template never enumerated (a real system raises questions no generic list foresaw), and split or
     reword rows as the picture sharpens. Unlike the recon map (frozen once confirmed), a pre-answer
     sheet keeps changing right up until its clean `architecture/` doc is written — then it is discarded.

     TWO MOVES:
     1. HARVEST (agent; human-free except the cost escalation): read the session file as REFERENCE
        DATA — never trigger its interview — and fill Decision / Drafted answer / Provenance /
        Confidence for every decision the session makes. An answer may draw on more than one source
        (code and a doc, or several files) — list every source in Provenance, not just the strongest.
     2. CONFIRM (with the user): walk each row proportionate to confidence × consequence — a
        from-code answer gets a fast "right?", a low-confidence or load-bearing one a real
        discussion — and record the outcome in Confirm. Then write the clean `architecture/` doc
        from `templates/architecture-doc-template.md`, at its `Version` and `Status` — the template
        carries the `Version Log` that `scripts/check.sh` check 4 also requires, which a doc written
        freehand loses. Record each decision by its Confirm outcome — independently of
        those two doc axes: a confirmed decision as plain fact; a decision left unconfirmed as
        `Coverage: deferred` with a `registries/risks.yml` row.

     TRANSIENT. Provenance and confidence live ONLY here — they never leak into the clean doc. The
     sheet is scratch in `Upcoming Prompts/retcon/`; it is discarded when STEP-1 lands (not archived
     as project history). Driven by RETCON-PROMPT.md's per-session harvest→confirm. -->

| # | Decision (from the session's decision list) | Drafted answer (from reality) | Provenance | Confidence | Confirm |
|---|---------------------------------------------|-------------------------------|------------|------------|---------|
| 1 | {{decision}} | {{answer drafted from reality}} | {{one or more — from-code `path`, from-doc (which + trust), from-memory (user), inferred, unknown}} | {{high / med / low}} | {{confirmed as-is / corrected: … / deferred → Coverage + risks.yml}} |
