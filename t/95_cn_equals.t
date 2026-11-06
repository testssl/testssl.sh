#!/usr/bin/env perl

# Regression test for get_cn_from_cert(): the reported common name must keep every
# character of the real CN, including an equals sign inside the value.
#
# testssl.sh renders the certificate subject with
#     openssl x509 -in <cert> -noout -subject -nameopt multiline,-align,sname,-esc_msb,utf8,-space_eq
# which yields a "subject=" line plus one "<short name>=<value>" line per RDN. An
# extractor which splits such a line at every '=' and prints field 2 returns "foo" for
# a certificate whose real CN is "foo=bar", so the cert_commonName field of the reports
# is wrong. The same split also picks up an "CN=" which merely appears inside another
# attribute value.
#
# This test does not re-implement the extractor. It cuts the complete get_cn_from_cert()
# function out of ./testssl.sh at runtime and runs that function in bash against real
# certificates. No scan, no target and no network access is involved: only the extracted
# function and local "openssl x509" calls are executed.
#
# The fixtures below are real self-signed certificates. Only the public certificate bytes
# are embedded here; their private keys were discarded and are not part of this
# repository. Independent DER oracle for the interesting one (openssl asn1parse):
#     56:d=5  hl=2 l=   3 prim: OBJECT            :commonName
#     61:d=5  hl=2 l=   7 prim: UTF8STRING        :foo=bar
#     74:d=5  hl=2 l=   3 prim: OBJECT            :organizationName
#     79:d=5  hl=2 l=  11 prim: UTF8STRING        :Fixture Org
#
# SHA256 of the PEM blocks as embedded below (LF line endings):
#     cn-eq.pem        75529714a9fad1eae452c743807dcef3288b840067a3ee9dc6bd36de4b3d0425
#     cn-control.pem   c50377469f34d009c2a0ff737be743a2d8afd28958638518d999eba72ee4111d
#     no-cn.pem        59da86ff4140e65cbad76c687b9a2b3ad5504698329b0ec7b4e4e91c066d283f
#     embedded-cn.pem  3d00d4e3de544e2507d199ab6cea2f7920c51be5493e93d98a358d260c848ad3
#     utf8-multi.pem   4c737c0a01dee4b7ad9740e7a3ce3e6e7e4f2c89051da1f415ea0dc58eaf8841

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

my $tests = 0;
my $prg = "./testssl.sh";
my $bash = $ENV{TESTSSL_BASH} || "bash";
my $openssl = $ENV{OPENSSL} || "openssl";

sub run {
     my @cmd = @_;
     my $out = "";

     open(my $ph, "-|", @cmd) or return ("", -1);
     {
          local $/;
          my $slurp = <$ph>;
          $out = $slurp if defined $slurp;
     }
     close $ph;
     return ($out, $? >> 8);
}

# Without bash and openssl nothing can be checked. Don't turn that into a pass.
my ($probe_out, $probe_rc) = run($bash, "-c", "printf ok");
plan skip_all => "No usable bash (set TESTSSL_BASH)" unless $probe_rc == 0 && $probe_out eq "ok";
($probe_out, $probe_rc) = run($bash, "-c", "$openssl version");
plan skip_all => "No usable openssl (set OPENSSL)" unless $probe_rc == 0 && $probe_out =~ /^\S+ \d/;

die "Unable to open $prg" unless -f $prg;

# useful against "failed to flush stdout" messages
STDOUT->autoflush(1);

# ---------------------------------------------------------------------------
# The function is taken verbatim from the script under test
# ---------------------------------------------------------------------------
open(my $fh, "<", $prg) or die "Unable to read $prg: $!";
my @src = <$fh>;
close $fh;

my ($func_start, $func_end) = (-1, -1);
for my $i (0 .. $#src) {
     if ($src[$i] =~ /^get_cn_from_cert\(\)\s*\{\s*$/) {
          $func_start = $i;
          last;
     }
}
die "get_cn_from_cert() not found in $prg" if $func_start < 0;
for my $i ($func_start + 1 .. $#src) {
     if ($src[$i] =~ /^\}\s*$/) {
          $func_end = $i;
          last;
     }
}
die "End of get_cn_from_cert() not found in $prg" if $func_end < 0;
my $func = join("", @src[$func_start .. $func_end]);

# ---------------------------------------------------------------------------
# Fixtures: real certificates, public part only
# ---------------------------------------------------------------------------
my %pem = (
     "cn-eq.pem" => <<'PEM',
-----BEGIN CERTIFICATE-----
MIIDLDCCAhSgAwIBAgIUGp3fpp2s4+JufvyI4M47CgOk7GwwDQYJKoZIhvcNAQEL
BQAwKDEQMA4GA1UEAwwHZm9vPWJhcjEUMBIGA1UECgwLRml4dHVyZSBPcmcwHhcN
MjYxMTA2MTA0NDM5WhcNMjYxMTA4MTA0NDM5WjAoMRAwDgYDVQQDDAdmb289YmFy
MRQwEgYDVQQKDAtGaXh0dXJlIE9yZzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
AQoCggEBAKMXTsIZTwZuifGqGyw3s8XuZrtpwfzDYEvviWE2fokZyyuI0beI643T
1mXm/+Q0xxMiVBlgzjaUcBVTs5/ZTIv+OeyqMpRIGKzhLum0wbBS5OpJDuiKZPJ6
vgdQcUrf9SzuiC4/MOD/KA/d1Mm0c8BemcRoUQkYEcldeRYlioNTji7wiq0pVe5u
+43m/vf/po29mHpOOBinE3c1U9ZuEhpGA8K9hFrmOd7fOkAYPfGOH/U19/Ds1Bqm
uxgg2n/WZr3nmnRqTMrZZcU9pmYNvqxq9Ws9bxNmo7Yx72iLcubCBk8EI82L5NQS
tVaLE4kZOLeZtQMz0ciWvrY/r614hukCAwEAAaNOMEwwDwYDVR0TAQH/BAUwAwEB
/zAaBgNVHREEEzARgg9maXh0dXJlLmludmFsaWQwHQYDVR0OBBYEFPK2AZ6aXS2G
58ac+T3Hx6glBLJKMA0GCSqGSIb3DQEBCwUAA4IBAQA48pqkmlKopUoyGjLbHFf7
uZZJYKRjonFBn5TmYVyFglYGNVPFVa5CKM9A39Cnr8kLCD8iJapwAr6lEnFM7Aep
n6EvjbixP3N45RJQmv33rIB6kTQy6INXdpBfdyGtu1i8fblhFArhifuF9mfyE06v
d5ZVU0e6KdnRQEc0ZbU9Fhd7B74SthvIkbj7sIyK8kRfiIpARjz7kbaxYjEP9hXp
SHkvppgZm4u4c+oe4faQfoVKIfNqZyveiHnfotKFyhnhF4LYWk/daZEviR7WEYJn
2nJeM5GHNAo792o0IoUjgYZVfJtQweKoGldXA5rDTgIFq3RObWXE4Sigx7ktkBUC
-----END CERTIFICATE-----
PEM
     "cn-control.pem" => <<'PEM',
-----BEGIN CERTIFICATE-----
MIIDNjCCAh6gAwIBAgIUfbosHGh23sKWDU5MvrFa+qPDqXgwDQYJKoZIhvcNAQEL
BQAwLjEWMBQGA1UEAwwNcGxhaW4uZXhhbXBsZTEUMBIGA1UECgwLRml4dHVyZSBP
cmcwHhcNMjYxMTA2MTA0NDM5WhcNMjYxMTA4MTA0NDM5WjAuMRYwFAYDVQQDDA1w
bGFpbi5leGFtcGxlMRQwEgYDVQQKDAtGaXh0dXJlIE9yZzCCASIwDQYJKoZIhvcN
AQEBBQADggEPADCCAQoCggEBAKWCL9ZPZ62SS3mtq67xjnDIevnGj2BenjqfqnZP
MbAUMCN3wNvh4rOgnr1AAHNO922ul7EYJq5WxU0thwT8Wgj0FV+yOjSqfbAr9BhT
5ipf+Go2z2sEfW1NH1lr6RkxeOSEEYnJ4DnSad6A7346Zg4wUXP/LI6O82Sx/eBx
8dQ4hS6MStVSIjeNaivff3htsfow4+xHw8yzgOdpu5UYj5L7X0HbSoQ8XYvSnWjt
dXAmL4ZM/Ex/ZA4FgRVEawGWSEvJoQSMG8myrnQIKtFss3M5M3qf1uy1gnVCp5+/
cmgs/0DLmj9iIl0JYIJHJ2h60HtBLKju5zhJ1V7uShfINp0CAwEAAaNMMEowDwYD
VR0TAQH/BAUwAwEB/zAYBgNVHREEETAPgg1wbGFpbi5leGFtcGxlMB0GA1UdDgQW
BBThnrXXOvZ+l0gj31sgQxnjz7lj7jANBgkqhkiG9w0BAQsFAAOCAQEAUrcDRgn4
UqGW78ds8TQJay74sVfh6gtJlTKvenbQMrLFWtTRgN2TXvPMoMdIsQkyTdBtu171
ACUodA4IOqnyrP+a7c61nNNQkKOiMNEQ7v0x4zhBpPYGKYzNH4vrFWZEH2PkHqQ7
6G/zo7k1JVLDJuKiYHpmpgscr/pcoXY6vfNGThAeLkOyqWFmxX+aNyh8vELQEKS0
s75XTPPXmlf6E2VTHg4xUX/mT4ryc+qVRpd+nAo6xwvD5EwPqriLIIgyiPWuu5fj
+gGcpPprXNC5xqI9zpY7iZzl/6nVufEgLz2UAIciJ3uaWPAPKBACWybwf6SEZsxA
4c88J42oW63pWg==
-----END CERTIFICATE-----
PEM
     "no-cn.pem" => <<'PEM',
-----BEGIN CERTIFICATE-----
MIIDAjCCAeqgAwIBAgIUL6cjGxOgY83YkO6PlasuD6PW1jwwDQYJKoZIhvcNAQEL
BQAwEzERMA8GA1UECgwIT25seSBPcmcwHhcNMjYxMTA2MTEzNzM0WhcNMzYxMTAz
MTEzNzM0WjATMREwDwYDVQQKDAhPbmx5IE9yZzCCASIwDQYJKoZIhvcNAQEBBQAD
ggEPADCCAQoCggEBALmCphLfPQSn8eyTJ+e3BXaSMvSs0ObUzFz7GslaKvZ8FAfq
Afyk4G02fM4xqEtNmR0qXH33v5Jv8zIIsNyZ827tvXq1o5HZkl2GxFjjQsIIKheW
EddXmDrSfWjGQ1DxsqwN2ODCKlTJ0B0suaF7xrolSkV3tj5/BnCt+n7OgDEJVhy2
F0SJy3CaZ7zw6TEI87fBTnmSNzzoj2EfDVJTZ/QpuCVA9dUsYUBI2ibrk+1Ux+TO
Qv44hGqPRO7YUlhME7KFCsXsJMY7224XnnZhhS2/vF0ZEQa7J3arPUHcD87bzw8D
/eJ3SJ+TciXwW1CdWNMMblbFsOHXVz46unAUJDECAwEAAaNOMEwwDwYDVR0TAQH/
BAUwAwEB/zAaBgNVHREEEzARgg9maXh0dXJlLmludmFsaWQwHQYDVR0OBBYEFDpK
N0zf1GXs1mZFLy9H0uh4ZBl8MA0GCSqGSIb3DQEBCwUAA4IBAQBRqz2+YkkgOYH1
nZFzb1x4814q3+lTUhVc/qj1Nh/r4HDqntC2RhneP3ahMrvlfZNY+SiD9CguB6In
TAlQF59C25PMOhcFNm1wwVQ9Mqn2v4GAX9sI8/NO7BXJd22ZK1Gy3YivwUWVqJmn
rFnmCudVjndyE5gslLVvBr6QDTQz2y6TmFC61VsRfg/gBfZ5+10o2IdobrA3dt56
VcDgmxPipq8y4Ibg1Rc5ExWM0WWTacA7L053noSYaOhs2DB30uSe1SVjIxrtJyXN
qDlj9VOTOOufNF9jYKzJezCvIOvq3rtDEb6ADqRVJ2oq/w11FkBmtLUZ9mciOA4N
WteVaCvK
-----END CERTIFICATE-----
PEM
     "embedded-cn.pem" => <<'PEM',
-----BEGIN CERTIFICATE-----
MIIDNjCCAh6gAwIBAgIUCcAs/INmUZ7P+K5/aYsYVnx8B+0wDQYJKoZIhvcNAQEL
BQAwLTEYMBYGA1UECgwPQ049ZXZpbC5leGFtcGxlMREwDwYDVQQLDAhOb3QgYSBD
TjAeFw0yNjExMDYxMTM3MzRaFw0zNjExMDMxMTM3MzRaMC0xGDAWBgNVBAoMD0NO
PWV2aWwuZXhhbXBsZTERMA8GA1UECwwITm90IGEgQ04wggEiMA0GCSqGSIb3DQEB
AQUAA4IBDwAwggEKAoIBAQCV24kWSJ+9WhIDlcmPkHqdxTabCi5mfm4vbzqwkX1y
4YzKAEdtscKRdXpVBX/9LxoPUFqbw+u2LgO4xIkJdyUmnkoKXMKKpd+kvfzAbbwe
yU6bkdOiLzdaRRrVcsI194bMXX/uDZJTOVZfj6jXDEs6xNfhupGVC/Ctix7gqnw/
Mo7gIg6KVaaL3uGwq48JaLRVmKL1Fb1Cs+5ugNumyL7ErdoQQ5XDvoofI6spBNQ6
QDJjNZO8K3gd/Q54vQclzSUeRRTaRUONQWOQcmOk2zPV7JTIyPV2j2bpdZChIv0Z
htMHwAUsGzHsncvnl68GgugRseooGmFoY+5C2oEjZjidAgMBAAGjTjBMMA8GA1Ud
EwEB/wQFMAMBAf8wGgYDVR0RBBMwEYIPZml4dHVyZS5pbnZhbGlkMB0GA1UdDgQW
BBS5jH3KxAqSTIdoBtkT6OQ+zB9QRjANBgkqhkiG9w0BAQsFAAOCAQEAGA5aZbvw
Ah3q9iXu9IDLB3PQQE3t6NRSlPEbcch1z2/hC25yinkcso7Kzs8mpeUtberiIj5z
wq1hAC81ATEE7uq+WEgRVcQMalUlZRhkuWa21ab/Rio8KUjYyv5SXSEfq0KCI1+K
n4HNhAt+9DVBfYLWtty+cGijqAzWd6B6ddflFqE98tQj+CPWulEAsrF4tSMtK/A8
tgSvqw0BnGsWAy0h8dx/XDBaGPL/J2t/OgLpB7JqoS5Y7sMypKJL5swEIF4ND+wk
72xrMMzIkWSAmPERby9IoCmOWKZRTljM5XyPoCaaEtxNp1Fc/s1lVXLA9PnJHJNJ
FdVXGnSKcJauqw==
-----END CERTIFICATE-----
PEM
     "utf8-multi.pem" => <<'PEM',
-----BEGIN CERTIFICATE-----
MIIDODCCAiCgAwIBAgIUKWap00Mdlj26S1JqzS8Aqb8fJUkwDQYJKoZIhvcNAQEL
BQAwLjEWMBQGA1UEAwwNdMOkc3QgPSBhPWIgYzEUMBIGA1UECgwLRml4dHVyZSBP
cmcwHhcNMjYxMTA2MTEzODM5WhcNMzYxMTAzMTEzODM5WjAuMRYwFAYDVQQDDA10
w6RzdCA9IGE9YiBjMRQwEgYDVQQKDAtGaXh0dXJlIE9yZzCCASIwDQYJKoZIhvcN
AQEBBQADggEPADCCAQoCggEBANHRO4i+auWiiAMwPXlYQia1HZPIV/stcsstemaN
x2EoS1NYuAZBOUSmQ3e1wUndiFLSt5dRpt018F4IhJlmBdNFAJKC1dxic2M+2wLL
TJdbX+dCyYdvAEmlLvWN+tp/oTlwt2S+9C4zG1H7GU4TCwLuihtVOsmiQeSgsnR/
30kQbz4u3qbKdOdTP4vkUUQw3xF2ITdQiLQI5mDrdvO1tLJZuG5Qrx+COPTLYe63
333v8KNZhxuvoGXWbPv6vn8vSq9RJMOi+Uyy9J/7npX5bdC0VDwhGA0f5/3VKiDj
R+VyjhDFpd3BhaGjPmynSrgg3H0oK/SeTnQBeHLOPZ54S9cCAwEAAaNOMEwwDwYD
VR0TAQH/BAUwAwEB/zAaBgNVHREEEzARgg9maXh0dXJlLmludmFsaWQwHQYDVR0O
BBYEFNxvqsM0j6UdUec0UgKRb0D7PsB0MA0GCSqGSIb3DQEBCwUAA4IBAQCpd9lg
+LD2Fq5DXeE0nwc2r2LGn1M9ccU7xEU1+tw0DAhQ0m6ecu2TCAQl+VuqAIgzhWiI
u/uov6M5xMHBrX0fr+jbuFMFw/go0r+6w1eUjMIYOP8fUFkQ2foz3nkQyZF7jFi/
CtTRK58/19LocmFjUqxdnoE0xIIcVMYfpm9k8iHN4a0bcZwEOeBNZdXosvyxxh9K
eNJI/U384OmyNc0V4rMxkuFVGrfxzsis2Vsj+YPX56Ee1xhIXE0+qK3NlLv9k5XS
/mCT7Chxusd6rmUHYlxKPhRV1xZTQMo1RwcABzQ1oEKgIWeC42wH5Y50Ptq3N8/M
I0AOHlZ+SoofoiH6
-----END CERTIFICATE-----
PEM
);

my $dir = tempdir(CLEANUP => 1);
my $dpos = $dir;
$dpos =~ s{\\}{/}g;

for my $name (keys %pem) {
     open(my $f, ">", "$dir/$name") or die "Unable to write $dir/$name: $!";
     print $f $pem{$name};
     close $f;
}

$ENV{OPENSSL} = $openssl;    # the product function calls $OPENSSL unquoted

# ---------------------------------------------------------------------------
# Run one certificate through the extracted function
# ---------------------------------------------------------------------------
sub cn_of {
     my ($cert) = @_;
     my $wrapper = "$dir/get_cn_from_cert.sh";

     open(my $w, ">", $wrapper) or die "Unable to write $wrapper: $!";
     print $w "#!/usr/bin/env bash\n";
     print $w "ERRFILE=\"$dpos/get_cn_from_cert.err\"\n";
     print $w $func;
     print $w "get_cn_from_cert \"\$1\"\n";
     close $w;

     my ($out, $rc) = run($bash, "$dpos/get_cn_from_cert.sh", "$dpos/$cert");
     chomp $out;              # drop the newline of the function's final echo only
     return ($out, $rc);
}

printf "\n%s\n", "get_cn_from_cert() on real certificates";

# Sanity check on the extraction: the body has to be the real one
like($func, qr/x509 -in/, "extracted function uses openssl x509");
$tests++;
like($func, qr/nameopt/, "extracted function keeps the testssl.sh nameopt");
$tests++;

# ---------------------------------------------------------------------------
# The certificates really contain what we claim (independent cross-check)
# ---------------------------------------------------------------------------
my ($subj, $subj_rc) = run($openssl, "x509", "-in", "$dir/cn-eq.pem", "-noout", "-subject",
     "-nameopt", "multiline,-align,sname,-esc_msb,utf8,-space_eq");
is($subj_rc, 0, "openssl x509 reads the cn-eq fixture");
$tests++;
like($subj, qr/^\s+CN=foo=bar\s*$/m, "cn-eq fixture subject is CN=foo=bar");
$tests++;

my ($der, $der_rc) = run($openssl, "asn1parse", "-in", "$dir/cn-eq.pem");
is($der_rc, 0, "openssl asn1parse reads the cn-eq fixture");
$tests++;
like($der, qr/UTF8STRING\s*:\s*foo=bar/, "DER oracle: commonName is the UTF8String \"foo=bar\"");
$tests++;

# ---------------------------------------------------------------------------
# The extractor itself
# ---------------------------------------------------------------------------
my ($out, $rc) = cn_of("cn-eq.pem");
is($rc, 0, "cn-eq: function returned 0");
$tests++;
is($out, "foo=bar ", "cn-eq: complete CN with equals sign, trailing space as before");
$tests++;

($out, $rc) = cn_of("cn-control.pem");
is($rc, 0, "cn-control: function returned 0");
$tests++;
is($out, "plain.example ", "cn-control: plain CN unchanged");
$tests++;

($out, $rc) = cn_of("no-cn.pem");
is($rc, 0, "no-cn: function returned 0");
$tests++;
is($out, "", "no-cn: no CN gives an empty result");
$tests++;

($out, $rc) = cn_of("embedded-cn.pem");
is($rc, 0, "embedded-cn: function returned 0");
$tests++;
is($out, "", "embedded-cn: \"CN=\" inside O/OU is not a commonName");
$tests++;

($out, $rc) = cn_of("utf8-multi.pem");
is($rc, 0, "utf8-multi: function returned 0");
$tests++;
is($out, "t\xc3\xa4st = a=b c ", "utf8-multi: raw UTF-8, spaces and several equals kept");
$tests++;

done_testing($tests);
printf "\n";


#  vim:ts=5:sw=5:expandtab
