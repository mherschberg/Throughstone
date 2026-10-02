# Contributing to Throughstone

Throughstone is a single-maintainer project, and the hope is that it grows into
something many people use and shape. Contributions are genuinely welcome — this guide keeps
things light so it's easy to get involved. Expect it to expand as the community grows.

Throughstone is an **opinionated, architecture-first methodology**, so the one thing to keep
in mind is that changes should fit the method's direction. When in doubt, open an issue first
and let's talk it through — that's always welcome.

## Reporting issues and ideas

- Found a bug, a broken step in `init.sh`, or a confusing doc? **Open an issue.**
- Have a question about how to use the method? Prefer
  [Discussions](../../discussions) for open-ended "how do I…" questions.
- Have an idea for the methodology itself? Open an issue to discuss it before writing a PR —
  see "Larger method changes" below.

## Small fixes

Typo fixes, broken links, clarifications, and small doc improvements are great first
contributions. Feel free to open a pull request directly — no need to ask first.

## Larger method changes

Throughstone is curated to stay coherent as a method. If you want to propose a change to the
methodology, the templates, or the architecture-session flow, **please open an issue first**
to discuss the direction. This saves you effort and helps keep the method consistent — some
changes may be declined if they conflict with the method's direction, and an early
conversation makes that clear up front.

## Working on Throughstone with an AI agent

Run `git config throughstone.author true` once in your clone. The root `AGENTS.md` and
`CLAUDE.md` tell an agent to check it. Without it, the agent treats the folder as a user's new
download and tells you to run `./init.sh`. The setting lives in your clone's `.git/config`, so
every worktree of the clone shares it and no download or push carries it.

## Comments and docs describe the present

Code comments and the directions in the method's files say how things work **now**. Context is
welcome, including warnings about what goes wrong if a rule is not followed. How it used to work,
and why it changed — the bug a fix answers, what it replaced — goes in the **commit message**,
where `git log` and `git blame` find it. In the file it costs every later reader, human or AI,
tokens and confusion. `CHANGELOG.md` and `UPDATING-THROUGHSTONE.md` record change by design, so
the rule does not apply to them.

## Placeholders in the scaffold's files

Write the docs hub as `Code/{{PROJECT}}-docs/`. `init.sh` replaces the placeholder with each
project's slug, so the path names the real folder. Where a file instructs a project's
contributors, write `Code/<project>-docs/` instead, as `ONBOARDING.md` does; its opening note
says what `<project>` stands for.

## Adding or improving coding standards

The `coding-standards/` files are starting points meant to be useful defaults. New language
standards or improvements to existing ones are welcome via pull request. Keep them in the
same style as the existing files and the `{{PROJECT}}` placeholder convention intact.

## A note on conduct

Please read our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you agree to uphold
it.

---

Thanks for helping make Throughstone better.
