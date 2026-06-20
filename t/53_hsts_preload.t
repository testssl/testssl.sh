#!/usr/bin/env perl

# Check the HSTS preload list status against the hstspreload.org API (needs --phone-out).
# github.com is on the preload list, example.com is not.
#
# We don't use a full run, only the HTTP header section.

use strict;
use Test::More;

my $tests = 0;
my $prg="./testssl.sh";
my $csv="tmp.csv";
my $cat_csv="";
my $check2run="-q --color 0 --phone-out --ip=one --headers --csvfile $csv";
my $uri="github.com";
my @args="";

die "Unable to open $prg" unless -f $prg;

# Provide proper start conditions
unlink $csv;

#1 run -- a domain which is on the HSTS preload list
printf "\n%s\n", "Unit test for HSTS preload list status against \"$uri\"";
@args="$prg $check2run $uri >/dev/null";
system("@args") == 0
     or die ("FAILED: \"@args\" ");
$cat_csv=`cat $csv`;

# github.com is on the preload list
like($cat_csv, qr/"HSTS_preloadAPI".*"preloaded"/,"\"$uri\" should be on the HSTS preload list");
$tests++;
unlink $csv;

#2 run -- a domain which is NOT on the HSTS preload list
$uri="example.com";
@args="$prg $check2run $uri >/dev/null";
system("@args") == 0
     or die ("FAILED: \"@args\" ");
$cat_csv=`cat $csv`;

# example.com is not on the preload list
like($cat_csv, qr/"HSTS_preloadAPI".*"no entry"/,"\"$uri\" should not be on the HSTS preload list");
$tests++;
unlink $csv;

done_testing($tests);
printf "\n";


# vim:ts=5:sw=5:expandtab
