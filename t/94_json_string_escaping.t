#!/usr/bin/env perl

# Offline unit test for the JSON string escaping in
# fileout_json_print_parameter().
#
# The function under test (and sanitize_fileout()) is extracted from
# ./testssl.sh at run time, so this always exercises the real product code.
# It is NOT a CLI/E2E test: no target is scanned, no network is used, and no
# JSON is fabricated here - bash writes the file, JSON::PP only reads it.

use strict;
use warnings;
use Test::More;
use JSON::PP;
use Encode qw(encode);
use File::Temp qw(tempdir);
use File::Spec;

my $tests = 0;
my $prg   = "./testssl.sh";
my $dir   = tempdir(CLEANUP => 1);
my $bash  = "bash";

die "Unable to open $prg" unless -f $prg;

my $sanitize_src = extract_function("sanitize_fileout");
my $printer_src  = extract_function("fileout_json_print_parameter");

printf "\n%s\n", "Unit testing JSON parameter escaping (offline function harness) ...";

# ---- positive cases: valid JSON, value is the text received --------------
my $raw;

# 1) plain ASCII, nothing to escape
$raw = check_case(name => "ASCII finding", parameter => "finding", filler => "      ",
                  value => "Test: TLS 1.2 offered", not_last => 1, pretty => 0,
                  expect => "Test: TLS 1.2 offered");

# 2) raw UTF-8 must survive byte-identically (é and CJK)
$raw = check_case(name => "raw UTF-8", parameter => "finding", filler => "      ",
                  value => "CN: caf\xc3\xa9 \xe4\xb8\xad\xe6\x96\x87", not_last => 1, pretty => 0,
                  expect => "CN: caf\xc3\xa9 \xe4\xb8\xad\xe6\x96\x87");

# 3) literal OpenSSL escape text must stay literal (not decoded to a NUL)
$raw = check_case(name => "literal \\0A text", parameter => "finding", filler => "      ",
                  value => 'CN=foo\0Abar', not_last => 1, pretty => 0,
                  expect => 'CN=foo\0Abar');

# 4) literal OpenSSL UTF-8 escape text must stay literal as well
$raw = check_case(name => "literal \\C5\\82 text", parameter => "finding", filler => "      ",
                  value => 'CN=foo\C5\82bar', not_last => 1, pretty => 0,
                  expect => 'CN=foo\C5\82bar');

# 5) backslashes and double quotes (Windows path / quoted name)
$raw = check_case(name => "path, backslash, quote", parameter => "finding", filler => "      ",
                  value => 'C:\tmp\"quoted"\x', not_last => 1, pretty => 0,
                  expect => 'C:\tmp\"quoted"\x');

# 6) \c must not terminate the output (printf escape, not data)
$raw = check_case(name => "backslash-c", parameter => "finding", filler => "      ",
                  value => 'before\cafter', not_last => 1, pretty => 0,
                  expect => 'before\cafter');
ok($raw =~ m{"\s*,\n\z}, "backslash-c: output is not truncated by \\c");
$tests++;
diag("truncated output: " . visible($raw)) unless $raw =~ m{"\s*,\n\z};

# 7) a LF is kept by sanitize_fileout(), so it must be JSON-escaped
$raw = check_case(name => "embedded LF", parameter => "finding", filler => "      ",
                  value => "line1\nline2", not_last => 1, pretty => 0,
                  expect => "line1\nline2");
is(scalar(() = $raw =~ /\n/g), 1, "embedded LF: no raw newline inside the JSON string");
$tests++;

# 8) sanitize_fileout() deletes CR and TAB; existing policy, not a loss claim
$raw = check_case(name => "CR removed by sanitize", parameter => "finding", filler => "      ",
                  value => "a\rb", not_last => 1, pretty => 0,
                  expect => "ab");

$raw = check_case(name => "TAB removed by sanitize", parameter => "finding", filler => "      ",
                  value => "a\tb", not_last => 1, pretty => 0,
                  expect => "ab");

# 9) last parameter of an object: no trailing comma
$raw = check_case(name => "last parameter", parameter => "finding", filler => "      ",
                  value => 'a"b', not_last => 0, pretty => 0,
                  expect => 'a"b');
ok($raw !~ /,\s*\z/, "last parameter: no trailing comma");
$tests++;

# ---- negative: the old %b path produced NUL / broken JSON ----------------
$raw = check_case(name => "NUL check", parameter => "finding", filler => "      ",
                  value => 'CN=foo\0Abar', not_last => 1, pretty => 0,
                  expect => 'CN=foo\0Abar');
ok(index($raw, "\0") < 0, "NUL check: no NUL byte in the JSON output");
$tests++;
diag("output contains a NUL byte") if index($raw, "\0") >= 0;

# ---- pretty JSON: same text, other indentation ----------------------------
$raw = check_case(name => "pretty finding", parameter => "finding", filler => "      ",
                  value => 'CN=foo\0Abar "x"', not_last => 0, pretty => 1,
                  expect => 'CN=foo\0Abar "x"');

my ($raw_flat, $got_flat) = run_harness("finding", "      ", 'CN=foo\0Abar "x"', 0, 0);
my ($raw_pretty, $got_pretty) = run_harness("finding", "      ", 'CN=foo\0Abar "x"', 0, 1);
ok(defined $got_flat && defined $got_pretty && $got_flat eq $got_pretty,
   "flat and pretty JSON decode to the same value");
$tests++;

printf "\n";
done_testing($tests);

# --------------------------------------------------------------------------

sub extract_function {
     my $name = shift;

     open my $fh, '<:raw', $prg or die "Unable to open $prg: $!";
     my $src = do { local $/; <$fh> };
     close $fh;

     my ($body) = $src =~ /^(\Q$name\E\(\) \{\n.*?^\}\n)/ms
          or die "Cannot find function $name in $prg";
     return $body;
}

sub check_case {
     my %c = @_;
     my ($raw, $got, $err) = run_harness(@c{qw(parameter filler value not_last pretty)});

     ok(!defined $err, "$c{name}: output is valid JSON")
          or diag("output: " . visible($raw) . "error: $err");
     $tests++;

     if (!defined $err) {
          is($got, $c{expect}, "$c{name}: value is the text received");
          $tests++;
     }
     return $raw;
}

sub run_harness {
     my ($parameter, $filler, $value, $not_last, $pretty) = @_;
     my $out     = File::Spec->catfile($dir, "out.json");
     my $harness = File::Spec->catfile($dir, "harness.sh");
     ($out, $harness) = map { my $p = $_; $p =~ s{\\}{/}g; $p } ($out, $harness);

     unlink $out;
     open my $fh, '>:raw', $harness or die "Unable to write $harness: $!";
     print $fh "#!/usr/bin/env bash\n";
     print $fh "do_json=", ($pretty ? "false" : "true"), "\n";
     print $fh "do_pretty_json=", ($pretty ? "true" : "false"), "\n";
     print $fh "JSONFILE=", sh_quote($out), "\n";
     print $fh $sanitize_src;
     print $fh $printer_src;
     print $fh q{run_case() { fileout_json_print_parameter "$1" "$2" "$3" "$4"; }} . "\n";
     print $fh "value=", sh_quote($value), "\n";
     print $fh "run_case ", sh_quote($parameter), " ", sh_quote($filler),
               q{ "$value" }, " ", sh_quote($not_last ? "true" : "false"), "\n";
     # the product function returns the status of `"$not_last"`; ignore it here
     print $fh "exit 0\n";
     close $fh;

     my $rc = system($bash, $harness);
     my $raw = "";
     if (-f $out) {
          open my $rf, '<:raw', $out or die "Unable to read $out: $!";
          $raw = do { local $/; <$rf> };
          close $rf;
     }
     return ($raw, undef, "harness exited with $rc") if $rc != 0;

     my $body = $raw;
     $body =~ s/,\n\z// if $not_last;
     my $json = "{" . $body . "}";

     my $decoded = eval { JSON::PP->new->utf8->decode($json) };
     return ($raw, undef, $@ || "decode returned nothing") if !defined $decoded;
     return ($raw, encode('UTF-8', $decoded->{$parameter}), undef);
}

sub sh_quote {
     my $s = shift;
     $s =~ s/'/'"'"'/g;
     return "'$s'";
}

sub visible {
     my $s = shift;
     $s =~ s/\0/<NUL>/g;
     $s =~ s/\r/<CR>/g;
     $s =~ s/\t/<TAB>/g;
     $s =~ s/\n/<LF>/g;
     return "[$s] ";
}

# vim:ts=5:sw=5:expandtab
