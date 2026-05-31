# Security Policy

Throughstone is a documentation-and-scripts template — most of its runnable surface is
`init.sh` and `Code/{{PROJECT}}-docs/scripts/setup-workspace.sh`, the shell scripts a user
runs to set up a project. If you find a vulnerability in those scripts (or anywhere else in
the project), please report it privately so it can be fixed before it's disclosed publicly.

## Reporting a vulnerability

**Please do not open a public issue for security problems.**

Instead, use one of these private channels:

- **Preferred:** GitHub's [private vulnerability reporting](../../security/advisories/new)
  ("Report a vulnerability" on the Security tab).
- **Fallback:** email **hershey@throughstone.org** with the details.

Please include enough information to reproduce the issue (affected file, steps, and impact).

## What to expect

This is a single-maintainer project, so responses are **best-effort**. You can expect an
acknowledgment as soon as practical, a fix or mitigation for confirmed issues, and credit for
the report if you'd like it.

## Supported versions

The latest version on the default branch is the supported one. Throughstone is a template you
copy at a point in time; once you've generated a project from it, keeping that project's copy
up to date is part of your own maintenance.
