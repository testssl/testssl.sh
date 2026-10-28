#!/usr/bin/env perl

# Baseline test for testssl, screen and JSON output

# We could also inspect the JSON for any problems for
#    "id"           : "scanProblem"
#    "finding"      : "Scan interrupted"

use strict;
use warnings;
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
check_no_match($terminal_out, $socket_errors, "via sockets, checking terminal output");
$tests++;

#2
check_no_match($json_string, $json_errors, "via sockets checking JSON output");
$tests++;

#3
unlink $json_file;
$terminal_out = `$prg --ssl-native $check2run $json_file $uri 2>&1`;
$json_string = json($json_file);
check_no_match($terminal_out, $openssl_errors, "via (builtin) OpenSSL, checking terminal output");
$tests++;

#4
check_no_match($json_string, $json_errors, "via OpenSSL (builtin) checking JSON output");
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


sub json {
	my $file = shift;
	my $content = `cat $file`;
	from_json($content);
	return $content;
}

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

# vim:ts=5:sw=5:expandtab

