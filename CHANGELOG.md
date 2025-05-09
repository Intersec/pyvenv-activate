# Change log

## [3.0] - 2025-05-09

- Support `uv` package manager.

## [2.1] - 2024-02-19

- Fix broken tests with old Azure pipeline. Use Github actions instead.
- Add `PYVENV_ACTIVATE_TOP_LEVEL_ENV` option to use top-level environment instead of lowest level by default (#4).
- Add `pyvenv_reactivate` command.

## [2.0] - 2021-07-22

- Rename `pipenv-activate` to `pyvenv-activate`.
- Support Poetry and manually virtual environments.

## [1.1] - 2020-10-20

- Fix retrieving Python executable path of Pipenv when `pipenv` executable is
  a shim like with ASDF.

## [1.0] - 2020-07-23

- First version of pipenv-activate to manually or automatically activate
  Pipenv environment when entering a Pipenv project directory.
