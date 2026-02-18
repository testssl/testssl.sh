### FAQs

This is a collection of frequently asked questions which should help to answer some of those. It is is recommended reading this before filing issues.


#### 1. Runtime

* I believe I spotted a false positive as testssl.sh complained about a finding \<XYZ\> but my OpenSSL command `openssl s_client -connect <host:port> <MoreParameters> </dev/null` showed no connection.
    * First of all: modern operating systems have disabled some insecure features for security reasons. As you probably can imagine testssl.sh has a different approach: it must have the capabilities to also test insecure cryptography. This is achieved either by supplying the right option to any OpenSSL version which testssl.sh finds or through bash socket programming. For OpenSSL you can temporarily re-enable some insecure crypto algorithms by using `openssl s_client -connect <host:port> -cipher 'DEFAULT@SECLEVEL=0' <MoreParameters> </dev/null`. The bad cryptography which you *can* test during runtime when supplying `-cipher 'DEFAULT@SECLEVEL=0'` to the OpenSSL version from your vendor are ciphers like NULL-MD5 and e.g. signature algorithms like RSA+SHA1. Also TLSv1 and TLSv1.1 may be enabled using this switch.
    * There is other bad cryptography though which you can't test this way, e.g. ancient SSL protocols. Modern OS supply OpenSSL binaries which have [SSLv2 and SSLv3 disabled in the source code or at least when compiling](https://docs.openssl.org/3.3/man7/ossl-guide-tls-introduction/#what-is-tls) which you can't re-enable during runtime. You might get a bit further with the by us supplied OpenSSL-bad version like `OPENSSL_CONF='' ./bin/openssl.Linux.x86_64 s_client -connect <host:port>` which has SSLv2 and SSLv3 enabled and much more  bad stuff. OTOH it doesn't support TLS 1.3 or modern elliptic curves. As said above this and any deficiency is compensated transparently either by using bash or in some cases by automagically and transparently by switching to the OpenSSL version from the vendor.
* I get inconsistent results from testssl.sh when testing through (Cloudflare|CDN XYZ|OnPrem Loadbalancer). 
    * testssl.sh in general is deterministic and provides reproducible results. However the nature of its testing is that it opens a good amount of connections. Thus you might hit rate limits on the server side. Depending on how your testing is performed (terminal or automated) you may or may not see connection errors. If you can't allow-listing your IP you test from you may want to try just to run a restricted test like 'testssl.sh -P' / 'testssl.sh -S' or a series of that.
* I am scanning an IPv6 address or a dual stacked host via the testssl.sh docker image but IPv6 doesn't work.
    * That is is not testssl.sh related but a docker "feature": docker on the host doesn't hand out per default IPv6 addresses to the container, also routing on the host might need additional configuration, see the [docker documentation](https://docs.docker.com/engine/daemon/ipv6/#use-ipv6-for-the-default-bridge-network). The fastest "fix" is just to use [host networking](https://docs.docker.com/engine/network/drivers/host/) like e.g. ``docker run --rm -ti  --net=host  drwetter/testssl.sh -6 ipv6.google.com``

#### 2. Rating / Grading

* I am testing STARTTLS <PROTO\> and I get a poor grading/rating. Why is that??
    * STARTTLS was originally not included in the SSLlabs grading/rating which otherwise we tried to adapt 1:1. The point is that STARTTLS speaks plaintext first and upon the client's request the server may upgrade the connection to TLS on the same port. That is inherently insecure for a number of reasons and **it should be avoided whenever possible** to avoid snooping or MitM attacks. This is the reaason why its labeled as it is.
* But there are standards like DNSSEC and MTA-STS which I implemented and you do not test for that!!
    * They provide a band aid, mostly, for SMTP port 25. For MTA-STS there is a PR pending. DNSSEC: we'll see. But still then we cannot label the server side as secure, as every client would need to test for that. Take this communication as an example: For SMTP and mail server to mail server communication it is still common to deliver e-mails to a mail server if the server certificate does not validate as mail delivery is per default preferred over security. Also if the receiving mail server configured ok and has a valid certificate we can tell whether the sending mail server cares and thus opens the door to MitM attacks. If we would label this as secure it would give you a false sense of security.
* But what about e.g. IMAPS?
    * Most of the clients probably do proper certificate validation nowadays. But still the upgrade form a plaintext connection is flawed and provides a can of worms of security problems, see e.g. [STARTTLS injection](https://nostarttls.secvuln.info/) and [Opossum](https://opossum-attack.com/). As the STARTTLS injection paper outlines: that bug dates back to 2011, when [Vietse Venema discovered a similar flaw](https://www.postfix.org/CVE-2011-0411.html). There is maybe more to come.

#### 3. Code

* Will you backport TLS 1.3, QUIC or some other modern crypto to the supplied OpenSSL-bad version?
    * That is not going to happen as it's more resource efficient use the vendor supplied version and compensate deficiencies with either the OpenSSL-bad version or with bash sockets as/where we see it fit.
    * Also likely there won't be another set of compiled binaries --unless the sky falls on our heads.
* Where can I find infos about "your" OpenSSL version?
    * Source code, documentation and license see [here](https://github.com/testssl/openssl-1.0.2.bad). You're welcome to use it for testing. But don't use it in production on a server or as a client in any other context like testssl.sh!


##### 3.1. Internals 

* Why are you using bash, everybody nowadays uses (python|Golang|Java|etc), it's much faster and modern!
    * The project started in 2007 as series of OpenSSL commands in a shell script which was used for pen testing. OpenSSL then was *the* mandatory part (and partly is) to do some basic operations for all connection checks which would have been more tedious to implement in other programming languages. Over time the project became bigger and it in terms of resources it wasn't a viable option to convert it to (python|Golang|Java|etc). Besides, bash is easy to debug as opposed to a compiled binary. Personally, I believe its capabilities are often underestimated, Testssl.sh contains code for de-/encoding chacha20 or gcm/ccm crypto functions --natively.
    * Since quite some time any OpenSSL or LibreSSL will "do it". What cannot be tested with a particular OpenSSL or LibreSSL version will be done in bash, see enc-/ dec-functions above. And for connection checks we are using bash sockets.
* What the heck are bash sockets?
    * Bash sockets are a method of network programming which happen through the shell interfaces `/dev/tcp/$IPADDRESS/$PORT` --or udp, respectively. It works also with IPv6. Here are some [randomly picked examples](https://www.xmodulo.com/tcp-udp-socket-bash-shell.html) of bash sockets.
* But why don't you now amend or replace that with a (python|perl|Golang|Java|etc) function which does \<ABC\> or \<DEF\> much faster?
    * The philosophy and the beauty of testssl.sh is that it runs *everywhere*, independent on the OS, with a minimal set of dependencies like typical Unix binaries, plus any bash and openssl version. No worries about dependencies on different version of libraries not installed or using binary version A.b or interpreter C.d. .
      



