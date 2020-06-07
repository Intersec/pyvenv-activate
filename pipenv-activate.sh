#!/bin/sh
#
# pipenv-activate.sh is a script containing a set of functions to activate
# and deactivate a Pipenv environment directly within the current shell.


# {{{ Pipenv activate

# Activate pipenv environment in the current shell.
#
# Unlike `pipenv shell`, this function will not create a sub-shell, but will
# activate the pipenv virtual environment directly the current shell.
#
# Args:
#   [venv_path]: string: the path of the virtual environment to activate.
# Returns:
#   0 on success, 1 on error.
pipenv_activate() {
    pa_venv_path_="${1:-$(pipenv --venv)}" || return 1

    if ! command [ -f "$pa_venv_path_/bin/activate" ]; then
        echo "$pa_venv_path_ is not a valid virtual environment" >&2
        unset pa_venv_path_
        return 1
    fi

    if command [ -n "$VIRTUAL_ENV" ] && \
       command [ "$VIRTUAL_ENV" != "$pa_venv_path_" ]
    then
        echo "another virtual environment is already active" >&2
        unset pa_venv_path_
        return 1
    fi

    export PIPENV_ACTIVE=1

    # shellcheck disable=SC1090
    . "$pa_venv_path_/bin/activate"

    unset pa_venv_path_
    return 0
}

# }}}
# {{{ Pipenv deactivate

# Deactivate pipenv environment in the current shell.
#
# Returns:
#   0 on success, 1 on error.
pipenv_deactivate() {
    if command [ -n "$VIRTUAL_ENV" ]; then
        deactivate nondestructive || return 1
        unset -f deactivate
    fi
    unset PIPENV_ACTIVE
    return 0
}

# }}}
