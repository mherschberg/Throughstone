#!/usr/bin/env bash
#
# links.sh — read-only stale-link checker for durable Throughstone documentation.
#
# Scope is intentionally narrow: root pointer/readme/artifact-tour files and durable docs-hub Markdown.
# It skips prompts/, Upcoming Prompts/, templates/, app repos, links outside the local
# workspace, and all external URLs so the result stays useful as a cheap check-in/CI guard
# instead of becoming a noisy site crawler.
#
# Usage:  from anywhere — Code/<project>-docs/scripts/links.sh
# Exit:   non-zero if any scoped Markdown file links to a missing local path or anchor.

set -uo pipefail

DOCS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(cd "$DOCS_DIR/../.." && pwd)"

if ! command -v python3 >/dev/null 2>&1; then
  echo "links.sh: python3 is required to parse Markdown links" >&2
  exit 1
fi

python3 - "$ROOT" "$DOCS_DIR" <<'PY'
import os
import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit

root = Path(sys.argv[1]).resolve()
docs_dir = Path(sys.argv[2]).resolve()

failures = []
checked_links = 0


# rel PATH — render a path relative to the workspace root for stable diagnostics.
def rel(path):
    try:
        return str(path.resolve().relative_to(root))
    except ValueError:
        return str(path)


# fail SOURCE LINE MESSAGE [HINT] — record one link failure without stopping the scan.
def fail(source, line_no, message, hint=None):
    failures.append((source, line_no, message, hint))


# scoped_markdown_files — list the durable Markdown files this checker owns.
def scoped_markdown_files():
    files = []
    for name in ("AGENTS.md", "CLAUDE.md", "README.md", "ARTIFACT-TRAIL.md"):
        candidate = root / name
        if candidate.is_file():
            files.append(candidate)
    template_dir = docs_dir / "templates"
    for candidate in sorted(docs_dir.rglob("*.md")):
        try:
            candidate.relative_to(template_dir)
            continue
        except ValueError:
            files.append(candidate)
    return files


# strip_inline_code LINE — hide inline code spans so examples do not look like links.
def strip_inline_code(line):
    # Preserve rough column shape while hiding inline code examples from the link parser.
    return re.sub(r"`[^`]*`", lambda match: " " * len(match.group(0)), line)


# iter_content_lines PATH — yield Markdown content lines, skipping fenced code and comments.
def iter_content_lines(path, strip_code=True):
    in_fence = False
    in_comment = False
    for line_no, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        stripped = raw.lstrip()
        if stripped.startswith(("```", "~~~")):
            in_fence = not in_fence
            continue
        if in_fence:
            continue

        line = raw
        if in_comment:
            if "-->" in line:
                line = line.split("-->", 1)[1]
                in_comment = False
            else:
                continue
        while "<!--" in line:
            before, after = line.split("<!--", 1)
            if "-->" in after:
                after = after.split("-->", 1)[1]
                line = before + after
            else:
                line = before
                in_comment = True
                break

        yield line_no, strip_inline_code(line) if strip_code else line


# markdown_slug TITLE — approximate GitHub-style heading anchors for local Markdown checks.
def markdown_slug(title):
    title = re.sub(r"\{#[A-Za-z0-9_.:-]+\}\s*$", "", title).strip()
    title = re.sub(r"<[^>]+>", "", title)
    title = re.sub(r"[`*_~\[\]()]|#+$", "", title)
    title = title.strip().lower()
    title = re.sub(r"[^\w\s-]", "", title, flags=re.UNICODE)
    title = re.sub(r"[\s-]+", "-", title).strip("-")
    return title


# heading_anchors PATH — collect generated and explicit heading anchors from one Markdown file.
def heading_anchors(path):
    anchors = set()
    counts = {}
    custom_anchor_re = re.compile(r"\{#([A-Za-z0-9_.:-]+)\}\s*$")
    for _, line in iter_content_lines(path, strip_code=False):
        match = re.match(r"^\s{0,3}(#{1,6})\s+(.+?)\s*#*\s*$", line)
        if not match:
            continue
        title = match.group(2).strip()
        custom = custom_anchor_re.search(title)
        if custom:
            anchors.add(custom.group(1))
        slug = markdown_slug(title)
        if not slug:
            continue
        count = counts.get(slug, 0)
        anchors.add(slug if count == 0 else f"{slug}-{count}")
        counts[slug] = count + 1
    return anchors


anchor_cache = {}


# anchors_for PATH — return cached heading anchors for a Markdown file.
def anchors_for(path):
    resolved = path.resolve()
    if resolved not in anchor_cache:
        anchor_cache[resolved] = heading_anchors(resolved)
    return anchor_cache[resolved]


# parse_destination TEXT — extract the URL/path portion from an inline or reference link.
def parse_destination(text):
    text = text.strip()
    if not text:
        return ""
    if text.startswith("<"):
        end = text.find(">")
        return text[1:end] if end != -1 else text[1:]
    chars = []
    escaped = False
    for char in text:
        if escaped:
            chars.append(char)
            escaped = False
        elif char == "\\":
            escaped = True
        elif char.isspace():
            break
        else:
            chars.append(char)
    return "".join(chars)


# extract_inline_links LINE — find inline Markdown link destinations in one line.
def extract_inline_links(line):
    links = []
    i = 0
    while i < len(line):
        start = line.find("[", i)
        if start == -1:
            break
        if start > 0 and line[start - 1] == "\\":
            i = start + 1
            continue
        end = line.find("]", start + 1)
        if end == -1 or end + 1 >= len(line) or line[end + 1] != "(":
            i = start + 1
            continue

        pos = end + 2
        depth = 0
        escaped = False
        chars = []
        while pos < len(line):
            char = line[pos]
            if escaped:
                chars.append(char)
                escaped = False
            elif char == "\\":
                escaped = True
                chars.append(char)
            elif char == "(":
                depth += 1
                chars.append(char)
            elif char == ")" and depth > 0:
                depth -= 1
                chars.append(char)
            elif char == ")":
                break
            else:
                chars.append(char)
            pos += 1

        if pos < len(line) and line[pos] == ")":
            links.append(parse_destination("".join(chars)))
            i = pos + 1
        else:
            i = start + 1
    return links


# extract_reference_definition LINE — return the destination from a Markdown reference definition.
def extract_reference_definition(line):
    match = re.match(r"^\s{0,3}\[[^\]]+\]:\s*(.+?)\s*$", line)
    if not match:
        return None
    return parse_destination(match.group(1))


# reference_label TEXT — normalize a Markdown reference-link label for lookup.
def reference_label(text):
    return re.sub(r"\s+", " ", text.strip()).casefold()


# reference_definitions PATH — collect reference-link definitions declared in one Markdown file.
def reference_definitions(path):
    definitions = {}
    for _, line in iter_content_lines(path):
        match = re.match(r"^\s{0,3}\[([^\]]+)\]:\s*(.+?)\s*$", line)
        if match:
            definitions[reference_label(match.group(1))] = parse_destination(match.group(2))
    return definitions


# extract_reference_usages LINE — find full/collapsed reference-style Markdown link labels.
def extract_reference_usages(line):
    usages = []
    i = 0
    while i < len(line):
        start = line.find("[", i)
        if start == -1:
            break
        if start > 0 and line[start - 1] == "\\":
            i = start + 1
            continue
        text_end = line.find("]", start + 1)
        if text_end == -1 or text_end + 1 >= len(line) or line[text_end + 1] != "[":
            i = start + 1
            continue
        label_end = line.find("]", text_end + 2)
        if label_end == -1:
            i = start + 1
            continue
        label = line[text_end + 2:label_end] or line[start + 1:text_end]
        usages.append(label)
        i = label_end + 1
    return usages


# iter_links PATH — yield all scoped link destinations from one Markdown file.
def iter_links(path):
    definitions = reference_definitions(path)
    for line_no, line in iter_content_lines(path):
        for target in extract_inline_links(line):
            yield line_no, target
        ref_target = extract_reference_definition(line)
        if ref_target:
            yield line_no, ref_target
            continue
        for label in extract_reference_usages(line):
            normalized = reference_label(label)
            if normalized in definitions:
                yield line_no, definitions[normalized]
            else:
                fail(path, line_no, f"uses undefined reference link: [{label}]")


# is_external_or_unsupported TARGET — skip links this local checker intentionally does not own.
def is_external_or_unsupported(target):
    if not target:
        return True
    parsed = urlsplit(target)
    if parsed.scheme or parsed.netloc:
        return True
    # This command checks relative local links only. Site-root paths are deployment-specific.
    return target.startswith("/")


# normalize_target SOURCE TARGET_PATH — resolve a relative link path from its source file.
def normalize_target(source, target_path):
    unquoted = unquote(target_path)
    return Path(os.path.normpath(str(source.parent / unquoted)))


# case_sensitive_status PATH — verify that each filesystem component exists with exact case.
def case_sensitive_status(path):
    # Do not call resolve() here: on case-insensitive filesystems it can canonicalize a
    # wrong-case input and hide the exact portability issue this check is meant to catch.
    parts = path.parts
    if not parts:
        return "missing", None

    current = Path(parts[0])
    suggested = current
    case_wrong = False
    for part in parts[1:]:
        if part in ("", "."):
            continue
        if part == "..":
            current = current.parent
            suggested = suggested.parent
            continue
        if not current.is_dir():
            return "missing", None
        names = {child.name: child.name for child in current.iterdir()}
        if part in names:
            current = current / part
            suggested = suggested / part
            continue
        lower_matches = [name for name in names if name.lower() == part.lower()]
        if lower_matches:
            actual = sorted(lower_matches)[0]
            current = current / actual
            suggested = suggested / actual
            case_wrong = True
            continue
        return "missing", None
    if not current.exists():
        return "missing", None
    return ("case", suggested) if case_wrong else ("ok", current)


# check_link SOURCE LINE TARGET — validate one local link path and optional Markdown anchor.
def check_link(source, line_no, raw_target):
    global checked_links
    if is_external_or_unsupported(raw_target):
        return

    parsed = urlsplit(raw_target)
    target_path = parsed.path
    fragment = unquote(parsed.fragment)
    if not target_path and fragment:
        target = source
    else:
        target = normalize_target(source, target_path)

    try:
        common = os.path.commonpath([str(root), str(target.resolve())])
    except ValueError:
        common = ""
    if common != str(root):
        return

    checked_links += 1
    status, suggested = case_sensitive_status(target)
    if status == "missing":
        fail(source, line_no, f"links to missing file: {raw_target}")
        return
    if status == "case":
        fail(
            source,
            line_no,
            f"links to path with wrong case: {raw_target}",
            f"use {rel(suggested)}",
        )
        return

    if fragment:
        if not suggested.is_file() or suggested.suffix.lower() != ".md":
            fail(source, line_no, f"links to anchor on a non-Markdown target: {raw_target}")
            return
        if fragment not in anchors_for(suggested):
            fail(source, line_no, f"links to missing anchor: {raw_target}")


files = scoped_markdown_files()
for source in files:
    for line_no, target in iter_links(source):
        check_link(source, line_no, target)

print(f"Throughstone links — {root}")
print()
print("Scope:")
print("  root AGENTS.md / CLAUDE.md / README.md / ARTIFACT-TRAIL.md when present")
print(f"  {rel(docs_dir)}/**/*.md except templates/")
print("  prompts/, Upcoming Prompts/, app repos, external URLs, and paths outside the workspace are skipped")
print()

if failures:
    print("Findings:")
    for source, line_no, message, hint in failures:
        print(f"  [FAIL] {rel(source)}:{line_no} {message}")
        if hint:
            print(f"         → fix: {hint}")
else:
    print(f"  [PASS] {checked_links} scoped local link(s) resolve")

print()
print("Summary")
print(f"  {len(failures)} fail(s)")
if failures:
    print("  RESULT: FAIL")
    sys.exit(1)
print("  RESULT: OK")
PY
