#!/usr/bin/env perl

# Just a functional test, whether there are any problems on the client side
# Probably we could also inspect the JSON for any problems for
#    "id"           : "scanProblem"
#    "finding"      : "Scan interrupted"

# Catches:
# - This unit test takes very long
# - Hosts which match the regex patterns should be avoided

use strict;
use Test::More;
use Data::Dumper;
# use JSON;
# if we need JSON we need to comment this and the lines below in

my $tests = 0;
my $prg="./testssl.sh";
my $check2run_smtp="--protocols --standard --fs --server-preference --headers --vulnerable -q --ip=one --color 0";
my $check2run="-q --ip=one --color 0";
my $uri="";
my $socket_out="";
my $openssl_out="";
# Patterns used to trigger an error:
my $socket_regex_bl='(e|E)rror|\.\/testssl\.sh: line |(f|F)atal|(c|C)ommand not found';
my $openssl_regex_bl='(e|E)rror|(f|F)atal|\.\/testssl\.sh: line |Oops|s_client connect problem|(c|C)ommand not found';
my $openssl_fallback_cmd="";       # empty for Linux
my $os="$^O";

# useful against "failed to flush stdout" messages
STDOUT->autoflush(1);

# my $socket_json="";
# my $openssl_json="";
# $check2run_smtp="--jsonfile tmp.json $check2run_smtp";
# $check2run="--jsonfile tmp.json $check2run";

die "Unable to open $prg" unless -f $prg;

if ( $os eq "darwin" ){
     # MacOS silicon doesn't have ~/bin/openssl.Darwin.arm64 binary so we use the
     # homebrew version which was moved to /opt/homebrew/bin/openssl.NOPE in
     # .github/workflows/unit_tests_macos.yml . The LibreSSL version from MacOS
     # sometimes have problems to finish the run, thus we use homebrew's version
     # as fallback.
     # If this will be run outside GH actions, i.e. locally, we provide a fallback to
     # /opt/homebrew/bin/openssl or just leave this thing
     if ( -x "/opt/homebrew/bin/openssl.NOPE" ) {
          $openssl_fallback_cmd="--openssl /opt/homebrew/bin/openssl.NOPE";
     }
     elsif ( -x "/opt/homebrew/bin/openssl" ) {
          $openssl_fallback_cmd="--openssl /opt/homebrew/bin/openssl";
     }
}

$check2run_smtp="$check2run_smtp $openssl_fallback_cmd" ;

#1
$uri="smtp-relay.gmail.com:587";
# unlink "tmp.json";
# we will have client simulations later, so we don't need to run everything again:
printf "\n%s\n", "STARTTLS SMTP unit test via sockets --> $uri ...";
$socket_out = `$prg $check2run_smtp -t smtp $uri 2>&1`;
# $socket_json = json('tmp.json');
unlike($socket_out, qr/$socket_regex_bl/, "");
$tests++;

#2
$uri="pop.gmx.net:110";
# unlink "tmp.json";
printf "\n%s\n", "STARTTLS POP3 unit tests via sockets --> $uri ...";
$socket_out = `$prg $check2run -t pop3 $uri 2>&1`;
# $socket_json = json('tmp.json');
unlike($socket_out, qr/$socket_regex_bl/, "");
$tests++;

#3
$uri="imap.gmx.net:143";
# unlink "tmp.json";
printf "\n%s\n", "STARTTLS IMAP unit tests via sockets --> $uri ...";
$socket_out = `$prg $check2run -t imap $uri 2>&1`;
# $socket_json = json('tmp.json');
unlike($socket_out, qr/$socket_regex_bl/, "");
$tests++;

#4
$uri="mail.tigertech.net:4190";
# unlink "tmp.json";
printf "\n%s\n", "STARTTLS MANAGE(SIEVE) unit tests via sockets --> $uri ...";
$socket_out = `$prg $check2run -t sieve $uri 2>&1`;
# $socket_json = json('tmp.json');
unlike($openssl_out, qr/$openssl_regex_bl/, "");
$tests++;

#5
$uri="jabber.org:5222";
# unlink "tmp.json";
printf "\n%s\n", "STARTTLS XMPP unit tests via sockets --> $uri ...";
$socket_out = `$prg $check2run -t xmpp $uri 2>&1`;
# $socket_json = json('tmp.json');
unlike($openssl_out, qr/$openssl_regex_bl/, "");
$tests++;

# commented out, bc of travis' limits
#
# $uri="jabber.ccc.de:5269";
# printf "\n%s\n", "Quick STARTTLS XMPP S2S unit tests via sockets --> $uri ...";
# $openssl_out = `$prg --openssl=/usr/bin/openssl -p $check2run -t xmpp-server $uri 2>&1`;
# # $openssl_json = json('tmp.json');
# unlike($openssl_out, qr/$openssl_regex_bl/, "");
# $tests++;

#6
$uri="ldap.uni-rostock.de:21";
# unlink "tmp.json";
printf "\n%s\n", "STARTTLS FTP unit tests via sockets --> $uri ...";
$socket_out = `$prg $check2run -t ftp $uri 2>&1`;
# $socket_json = json('tmp.json');
# OCSP stapling fails sometimes with: 'offered, error querying OCSP responder (ERROR: No Status found)'
$socket_out =~ s/ error querying OCSP responder .*\n//g;
unlike($socket_out, qr/$socket_regex_bl/, "");
$tests++;

#7
# https://ldapwiki.com/wiki/Public%20LDAP%20Servers
$uri="db.debian.org:389";
printf "\n%s\n", "STARTTLS LDAP unit tests via sockets --> $uri ...";
$socket_out = `$prg $check2run -t ldap $uri 2>&1`;
# $socket_json = json('tmp.json');
unlike($socket_out, qr/$socket_regex_bl/, "");
$tests++;

# For NNTP there doesn't seem to be reliable host out there
#$uri="144.76.182.167:119";

#printf "\n%s\n", "STARTTLS NNTP unit tests via sockets --> $uri ...";
#$socket_out = `$prg $check2run -t nntp $uri 2>&1`;
#unlike($socket_out, qr/$socket_regex_bl/, "");
#$tests++;
# also: commented out, bc of travis' limits

# IRC: missing
# LTMP, mysql, postgres


done_testing($tests);
# unlink "tmp.json";

sub json($) {
	my $file = shift;
	$file = `cat $file`;
	unlink $file;
	return from_json($file);
}


#  vim:ts=5:sw=5:expandtab

