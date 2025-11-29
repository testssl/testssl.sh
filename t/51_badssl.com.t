#!/usr/bin/env perl

use strict;
use Test::More;
use Data::Dumper;
use JSON;

my $tests = 0;
my $prg="./testssl.sh";
my $check2run="-S -q --ip=one --color 0";
my $okout;
my $okjson;
my $uri="badssl.com";

my (
	$out,
	$json,
	$found,
);

die "Unable to open $prg" unless -f $prg;

# useful against "failed to flush stdout" messages
STDOUT->autoflush(1);

# Provide proper start conditions
unlink 'tmp.json';

#1+#2 OK
pass("Running testssl.sh against $uri to create a baseline (may take 2-3 minutes)"); $tests++;
$okout = `$prg $check2run --jsonfile tmp.json $uri`;
$okjson = json('tmp.json');
unlink 'tmp.json';
cmp_ok(@$okjson,'>',10,"We should have more then 10 findings"); $tests++;

# Expiration
$uri="expired.badssl.com";
pass("Running testssl against $uri"); $tests++;
$out = `$prg $check2run --jsonfile tmp.json $uri`;
like($out, qr/Chain of trust\s+NOT ok \(expired\)/,"The chain of trust should be expired"); $tests++;
like($out, qr/Certificate Validity \(UTC\)\s+expired/,"The certificate should be expired"); $tests++;
$json = json('tmp.json');
unlink 'tmp.json';
$found = 0;
foreach my $f ( @$json ) {
	if ( $f->{id} eq "cert_expirationStatus" ) {
		$found = 1;
		like($f->{finding},qr/^expired/,"Finding reads expired."); $tests++;
		is($f->{severity}, "CRITICAL", "Severity should be CRITICAL"); $tests++;
		last;
    }
}
is($found,1,"We should have a finding for this in the JSON output"); $tests++;

# Self signed and not-expired
$uri="self-signed.badssl.com";
pass("Running testssl against $uri"); $tests++;
$out = `$prg $check2run --jsonfile tmp.json $uri`;
unlike($out, qr/Certificate Validity \(UTC\)s+expired/,"The certificate should not be expired"); $tests++;
$json = json('tmp.json');
unlink 'tmp.json';
$found = 0;
foreach my $f ( @$json ) {
	if ( $f->{id} eq "cert_expirationStatus" ) {
		$found = 1;
		like($f->{finding},qr/days/,"Finding doesn't read expired."); $tests++;
		isnt($f->{severity}, "CRITICAL", "Severity should be OK, MEDIUM or HIGH"); $tests++;
		last;
    }
}
is($found,1,"We should a finding for this in the JSON output"); $tests++;

like($out, qr/Chain of trust.*?NOT ok.*\(self signed\)/,"Chain of trust should fail because of self signed"); $tests++;
$found = 0;
foreach my $f ( @$json ) {
	if ( $f->{id} eq "cert_chain_of_trust" ) {
	$found = 1;
		like($f->{finding},qr/^.*self signed/,"Finding says certificate cannot be trusted."); $tests++;
		is($f->{severity}, "CRITICAL", "Severity should be CRITICAL"); $tests++;
		last;
    }
}
is($found,1,"We should have a finding for this in the JSON output"); $tests++;

like($okout, qr/Chain of trust[^\n]*?Ok/,"Chain of trust should be ok"); $tests++;
$found = 0;
foreach my $f ( @$okjson ) {
	if ( $f->{id} eq "cert_chain_of_trust" ) {
		$found = 1;
		like($f->{finding},qr/passed/,"Finding says certificate can be trusted."); $tests++;
		# is($f->{finding},"^.*passed.*","Finding says certificate can be trusted."); $tests++;
		is($f->{severity}, "OK", "Severity should be OK"); $tests++;
		last;
    }
}
is($found,1,"We should have a finding for this in the JSON output"); $tests++;

# Wrong host
#$uri="wrong.host.badssl.com";
#pass("Running testssl against $uri"); $tests++;
#$out = ``$prg $check2run --jsonfile tmp.json $uri`;
#unlike($out, qr/Certificate Expiration\s+expired\!/,"The certificate should not be expired"); $tests++;
#$json = json('tmp.json');
#unlink 'tmp.json';
#$found = 0;
#foreach my $f ( @$json ) {
#	if ( $f->{id} eq "expiration" ) {
#		$found = 1;
#		unlike($f->{finding},qr/^Certificate Expiration.*expired\!/,"Finding should not read expired."); $tests++;
#		is($f->{severity}, "ok", "Severity should be ok"); $tests++;
#		last;
#    }
#}
#is($found,1,"We had a finding for this in the JSON output"); $tests++;

# Incomplete chain
$uri='incomplete-chain.badssl.com';
pass("Running testssl against $uri"); $tests++;
$out = `$prg $check2run --jsonfile tmp.json $uri`;
like($out, qr/Chain of trust.*?NOT ok\s+\(chain incomplete\)/,"Chain of trust should fail because of incomplete"); $tests++;
$json = json('tmp.json');
unlink 'tmp.json';
$found = 0;
foreach my $f ( @$json ) {
	if ( $f->{id} eq "cert_chain_of_trust" ) {
		$found = 1;
		like($f->{finding},qr/^.*chain incomplete/,"Finding says certificate cannot be trusted."); $tests++;
		is($f->{severity}, "CRITICAL", "Severity should be CRITICAL"); $tests++;
		last;
    }
}
is($found,1,"We should have a finding for this in the JSON output"); $tests++;

# TODO: RSA 8192

# TODO: CBC
#$uri='cbc.badssl.com';
#pass("Running testssl against $uri"); $tests++;
#$out = `$prg $check2run --jsonfile tmp.json $uri`;
#like($out, qr/Chain of trust.*?NOT ok\s+\(chain incomplete\)/,"Chain of trust should fail because of incomplete"); $tests++;
#$json = json('tmp.json');
#unlink 'tmp.json';
#$found = 0;
#foreach my $f ( @$json ) {
#	if ( $f->{id} eq "cert_chain_of_trust" ) {
#		$found = 1;
#		like($f->{finding},qr/^All certificate trust checks failed.*incomplete/,"Finding says certificate cannot be trusted."); $tests++;
#		is($f->{severity}, "CRITICAL", "Severity should be CRITICAL"); $tests++;
#		last;
#    }
#}
#is($found,1,"We had a finding for this in the JSON output"); $tests++;


done_testing($tests);

sub json($) {
	my $file = shift;
	$file = `cat $file`;
	unlink $file;
	return from_json($file);
}


# vim:ts=5:sw=5:expandtab

