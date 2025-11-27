#!/usr/bin/env perl

# This is more a PoC. Improvements welcome!
#

use strict;
use Test::More;
use JSON;

my $tests = 0;
my $prg="./testssl.sh";
my $json="tmp.json";
my $check2run ="--ip=one --ids-friendly -q --color 0";
my $uri="example.com";        # Cloudflare blocks too often
my $out="";
my $cmd_timeout="--openssl-timeout=10";

# Patterns used to trigger an error:
my $socket_regex_bl='(e|E)rror|\.\/testssl\.sh: line |(f|F)atal|(c|C)ommand not found';
my $openssl_regex_bl='(e|E)rror|(f|F)atal|\.\/testssl\.sh: line |Oops|s_client connect problem|(c|C)ommand not found';
my $os="$^O";

# useful against "failed to flush stdout" messages
STDOUT->autoflush(1);

die "Unable to open $prg" unless -f $prg;

# Provide proper start conditions
unlink $json;

# Title
printf "\n%s\n", "Unit testing JSON output ...";

#1
printf "%s\n", ".. plain JSON --> $uri ";
$out = `$prg $check2run --jsonfile tmp.json $uri`;
$json = json('tmp.json');
unlink 'tmp.json';
my @errors=eval { decode_json($json) };
is(@errors,0,"no errors");
$tests++;

#2
printf "%s\n", ".. pretty JSON --> $uri ";
$out = `$prg $check2run --jsonfile-pretty tmp.json $uri`;
$json = json('tmp.json');
unlink 'tmp.json';
@errors=eval { decode_json($json) };
is(@errors,0,"no errors");
$tests++;


#3
my $uri = "smtp-relay.gmail.com:587";
printf "%s\n", " .. plain JSON and STARTTLS --> $uri ...";
$out = `$prg --jsonfile tmp.json $check2run -t smtp $uri`;
$json = json('tmp.json');
unlink 'tmp.json';
@errors=eval { decode_json($json) };
is(@errors,0,"no errors");
$tests++;

if ( $os eq "linux" ){
     # macos doesn't have a timeout command, unless we install coreutils (gnu coreutils)
     # so we just silently skip this

     #4
     # This testssl.sh run deliberately does NOT work as github actions block port 25 egress.
     # but the output should be fine. The idea is to have a unit test for a failed connection.
     printf "%s\n", ".. plain JSON for a failed run: '--mx $uri' ...";
     $out = `$prg --ssl-native --openssl-timeout=10 $check2run --jsonfile tmp.json --mx $uri`;
     $json = json('tmp.json');
     unlink 'tmp.json';
     @errors=eval { decode_json($json) };
     is(@errors,0,"no errors");
     $tests++;

     #5
     # Same as above but with pretty JSON
     printf "%s\n", ".. pretty JSON for a failed run '--mx $uri' ...";
     $out = `$prg --ssl-native --openssl-timeout=10 $check2run --jsonfile-pretty tmp.json --mx $uri`;
     $json = json('tmp.json');
     unlink 'tmp.json';
     @errors=eval { decode_json($json) };
     is(@errors,0,"no errors");
     $tests++;

} elsif ( $os eq "darwin" ){
     printf "skipped two checks on MacOS\n\n";
}

done_testing($tests);
printf "\n";

sub json($) {
    my $file = shift;
    $file = `cat $file`;
    unlink $file;
    return from_json($file);
}


# vim:ts=5:sw=5:expandtab

