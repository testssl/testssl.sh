#!/usr/bin/env perl

# Just a functional test, whether there are any problems on the client side

# We could also inspect the JSON for any problems for
#    "id"           : "scanProblem"
#    "finding"      : "Scan interrupted"

use strict;
use Test::More;
use Data::Dumper;
# if needed: comment this and the lines below in:
# use JSON;

my $tests = 0;
my $prg="./testssl.sh";
my $check2run ="--client-simulation -q --ip=one --color 0";
my $uri="";
my $socket_out="";
my $openssl_out="";
# Pattern we use to trigger an error:
my $socket_regex_bl='(e|E)rror|\.\/testssl\.sh: line |(f|F)atal|(c|C)ommand not found';
my $openssl_regex_bl='(e|E)rror|(f|F)atal|\.\/testssl\.sh: line |Oops|s_client connect problem|(c|C)ommand not found';

# useful against "failed to flush stdout" messages
STDOUT->autoflush(1);

# my $socket_json="";
# my $openssl_json="";
# $check2run="--jsonfile tmp.json $check2run";

die "Unable to open $prg" unless -f $prg;

#1
$uri="google.com";
# unlink "tmp.json";
printf "\n%s\n", "Client simulations unit test via sockets --> $uri ...";
$socket_out = `$prg $check2run $uri 2>&1`;
# $socket_json = json('tmp.json');
unlike($socket_out, qr/$socket_regex_bl/, "");
$tests++;

#2 Makes little sense anymore but lets just keep this unit test
# unlink "tmp.json";
printf "\n%s\n", "Client simulations unit test via OpenSSL --> $uri ...";
$openssl_out = `$prg $check2run --ssl-native $uri 2>&1`;
# $openssl_json = json('tmp.json');
unlike($openssl_out, qr/$openssl_regex_bl/, "");
$tests++;


#3
$uri="smtp-relay.gmail.com:587";
# unlink "tmp.json";
printf "\n%s\n", "STARTTLS: Client simulations unit test via sockets --> $uri ...";
$socket_out = `$prg $check2run -t smtp $uri 2>&1`;
# $socket_json = json('tmp.json');
unlike($socket_out, qr/$socket_regex_bl/, "");
$tests++;

# unlink "tmp.json";

done_testing($tests);
printf "\n";


sub json($) {
	my $file = shift;
	$file = `cat $file`;
	unlink $file;
	return from_json($file);
}


# vim:ts=5:sw=5:expandtab

