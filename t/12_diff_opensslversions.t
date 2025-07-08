#!/usr/bin/env perl

# Baseline diff test against testssl.sh (csv output)
#
# This runs a basic test with the supplied openssl vs /usr/bin/openssl

use strict;
use Test::More;
use Data::Dumper;
use Text::Diff;

my $tests = 0;
my $prg="./testssl.sh";
my $check2run="--protocols --std --server-preference --fs --header --renegotiation --crime --breach --poodle --tls-fallback --sweet32 --beast --lucky13 --freak --logjam --drown --rc4 --phone-out --client-simulation -q --ip=one --color 0 --csvfile";
my $csvfile="tmp.csv";
my $csvfile2="tmp2.csv";
my $cat_csvfile="";
my $cat_csvfile2="";
my $uri="google.com";
my $diff="";
my $distro_openssl="/usr/bin/openssl";
my @args="";
# that can be done better but I am a perl n00b ;-)
my $os=`perl -e 'print "$^O";'`;

die "Unable to open $prg" unless -f $prg;
die "Unable to open $distro_openssl" unless -f $distro_openssl;

# Provide proper start conditions
unlink $csvfile;
unlink $csvfile2;

#1 run

if ( $os eq "linux" ){
     printf "\n%s\n", "Test with supplied openssl against \"$uri\" and save it";
     @args="$prg $check2run $csvfile $uri >/dev/null";
} elsif ( $os eq "darwin" ){
     # macos silicon doesn't have ~/bin/openssl.Darwin.arm64 binary so we use the
     # homebrew version which was moved to /opt/homebrew/bin/openssl.NOPE in
     # .github/workflows/unit_tests_macos.yml
     printf "\n%s\n", "Test with homebrew's openssl 3.5.x against \"$uri\" and save it";
     @args="$prg $check2run $csvfile --openssl /opt/homebrew/bin/openssl.NOPE $uri >/dev/null";
}
system("@args") == 0
     or die ("FAILED: \"@args\"");

# 2
printf "\n%s\n", "Test with $distro_openssl against \"$uri\" and save it";
@args="$prg $check2run $csvfile2 --openssl=$distro_openssl $uri >/dev/null";
system("@args") == 0
     or die ("FAILED: \"@args\" ");

$cat_csvfile  = `cat $csvfile`;
$cat_csvfile2 = `cat $csvfile2`;

# Filter for changes that are allowed to occur
$cat_csvfile  =~ s/HTTP_clock_skew.*\n//g;
$cat_csvfile2 =~ s/HTTP_clock_skew.*\n//g;

# HTTP time
$cat_csvfile  =~ s/HTTP_headerTime.*\n//g;
$cat_csvfile2 =~ s/HTTP_headerTime.*\n//g;

#engine_problem
$cat_csvfile  =~  s/"engine_problem.*\n//g;
$cat_csvfile2  =~ s/"engine_problem.*\n//g;

# PR #2628. TL:DR; make the kx between tls_sockets() and openssl the same for this CI run
$cat_csvfile  =~  s/ECDH 256/ECDH 253/g;
$cat_csvfile  =~  s/ECDH\/MLKEM/ECDH 253  /g;

# Nonce in CSP
$cat_csvfile  =~ s/.nonce-.* //g;
$cat_csvfile2 =~ s/.nonce-.* //g;

# Fix IP addresses. Needed when we don't hit the same IP address. We just remove them
$cat_csvfile  =~ s/","google.com\/.*","443/","google.com","443/g;
$cat_csvfile2 =~ s/","google.com\/.*","443/","google.com","443/g;

$diff = diff \$cat_csvfile, \$cat_csvfile2;

# Compare the differences -- and print them if there were any
ok( $cat_csvfile eq $cat_csvfile2, "Check whether CSV outputs match" ) or
     diag ("\n%s\n", "$diff");

unlink "tmp.csv";
unlink "tmp2.csv";

$tests++;
done_testing($tests);
printf "\n";


#  vim:ts=5:sw=5:expandtab

