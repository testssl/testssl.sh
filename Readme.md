
## Intro
<!--
![GitHub Tag](https://img.shields.io/github/v/tag/testssl/testssl.sh)
This would display the latest tag which is from the 3.2 branch. Here we don't have tags yet
-->
![GitHub forks](https://img.shields.io/github/forks/testssl/testssl.sh)
![GitHub Repo stars](https://img.shields.io/github/stars/testssl/testssl.sh)
![GitHub Created At](https://img.shields.io/github/created-at/testssl/testssl.sh)
![GitHub last commit](https://img.shields.io/github/last-commit/testssl/testssl.sh)
![GitHub commit activity](https://img.shields.io/github/commit-activity/m/testssl/testssl.sh)
[![Docker](https://img.shields.io/docker/pulls/drwetter/testssl.sh)](https://github.com/testssl/testssl.sh/blob/3.3dev/Dockerfile.md)

[![License](https://img.shields.io/github/license/testssl/testssl.sh)](https://github.com/testssl/testssl.sh/LICENSE)
![Static Badge](https://img.shields.io/badge/version-3.3dev-blue)
![Static Badge](https://img.shields.io/badge/%2Fbin%2Fbash_-blue)
![Static Badge](https://img.shields.io/badge/Libre+OpenSSL_-blue)
[![Vim](https://img.shields.io/badge/Vim-%2311AB00.svg?logo=vim&logoColor=white)](#)
[![Visual Studio Code](https://custom-icon-badges.demolab.com/badge/Visual%20Studio%20Code-0078d7.svg?logo=vsc&logoColor=white)](#)
[![CI test Ubuntu](https://github.com/testssl/testssl.sh/actions/workflows/unit_tests_ubuntu.yml/badge.svg)](https://github.com/testssl/testssl.sh/actions/workflows/unit_tests_ubuntu.yml?branch=3.3dev)
[![CI test MacOS](https://github.com/testssl/testssl.sh/actions/workflows/unit_tests_macos.yml/badge.svg)](https://github.com/testssl/testssl.sh/actions/workflows/unit_tests_macos.yml?branch=3.3dev)
![Mastodon Follow](https://img.shields.io/mastodon/follow/109319848143024146?domain=infosec.exchange)
[![Bluesky](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fpublic.api.bsky.app%2Fxrpc%2Fapp.bsky.actor.getProfile%2F%3Factor%3Dtestssl.bsky.social&query=%24.followersCount&style=social&logo=bluesky&label=Follow%20%40testssl.sh)

`testssl.sh` is a free command line tool which checks a server's service on
any port for the support of TLS/SSL ciphers, protocols as well as some
cryptographic flaws.

### Key features

* Clear output: you can tell easily whether anything is good or bad.
* Machine readable output (CSV, two JSON formats), also HTML output.
* No need to install or to configure something.  No gems, CPAN, pip or the like.
* Works out of the box: Linux, MacOS, FreeBSD, NetBSD, WSL2, MSYS2/Cygwin, OpenBSD needs bash.
* A Dockerfile is provided, there's also an official container build @ dockerhub and GHCR.
* Flexibility: You can test any SSL/TLS enabled and STARTTLS service, not only web servers at port 443.
* Toolbox: Several command line options help you to run *your* test and configure *your* output.
* Reliability: features are tested thoroughly.
* Privacy: It's only you who sees the result, not a third party.
* Freedom: It's 100% open source. You can look at the code, see what's going on.
* The development is free and open @ GitHub. Participation and contributions are welcome.
* Unit tests ensure maturity: check for consistency, whether JSON is valid, runs under Linux+MacOS, and a lot more!

### License

This software is free. You can use it under the terms of GPLv2, see LICENSE.

Attribution is important for the future of this project -- also in the
internet. Thus if you're offering a scanner based on testssl.sh as a public and/or
paid service in the internet you are strongly encouraged to mention to your audience
that you're using this program and where to get this program from. That helps us
to get bugfixes, other feedback and more contributions.

### Compatibility

Testssl.sh is working on every Linux/BSD distribution and MacOS out of the box. Latest when 
the very old version 2.9 was developed, most of the limitations due to disabled features from 
the openssl client are gone due to bash-socket-based checks. An old OpenSSL-bad version is 
supplied but these days you can also use _any_ LibreSSL or OpenSSL version.
   testssl.sh also works on other unixoid systems out of the box, supposed they have
`/bin/bash` >= version 3.2 and standard tools like sed and awk installed. Windows 
(using MSYS2, Cygwin or WSL/WSL2) work too. An implicit (silent) check for binaries is performed 
when you start testssl.sh . System V Unix needs probably to have GNU grep installed. 

Update notifications can be found at [github](https://github.com/testssl/testssl.sh) or most important ones @ [mastodon](https://infosec.exchange/@testssl) or [bluesky](https://bsky.app/profile/testssl.bsky.social). [twitter](https://twitter.com/drwetter) is not being used anymore.

### Installation

You can download testssl.sh branch 3.3dev just by cloning this git repository:

    git clone --depth 1 https://github.com/testssl/testssl.sh.git --branch 3.3dev

3.3dev is the latest development branch which evolved from 3.2 stable. We're trying not to do big experiments in the dev branch, however the point of development is that there will be changes and changes might need a bit time to mature.



#### Docker

Testssl.sh has minimal requirements. As stated you don't have to install or build anything. You can just run it from the pulled/cloned directory. Still if you don't want to pull the GitHub repo to your directory of choice you can pull a container from dockerhub and run it:

<!--

#FIXME: 3.3dev @ dockerhib to be created

```
docker run --rm -ti  drwetter/testssl.sh <your_cmd_line>
```

or from GHCR (GitHub Container Registry which supports more platforms: linux/amd64, linux/386, linux/arm64, linux/arm/v7, linux/arm/v6, linux/ppc64le):

-->

```
docker run --rm -it ghcr.io/testssl/testssl.sh <your_cmd_line>
```

Or if you have cloned this repo you also can just ``cd`` to the INSTALLDIR and run

```
docker build . -t imagefoo && docker run --rm -t imagefoo testssl.net
```

For more please consult [Dockerfile.md](https://github.com/testssl/testssl.sh/blob/3.3dev/Dockerfile.md).




### No Warranty

Usage of the program is without any warranty. Use it at your own risk.

Testssl.sh is intended to be used as a standalone CLI tool. While we tried to apply best practise security measures and sanitize external input, we can't guarantee that the program is without any vulnerabilities. Running as a web service may pose security risks and you're advised to apply additional security measures. Validate input from the user and from all services which are queried.

### Status

Given the current manpower we only support n-1 versions. You're looking at the 3.3.dev branch where further development takes place before 3.4 becomes the stable version and 3.2 becomes old-stable. If you are hestitant with respect to changes, you need to use 3.2. The version 3.0.10 was the last one, there won't be any more updates.


### Documentation

* .. it is there for reading. Please do so :-) -- at least before asking questions. See man page in groff, html and markdown format in `~/doc/`.
* [https://testssl.sh/](https://testssl.sh/) will help to get you started.
* There's also an [AI generated doc](https://deepwiki.com/testssl/testssl.sh), see also below.
* Will Hunt provided a longer [description](https://www.4armed.com/blog/doing-your-own-ssl-tls-testing/) . While it was written for an older version (2.8), it still includes background information.

### Contributing

A lot of contributors already helped to push the project where it currently is, see [CREDITS.md](https://github.com/testssl/testssl.sh/blob/3.3dev/CREDITS.md). Your contribution would be also welcome! There's an [issue list](https://github.com/testssl/testssl.sh/issues). To get started look for issues which are labeled as [good first issue](https://github.com/testssl/testssl.sh/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22), [for grabs](https://github.com/testssl/testssl.sh/issues?q=is%3Aissue+is%3Aopen+label%3A%22for+grabs%22) or [help wanted](https://github.com/testssl/testssl.sh/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22). The latter is more advanced. You can also lookout for [documentation issues](https://github.com/testssl/testssl.sh/issues?q=is%3Aissue%20state%3Aopen%20label%3Adocumentation), or you can help with [unit testing](https://github.com/testssl/testssl.sh/issues?q=is%3Aissue%20state%3Aopen%20label%3A%22unit%20test%22) or improving github actions.

It is recommended to read [CONTRIBUTING.md](https://github.com/testssl/testssl.sh/blob/3.3dev/CONTRIBUTING.md) and please also have a look at he [Coding Convention](https://github.com/testssl/testssl.sh/blob/3.3dev/Coding_Convention.md). Before you start writing PRs with hundreds of lines, better create an issue first.

In general there's also some maintenance burden, like maintaining handshakes and CA stores etc. . If you believe you can contribute and be responsible to one of those maintenance task, please speak up. That would free resources that we could use for development.


### Bug reports

Bug reports are important. It makes this project more robust.

Please file bugs in the issue tracker @ GitHub. Do not forget to provide detailed information, see the template for issues, and further details @
https://github.com/testssl/testssl.sh/wiki/Bug-reporting. Nobody can read your thoughts -- yet. And only agencies your screen ;-)

You can also debug yourself, see [here](https://github.com/testssl/testssl.sh/wiki/Findings-and-HowTo-Fix-them).

----

### External/related projects

Please address questions not specifically to the code of testssl.sh to the respective projects below.

#### AI powered docs @ DeepWiki
* https://deepwiki.com/testssl/testssl.sh

#### Web frontend
* https://github.com/johannesschaefer/webnettools
* https://github.com/TKCERT/testssl.sh-webfrontend

#### Mass scanner w parallel scans and elastic searching the results
* https://github.com/TKCERT/testssl.sh-masscan

#### Privacy checker using testssl.sh
* https://privacyscore.org

#### Nagios / Icinga Plugins
* https://github.com/dnmvisser/nagios-testssl (Python 3)
* https://gitgud.malvager.net/Wazakindjes/icinga2_plugins/src/master/check_testssl.sh (Shell)

#### pentest2xlsx: generate Excel sheets from CSV
* https://github.com/AresS31/pentest2xlsx (python)

#### Brew package

* see [#233](https://github.com/testssl/testssl.sh/issues/233) and
  [https://github.com/Homebrew/homebrew](https://github.com/Homebrew/homebrew)

#### Daemon for batch execution of testssl.sh command files
* https://github.com/bitsofinfo/testssl.sh-processor

#### Daemon for batch processing of testssl.sh JSON result files for sending Slack alerts, reactive copying etc
* https://github.com/bitsofinfo/testssl.sh-alerts

#### GitHub Actions
* https://github.com/marketplace/actions/testssl-sh-scan
