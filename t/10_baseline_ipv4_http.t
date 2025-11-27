#!/usr/bin/env perl

# baseline test for testssl, screen and JSON output

# We could also inspect the JSON for any problems for
#    "id"           : "scanProblem"
#    "finding"      : "Scan interrupted"

use strict;
use Test::More;
use Data::Dumper;
use JSON;

my $tests = 0;
my $prg="./testssl.sh";
my $tmp_json="tmp.json";
my $check2run="-p -s -P --fs -S -h -U -q --ip=one --color 0 --jsonfile $tmp_json";
my $uri="google.com";
my $socket_out="";
my $openssl_out="";
my $socket_json="";
my $openssl_json="";
#FIXME: Pattern we use to trigger an error, but likely we can skip that and instead we should?/could use the following??
#       @args="$prg $check2run $uri >/dev/null";
#       system("@args") == 0
#           or die ("FAILED: \"@args\" ");
my $socket_errors='(e|E)rror|FIXME|\.\/testssl\.sh: line |(f|F)atal|(c|C)ommand not found';
my $openssl_errors='(e|E)rror|FIXME|(f|F)atal|\.\/testssl\.sh: line |Oops|s_client connect problem|(c|C)ommand not found';
my $json_errors='(id".*:\s"scanProblem"|severity".*:\s"FATAL"|"Scan interrupted")';

# useful against "failed to flush stdout" messages
STDOUT->autoflush(1);

die "Unable to open $prg" unless -f $prg;

# Provide proper start conditions
unlink $tmp_json;

# Title
printf "\n%s\n", "Baseline unit test IPv4 against \"$uri\"";
$socket_out = `$prg $check2run $uri 2>&1`;
$socket_json = json($tmp_json);

#1
unlike($socket_out, qr/$socket_errors≈/, "via sockets, checking terminal output");
$tests++;

#2
unlike($socket_json, qr/$json_errors/, "via sockets checking JSON output");
$tests++;
unlink $tmp_json;

#3
$openssl_out = `$prg --ssl-native $check2run $uri 2>&1`;
$openssl_json = json($tmp_json);
unlike($openssl_out, qr/$openssl_errors/, "via (builtin) OpenSSL, checking terminal output");
$tests++;

#4
unlike($openssl_json, qr/$json_errors/, "via OpenSSL (builtin) checking JSON output");
$tests++;
unlink $tmp_json;

done_testing($tests);
printf "\n";


sub json($) {
	my $file = shift;
	$file = `cat $file`;
	unlink $file;
	return from_json($file);
}


# vim:ts=5:sw=5:expandtab

