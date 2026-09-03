#!/usr/bin/env perl

# As the name indicates: Check for TLS 1.3 only hosts. It just run the protocol section, there
# it checks for TLS 1.2 (disabled) and TLS 1.3 (enabled)

use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use File::Temp qw( tempdir );
use File::Basename;

my $port = 1443;
my $temp_dir = tempdir(CLEANUP => 1);
my $server_script = "$temp_dir/start_server.sh";

# 1. The Shell Script as HEREDOC
my $shell_code = <<'HEREDOC';
#!/bin/bash
# Configuration
PORT=1443
CERT="server.pem"
KEY="server.key"
# This OpenSSL version will support TLS 1.3
OPENSSL=/usr/bin/openssl

# Force a specific TLS 1.3 cipher suite when needed
# CIPHER_SUITE="TLS_AES_256_GCM_SHA384"

# Generate self-signed cert and key if they don't exist
if [ ! -f "$CERT" ] || [ ! -f "$KEY" ]; then
    echo "Generating self-signed certificate and key..."
    $OPENSSL req -x509 -newkey rsa:2048 -keyout "$KEY" -out "$CERT" -days 42 -nodes -subj "/CN=localhost" 2>&1
fi

# Start OpenSSL server
echo "Starting server on port $PORT..."
# $OPENSSL s_server -accept "$PORT" -cert "$CERT" -key "$KEY" -tls1_3 -ciphersuites "$CIPHER_SUITE"
$OPENSSL s_server -accept "$PORT" -cert "$CERT" -key "$KEY" -tls1_3
HEREDOC


# Write the script to the temp directory
open(my $fh, '>', $server_script) or die "Cannot write script: $!";
print $fh $shell_code;
close($fh);

chmod 0755, $server_script;

# Start the server in the background using fork/exec
my $pid = fork();
if ($pid == 0) {
   # Exec the script in a child process
   exec($server_script);
   exit 0; # Should not reach here
}
elsif ($pid > 0) {
   # Parent process: Wait for server to be ready

   # Wait for the server to be listening on the port
   my $socket;
   my $ready = 0;

   for my $i (1..30) {
       $socket = IO::Socket::INET->new(
           PeerAddr => 'localhost',
           PeerPort => $port,
           Proto    => 'tcp',
           Timeout  => 2,
       );

       if ($socket) {
           $ready = 1;
           close($socket);
           last;
       }
       sleep 1;
   }

   ok($ready, "Server is listening on port $port");

   if ($ready) {
       # Run testssl.sh, capture both stdout and stderr.
       # We're using the OpenSSL version testssl.sh picks up
       my $testssl_output = `./testssl.sh --protocols localhost:$port 2>&1`;

       # Check if TLS 1.3 is found
       like($testssl_output, qr/TLS 1\.3/, "TLS 1.3 is supported");

       # Check if TLS 1.2 is NOT found
       unlike($testssl_output, qr/OFFERED\s+TLS 1\.2/, "TLS 1.2 is NOT offered");

       diag("Test output:\n$testssl_output");
   } else {
       diag("Server failed to start");
   }

   # Cleanup: Kill the server process
   kill 9, $pid;
   waitpid($pid, 0);
}
else {
   die "Fork failed: $!";
}

done_testing();

#  vim:ts=5:sw=5:expandtab
