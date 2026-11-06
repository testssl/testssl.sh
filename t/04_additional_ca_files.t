#!/usr/bin/env perl

# Offline coverage for --add-ca path expansion and CA bundle concatenation.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

my $dir = tempdir(TMPDIR => 1, CLEANUP => 1);
mkdir "$dir/CA directory" or die "mkdir: $!";
mkdir "$dir/empty directory" or die "mkdir: $!";

sub write_file {
     my ($path, $contents) = @_;
     open my $fh, '>', $path or die "$path: $!";
     print {$fh} $contents;
     close $fh or die "$path: $!";
}

my $ca_a = "-----BEGIN CERTIFICATE-----\nCA A\n-----END CERTIFICATE-----\n";
my $ca_b = "-----BEGIN CERTIFICATE-----\nCA B\n-----END CERTIFICATE-----\n";
my $ca_c = "-----BEGIN CERTIFICATE-----\nCA C\n-----END CERTIFICATE-----\n";
write_file("$dir/root.pem", $ca_a);
write_file("$dir/CA directory/first root.pem", $ca_b);
write_file("$dir/CA directory/second\troot.pem", $ca_c);
write_file("$dir/CA directory/ignored.txt", "not a CA\n");
write_file("$dir/not a CA.pem", "not a CA\n");
write_file("$dir/empty.pem", '');

# Load the actual helper, without starting the scanner or making connections.
open my $source, '<', 'testssl.sh' or die "testssl.sh: $!";
my $script = do { local $/; <$source> };
close $source;
my ($helper) = $script =~ /^(prepare_additional_ca_files\(\) \{\n.*?^\})/ms;
defined $helper or BAIL_OUT('Cannot find prepare_additional_ca_files');
write_file("$dir/prepare.sh", "$helper\n" . <<'BASH');
fatal_cmd_line() {
     printf '%s\n' "$1"
     exit "$2"
}
ERR_RESOURCE=244
ADDTL_CA_FILES=$1
prepare_additional_ca_files
# Model all CAfile consumers: an empty additional list must not read stdin.
cat "${ADDTL_CA_FILES_ARRAY[@]}" "$2"
BASH

sub check_ca_files {
     my ($name, $paths, $expected_status, $expected_output) = @_;
     open my $pipe, '-|', 'bash', "$dir/prepare.sh", $paths, "$dir/root.pem"
          or die "bash: $!";
     my $output = do { local $/; <$pipe> };
     close $pipe;
     my $status = $? >> 8;
     is($status, $expected_status, "$name: exit status");
     if (ref($expected_output) eq 'Regexp') {
          like($output, $expected_output, "$name: diagnostic");
     } else {
          is($output, $expected_output, "$name: concatenated CAs");
     }
}

check_ca_files('no additional CAs', '', 0, $ca_a);
check_ca_files('single file', "$dir/root.pem", 0, $ca_a . $ca_a);
check_ca_files('filename with spaces', "$dir/CA directory/first root.pem", 0, $ca_b . $ca_a);
check_ca_files('filename with a tab', "$dir/CA directory/second\troot.pem", 0, $ca_c . $ca_a);
check_ca_files('comma-separated files', "$dir/root.pem,$dir/CA directory/first root.pem", 0,
     $ca_a . $ca_b . $ca_a);
check_ca_files('directory with spaces', "$dir/CA directory", 0, $ca_b . $ca_c . $ca_a);
check_ca_files('wildcard with spaces', "$dir/CA directory/*.pem", 0, $ca_b . $ca_c . $ca_a);
check_ca_files('missing file', "$dir/missing root.pem", 244, qr/does not exist/);
check_ca_files('empty file', "$dir/empty.pem", 244, qr/does not exist/);
check_ca_files('invalid PEM', "$dir/not a CA.pem", 244, qr/not CA file in PEM format/);
check_ca_files('empty directory', "$dir/empty directory", 244, qr/does not exist/);
check_ca_files('invalid second file', "$dir/root.pem,$dir/not a CA.pem", 244,
     qr/not CA file in PEM format/);

done_testing();

# vim:ts=5:sw=5:expandtab
