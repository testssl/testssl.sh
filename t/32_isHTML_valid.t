#!/usr/bin/env perl

# Checking whether the HTML output is somehow valid
# This could be amended by using HTML::Tidy or HTML::Valid

use strict;
use Test::More;
use Data::Dumper;
use Text::Diff;

my $tests = 0;
my $prg="./testssl.sh";
my $html="";
my $html_file="";
my $check2run="--ip=one -4 --openssl /usr/bin/openssl --sneaky --ids-friendly --color 0 --htmlfile";
my $uri="github.com";
my $out="";
my $debughtml="";
my $edited_html="";
# Pick /usr/bin/openssl as we want to avoid the debug messages like "Your ./bin/openssl.Linux.x86_64 doesn't support X25519"
my $diff="";
my $ip="";

# useful against "failed to flush stdout" messages
STDOUT->autoflush(1);

die "Unable to open $prg" unless -f $prg;

# Provide proper start conditions
$html_file="tmp.html";
unlink $html_file;

# Title
printf "\n%s\n", "Unit testing HTML output ...";

#1
printf "%s\n", " .. running $prg against \"$uri\" to create HTML and terminal outputs (may take ~2 minutes)";
# specify a TERM_WIDTH so that the two calls to testssl.sh don't create HTML files with different values of TERM_WIDTH
$out = `TERM_WIDTH=120 $prg $check2run $html_file $uri`;
$html = `cat $html_file`;
# $edited_html will contain the HTML with formatting information removed in order to compare against terminal output
# Start by removing the HTML header.
$edited_html = `tail -n +11 $html_file`;
unlink $html_file;

# Remove the HTML footer
$edited_html =~ s/\n\<\/pre\>\n\<\/body\>\n\<\/html\>//;
# Remove any hypertext links for URLs
$edited_html =~ s/<a href=[0-9A-Za-z ";:_&=\/\.\?\-]*>//g;
$edited_html =~ s/<\/a>//g;

# Replace escaped characters with their original text
$edited_html =~ s/&amp;/&/g;
$edited_html =~ s/&lt;/</g;
$edited_html =~ s/&gt;/>/g;
$edited_html =~ s/&quot;/"/g;
$edited_html =~ s/&apos;/'/g;

$diff = diff \$edited_html, \$out;

ok($edited_html eq $out, "Checking if HTML file matches terminal output") or
     diag ("\n%s\n", "$diff");

$tests++;


if ( $^O eq "darwin" ){
     printf "\nskip debug check on MacOS\n\n";
     done_testing($tests);
     exit 0;
}


#2
printf "%s\n", " .. running again $prg against \"$uri\", now with --debug 4 to create HTML output (may take another ~2 minutes)";
# Redirect stderr to /dev/null in order to avoid some unexplained "date: invalid date" error messages
$out = `TERM_WIDTH=120 $prg $check2run $html_file --debug 4 $uri 2>/dev/null`;
$debughtml = `cat $html_file`;
unlink $html_file;

# Remove date information from the Start and Done banners in the two HTML files, since they were created at different times
$html =~ s/Start 2[0-9][0-9][0-9]-[0-3][0-9]-[0-3][0-9] [0-2][0-9]:[0-5][0-9]:[0-5][0-9]/Start XXXX-XX-XX XX:XX:XX/;
$debughtml =~ s/Start 2[0-9][0-9][0-9]-[0-3][0-9]-[0-3][0-9] [0-2][0-9]:[0-5][0-9]:[0-5][0-9]/Start XXXX-XX-XX XX:XX:XX/;

$html =~ s/Done 2[0-9][0-9][0-9]-[0-3][0-9]-[0-3][0-9] [0-2][0-9]:[0-5][0-9]:[0-5][0-9] \[ *[0-9]*s\]/Done XXXX-XX-XX XX:XX:XX [   Xs]/;
$debughtml =~ s/Done 2[0-9][0-9][0-9]-[0-3][0-9]-[0-3][0-9] [0-2][0-9]:[0-5][0-9]:[0-5][0-9] \[ *[0-9]*s\]/Done XXXX-XX-XX XX:XX:XX [   Xs]/;

# Remove time difference from "HTTP clock skew" line
$html =~ s/HTTP clock skew              \+?-?[0-9]* /HTTP clock skew              X /;
$debughtml =~ s/HTTP clock skew              \+?-?[0-9]* /HTTP clock skew              X /;

$debughtml =~ s/ Pre-test: .*\n//g;
$debughtml =~ s/.*OK: below 825 days.*\n//g;
$debughtml =~ s/.*DEBUG:.*\n//g;
$debughtml =~ s/No engine or GOST support via engine with your.*\n//g;
$debughtml =~ s/.*built: .*\n//g;
$debughtml =~ s/.*Using bash .*\n//g;
$debughtml =~ s/.*has_compression.*\n//g;
$debughtml =~ s/.*Extended master secret extension detected.*\n//g;
# is whole line:   s/.*<pattern> .*\n//g;

# Extract and mask IP address as it can change
if ( $html =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/ ) {
    $ip = $1;
}
$html =~ s/$ip/AAA.BBB.CCC.DDD/g;

if ( $debughtml =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/ ) {
    $ip = $1;
}
$debughtml =~ s/$ip/AAA.BBB.CCC.DDD/g;


$diff = diff \$debughtml, \$html;

ok($debughtml eq $html, "Checking if HTML file created with --debug 4 matches HTML file created without --debug") or
     diag ("\n%s\n", "$diff");
$tests++;

done_testing($tests);
printf "\n\n";


# vim:ts=5:sw=5:expandtab

