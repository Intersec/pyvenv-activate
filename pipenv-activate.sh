#!/bin/sh
#
# pipenv-activate.sh is a script containing a set of functions to activate
# and deactivate a Pipenv environment directly within the current shell.


# {{{ Pipenv activate

# Use `echo -e` instead of `echo` when available to interpret backslash
# characters.
_PIPENV_ACTIVATE_ECHO_ESC="echo -e"
# shellcheck disable=SC2039
if [ "$(echo -e 'test')" = '-e test' ]; then
    _PIPENV_ACTIVATE_ECHO_ESC="echo"
fi

# Python code to load the dotenv file using the dotenv module.
#
# This script will load the variables from the dotenv file skipping the
# variables already set in the environment the same way as Pipenv.
#
# The variables are output in the format `$key\t$value` with $value having its
# non-ascii and whitespace characters escaped. This way, we are sure $value
# does not contain an unescaped `\t` (\x09) character.
#
_PIPENV_ACTIVATE_PYTHON_DOTENV_VARS_GETTER=$(cat <<EOF
from sys import argv as sys_argv
from os import environ as os_environ
from json import dumps as json_dumps

try:
    # Importing dotenv from pipenv is slow.
    # Try first with the regular dotenv package.
    from dotenv import dotenv_values
except ImportError:
    from pipenv.vendor.dotenv import dotenv_values

dotenv_file = sys_argv[1]
values = dotenv_values(dotenv_file)
for k, v in values.items():
    if k not in os_environ:
        v = json_dumps(v)[1:-1]
        print('{}\t{}'.format(k, v))
EOF
)

# Get the Python interpreter used by Pipenv from its shebang.
#
# This is the python interpreter used by Pipenv, not the interpreter used in
# in the virtual envionment.
#
# Outputs:
#   The path to Python interperter used by Pipenv.
_pipenv_activate_get_pipenv_python() {
    head -n 1 "$(command -v pipenv)" | sed 's/#!//'
}

# Get dotenv variables by loading dotenv file with Python dotenv module.
#
# Run _PIPENV_ACTIVATE_PYTHON_DOTENV_LOADER with Pipenv python interpreter.
#
# Args:
#   dotenv_file: string: the path to the dotenv file.
# Outputs:
#   The dotenv variables.
_pipenv_activate_get_dotenv_variables() {
    $(_pipenv_activate_get_pipenv_python) \
        -c "$_PIPENV_ACTIVATE_PYTHON_DOTENV_VARS_GETTER" "$1"
}

# Load variables from dotenv file the same way as Pipenv.
#
# Args:
#   proj_dir: string: The path to the Pipenv project.
# Returns:
#   0 on success, 1 on error.
_pipenv_activate_load_dotenv() {
    if [ -n "$PIPENV_DONT_LOAD_ENV" ]; then
        # Do nothing if PIPENV_DONT_LOAD_ENV is set.
        return
    fi

    if [ -n "$PIPENV_DOTENV_LOCATION" ]; then
        pa_dotenv_file_="$PIPENV_DOTENV_LOCATION"
    else
        pa_dotenv_file_="$1/.env"
    fi

    if ! [ -r "$pa_dotenv_file_" ]; then
        # Do nothing if file is not available.
        unset pa_dotenv_file_
        return
    fi

    # Will contains the list of variables set by the dotenv file.
    pa_dotenv_vars_=""

    # Read variables line by lines.
    # Since the values are escaped, we are sure that each line corresponds to
    # one and only one variable.
    while IFS= read -r pa_dotenv_line_; do
        if [ -z "$pa_dotenv_line_" ]; then
            # Line is empty, this can happen if the dotenv is empty.
            continue
        fi

        # Split up the key and the value with `\t` as separator.
        IFS="	" read -r pa_do_env_key_ pa_dotenv_value_ <<EOF
$pa_dotenv_line_
EOF

        # Add the key to the list of variables.
        pa_dotenv_vars_="${pa_dotenv_vars_} ${pa_do_env_key_}"

        # Unescape the value with `echo -e`.
        pa_dotenv_value_="$($_PIPENV_ACTIVATE_ECHO_ESC "$pa_dotenv_value_")"

        # Export the value in the current environment.
        export "$pa_do_env_key_=$pa_dotenv_value_"

    done <<EOF
$(_pipenv_activate_get_dotenv_variables "$pa_dotenv_file_")
EOF

    # Export the list of variables.
    export _PIPENV_ACTIVATE_DOTENV_VARS="$pa_dotenv_vars_"

    unset pa_dotenv_file_ pa_dotenv_vars_ pa_dotenv_line_ pa_dotenv_key_ \
        pa_dotenv_value_
}

# Activate pipenv environment in the current shell.
#
# Unlike `pipenv shell`, this function will not create a sub-shell, but will
# activate the pipenv virtual environment directly the current shell.
#
# Args:
#   [proj_dir]: string: The path to the Pipenv project.
#                       Default is to use the current directory.
#   [venv_dir]: string: The path to the virtual environment directory to
#                       activate.
#                       Default is to use `pipenv --venv` in the project
#                       directory.
# Returns:
#   0 on success, 1 on error.
pipenv_activate() {
    pa_proj_dir_="$1"
    pa_venv_dir_="$2"

    if [ -z "$pa_proj_dir_" ]; then
        pa_proj_dir_="$(pwd -P)"
    fi

    if [ -z "$pa_venv_dir_" ]; then
        pa_venv_dir_="$(pipenv --venv)" || return 1
    fi

    if ! [ -f "$pa_venv_dir_/bin/activate" ]; then
        echo "$pa_venv_dir_ is not a valid virtual environment" >&2
        unset pa_venv_dir_
        return 1
    fi

    if [ -n "$VIRTUAL_ENV" ] && [ "$VIRTUAL_ENV" != "$pa_venv_dir_" ]; then
        echo "another virtual environment is already active" >&2
        unset pa_venv_dir_
        return 1
    fi

    _pipenv_activate_load_dotenv "$pa_proj_dir_"

    export PIPENV_ACTIVE=1

    # shellcheck disable=SC1090
    . "$pa_venv_dir_/bin/activate"

    unset pa_proj_dir_ pa_venv_dir_
    return 0
}

# }}}
# {{{ Pipenv deactivate

# Unset the variables set by the dotenv file.
_pipenv_deactivate_unload_dotenv() {
    if [ -n "$_PIPENV_ACTIVATE_DOTENV_VARS" ]; then
        #shellcheck disable=SC2046
        unset $(echo "$_PIPENV_ACTIVATE_DOTENV_VARS" | xargs)
    fi
}

# Deactivate pipenv environment in the current shell.
#
# Returns:
#   0 on success, 1 on error.
pipenv_deactivate() {
    if [ -n "$VIRTUAL_ENV" ]; then
        deactivate nondestructive || return 1
        unset -f deactivate
    fi
    unset PIPENV_ACTIVE
    _pipenv_deactivate_unload_dotenv
    return 0
}

# }}}
