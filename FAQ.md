### FAQs

This is a collection of frequently asked questions which should help to answer some of those or gain some insights. It could be helpful reading before filing issues.

#### Coding

* Why are you using bash, everybody nowadays uses (python|Golang|Java|etc), it's much faster and modern!
   * The project started in 2007 as series of OpenSSL commands in a shell script which was used for pen testing. OpenSSL then was the central part (and partly is) to do some basic operations for connections and certificates verification which would have been more tedious to implement in other programming languages. Over time the project became bigger and it in terms of resources it wasn't a viable option to convert it to (python|Golang|Java|etc). Besides, bash is easy to debug as opposed to a compiled binary. Personally, I believe its capabilities are often underestimated.

* But why don't you now amend it with a (python|perl|Golang|Java|etc) function which does \<ABC\> or \<DEF\> much faster?
   * The philosophy and the beauty of testssl.sh is that it runs *everywhere* with a minimal set of dependencies like typical Unix binaries. No worries about having a different version of libraries/ interpreter not installed.


#### Runtime

* I believe I spotted a false positive as testssl.sh complained about a finding \<XYZ\> but my OpenSSL command `openssl s_client -connect <host:port> <MoreParameters> </dev/null` showed no connection.
   * First of all: modern operating systems have disabled some insecure features for security reasons. As you probably can imagine testssl.sh has a different approach: it should have the capabilities to also test insecure crypto. This is achieved either by supplying the right option to any OpenSSL version which testssl.sh finds or through bash socket programming. For OpenSSL you can temporarily re-enable some insecure crypto by using `openssl s_client -connect <host:port> -cipher 'DEFAULT@SECLEVEL=0' <MoreParameters> </dev/null `. Or just use the by us supplied OpenSSL-bad version like `OPENSSL_CONF='' ./bin/openssl.Linux.x86_64 s_client -connect <host:port> </dev/null`. The bad crypto which you *can* test during runtime when supplying `-cipher 'DEFAULT@SECLEVEL=0'` to the OpenSSL version from your vendor are ciphers like NULL-MD5 and e.g. signature algorithms like RSA+SHA1. Also TLSv1 and TLSv1.1 may be enabled.
   * There is other bad crypto though which you can't test this way, e.g. former SSL protocols. Modern OS supply OpenSSL binaries which have [SSLv2 and SSLv3 disabled in the source code or at least when compiling](https://docs.openssl.org/3.3/man7/ossl-guide-tls-introduction/#what-is-tls) which you can't re-enable during runtime. OTOH the supplied OpenSSL-bad version from our project supports this -- and more. OTOH it doesn't support TLS 1.3 or modern elliptic curves. This is done via bash sockets or in some cases automagically and transparently by switching to the OpenSSL version from the vendor.

* Will you backport TLS 1.3, QUIC or some other modern crypto to the supplied OpenSSL-bad version?
  * That is not going to happen as it's more resource efficient use the vendor supplied version and compensate deficiencies with either the OpenSSL-bad version or with bash sockets as/where we see it fit.
  * Also likely there won't be another set of compiled binaries --unless the sky falls on our head.


* Where can I find infos about "your" OpenSSL version?
  * Source code, documentation and license see [here](https://github.com/testssl/openssl-1.0.2.bad). You may use it for testing. But don't use it in production on a server or as a client in any other context like testssl.sh!

* What the heck are bash sockets?
   * Bash sockets are a method of network programming which happen through the shell interfaces `/dev/tcp/$IPADDRESS/$PORT` --or udp, respectively. It works also with IPv6. Here are some [randomly picked examples](https://www.xmodulo.com/tcp-udp-socket-bash-shell.html) of bash sockets.
