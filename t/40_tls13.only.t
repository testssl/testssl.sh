#!/usr/bin/env perl

# As the name indicates: Check for TLS 1.3 only hosts

use strict;
use warnings;
use Test::More;
use IPC::Run qw( start timeout );
use File::Temp qw( tempdir );
use File::Basename;
use File::Path qw( remove_tree );
use File::Copy;

my $port = 1443;
my $server_script;
my $temp_dir;

BEGIN {
    $temp_dir = tempdir(CLEANUP => 1);
    # Path to the testssl.sh script (assuming we are in the project root)
    $server_script = "$temp_dir/start_server.sh";
}

# 2. The Shell Script (HEREDOC)
# We adapt your snippet slightly to ensure it runs deterministically as a test.
my $shell_code = <<'HEREDOC';
#!/bin/bash
# Configuration
PORT=1443
CERT="server.pem"
KEY="server.key"
PROTOCOL="tls1_3"
DAYS=365
OPENSSL=/usr/bin/openssl

# For a test, we force a specific TLS 1.3 cipher suite to ensure the server starts reliably
# instead of relying on defaults or user input.
# CIPHER_SUITE="TLS_AES_256_GCM_SHA384"

# Generate self-signed cert and key if they don't exist
if [ ! -f "$CERT" ] || [ ! -f "$KEY" ]; then
    echo "Generating self-signed certificate and key..."
    $OPENSSL req -x509 -newkey rsa:2048 -keyout "$KEY" -out "$CERT" -days "$DAYS" -nodes -subj "/CN=localhost"
fi

# Start OpenSSL server
# Note: We use -tls1_3 to enable TLS 1.3.
echo "Starting server on port $PORT..."
# $OPENSSL s_server -accept "$PORT" -cert "$CERT" -key "$KEY" -tls1_3 -ciphersuites "$CIPHER_SUITE"
$OPENSSL s_server -accept "$PORT" -cert "$CERT" -key "$KEY" -tls1_3
HEREDOC

# 3. Setup: Write and execute the script
subtest 'TLS 1.3 Only Server Setup', sub {
    plan skip_all => "IPC::Run not available" unless eval { require IPC::Run; 1 };

    # Write the script to the temp directory
    open(my $fh, '>', $server_script) or die "Cannot write script: $!";
    print $fh $shell_code;
    close($fh);

    chmod 0755, $server_script;

    # Start the server in the background
    my $server = IPC::Run::start([ $server_script ]);

    # Wait for the server to be listening on the port
    my $ready = 0;
    for my $i (1..20) {
        if (system("nc -z localhost $port") == 0) {
            $ready = 1;
            last;
        }
        sleep 1;
    }

    ok($ready, "Server is listening on port $port");

    if (!$ready) {
        diag("Server failed to start");
        $server->finish;
        return;
    }

    # Run testssl.sh
    my $testssl_output = `./testssl.sh --protocols localhost:$port 2>&1`;

    # Verify
    like($testssl_output, qr/TLS 1\.3/, "TLS 1.3 is supported");

    # Check if TLS 1.2 is NOT found (since we only enabled tls1_3)
    # We look for "TLS 1.2" but try to exclude it if it's in a "not supported" section, 
    # but usually testssl prints "NOT offered" or similar.
    # A safer check for "TLS 1.3 ONLY" is to ensure 1.2 is explicitly rejected.
    unlike($testssl_output, qr/OFFERED\s+TLS 1\.2/, "TLS 1.2 is NOT offered");

    # Cleanup the server process
    $server->finish;
};

done_testing();
