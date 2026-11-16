
### Contributing / participating

Contributing / participating is always welcome!

Please note the following:

* Please read the [coding convention](https://github.com/testssl/testssl.sh/blob/3.3dev/Coding_Convention.md).
* If you have something new and / or bigger which you like to contribute, better open an issue first before you get frustrated.
* Please use one pull request per feature or bug fix or improvement. Please do not mix issues.
* Please test your changes thoroughly as reliability is important for this project. You may want to check different servers with different settings.
* GitHub actions are running automatically when anything is committed. Please inspect any complaints and fix them. Beforehand you could also check using `prove -v` from the "root dir" of this project for the complete run, a single (perl) script with `./t/NR_NAME.t`. You need to have Perl and modules like `Test::More` installed .
* If it's a new feature, please consider writing a unit test for it. You can use e.g. `t/10_baseline_ipv4_http.t` or `t/61_diff_testsslsh.t` as a template. The general documentation for [Test::More](https://perldoc.perl.org/Test/More.html) is a good start.
* When using LLMs: Self-tests which e.g. prove portions of the code fixes an issue are appreciated. However refrain from submitting those in `t/` as unit tests (they run on every PR/commit). Attach self-tests instead.
* New features would need to be documented in the appropriate section in `help()` and in `~/doc/testssl.1.md` . Normally the corresponding ROFF and HTML files should be generated automatically.
* Code documentation pays off!  Please your document your code to make it easier for others to understand what it does .

If you're interested in contributing and wonder how you can help, you can search for different tags in the issues (somewhat increasing degree of difficulty):
* [documentation](https://github.com/testssl/testssl.sh/issues?q=is:issue%20state:open%20label:documentation)
* [good first issue](https://github.com/testssl/testssl.sh/issues?q=is:issue%20state:open%20label:%22good%20first%20issue%22)
* [help wanted](https://github.com/testssl/testssl.sh/issues?q=is:issue%20state:open%20label:%22help%20wanted%22)
* [for grabs](https://github.com/testssl/testssl.sh/issues?q=is:issue%20state:open%20label:%22good%20first%20issue%22)

For questions just open an issue.  Thanks for reading this!


