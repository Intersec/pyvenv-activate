# Pyvenv activate

[![Build Status](https://dev.azure.com/nicolaspauss/nicolaspauss/_apis/build/status/Intersec.pipenv-activate?branchName=master)](https://dev.azure.com/nicolaspauss/nicolaspauss/_build/latest?definitionId=3&branchName=master)
[![License](https://img.shields.io/github/license/Intersec/pipenv-activate)](https://github.com/Intersec/pipenv-activate/blob/master/LICENSE)

`pyvenv-activate.sh` is a POSIX shell script containing functions to manually
or automatically activate and deactivate the Python virtual environment of
projects within the current shell.

It currently supports [Pipenv](https://github.com/pypa/pipenv),
[Poetry](https://github.com/python-poetry/poetry), and
[manual virtual environment](#setup-venv-path-file) projects.

Unlike `pipenv shell` or `poetry shell`, the virtual environment is directly
loaded in the current Shell environment and thus it will not start a
new sub-shell when the virtual environment is activated.

For [Pipenv](https://github.com/pypa/pipenv) projects, similar to `pipenv run`
or `pipenv shell`, when a `.env` is present, it will be loaded when the
virtual environment is activated.

Of course, in order to load the different environments,
[Pipenv](https://github.com/pypa/pipenv) or
[Poetry](https://github.com/python-poetry/poetry) must be installed first.


## Table of Contents

* [Features](#features)
* [Installation](#installation)
    * [Plugin installation](#plugin-installation)
        * [Zsh](#zsh)
        * [Bash](#bash)
    * [Manual installation](#manual-installation)
* [Usage](#usage)
    * [Manually](#manually)
    * [Automatically](#automatically)
        * [Mode](#mode)
* [Setup venv path file](#setup-venv-path-file)
* [Pipenv activate](#pipenv-activate)
* [Tests](#tests)

## Features

* Load the virtual environment within the current shell.
* Simple functions for virtual environment activation/deactivation.
* Automatic virtual environment activation/deactivation when entering or
  exiting a Python virtual environment project.
* For [Pipenv](https://github.com/pypa/pipenv) projects:
    * Automatically load `.env` file.
    * Respect [Pipenv configuration environment variables](
https://pipenv.pypa.io/en/latest/advanced/#configuration-with-environment-variables)
(`PIPENV_MAX_DEPTH`, `PIPENV_DOTENV_LOCATION`, ...).
* Works with every POSIX shells (bash, zsh, ksh, ...).

## Installation

### Plugin installation

`pyvenv-activate` can be used as a plugin for shells that support plugin
managers.

#### Zsh

[ZPlug](https://github.com/zplug/zplug)

```zsh
zplug "Intersec/pipenv-activate"
pyvenv_auto_activate_enable # Optional, enable auto activate, see below
```

[Antigen](https://github.com/zsh-users/antigen)

```zsh
antigen bundle "Intersec/pipenv-activate"
pyvenv_auto_activate_enable # Optional, enable auto activate, see below
```

[Zgen](https://github.com/robbyrussell/oh-my-zsh)

```zsh
zgen load "Intersec/pipenv-activate"
pyvenv_auto_activate_enable # Optional, enable auto activate, see below
```

[oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh)

Copy this repository to ``$ZSH_CUSTOM/plugins``, where ``$ZSH_CUSTOM``
is the directory with custom plugins of oh-my-zsh ([read more](https://github.com/robbyrussell/oh-my-zsh/wiki/Customization/)):

```
git clone "https://github.com/Intersec/pipenv-activate.git" "$ZSH_CUSTOM/plugins/pyvenv-activate"
```

Then add `pyvenv-activate` to the list of plugins in your ``.zshrc``. Make sure it is **before** the line `source $ZSH/oh-my-zsh.sh`:
```zsh
plugins=(... pyvenv-activate)
```

To enable the automatic activation, add this line **after** the line `source $ZSH/oh-my-zsh.sh`:
```zsh
pyvenv_auto_activate_enable # Optional, enable auto activate, see below
```

#### Bash

[oh-my-bash](https://github.com/ohmybash/oh-my-bash)

Copy this repository to ``$OSH_CUSTOM/plugins``, where ``$OSH_CUSTOM``
is the directory with custom plugins of oh-my-bash ([read more](https://github.com/ohmybash/oh-my-bash#custom-plugins-and-themes)):

```
git clone "https://github.com/Intersec/pipenv-activate.git" "$OSH_CUSTOM/plugins/pyvenv-activate"
```

Then add `pyvenv-activate` to the list of plugins in your ``.bashrc``. Make sure it is **before** the line `source $OSH/oh-my-bash.sh`:
```bash
plugins=(... pyvenv-activate)
```

To enable the automatic activation, add this line **after** the line `source $ZSH/oh-my-bash.sh`:
```bash
pyvenv_auto_activate_enable # Optional, enable auto activate, see below
```

### Manual installation

`pyvenvactivate.sh` can be sourced directly without any dependency.
First, clone the repository:
```
mkdir -p "$HOME/.sh-plugins"
git clone "https://github.com/Intersec/pipenv-activate.git" "$HOME/.sh-plugins/pyvenv-activate"
```

Next, you need to source `pyvenv-activate.sh` in the interactive
configuration file for your shell (`.bashrc` for bash, `.zshrc` for zsh, ...):
```
. $HOME/.sh-plugins/pyvenv-activate/pyvenv-activate.sh
pyvenv_auto_activate_enable # Optional, enable auto activate, see below
```

## Usage

### Manually

The virtual environment of a Python environment project can be activated in
the current shell manually with the function `pyvenv_activate`.
This works the same way as running `pipenv shell`, but no sub-shells are
created.

To deactivate the virtual environment, you will need to run
`pyvenv_deactivate`.

Example:
```console
pauss@home: envs$ . ~/dev/pyvenv-activate/pyvenv-activate.sh
pauss@home: envs$ python --version
Python 2.7.18rc1
pauss@home: envs$ which python
/usr/bin/python
pauss@home: envs$ cd A
pauss@home: envs/A$ python --version
Python 2.7.18rc1
pauss@home: envs/A$ which python
/usr/bin/python
pauss@home: envs/A$ pyvenv_activate
(A) pauss@home: envs/A$ python --version
Python 3.8.2
(A) pauss@home: envs/A$ which python
/home/pauss/.local/share/virtualenvs/A-1baQ-YWx/bin/python
(A) pauss@home: envs/A$ python -c 'import six; print(six.__version__)'
1.15.0
(A) pauss@home: envs/A$ cd ..
(A) pauss@home: envs$ python --version
Python 3.8.2
(A) pauss@home: envs$ which python
/home/pauss/.local/share/virtualenvs/A-1baQ-YWx/bin/python
(A) pauss@home: envs$ pyvenv_deactivate
pauss@home: envs$ python --version
Python 2.7.18rc1
pauss@home: envs$ which python
/usr/bin/python
pauss@home: envs$ cd B
pauss@home: envs/B$ pyvenv_activate
(B) pauss@home: envs/B$ python --version
Python 3.8.2
(B) pauss@home: envs/B$ which python
/home/pauss/.local/share/virtualenvs/B-XFzaNdvP/bin/python
(B) pauss@home: envs/B$ python -c 'import six; print(six.__version__)'
Traceback (most recent call last):
  File "<string>", line 1, in <module>
ModuleNotFoundError: No module named 'six'
(B) pauss@home:(1) envs/B$ cd ../C
(B) pauss@home: envs/C$ pyvenv_deactivate
pauss@home: envs/C$ echo $VAR_A

pauss@home: envs/C$ pyvenv_activate
(C) pauss@home: envs/C$ echo $VAR_A
foo
(C) pauss@home: envs/C$ pyvenv_deactivate
pauss@home: envs/C$ echo $VAR_A

pauss@home: envs/C$
```

### Automatically

`pyvenv-activate` can also be used to automatically activate and deactivate
the virtual environment when entering or exiting a Python virtual environment
project.

In order to enable it, you will need call the function
`pyvenv_auto_activate_enable` in the interactive configuration file of your
shell (`.bashrc` for bash, `.zshrc` for zsh, ...).

It is possible to disable this mechanism by calling
`pyvenv_auto_activate_disable`.

Example:
```console
pauss@home: envs$ . ~/dev/pyvenv-activate/pyvenv-activate.sh
pauss@home: envs$ pyvenv_auto_activate_enable
pauss@home: envs$ python --version
Python 2.7.18rc1
pauss@home: envs$ which python
/usr/bin/python
pauss@home: envs$ cd A
(A) pauss@home: envs/A$ python --version
Python 3.8.2
(A) pauss@home: envs/A$ which python
/home/pauss/.local/share/virtualenvs/A-1baQ-YWx/bin/python
(A) pauss@home: envs/A$ python -c 'import six; print(six.__version__)'
1.15.0
(A) pauss@home: envs/A$ cd ..
pauss@home: envs$ python --version
Python 2.7.18rc1
pauss@home: envs$ which python
/usr/bin/python
pauss@home: envs$ cd B
(B) pauss@home: envs/B$ python --version
Python 3.8.2
(B) pauss@home: envs/B$ which python
/home/pauss/.local/share/virtualenvs/B-XFzaNdvP/bin/python
(B) pauss@home: envs/B$ python -c 'import six; print(six.__version__)'
Traceback (most recent call last):
  File "<string>", line 1, in <module>
ModuleNotFoundError: No module named 'six'
(B) pauss@home:(1) envs/B$ cd ..
pauss@home: envs$ echo $VAR_A

pauss@home: envs$ cd C
(C) pauss@home: envs/C$ echo $VAR_A
foo
(C) pauss@home: envs/C$ cd ..
pauss@home: envs$ echo $VAR_A

pauss@home: envs$
```

#### Mode

For Bash and Zsh, by default, we check if we have entered or exited a Python
virtual environment project on each prompt.

This is useful because it covers the case when we are changing the current
directory, and when we are creating a new Python virtual environment project.

Checking if we are in a Python virtual environment project is pretty fast, so
it is normally not an issue to do it every prompt.

For other POSIX shells, unfortunately, we don't have a hook that can be run
every prompt.
So, in order to still have access to the automatic activation, we redefine the
command `cd` to check the Python virtual environment project when changing the
current directory.

If you don't want to check the Python virtual environment project on every
prompt for Bash and Zsh, and only do the check when changing the current
directory, `pyvenv_auto_activate_enable` actually takes an optional argument
which is the mode to use.

It can take three different values:
* `prompt`: Check the Python virtual environment project on every prompt. This
            is the default for Bash and Zsh. It is not available for other
            POSIX shells.
* `chpwd`: Check the Python virtual environment project when changing the
           current directory.
           This is the default for POSIX shells other than Bash and Zsh.
* `default`: Use the best mode for the current shell.

Example:
```shell
pyvenv_auto_activate_enable chpwd
```

## Setup venv path file

It is possible to use `pyvenv-activate` with projects that use
[venv](https://docs.python.org/3/tutorial/venv.html) or
[virtualenv](https://virtualenv.pypa.io/en/latest/).

In order to work, `pyvenv-activate` needs to know where to find the virtual
environment directory.

This is done by creating a special file `.pyvenv_venv_path` in the project
directory using the function `pyvenv_setup_venv_file_path`.

`pyvenv_setup_venv_file_path` takes two optional arguments:
* `venv_path`: The path to the virtual env to register.
               If not set, `$VIRTUAL_ENV` is used.
* `proj_path`: The path to the project where to store the virtual environment
               path file.
               If not set, use the current directory.


Example:
```console
pauss@home: envs/B$ virtualenv .venv
created virtual environment CPython3.8.2.final.0-64 in 165ms
  creator CPython3Posix(dest=/tmp/test_pyvenv_path/B/.env, clear=False, no_vcs_ignore=False, global=False)
  seeder FromAppData(download=False, pip=bundle, setuptools=bundle, wheel=bundle, via=copy, app_data_dir=/home/pauss/.local/share/virtualenv)
    added seed packages: pip==21.0.1, setuptools==57.0.0, wheel==0.36.2
  activators BashActivator,CShellActivator,FishActivator,PowerShellActivator,PythonActivator,XonshActivator
pauss@home: envs/B$ pyvenv_setup_venv_file_path .venv
pauss@home: envs/B$ ls -a
.  ..  .pyvenv_venv_path  .venv
pauss@home: envs/B$ pyvenv_activate
(.venv) pauss@home: envs/B$ which python
/home/pauss/envs/B/.venv/bin/python

```


## Pipenv activate

The first version of `pyvenv-activate` only supported `pipenv` and was called
`pipenv-activate`.

In order to keep the backward compatibility, the public function are kept, and
some symlinks are done to the new files.

## Tests

We are using the unit test framework
[shUnit2](https://github.com/kward/shunit2).

First, you will need to initialize, and potentially update, the git
submodules:
```sh
git submodule update --init --recursive
```

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
