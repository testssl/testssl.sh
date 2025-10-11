#!/usr/bin/env perl

# Baseline diff test against testssl.sh (csv output)
#
# We don't use a full run yet and only the certificate section.
# There we would need to blacklist more, like:
# cert_serialNumber, cert_fingerprintSHA1, cert_fingerprintSHA256, cert
# cert_expirationStatus, cert_notBefore, cert_notAfter, cert_caIssuers, intermediate_cert
#

use strict;
use Test::More;
use Data::Dumper;
use Text::Diff;

my $tests = 0;
my $prg="./testssl.sh";
my $baseline_csv="./t/baseline_data/default_testssl.csvfile";
my $cat_csv="tmp.csv";
my $check2run="-p -s -P --fs -h -U -c -q --ip=one --color 0 --csvfile $cat_csv";
my $uri="testssl.sh";
my $diff="";
my @args="";

die "Unable to open $prg" unless -f $prg;
die "Unable to open $baseline_csv" unless -f $baseline_csv;

# Provide proper start conditions
unlink $cat_csv;


#1 run
printf "\n%s\n", "Diff unit test (IPv4) against \"$uri\"";
@args="$prg $check2run $uri >/dev/null";
system("@args") == 0
     or die ("FAILED: \"@args\" ");

$cat_csv=`cat $cat_csv`;
$baseline_csv=`cat $baseline_csv`;

# Filter for changes that are allowed to occur
$cat_csv      =~ s/HTTP_clock_skew.*\n//g;
$baseline_csv =~ s/HTTP_clock_skew.*\n//g;

# HTTP time
$cat_csv      =~ s/HTTP_headerTime.*\n//g;
$baseline_csv =~ s/HTTP_headerTime.*\n//g;

# DROWN
$cat_csv      =~ s/censys.io.*\n//g;
$baseline_csv =~ s/censys.io.*\n//g;

# MacOS / LibreSSL has different OpenSSL names for TLS 1.3 ciphers. That should be rather solved in
#       testssl.sh, see #2763. But for now we do this here.
$cat_csv      =~ s/AEAD-AES128-GCM-SHA256/TLS_AES_128_GCM_SHA256/g;
$cat_csv      =~ s/AEAD-AES256-GCM-SHA384/TLS_AES_256_GCM_SHA384/g;
# this is a bit ugly but otherwise the line cipher-tls1_3_x1303 with the CHACHA20 cipher misses a space
$cat_csv      =~ s/x1303   AEAD-CHACHA20-POLY1305-SHA256/x1303   TLS_CHACHA20_POLY1305_SHA256 /g;
# now the other lines, where we don't need to insert the additional space:
$cat_csv      =~ s/AEAD-CHACHA20-POLY1305-SHA256/TLS_CHACHA20_POLY1305_SHA256/g;

# For Ubuntu 24.04 we don't have MLKEMs yet
$cat_csv      =~ s/ECDH\/MLKEM AESGCM/ECDH 253   AESGCM/g;
$baseline_csv =~ s/ECDH\/MLKEM AESGCM/ECDH 253   AESGCM/g;
$cat_csv      =~ s/ECDH\/MLKEM ChaCha20/ECDH 253   ChaCha20/g;
$baseline_csv =~ s/ECDH\/MLKEM ChaCha20/ECDH 253   ChaCha20/g;

# Same with ECDH bit length
$cat_csv      =~ s/ECDH 253/ECDH 256/g;
$baseline_csv =~ s/ECDH 253/ECDH 256/g;

# this could contain the openssl path
$cat_csv      =~ s/"engine_problem.*\n//g;
$baseline_csv =~ s/"engine_problem.*\n//g;

$diff = diff \$cat_csv, \$baseline_csv;

# Compare the differences to the baseline file -- and print differences if there were detected.
#
ok($cat_csv eq $baseline_csv, "Check whether CSV output matches baseline file from $uri") or
     diag ("\n%s\n", "$diff");

unlink "tmp.csv";

$tests++;
done_testing($tests);
printf "\n";


# vim:ts=5:sw=5:expandtab

