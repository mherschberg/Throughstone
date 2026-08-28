# tests/tools — maintainer instruments

Things that test this repository but are **not** part of the suite a contributor runs. The suite is
`tests/*.sh`, and this directory is deliberately not matched by that glob, so nothing here joins a
suite run or adds a dependency to one. `init.sh` deletes `tests/` wholesale when a project is
generated, so nothing here reaches a user's project either.

## yaml-differential.pl — the YAML differential sweep

Three things in this project read `registries/repos.yml` and none of them parses YAML: they match
line prefixes and walk characters. Four review rounds each found a different silent misreading in
that code, and each round found a narrower shape than the last. Hunting the next one by hand has no
terminating condition.

This does. It generates a corpus of registry values, asks a real YAML parser what each one means,
asks the shipped readers what each one means, and prints every disagreement.

```
tests/tools/yaml-differential.pl                 # the working tree
tests/tools/yaml-differential.pl --against REF   # a git archive of REF
tests/tools/yaml-differential.pl --show 40       # print more of the divergences
```

Exit 0 when the readers agree with YAML everywhere, 1 when they do not, 2 when the sweep could not
run at all — an extraction that no longer matches, an awk it could not drive. Exit 2 is a failure to
test, which is not a pass, so it is kept apart from both.

**It runs on system perl and nothing else.** `YAML::PP` ships with macOS perl under
`/System/Library/Perl/Extras`, and `init.sh` already hard-depends on `/usr/bin/perl`, so the sweep
adds no dependency to the project. No ruby, no python. To prove that rather than assert it:

```
env -i PATH=/usr/bin:/bin HOME=/tmp /usr/bin/perl tests/tools/yaml-differential.pl
```

The shebang names `/usr/bin/perl` rather than `/usr/bin/env perl` on purpose: a perl earlier on
PATH probably has no `YAML::PP`, and the sweep says so rather than half-running.

### The readers are extracted, never copied

The awk is pulled out of `setup-workspace.sh` and `check.sh` at run time. A copy drifts, and a
drifted differential test is worse than none, because it looks like coverage. If either script's
shape changes so an extraction stops matching, the sweep exits 2 and says which one — it never
reports agreement it did not measure.

Two of the three readers are covered:

- `clean()`, the scalar reader for `location:` and `remote:`. The clone loop and the registry
  flattener carry it separately and are meant to be identical, so both copies run over the same
  corpus and each is held to YAML — which also catches the two of them drifting apart.
- `fmparse()`, check 11's reader for a `provides:` flow mapping.

The third, `record_registry_remote()` in `init.sh`, is **not** covered. It is a writer, so testing it
means a round trip — write, re-parse, ask whether exactly the intended row changed — which is a
different harness. It is also the one whose teeth could not be shown the way these were: the pre-fix
commit below does not touch it. Known unswept ground, written down so it is not mistaken for covered.

### Showing it can fail at all

A sweep that reports zero and cannot demonstrate a non-zero is an assertion that cannot fail.
`--against` is how that is shown: `3e40945` is the commit before the last round of reader fixes.

| corpus | tree | scalar | mapping |
| --- | --- | --- | --- |
| this one | working tree | 10 of 638 valid shapes | 49 of 326 |
| this one | `3e40945` | 49 | 75 |
| the prototype's narrower axes | working tree | 0 of 153 | 0 of 88 |
| the prototype's narrower axes | `3e40945` | 8 | 16 |

The last two rows are the Ruby prototype's own measurements, reproduced by this port — the check
that the port reads the same as the reference it replaces. The first two are the widened corpus:
everything the prototype found, plus shapes it never generated. Re-derive all of it; do not trust
the table.

The working tree is not at zero. Those divergences are **open findings**, not a broken instrument —
three classes, all of them older than `3e40945` and none of them introduced by it:

- a single-quoted note whose apostrophes are written the YAML way, doubled — `fmparse()` drops
  them, where `clean()` handles the same doubling
- an unquoted note containing a quote character — `fmparse()` reads it as a delimiter, which can
  fail a legitimate row with a wrong diagnosis
- `{status:ours,note:"x"}` with no space after a colon — YAML reads no keys there at all
- a `location:` that is only a comment — both readers take the comment text as the path

### What is deliberately not generated

Three shapes where a reader diverges from YAML by decision rather than by accident. Generating them
would put a permanent non-zero in the result and say nothing new:

- a tab inside a value — `clean()` turns it into a space so it cannot spill a tab-separated record
- a `\n` or `\t` escape in a double-quoted value — `clean()` emits the escaped character rather than
  decoding it, which is right for `\"` and `\\` and knowingly wrong for the rest
- a note whose leading or trailing whitespace is meant to survive — `fmparse()` trims both ends of
  every key and value, which is how it tells `k: v` apart at all

Each is written down beside the corpus in the script, so the omissions are arguable rather than
invisible.
