# Runbook — Dependencies & Supply Chain

> **How to run:** This is an **operational procedure, not a STEP** (like the release runbook),
> with two modes:
> - **Adding a dependency** → run the vetting checklist (**Part 1**) *before* you
>   `npm install` / `pip install` / `go get` / `cargo add` — tell your agent *"vet this
>   dependency."*
> - **Periodic audit** → run **Parts 2–3** on a cadence: it rides naturally on the **check-in**
>   (`runbooks/check-in.md`, every ~10–20 STEPs), and you also run it whenever a vulnerability
>   advisory lands for something you use.
>
> **Optional and yours to customize.** Like the release runbook, this leaves the specific tools
> to your stack (`npm audit`, `pip-audit`, `cargo audit`, `govulncheck`, Dependabot/Renovate,
> a license scanner…). The *discipline* below — vet before you add, pin, audit on a cadence — is
> the durable part; fill in your ecosystem's commands. It operationalizes the dependency-risk
> posture set in `architecture/*-security-threat-model.md`.

## Why this runbook exists
Most of a modern application is code you didn't write — your dependencies, and *their*
dependencies, several layers deep. That's the dominant way trouble enters a project that's
otherwise careful: a compromised or abandoned package, a known CVE you never patched, a
typosquatted name, a copyleft license that quietly contaminates a proprietary product.
"It installed and it worked" is not vetting. This runbook makes adding and maintaining
dependencies a deliberate choice rather than a reflex, because every dependency is a permanent
liability you're taking on — and the cheapest one is the one you don't add.

## Part 1 — Before you add a dependency (vetting)
- [ ] **Do you actually need it?** Is this genuine leverage, or a few lines you could write and
      own? Weigh the permanent cost — supply-chain surface, updates, license, breakage risk —
      against what it saves. The cheapest dependency is no dependency.
- [ ] **Is it healthy?** Actively maintained (recent releases/commits), genuinely used (not
      single-maintainer abandonware), and reasonably responsive on issues/security. A popular,
      maintained package is a smaller risk than a clever neglected one.
- [ ] **License compatibility.** Check the package's license — and its transitive licenses —
      against the license your project ships under (the one `init.sh` stamped). Copyleft
      (GPL/AGPL) inside a proprietary product, or an incompatible mix, is a real legal problem;
      catch it *before* the dependency is load-bearing.
- [ ] **Security & provenance.** Any known CVEs? Is this the **canonical** package from the
      official registry/org, spelled exactly right? Typosquatted and confusable names are a
      common attack — a momentary misread installs hostile code.
- [ ] **Transitive weight.** What does it drag in? A small direct dependency with a huge
      transitive tree expands your attack surface far more than its own size suggests.
- [ ] **Pin it.** Add it with a version constraint and **commit the lockfile**, so builds are
      reproducible and an upstream change can't silently alter what you ship.

## Part 2 — Periodic audit (on the check-in cadence)
- [ ] **Scan for known vulnerabilities.** Run your ecosystem's audit across **all repos**.
      Triage the findings: patch the exploitable ones now; for any you consciously defer, record
      an **accepted-risk** note with the trigger to revisit — the same discipline as a deferred
      threat in `architecture/*-security-threat-model.md` (a standing policy → an ADR; a
      one-off → a line in the check-in record).
- [ ] **Update cadence.** Apply **security patches promptly**; take feature/major upgrades
      *deliberately* (read the changelog, expect breaking changes, run the tests). Neither
      extreme is safe: everything pinned years behind becomes one terrifying upgrade, but
      auto-merging majors blind breaks things — choose, don't drift.
- [ ] **Lockfile hygiene.** Lockfile committed and in sync with the manifest; no unexplained or
      unexpected entries (a surprise transitive change is worth a look).
- [ ] **Prune the unused.** Remove dependencies you no longer use — dead dependencies are pure
      liability (attack surface + audit noise) for zero benefit.
- [ ] **SBOM (if you keep one).** Regenerate the software bill of materials so that when the next
      big advisory drops you can answer *"are we affected by CVE-X?"* in minutes, not days.

## Part 3 — When supply chain *is* the incident
A dependency vulnerability that's being exploited, or a malicious/compromised package found in
your tree, is an **incident** — switch to `runbooks/incident-postmortem.md`. The *find-similar*
substep there is exactly the right reflex: is the same bad package, or the same unpatched class,
present in other repos or other services?

## Output / record
Most of this is action, not documents — but leave a trail:
- **Audit result** noted in the check-in record (vulnerabilities found, patched, or deferred).
- **Accepted-risk deferrals** with their revisit trigger (per above).
- **Standing policies** as **ADRs** — e.g. "no AGPL dependencies," "pin exact versions,"
  "security patches within N days" — so the rule outlives the person who set it.
- File a **follow-up STEP** for anything too big to handle in the moment (a major framework
  upgrade, replacing an abandoned package).
