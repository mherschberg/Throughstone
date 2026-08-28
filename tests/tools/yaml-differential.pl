#!/usr/bin/perl
#
# The YAML differential sweep — a maintainer instrument, not part of the shipped suite.
#
# Three things in this project read registries/repos.yml and none of them parses YAML: they match
# line prefixes and walk characters. Four review rounds each found a different silent misreading in
# that code — a value truncated at the wrong quote, a comment cloned into a path, a note that became
# a row's status, an escape that hid a real gap — and each round found a narrower shape than the
# last. Hunting the next one by hand has no terminating condition. This does: it generates a corpus
# of registry values, asks a real YAML parser what each one means, asks the shipped readers what
# each one means, and prints every disagreement.
#
# The readers are extracted LIVE from the shipped scripts, never copied. A copy drifts, and a
# drifted differential test is worse than none because it looks like coverage.
#
#   clean()    the scalar reader, for location: and remote:. setup-workspace.sh's clone loop and
#              check.sh's registry flattener carry it separately and are meant to be identical, so
#              the sweep runs BOTH copies over the same corpus and holds each to YAML — which also
#              catches the two of them drifting apart.
#   fmparse()  check 11's reader for a provides: flow mapping.
#
# What it does NOT cover: record_registry_remote() in init.sh, the third reader. That one is a
# writer, so testing it means a round trip — write, re-parse, ask whether exactly the intended row
# changed — which is a different harness. It is also the one whose teeth could not be shown the way
# these are: the pre-fix commit this sweep is demonstrated against did not touch it. Known unswept
# ground, named here so it is not mistaken for covered.
#
# Why it is not in tests/*.sh: it needs a YAML parser, and the shipped suite must stay runnable with
# nothing a contributor does not already have. tests/tools/ is versioned but is not matched by the
# tests/*.sh glob, so the suite loop does not pick it up — and init.sh deletes tests/ wholesale when
# a project is generated, so nothing here reaches a user's project at all.
#
# Why the shebang names /usr/bin/perl rather than /usr/bin/env perl: the parser is YAML::PP, which
# ships with macOS system perl under /System/Library/Perl/Extras. A perl earlier on PATH probably
# does not have it. init.sh already hard-depends on system perl, so this adds no dependency to the
# project — and nothing here needs ruby or python.
#
# Usage:
#     tests/tools/yaml-differential.pl                 # the working tree
#     tests/tools/yaml-differential.pl --against REF   # a git archive of REF — this is how you
#                                                      #   show the sweep can fail at all
#     tests/tools/yaml-differential.pl --src DIR       # a tree already extracted somewhere
#     tests/tools/yaml-differential.pl --show 40       # print more of the divergences
#
# Exit status: 0 when the readers agree with YAML on every shape, 1 when they do not, and 2 when the
# sweep could not run — a reader it could not extract, an awk it could not drive. Exit 2 is a
# failure to test, which is not a pass, so it is not folded into either of the others.

use strict;
use warnings;
use utf8;
use open qw(:std :encoding(UTF-8));
use File::Temp qw(tempdir);
use FindBin ();
use Getopt::Long qw(GetOptions);

BEGIN {
    eval { require YAML::PP; 1 } or do {
        print STDERR "yaml-differential: $^X has no YAML::PP, so there is no ground truth to\n";
        print STDERR "  compare against. macOS system perl carries it — run it as:\n";
        print STDERR "      /usr/bin/perl $0\n";
        exit 2;
    };
}

my %opt = (show => 12);
GetOptions(\%opt, 'src=s', 'against=s', 'show=i', 'help') or exit 2;

if ($opt{help}) {
    print "usage: yaml-differential.pl [--src DIR | --against REF] [--show N]\n";
    exit 0;
}

sub bail { print STDERR "yaml-differential: $_[0]\n"; exit 2 }

sub run_or_bail {
    my @cmd = @_;
    bail("command failed: @cmd") unless system(@cmd) == 0;
}

sub slurp {
    # Explicitly UTF-8: the shipped scripts carry em dashes in their comments, and reading them as
    # bytes slices a multi-byte character in half when the extraction below cuts near one.
    my $path = shift;
    open my $fh, '<:encoding(UTF-8)', $path or bail("cannot read $path: $!");
    local $/;
    my $text = <$fh>;
    close $fh;
    return $text;
}

# --- Where the readers come from ----------------------------------------------------------------

my $root = "$FindBin::RealBin/../..";
my $src  = $opt{src};
my $label = 'working tree';
my $scratch;

if (defined $opt{against}) {
    bail('pass --src or --against, not both') if defined $src;
    # git archive reads the COMMITTED tree at that ref, which is the point: it is the only way to
    # ask what the readers did before a fix, without touching the working tree or the branch.
    $scratch = tempdir(CLEANUP => 1);
    my $tar = "$scratch/tree.tar";
    run_or_bail('git', '-C', $root, 'archive', '-o', $tar, $opt{against});
    run_or_bail('tar', '-xf', $tar, '-C', $scratch);
    $src = $scratch;
    $label = "git archive of $opt{against}";
}
$src = $root unless defined $src;

my $SW = "$src/Code/{{PROJECT}}-docs/scripts/setup-workspace.sh";
my $CK = "$src/Code/{{PROJECT}}-docs/scripts/check.sh";

sub extract {
    my ($text, $re, $what, $path) = @_;
    # A sweep that quietly tests nothing is the failure this whole instrument exists to prevent, so
    # an extraction that no longer matches stops the run rather than reporting agreement.
    $text =~ $re
        or bail("could not extract $what from $path — the script's shape changed; fix the pattern\n"
              . "  in this file rather than letting the sweep report agreement it never measured");
    return $1;
}

my $sw_clone_awk = extract(slurp($SW), qr/done < <\(awk '\n(.*?)\n  ' "\$REG"\)/s,
                           "the clone loop's awk", $SW);
my $ck_text      = slurp($CK);
my $ck_rows_awk  = extract($ck_text, qr/^registry_rows\(\) \{\n  awk '\n(.*?)\n  ' "\$1"\n\}/ms,
                           "registry_rows()'s awk", $CK);
my $ck_fmparse   = extract($ck_text, qr/^(    function fmparse\(.*?^    \})$/ms,
                           "fmparse()", $CK);

# The clone loop's program, unmodified, plus one rule that prints the location the loop would have
# used. Nothing is removed: the generated rows carry no remote:, so the loop's own print never fires
# and the appended rule is the only thing that speaks.
my $prog_sw = $sw_clone_awk . "\n/^[[:space:]]*location:/ { print value(\$0) }\n";

# registry_rows()'s program needs no adaptation at all — it already prints one record per field.
my $prog_ck = $ck_rows_awk;

# fmparse() is a function whose results are consumed inside a large END block, so it is the one
# reader that has to be driven directly: read one mapping per line and print what it understood.
my $prog_fm = "BEGIN { SQ = sprintf(\"%c\", 39) }\n" . $ck_fmparse . "\n"
    . "{ r = fmparse(\$0); printf \"%s\\t%s\\t%s\\t%s\\n\", r,"
    . " (\"status\" in FM ? FM[\"status\"] : \"<none>\"),"
    . " (\"note\" in FM ? FM[\"note\"] : \"<none>\"), FM_DUP }\n";

sub run_awk {
    # Program and input both go to files. An awk program passed as an argument would have to survive
    # this script's own quoting, and the extracted text contains apostrophes and em dashes; a file
    # has no quoting at all.
    my ($prog, $input) = @_;
    my $dir = tempdir(CLEANUP => 1);
    open my $p, '>:encoding(UTF-8)', "$dir/prog.awk" or bail("cannot write program: $!");
    print $p $prog;
    close $p;
    open my $i, '>:encoding(UTF-8)', "$dir/input" or bail("cannot write input: $!");
    print $i $input;
    close $i;
    open my $out, '-|:encoding(UTF-8)', 'awk', '-f', "$dir/prog.awk", "$dir/input"
        or bail("cannot run awk: $!");
    local $/;
    my $text = <$out>;
    close $out;
    return defined $text ? $text : '';
}

sub lines_of { my @l = ($_[0] =~ /([^\n]*)\n/g); return @l }

sub vis {
    # Values here end in spaces and carriage returns on purpose, and a raw print hides both. The
    # guillemets are the boundary; only control characters are escaped, so a backslash in a path
    # still reads as the one character it is.
    my $s = shift;
    return '(no record)' unless defined $s;
    $s =~ s/\r/\\r/g;
    $s =~ s/\n/\\n/g;
    $s =~ s/\t/\\t/g;
    return "\x{ab}$s\x{bb}";
}

# duplicate_keys => 0 makes a repeated key an error rather than last-wins. Last-wins is not a
# reading anything here should be held to: a mapping that names status twice says two things, and
# fmparse reports that rather than picking one. Left at the default, the ground truth would call
# the reader wrong for being right.
my $yp = YAML::PP->new(duplicate_keys => 0);

# --- What neither corpus generates ---------------------------------------------------------------
#
# Three shapes where a reader parts company with YAML by decision rather than by accident.
# Generating them would put a permanent non-zero in the result and say nothing anyone can act on:
#
#   - a tab inside a value. clean() turns it into a space on purpose, because the flattener's own
#     records are tab-separated and a tab would spill a value into the next column.
#   - a \n or \t escape inside a double-quoted value. clean() emits the escaped character rather
#     than decoding it, which is right for \" and \\ — the two a path can carry — and knowingly
#     wrong for the rest. Decoding them would make clean() a YAML parser.
#   - a note whose leading or trailing whitespace is meant to survive. fmparse() trims both ends of
#     every key and value, which is how it tells `k: v` apart at all, and a note that is only spaces
#     is no note — the reading check 11 wants. It can never agree with YAML there.
#
# They are written down rather than merely absent, so the omissions are arguable.

# --- Sweep 1: clean(), over location: values -----------------------------------------------------
#
# cores x wrappings x tails. The prototype's axes were picked in ten minutes by someone hunting two
# known bugs; the ones marked (+) were added here, each for a shape a real registry can carry.

my @cores = (
    # paths, and the punctuation a hand-written walk has to survive
    'Code/api', 'Code/api/', 'a', 'x', '.', 'Code/./a',
    'Code/a b', 'Code/a#b', 'Code/a{b}', 'Code/a}b', "Code/a'b", 'Code/a"b',
    'Code/a\\b', 'Code/a,b', 'Code/a:b', 'Code/a|b', 'Code/a.b',
    # (+) both quote kinds in one value, a doubled backslash, and a backslash already followed by a
    # quote: the two escapes the quoted branch steps over, and the shape that mixes them.
    'Code/a"b\'c', 'Code/a\\\\b', 'Code/a\\"b',
    # (+) a value that is empty, and one that is only spaces. A row whose location has not been
    # filled in yet is an ordinary thing to meet mid-edit, and clean() trims where YAML nullifies.
    '', '   ',
    # (+) non-ASCII. The quoted branch walks a value one substr() at a time, which is a byte rather
    # than a character in some awks, so a multi-byte character can be cut down the middle. The em
    # dash is the one this codebase actually writes.
    'Code/café', 'Code/日本', 'Code/a—b',
    # (+) the locations the clone loop refuses instead of cloning. The refusal is textual, so the
    # text has to survive the read intact to be refused at all.
    '/abs/path', '../up', 'Code/../a', '~/Code/a',
);

my @wraps = (
    sub { $_[0] },
    sub { my $c = shift; $c =~ s/\\/\\\\/g; $c =~ s/"/\\"/g; '"' . $c . '"' },
    sub { my $c = shift; $c =~ s/'/''/g;    "'" . $c . "'" },
);

my @tails = (
    '',
    '   # the checkout on this machine',
    ' # x',
    ' ',                  # (+) trailing whitespace — clean() trims it, YAML keeps it inside quotes
    " # it's here",       # (+) an apostrophe in a comment
    ' # says "hi"',       # (+) a quote in a comment, following a quoted value
    '#nospace',           # (+) a # with no space before it does not start a YAML comment at all
    "\r",                 # (+) a registry saved with CRLF line endings
);

sub loc_line {
    my $lit = shift;
    return "    location:" . ($lit eq '' ? '' : " $lit") . "\n";
}

my (@scalar_cases, %seen_scalar);
for my $core (@cores) {
    for my $wrap (@wraps) {
        my $wrapped = $wrap->($core);
        for my $tail (@tails) {
            my $lit = $wrapped . $tail;
            next if $seen_scalar{$lit}++;
            push @scalar_cases, $lit;
        }
    }
}

my $scalar_reg = "repos:\n";
{
    my $n = 0;
    $scalar_reg .= "  - name: \"r" . (++$n) . "\"\n" . loc_line($_) for @scalar_cases;
}

my @got_sw = lines_of(run_awk($prog_sw, $scalar_reg));
bail(sprintf("the clone loop printed %d locations for %d rows — the corpus and the output are not\n"
           . "  aligned, so no comparison here would mean anything", scalar @got_sw, scalar @scalar_cases))
    unless @got_sw == @scalar_cases;

my %got_ck;
for my $line (split /\n/, run_awk($prog_ck, $scalar_reg), -1) {
    my @f = split /\t/, $line, -1;
    next unless @f >= 6 && $f[2] eq 'field' && $f[4] eq 'location';
    $got_ck{$f[0]} = $f[5];
}

my $scalar_valid = 0;
my @scalar_div;
for my $n (1 .. scalar @scalar_cases) {
    my $lit = $scalar_cases[$n - 1];
    my $doc = eval { $yp->load_string("repos:\n  - name: \"r\"\n" . loc_line($lit)) };
    # A document YAML itself rejects is not a disagreement about a value — it is check 13's
    # business, and the readers are not asked to agree about a file that does not parse.
    next if $@ || ref $doc ne 'HASH' || ref $doc->{repos} ne 'ARRAY' || ref $doc->{repos}[0] ne 'HASH';
    my $v = $doc->{repos}[0]{location};
    next if ref $v;
    # YAML null and the empty string are the same thing to both readers: the row has no location,
    # and the clone loop skips it either way.
    my $truth = defined $v ? "$v" : '';
    $scalar_valid++;

    my $sw = $got_sw[$n - 1];
    my $ck = $got_ck{$n};
    next if defined $ck && $sw eq $truth && $ck eq $truth;
    push @scalar_div, [ $lit, $truth, $sw, $ck ];
}

# --- Sweep 2: fmparse(), over provides: flow mappings --------------------------------------------
#
# notes x quotings x statuses x key orderings. Both orderings matter: one of the round-4 findings
# appeared only with note: written before status:.

my @notes = (
    '', 'plain', 'has, comma', 'says status: ours', 'before, status: ours, later',
    "has 'single' quotes", 'has } brace', 'has # hash', 'has \\" escaped quote',
    'ends with backslash \\\\', 'has : colon',
    # (+) the opening brace as prose, the other quote kind as prose, an apostrophe in ordinary
    # English, and non-ASCII including the em dash this project writes.
    'has { brace', 'has "double" quotes', "it's an apostrophe", 'café — ünïcode',
    # (+) a note that reads like the rest of a mapping. This is the shape that hid a real gap.
    'was = ours, status: gap, still prose',
);

my @note_wraps = (
    sub { my $n = shift; $n =~ s/\\/\\\\/g; $n =~ s/"/\\"/g; '"' . $n . '"' },
    sub { my $n = shift; $n =~ s/'/''/g;    "'" . $n . "'" },
    # An unquoted note is only generated for prose that carries none of a flow mapping's own
    # punctuation. With it, the document is one YAML itself has no single reading of — YAML::PP
    # takes `note: says status: ours` as the note `says status` and drops the rest, where the spec
    # calls the whole thing an error — and a ground truth that lenient cannot say who is wrong.
    sub { my $n = shift; return undef if $n =~ /[:,{}\[\]#]/; $n },
);

my (@map_cases, %seen_map);
for my $note (@notes) {
    for my $wrap (@note_wraps) {
        my $qn = $wrap->($note);
        next unless defined $qn;
        for my $st (qw(ours theirs gap extended)) {
            for my $lit ("{ status: $st, note: $qn }", "{ note: $qn, status: $st }") {
                next if $seen_map{$lit}++;
                push @map_cases, $lit;
            }
        }
    }
}

# Shapes that are not a product of those axes. Each is a whole mapping a registry can really carry.
for my $lit (
    '{}',                                                     # nothing in it
    '{ status: ours }',                                       # no note
    '{ status: ours, note: }',                                # a key with no value
    '{ status: ours, status: gap }',                          # the same key twice
    '{ note: "x", status: ours, }',                           # a trailing comma
    '{status:ours,note:"x"}',                                 # no spaces anywhere
    '{ status: ours, note: "x" } # observed during adoption', # a comment after the closing brace
    '{ status: ours, note: "unterminated }',                  # the quote swallows the closing brace
    '{ status: ours, note: "x"',                              # the brace never closes
    '{ status: ours, note: "x" } trailing',                   # text after the closing brace
) {
    next if $seen_map{$lit}++;
    push @map_cases, $lit;
}

my @got_fm = lines_of(run_awk($prog_fm, join("\n", @map_cases) . "\n"));
bail(sprintf("fmparse answered %d times for %d mappings — the corpus and the output are not\n"
           . "  aligned, so no comparison here would mean anything", scalar @got_fm, scalar @map_cases))
    unless @got_fm == @map_cases;

# The shape test check 13 applies to a provides: value, character for character. A line that fails
# it is failed from the text, before anything asks fmparse what it holds — the same division of
# labour the scalar sweep respects by skipping documents YAML rejects. Holding fmparse to a line
# check 11 never sees would be inventing a contract the code does not have.
my $check13_shape = qr/^\{.*\}([[:space:]]+#.*)?$/;

my $map_valid = 0;
my $map_shape_failed = 0;
my @map_div;
for my $n (1 .. scalar @map_cases) {
    my $lit = $map_cases[$n - 1];
    if ($lit !~ $check13_shape) { $map_shape_failed++; next }
    my ($r, $st, $note, $dup) = split /\t/, $got_fm[$n - 1], -1;
    my $read = "return $r, status " . vis($st) . ", note " . vis($note)
             . ($dup ne '' ? ", duplicate $dup" : '');
    # fmparse reports a clean read only by returning 1 with no duplicate key: 0 and 2 are its two
    # ways of saying the mapping did not close, and a duplicate is a mapping that says two things.
    my $clean_read = ($r eq '1' && $dup eq '');

    my $doc = eval { $yp->load_string("repos:\n  - name: \"r\"\n    provides:\n      ci: $lit\n") };
    my $m;
    $m = $doc->{repos}[0]{provides}{ci}
        if !$@ && ref $doc eq 'HASH' && ref $doc->{repos} eq 'ARRAY'
           && ref $doc->{repos}[0] eq 'HASH' && ref $doc->{repos}[0]{provides} eq 'HASH';

    if (ref $m ne 'HASH') {
        # YAML will not read it as a mapping. The reader is not required to say why — check 13 says
        # that from the text — but it must not report a clean read of something that is not one.
        push @map_div, [ $lit, 'not a mapping YAML will read', $read ] if $clean_read;
        next;
    }
    $map_valid++;
    my $t_st   = exists $m->{status} ? (defined $m->{status} ? "$m->{status}" : '') : '<none>';
    my $t_note = exists $m->{note}   ? (defined $m->{note}   ? "$m->{note}"   : '') : '<none>';
    next if $clean_read && $st eq $t_st && $note eq $t_note;
    push @map_div, [ $lit, "status " . vis($t_st) . ", note " . vis($t_note), $read ];
}

# --- What it found -------------------------------------------------------------------------------

printf "YAML differential sweep — %s\n", $label;
print  "  readers  clean() from setup-workspace.sh and check.sh, fmparse() from check.sh\n";
printf "  truth    YAML::PP %s under %s\n", YAML::PP->VERSION, $^X;
print  "\n";
printf "  scalar   %4d shapes, %4d of them valid YAML, %d divergence(s)\n",
       scalar @scalar_cases, $scalar_valid, scalar @scalar_div;
printf "  mapping  %4d shapes, %4d of them valid YAML, %d divergence(s)\n",
       scalar @map_cases - $map_shape_failed, $map_valid, scalar @map_div;
# Said rather than silently dropped: a count that quietly shrinks reads as coverage it is not.
printf "           %4d further shape(s) check 13 fails from the text, so fmparse is not asked\n",
       $map_shape_failed if $map_shape_failed;

if (@scalar_div) {
    print "\nscalar divergences — what the readers make of a location: value\n";
    my $shown = 0;
    for my $d (@scalar_div) {
        last if $shown++ >= $opt{show};
        my ($lit, $truth, $sw, $ck) = @$d;
        printf "\n  location: %s\n", vis($lit);
        printf "      YAML                 %s\n", vis($truth);
        printf "      setup-workspace.sh   %s%s\n", vis($sw), ($sw eq $truth ? '' : '   <-- differs');
        printf "      check.sh             %s%s\n", vis($ck),
               (defined $ck && $ck eq $truth ? '' : '   <-- differs');
    }
    printf "\n  (%d more not shown; --show %d)\n", @scalar_div - $shown, scalar @scalar_div
        if @scalar_div > $shown;
}

if (@map_div) {
    print "\nmapping divergences — what fmparse() makes of a provides: entry\n";
    my $shown = 0;
    for my $d (@map_div) {
        last if $shown++ >= $opt{show};
        my ($lit, $truth, $read) = @$d;
        printf "\n  %s\n", $lit;
        printf "      YAML     %s\n", $truth;
        printf "      fmparse  %s\n", $read;
    }
    printf "\n  (%d more not shown; --show %d)\n", @map_div - $shown, scalar @map_div
        if @map_div > $shown;
}

my $total = @scalar_div + @map_div;
print "\n";
if ($total) {
    printf "RESULT: %d shape(s) the readers and YAML do not agree on.\n", $total;
    exit 1;
}
print "RESULT: the readers agree with YAML on every shape generated.\n";
exit 0;
