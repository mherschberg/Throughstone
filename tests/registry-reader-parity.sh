#!/usr/bin/env bash
#
# Parity coverage for the two scripts that read registries/repos.yml.
#
# `- name:`, `location:` and `remote:` are read by the same two lines of awk, written out four
# times across two files: scripts/check.sh keeps them in a `val()` function per awk program that
# reads the registry — one for the check-in's three fields, one for the workspace-root locations
# check 7 allows — and scripts/setup-workspace.sh has them inline twice, once for the location it
# clones into and once for the remote it clones from. Nothing connects the copies. The failure
# that follows is a quiet one: teach one of them a new quoting rule and leave the other alone, and
# the check-in passes a row that the clone loop then clones into a directory whose name starts
# with a quote.
#
# So this file extracts the expressions from the scripts themselves — by content, never by line
# number, because both coordinates recorded for them went stale before it was written — runs every
# one over the same registry lines, and asserts two things per line. That every one of them
# returns the same string: that is the drift this exists to catch, and it is the one that will actually
# happen. And that the string is the value registries/repos.yml's own rules say the line carries:
# copies of one expression cannot disagree with each other about a case they all get wrong,
# so agreement on its own would not be correctness.
#
# It binds the duplication; it does not remove it. Reading the copies into one shared reader is a
# much larger change and not one this test is a step towards.
#
# Deliberately absent, and not an oversight to fill in: any line whose value repos.yml does not
# describe — an embedded `\"`, a doubled closing quote — because pinning an expected value with no
# rule behind it fixes an accident in place. Absent too are the patterns deciding which lines are
# fields at all (`/^[[:space:]]*location:/` and its twin). They are duplicated the same way and are
# identical today, but they are a different expression and belong to a case of their own.

set -uo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/throughstone-registry-reader-test.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

failures=0
bad() { printf 'FAIL: %s\n' "$1" >&2; failures=$((failures + 1)); }

CHECK="$ROOT/Code/{{PROJECT}}-docs/scripts/check.sh"
SETUP="$ROOT/Code/{{PROJECT}}-docs/scripts/setup-workspace.sh"
for script in "$CHECK" "$SETUP"; do
  [ -f "$script" ] || { printf 'FAIL: no such script: %s\n' "$script" >&2; exit 1; }
done

# The opening sub() is what every copy has in common, so a copy added to either script is found
# by it — and a copy this file does not know how to extract fails the counts below rather than
# going unread.
STRIP='sub(/^[^:]*:'

# copies FILE — the lines of FILE that strip a key: prefix. A commented-out copy is not a reader,
# so they are skipped under the same rule both scripts apply to the registry itself: a line whose
# first non-blank character is `#`. Without that, commenting a rule out mid-edit leaves the dead
# line being compared while the script it came from has stopped reading the field.
copies() { grep -F "$STRIP" "$1" | grep -v '^[[:space:]]*#'; }

readers=0
# add_reader LABEL PROGRAM — register one extracted expression as a runnable awk program. Each
# prints its result for every input line, wrapped in markers so that trailing space and an empty
# value are visible in a failure message rather than invisible in it.
add_reader() {
  readers=$((readers + 1))
  printf '%s\n' "$1" > "$TMP_ROOT/reader.$readers.label"
  printf '%s\n' "$2" > "$TMP_ROOT/reader.$readers.awk"
}

# --- 1. Extract the expressions from the scripts --------------------------------
# check.sh wraps its copy in a function, so the program is that function plus a call. The guard
# is not that the line is where it was, but that it is still the shape the call assumes.
check_hits="$(copies "$CHECK" | awk 'END { print NR }')"
setup_hits="$(copies "$SETUP" | awk 'END { print NR }')"
check_vals="$(copies "$CHECK" | grep -cF 'function val(')"
[ "$check_hits" -ge 1 ] \
  || bad "check.sh no longer strips a key: prefix anywhere — find what now reads the three fields"
[ "$check_vals" = "$check_hits" ] \
  || bad "check.sh has $check_hits line(s) stripping a key: prefix and $check_vals of them sit in a val() function, which is the only shape this file knows how to run — teach the extraction below the shape the rest have, or keep every strip on one line with a val() header"
[ "$setup_hits" -ge 2 ] \
  || bad "setup-workspace.sh has $setup_hits line(s) stripping a key: prefix, fewer than the two fields it reads — check what now reads the other one"

# check.sh wraps each copy in a val() function, so a program is that function plus a call. It
# holds one per awk program that reads the registry, and every one of them is run: a copy added
# beside them is compared with the rest instead of going unread.
val_n=0
while IFS= read -r val_line; do
  val_n=$((val_n + 1))
  add_reader "check.sh val() #$val_n" "$val_line
{ print \"<\" val(\$0) \">\" }"
done < <(copies "$CHECK" | grep -F 'function val(')

# setup-workspace.sh writes its copies out inline, one per field, each as the action half of a
# pattern-action rule. Dropping the pattern is the point: the action is the reader, and running it
# on every line is what makes the three comparable on the same input.
while IFS= read -r line; do
  guard="${line%%\{*}"
  action="{${line#*\{}"
  field="$(printf '%s' "$guard" | sed -n 's/.*\*\([a-z][a-z]*\):.*/\1/p')"
  var="$(printf '%s' "$action" | sed -n 's/.*{[[:space:]]*\([A-Za-z_][A-Za-z0-9_]*\)=\$0.*/\1/p')"
  if [ -z "$field" ] || [ -z "$var" ]; then
    bad "setup-workspace.sh: cannot tell which field this line reads or where it puts the value: $line"
    continue
  fi
  add_reader "setup-workspace.sh $field:" "$action
{ print \"<\" $var \">\" }"
done < <(copies "$SETUP")

# Every copy found has to have become a runnable reader, or the comparisons below quietly skip
# one. A copy added later to either script is welcome and is simply compared with the rest — in
# check.sh as long as it is a val() function, which is the shape the guard above requires and the
# extraction runs. A copy this file cannot run is the thing to catch: it is a copy nothing binds.
[ "$readers" -eq $((check_hits + setup_hits)) ] \
  || bad "built $readers runnable reader(s) from $((check_hits + setup_hits)) line(s) that strip a key: prefix — the copies this file could not run are bound by nothing"

# --- 2. The lines, and the value repos.yml says each one carries ------------------
# Every expected value here is what registries/repos.yml states, not what the readers happen to
# do. Its rules: a value is a single-line scalar; a `#` on a value line is part of the value, not
# a comment; and the three fields these readers touch are quoted with double quotes or not at all,
# because a single quote is read as part of the value too.
IN="$TMP_ROOT/inputs"
EXPECTED="$TMP_ROOT/expected"
LABELS="$TMP_ROOT/labels"
: > "$IN"; : > "$EXPECTED"; : > "$LABELS"

# row LABEL LINE VALUE — one registry line, and the value repos.yml says it carries.
row() {
  printf '%s\n' "$1" >> "$LABELS"
  printf '%s\n' "$2" >> "$IN"
  printf '<%s>\n' "$3" >> "$EXPECTED"
}

# The shapes a registry written by the method actually holds.
row "a double-quoted location"     '    location: "Code/api/"'                  'Code/api/'
row "an unquoted location"         '    location: Code/api/'                    'Code/api/'
row "the workspace-root row"       '    location: "."'                          '.'
row "a remote with a colon in it"  '    remote: "git@example.com:TEAM/api.git"'  'git@example.com:TEAM/api.git'
row "the same remote, unquoted"    '    remote: git@example.com:TEAM/api.git'    'git@example.com:TEAM/api.git'
row "a row's own name line"        '  - name: "api"'                            'api'

# The two shapes repos.yml warns about by name. A single quote stays in the value, so a row
# written that way clones into a directory called 'Code — the defect the quoting rule exists for,
# and the one a reader taught single quotes on its own would silently start disagreeing about.
row "a single-quoted location"     "    location: 'Code/api'"                   "'Code/api'"
row "a trailing # note"            '    location: "Code/api/" # team mode: on'   'Code/api/" # team mode: on'

# Whitespace: stripped outside the quotes, kept inside them, and the indent may be tabs.
row "spaces after the quote"       '    location: "Code/api/"   '               'Code/api/'
row "a tab after the quote"        $'    location: "Code/api/"\t'                'Code/api/'
row "trailing spaces, unquoted"    '    location: Code/api/   '                 'Code/api/'
row "spaces inside the quotes"     '    location: "  Code/api/  "'              '  Code/api/  '
row "tabs rather than spaces"      $'\tlocation:\t"Code/api/"'                  'Code/api/'

# Both empties read as no value at all, which is what makes check.sh able to report the row and
# setup-workspace.sh able to skip it.
row "an empty value"               '    location: ""'                           ''
row "a key with no value"          '    location:'                              ''

rows="$(awk 'END { print NR }' "$IN")"
[ "$rows" -gt 0 ] || bad "no input lines — the comparisons below assert nothing"

# --- 3. Run every reader over every line ------------------------------------------
r=0
while [ "$r" -lt "$readers" ]; do
  r=$((r + 1))
  awk -f "$TMP_ROOT/reader.$r.awk" "$IN" > "$TMP_ROOT/out.$r" 2> "$TMP_ROOT/err.$r"
  label="$(cat "$TMP_ROOT/reader.$r.label")"
  [ -s "$TMP_ROOT/err.$r" ] \
    && bad "$label: awk wrote to stderr, so the extracted expression is not a runnable program: $(head -2 "$TMP_ROOT/err.$r")"
  got_rows="$(awk 'END { print NR }' "$TMP_ROOT/out.$r")"
  [ "$got_rows" = "$rows" ] \
    || bad "$label: returned $got_rows line(s) for $rows input line(s), so it did not read them all"
done

# --- 4. The two assertions, per line ------------------------------------------------
# They are independent on purpose. A reader that has drifted fails both — the schema assertion
# names which one is wrong, the parity assertion names what it now disagrees with — and readers
# that agree on a wrong value fail only the first, which is the case agreement alone
# would never have shown.
i=0
while [ "$i" -lt "$rows" ]; do
  i=$((i + 1))
  line_label="$(sed -n "${i}p" "$LABELS")"
  want="$(sed -n "${i}p" "$EXPECTED")"
  first=""
  first_label=""
  r=0
  while [ "$r" -lt "$readers" ]; do
    r=$((r + 1))
    label="$(cat "$TMP_ROOT/reader.$r.label")"
    got="$(sed -n "${i}p" "$TMP_ROOT/out.$r")"
    [ "$got" = "$want" ] \
      || bad "$line_label: $label returned $got, and repos.yml says the value is $want"
    if [ "$r" -eq 1 ]; then
      first="$got"
      first_label="$label"
    elif [ "$got" != "$first" ]; then
      bad "$line_label: $label returned $got where $first_label returned $first — the copies have drifted apart"
    fi
  done
done

if [ "$failures" -ne 0 ]; then
  printf 'repos.yml value readers: %d FAILURE(S)\n' "$failures" >&2
  exit 1
fi
printf 'repos.yml value readers: PASS (%d readers x %d lines)\n' "$readers" "$rows"
