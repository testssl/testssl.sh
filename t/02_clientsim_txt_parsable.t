#!/usr/bin/env perl

# Just a functional test, whether ~/etc/client-simulation.txt
# doesn't have any syntax errors

use strict;
use warnings;
use Test::More;

my $tests = 0;
my $fileout="";
# Patterns used to trigger an error:
my $error_regexp1='(syntax|parse) (e|E)rror';
my $error_regexp2='client-simulation.txt:';

printf "\n%s\n", "Testing whether \"~/etc/client-simulation.txt\" isn't broken ...";
$fileout = `bash ./etc/client-simulation.txt 2>&1`;

#1
check_no_match($fileout, $error_regexp1, "regex 1");
$tests++;

#2
check_no_match($fileout, $error_regexp2, "regex 2");
$tests++;

printf "\n";
done_testing($tests);

# unlike() dumps the entire (often huge) output on failure, which makes the
# actual problem hard to spot in CI. This helper performs the same check but,
# on failure, prints only the lines that matched the error pattern (via diag,
# i.e. stderr) instead of the whole output.
sub check_no_match {
    my ($output, $regex, $desc) = @_;
    $output = "" unless defined $output;
    my $re = $regex;
    $re = qr/$re/ unless ref($re);
    if ($output =~ $re) {
        fail($desc);
        my @lines = ();
        foreach my $line (split /\n/, $output) {
            if ($line =~ $re) {
                push @lines, $line;
            }
        }
        diag("---- ", scalar(@lines), " matching line(s) ----");
        foreach my $line (@lines) {
            diag($line);
        }
        diag("---- end matching lines ----");
    }
    else {
        ok(1, $desc);
    }
    return;
}

#  vim:ts=5:sw=5:expandtab

