### Naming scheme

* 00-05:  Does the bare testssl.sh work at all?
* 10-29:  Do scans work fine (client side)?
* 30-39:  Does reporting work?
* 50-69:  Are the results what I expect (server side)?

Please help to write CI tests! Documentation can be found [here](https://perldoc.perl.org/Test/More.html).
You can consult the existing code here. Feel free to use `10_baseline_ipv4_http.t` or `12_diff_opensslversions.t` as a
template. The latter is newer and code is cleaner.


* `03_debug.t.DISABLED` is a handy tool when the runner is not in line with checks outside github. It provides debugging means
* IPv6 was (status 2025) not allowed, thus the file `11_baseline_ipv6_http.t.DISABLED` which can be renamed if that will change.
