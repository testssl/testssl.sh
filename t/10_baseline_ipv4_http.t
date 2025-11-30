#!/usr/bin/env perl

# Baseline test for testssl, screen and JSON output

# We could also inspect the JSON for any problems for
#    "id"           : "scanProblem"
#    "finding"      : "Scan interrupted"

use strict;
use Test::More;
use Data::Dumper;
use JSON;

my $tests = 0;
my $prg="./testssl.sh";
my $json_file="";
my $check2run="-p -s -P --fs -S -h -U -q --ip=one --color 0 --jsonfile";
my $uri="google.com";
my $terminal_out="";
my $json_string="";
#FIXME: Pattern we use to trigger an error, but likely we can skip that and instead we should?/could use the following??
#       @args="$prg $check2run $uri >/dev/null";
#       system("@args") == 0
#           or die ("FAILED: \"@args\" ");
my $socket_errors='(e|E)rror|FIXME|\.\/testssl\.sh: line |(f|F)atal|(c|C)ommand not found';
my $openssl_errors='(e|E)rror|FIXME|(f|F)atal|\.\/testssl\.sh: line |Oops|s_client connect problem|(c|C)ommand not found';
my $json_errors='(id".*:\s"scanProblem"|severity".*:\s"FATAL"|"Scan interrupted")';
my $os="$^O";

# useful against "failed to flush stdout" messages
STDOUT->autoflush(1);

die "Unable to open $prg" unless -f $prg;

# Provide proper start conditions
$json_file="tmp.json";
unlink $json_file;

# Title
printf "\n%s\n", "Baseline unit test IPv4 against \"$uri\"";


# run the check
$terminal_out = `$prg $check2run $json_file $uri 2>&1`;
$json_string = json($json_file);


#1
unlike($terminal_out, qr/$socket_errors≈/, "via sockets, checking terminal output");
$tests++;

#2
unlike($json_string, qr/$json_errors/, "via sockets checking JSON output");
$tests++;

#3
unlink $json_file;
$terminal_out = `$prg --ssl-native $check2run $json_file $uri 2>&1`;
$json_string = json($json_file);
unlike($terminal_out, qr/$openssl_errors/, "via (builtin) OpenSSL, checking terminal output");
$tests++;

#4
unlike($json_string, qr/$json_errors/, "via OpenSSL (builtin) checking JSON output");
$tests++;

if ( $os eq "linux" ){
     #5 -- early data test. We just take the last check
     my $found=0;
     open my $fh, '<', $json_file or die "Can't open '$json_file': $!";
     local $/;                    # undef slurp mode
     my $data = decode_json(<$fh>);
     close $fh;

     # Check if the decoded data is an array
     if (ref $data eq 'ARRAY') {
          # Iterate through the array of JSON objects
          foreach my $obj (@$data) {
               # Check if the 'id' is "early_data" and 'severity' is "HIGH"
               if ($obj->{id} eq 'early_data' && $obj->{severity} eq 'HIGH') {
                    $found=1;
                    last;          # we can leave the loop
               }
          }
     }

     if ($found) {
         ok(1, "0‑RTT found in JSON from $uri");
     } else {
         fail("0‑RTT test for $uri failed");
     }
     $tests++;
} elsif ( $os eq "darwin" ){
     printf "%s\n", "Skipping test. The result of the check under MacOS is not understood" ;
}

done_testing($tests);
printf "\n\n";


sub json($) {
	my $file = shift;
	$file = `cat $file`;
	unlink $file;
	return from_json($file);
}

# vim:ts=5:sw=5:expandtab

