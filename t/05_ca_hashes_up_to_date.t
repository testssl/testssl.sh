#!/usr/bin/env perl

use strict;
use Test::More;

# Verify that etc/ca_hashes.txt is in sync with the CA bundles (etc/*.pem).
# Regenerates the hashes and compares content, rather than relying on
# file modification times (which git does not preserve).

# Regenerate ca_hashes.txt from the .pem bundles
my $rc = system('./utils/create_ca_hashes.sh');
is($rc, 0, "create_ca_hashes.sh exited successfully");

# Compare the set of SPKI hashes (field 1) between the committed file and
# the freshly regenerated one, order-independently. We do NOT compare the
# whole file byte-for-byte: the name column (field 2) and the line order
# are cosmetic and are not stable across platforms. The name comes from
# `openssl x509 -subject`, which formats differently between LibreSSL
# (macOS) and OpenSSL (Linux); the order comes from `sort`, whose collation
# differs between BSD libc and glibc even under an identically-named locale.
# Only the SPKI hash is deterministic, and it is the sole column testssl.sh
# consumes (grep -h "$hpkp_spki"), so that is what "up to date" means here.
# LC_ALL=C pins the collation so the set comparison is byte-order and
# platform-independent.
my $committed   = `git show HEAD:etc/ca_hashes.txt 2>/dev/null | cut -d' ' -f1 | LC_ALL=C sort -u`;
my $regenerated = `cut -d' ' -f1 etc/ca_hashes.txt 2>/dev/null | LC_ALL=C sort -u`;
my $has_diff = ($committed eq $regenerated) ? "0" : "1";

# Restore the original file and remove the .bak the script creates
system('git checkout -- etc/ca_hashes.txt 2>/dev/null');
unlink 'etc/ca_hashes.txt.bak';

is($has_diff, "0",
   "ca_hashes.txt is up to date with the .pem bundles (run ./utils/create_ca_hashes.sh if not)");

done_testing;


#  vim:ts=5:sw=5:expandtab

