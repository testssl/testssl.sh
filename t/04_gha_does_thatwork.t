#!/usr/bin/env perl
#
# tls_server_client_test.pl
#
# Starts `openssl s_server` in the background (safe under GitHub Actions:
# strips RUNNER_TRACKING_ID so the runner's cleanup sweep won't reap it,
# and redirects stdin from /dev/null with -ign_eof so s_server doesn't
# quit after the first connection), waits until it's actually accepting
# connections, then drives one or more `openssl s_client` checks against
# it. Server is always killed on the way out, success or failure.
#
# Host, port, and the self-signed cert/key are all generated/fixed here
# rather than taken from the command line.
#
# Usage:
#   ./tls_server_client_test.pl
#
use strict;
use warnings;
use IPC::Run3;
use File::Temp qw(tempdir);

use constant {
    HOST => '127.0.0.1',
    PORT => 4433,
};

my $LOG = 's_server.' . PORT . '.log';

# tempdir with CLEANUP => 1 removes itself (and the cert/key inside it)
# when the script exits, normally or via die/signal.
my $CERT_DIR = tempdir(CLEANUP => 1);
my $CERT     = "$CERT_DIR/cert.pem";
my $KEY      = "$CERT_DIR/key.pem";

generate_cert($CERT, $KEY);
print "generated self-signed cert/key in $CERT_DIR\n";

# ---------------------------------------------------------------------
# Start the server
# ---------------------------------------------------------------------
my $server_pid = start_server(HOST, PORT, $CERT, $KEY, $LOG);
print "started s_server pid=$server_pid on " . HOST . ":" . PORT . " (log: $LOG)\n";

# Make sure we clean up on normal exit *and* on die()/signal.
my $cleaned_up = 0;
local $SIG{__DIE__} = sub { cleanup($server_pid) unless $cleaned_up; };
local $SIG{INT}     = sub { cleanup($server_pid) unless $cleaned_up; exit 1; };
local $SIG{TERM}    = sub { cleanup($server_pid) unless $cleaned_up; exit 1; };

my $exit_code = 0;
eval {
    wait_for_ready(HOST, PORT, 20, 0.5);
    run_client_checks(HOST, PORT);
    1;
} or do {
    warn "test failed: $@";
    $exit_code = 1;
};

cleanup($server_pid);
exit $exit_code;

# ---------------------------------------------------------------------

sub generate_cert {
    my ($cert, $key) = @_;

    my ($out, $err);
    run3(
        ['openssl', 'req', '-x509', '-newkey', 'rsa:2048', '-nodes',
         '-keyout', $key, '-out', $cert,
         '-days', '1',
         '-subj', '/CN=localhost',
         '-addext', 'subjectAltName=IP:' . HOST],
        \undef, \$out, \$err,
    );

    die "cert generation failed:\n$err\n" if $? != 0;
}

sub start_server {
    my ($host, $port, $cert, $key, $log) = @_;

    my $pid = fork();
    die "fork failed: $!" unless defined $pid;

    if ($pid == 0) {
        # --- child: becomes openssl s_server ---

        # Strip the runner's tracking env var so the Actions runner's
        # process-cleanup sweep (which greps for it) doesn't kill us
        # the moment this step/job ends.
        delete local $ENV{RUNNER_TRACKING_ID};

        # Detach stdin from whatever the parent had (important: s_server
        # treats stdin EOF as "quit after this connection" unless told
        # otherwise). -ign_eof is a second belt-and-suspenders layer.
        open(STDIN,  '<', '/dev/null') or die "reopen STDIN: $!";
        open(STDOUT, '>', $log)        or die "reopen STDOUT: $!";
        open(STDERR, '>&STDOUT')       or die "reopen STDERR: $!";

        exec('openssl', 's_server',
             '-accept', "$host:$port",
             '-cert',   $cert,
             '-key',    $key,
             '-ign_eof',
             '-quiet');
        # exec only returns on failure
        die "exec openssl s_server failed: $!";
    }

    return $pid;
}

sub wait_for_ready {
    my ($host, $port, $tries, $delay) = @_;

    for my $i (1 .. $tries) {
        my ($out, $err);
        # Empty stdin: just probe the handshake, don't send app data.
        run3(
            ['openssl', 's_client', '-connect', "$host:$port"],
            \'', \$out, \$err,
        );
        return 1 if $? == 0;
        select(undef, undef, undef, $delay); # fractional sleep
    }

    die "server on $host:$port never became ready after $tries attempts\n";
}

sub run_client_checks {
    my ($host, $port) = @_;

    # Replace this with your real test(s). Shown here: a basic connect
    # that feeds a line of data through and checks openssl's exit code
    # plus captured output. Swap in Test::More ok()/is() calls as needed.
    my ($out, $err);
    run3(
        ['testssl.sh', '-p', "$host:$port"],
        \"", \$out, \$err,
    );

    die "s_client exited non-zero: $?\nstderr:\n$err\n" if $? != 0;

    print "client check ok, output:\n$out\n";
}

sub cleanup {
    my ($pid) = @_;
    return unless $pid;
    $cleaned_up = 1;

    if (kill(0, $pid)) {          # still alive?
        kill('TERM', $pid);
        # give it a moment, then force it
        for (1 .. 10) {
            last unless kill(0, $pid);
            select(undef, undef, undef, 0.2);
        }
        kill('KILL', $pid) if kill(0, $pid);
    }
    waitpid($pid, 0);
    print "cleaned up s_server pid=$pid\n";
}
