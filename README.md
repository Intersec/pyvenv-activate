# Pipenv activate

[![Build Status](https://img.shields.io/travis/nicopauss/pipenv-activate)](https://travis-ci.org/nicopauss/pipenv-activate)
[![License](https://img.shields.io/github/license/nicopauss/pipenv-activate)](https://github.com/nicopauss/pipenv-activate/blob/master/LICENSE)

TODO

## Tests

We are using the unit test framework
[shUnit2](https://github.com/kward/shunit2).

Each test `./test/*_test.sh` can be run individually, but it is also possible
to run all tests for all shells supported by
[shUnit2](https://github.com/kward/shunit2) on your platform by running the
script `./tests/run_all_tests`.

The tests are run on the following shells when available:
- [sh](https://en.wikipedia.org/wiki/Bourne_shell)
- [ash](https://en.wikipedia.org/wiki/Almquist_shell)
- [bash](https://en.wikipedia.org/wiki/Bash_(Unix_shell))
- [dash](https://en.wikipedia.org/wiki/Almquist_shell#dash)
- [ksh](https://en.wikipedia.org/wiki/KornShell)
- [pdksh](https://en.wikipedia.org/wiki/KornShell)
- [zsh](https://en.wikipedia.org/wiki/Z_shell)
