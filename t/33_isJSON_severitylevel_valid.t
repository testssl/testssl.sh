#!/usr/bin/env perl

use strict;
use Test::More;
use Data::Dumper;
use JSON;

my $tests = 0;



my $prg="./testssl.sh";
my $json="";
my $json_file="";
my $check2run = '-S --beast --sweet32 --breach --beast --lucky13 --rc4 --severity LOW --color 0';
my $uri = 'badssl.com';
my $out="";
my $json_pretty="";
my $found=1;




# useful against "failed to flush stdout" messages
STDOUT->autoflush(1);

die "Unable to open $prg" unless -f $prg;

# Provide proper start conditions
$json_file="tmp.json";
unlink $json_file;

# Title
printf "\n%s\n", "Doing severity level checks";

#1
pass(" .. running testssl.sh against $uri to create a JSON report with severity level >= LOW (may take 2~3 minutes)"); $tests++;
$out = `$prg $check2run --jsonfile $json_file $uri`;
$json = json($json_file);
unlink $json_file;
$found = 0;
cmp_ok(@$json,'>',0,"At least 1 finding is expected"); $tests++;
foreach my $f ( @$json ) {
    if ( $f->{severity} eq "INFO" ) {
        $found = 1;
        last;
    }
}
is($found,0,"We should not have any finding with INFO level"); $tests++;

#2
pass(" .. running testssl.sh against $uri to create a JSON-PRETTY report with severity level >= LOW (may take 2~3 minutes)"); $tests++;
$out = `$prg $check2run --jsonfile-pretty $json_file $uri`;
$json_pretty = json($json_file);
unlink $json_file;
$found = 0;
my $vulnerabilities = $json_pretty->{scanResult}->[0]->{vulnerabilities};
foreach my $f ( @$vulnerabilities ) {
    if ( $f->{severity} eq "INFO" ) {
        $found = 1;
        last;
    }
}
is($found,0,"We should not have any finding with INFO level"); $tests++;

done_testing($tests);
printf "\n\n";

sub json($) {
    my $file = shift;
    $file = `cat $file`;
    unlink $file;
    return from_json($file);
}


# vim:ts=5:sw=5:expandtab

