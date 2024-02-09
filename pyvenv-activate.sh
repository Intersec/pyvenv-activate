#!/bin/sh
#
# pyvenv-activate.sh is a script containing a set of functions to activate
# and deactivate a python virtual environment directly within the current
# shell.

# shellcheck disable=SC2034
PYVENV_ACTIVATE_VERSION=2.0
PYVENV_ACTIVATE_VENV_PATH_FILE_NAME=.pyvenv_venv_path

# {{{ Helpers

# Safe version of echo by using printf.
#
# See
# https://oliviercontant.com/why-is-printf-better-than-echo-in-shell-scripting/
# why echo is not safe with uncontrolled data.
_pyvenv_activate_safe_echo() {
    (
        IFS=" "
        printf '%s\n' "$*"
    )
}

# Call builtin cd command even if cd has been redefined.
#
# Some shells use `builtin` for calling the original cd command, others
# use `command`.
#
# shellcheck disable=SC2039
if (builtin printf "123" >/dev/null 2>&1); then
    _pyvenv_activate_builtin_cd() {
        # shellcheck disable=SC2039,SC2164
        builtin cd "$@"
    }
else
    _pyvenv_activate_builtin_cd() {
        # shellcheck disable=SC2164
        command cd "$@"
    }
fi

# Get normalized absolute path of given directory.
_pyvenv_activate_get_dir_abs_path() {
    (
        _pyvenv_activate_builtin_cd -P -- "$1" && pwd -P
    )
}

# }}}
# {{{ Pyvenv activate

# Try to find pipenv module for the given python executable.
#
# Args:
#   python_exec: string: the path to the python executable to use.
#
# Returns:
#   0 on if found, 1 if not found.
_pyvenv_activate_find_pipenv_module() {
    "$1" - <<EOF
import pkgutil
import sys

sys.exit(0 if pkgutil.find_loader('pipenv') else 1)
EOF
}

# Get the current Python interpreter of Pipenv.
#
# Find the first python executable that have the pipenv module.
# We privilege python3 over python2.
#
# Outputs:
#   The path to Python executable.
_pyvenv_activate_get_pipenv_python_exec() {
    # Iterate through python3, python2 and python in tht order to find a valid
    # python executable.
    for pa_python_ver in python3 python2 python; do

        # Iterate through each directories of $PATH.
        while IFS= read -r pa_path; do
            if [ -z "$pa_path" ]; then
                # Skip empty line.
                continue
            fi

            pa_python_exec="$pa_path/$pa_python_ver"

            if [ -r "$pa_python_exec" ] && [ -x "$pa_python_exec" ] \
            && _pyvenv_activate_find_pipenv_module "$pa_python_exec"; then
                # pipenv module has been found for the given python
                # executable, return now.
                _pyvenv_activate_safe_echo "$pa_python_exec"
                break 2
            fi

        done <<EOF
$(printf '%s\n' "$PATH" | tr ':' '\n')
EOF

    done

    unset pa_python_ver pa_path pa_python_exec
}

# Get dotenv variables by loading dotenv file with Python dotenv module.
#
# Run python code to load the dotenv file using the dotenv module with Pipenv
# python interpreter.
#
# The script will load the variables from the dotenv file overwriting the
# variables already set in the environment the same way as Pipenv.
#
# The variables are output in the format `$key base64($value)`. Since the
# value is encoded in base64, we are sure there are no special characters that
# can cause issues when parsing it back with the shell.
#
# Args:
#   python_exec: string: the path to the python executable to use.
#   dotenv_file: string: the path to the dotenv file.
# Outputs:
#   The dotenv variables.
_pyvenv_activate_get_dotenv_variables() {
    "$1" - "$2" <<EOF
from sys import argv as sys_argv
from base64 import b64encode

try:
    # Importing dotenv from pipenv is slow.
    # Try first with the regular dotenv package.
    from dotenv import dotenv_values
except ImportError:
    from pipenv.vendor.dotenv import dotenv_values

dotenv_file = sys_argv[1]
values = dotenv_values(dotenv_file)
for k, v in values.items():
    if not isinstance(v, bytes):
        v = v.encode('utf-8')
    v = b64encode(v).decode('utf-8')
    print("{} {}".format(k, v))
EOF
}

# Encode dotenv value in base64 using python.
#
# `base64` command is not POSIX, it is part of GNU coreutils.
# So, the most portable way to do it here is to use python as we are sure that
# its is available for Pipenv.
#
# Args:
#   python_exec: string: the path to the python executable to use.
#   value: string: the value to encode.
# Outputs:
#   The encoded value in base64.
_pyvenv_activate_pipenv_dotenv_encode_value() {
    "$1" - "$2" <<EOF
from sys import argv as sys_argv
from base64 import b64encode

v = sys_argv[1]
if not isinstance(v, bytes):
    v = v.encode('utf-8')
print(b64encode(v).decode('utf-8'))
EOF
}

# Decode dotenv value as base64 using python.
#
# `base64` command is not POSIX, it is part of GNU coreutils.
# So, the most portable way to do it here is to use python as we are sure that
# its is available for Pipenv.
#
# Args:
#   python_exec: string: the path to the python executable to use.
#   value: string: the base64 value to decode.
# Outputs:
#   The decoded value.
_pyvenv_activate_pipenv_dotenv_decode_value() {
    "$1" - "$2" <<EOF
from sys import argv as sys_argv
from base64 import b64decode

v = sys_argv[1]
if not isinstance(v, bytes):
    v = v.encode('utf-8')
print(b64decode(v).decode('utf-8'))
EOF
}

# Load variables from dotenv file the same way as Pipenv.
#
# Args:
#   proj_dir: string: The path to the Pipenv project.
# Returns:
#   0 on success, 1 on error.
_pyvenv_activate_pipenv_load_dotenv() {
    if [ -n "$PIPENV_DONT_LOAD_ENV" ]; then
        # Do nothing if PIPENV_DONT_LOAD_ENV is set.
        return 0
    fi

    if [ -n "$PIPENV_DOTENV_LOCATION" ]; then
        pa_dotenv_file_="$PIPENV_DOTENV_LOCATION"
    else
        pa_dotenv_file_="$1/.env"
    fi

    if ! [ -r "$pa_dotenv_file_" ]; then
        # Do nothing if file is not available.
        unset pa_dotenv_file_
        return 0
    fi

    # Get the python executable
    pa_python_exec_="$(_pyvenv_activate_get_pipenv_python_exec)"
    if [ -z "$pa_python_exec_" ]; then
        _pyvenv_activate_safe_echo "unable to find python executable" >&2
        return 1
    fi

    # Will contains the list of variables set by the dotenv file.
    pa_dotenv_vars_=""

    # Will contains the list of existing environment variables
    pa_dotenv_existing_vals_=""

    # Read variables line by lines.
    # Since the values are encoded, we are sure that each line corresponds to
    # one and only one variable.
    while IFS= read -r pa_dotenv_line_; do
        if [ -z "$pa_dotenv_line_" ]; then
            # Line is empty, this can happen if the dotenv is empty.
            continue
        fi

        # Split up the key and the value.
        IFS=" " read -r pa_dotenv_key_ pa_dotenv_value_ <<EOF
$pa_dotenv_line_
EOF

        # Key already exists in shell environment.
        # We will need to store it in order to restore it on unload.
        if eval "[ -n \"\${$pa_dotenv_key_+x}\" ]"; then
            # Get the existing value and encode it.
            pa_existing_val_="$(eval "printf '%s' \"\$$pa_dotenv_key_\"")"
            pa_existing_val_="$(_pyvenv_activate_pipenv_dotenv_encode_value \
                "$pa_python_exec_" "$pa_existing_val_")" || return 1

            # Get type of exising variable, if it is exported or not.
            # shellcheck disable=SC2039
            if export -p | grep -q "$pa_dotenv_key_="; then
                pa_existing_kind_='e'
            else
                pa_existing_kind_='v'
            fi

            # Create the line to be inserted in the variable.
            pa_existing_line_="$(printf '%s %s %s' "$pa_existing_kind_" \
                "$pa_dotenv_key_" "$pa_existing_val_")"

            if [ -z "$pa_dotenv_existing_vals_" ]; then
                pa_dotenv_existing_vals_="$pa_existing_line_"
            else
                pa_dotenv_existing_vals_="$pa_dotenv_existing_vals_
$pa_existing_line_"
            fi

            unset pa_existing_val_ pa_existing_kind_ pa_existing_line_
        fi

        # Add the key to the list of variables.
        if [ -z "$pa_dotenv_vars_" ]; then
            pa_dotenv_vars_="${pa_dotenv_key_}"
        else
            pa_dotenv_vars_="${pa_dotenv_vars_}
${pa_dotenv_key_}"
        fi

        # Decode the value.
        pa_dotenv_value_="$(_pyvenv_activate_pipenv_dotenv_decode_value \
            "$pa_python_exec_" "$pa_dotenv_value_")" || return 1

        # Export the value in the current environment.
        export "$pa_dotenv_key_=$pa_dotenv_value_" || return 1
    done <<EOF
$(_pyvenv_activate_get_dotenv_variables "$pa_python_exec_" "$pa_dotenv_file_")
EOF

    # Set the list of variables to global variable.
    _PYVENV_ACTIVATE_PIPENV_DOTENV_VARS="$pa_dotenv_vars_"

    # Set the list of existing values to global variable.
    _PYVENV_ACTIVATE_PIPENV_DOTENV_EXISTING_VALS="$pa_dotenv_existing_vals_"

    unset pa_dotenv_file_ pa_python_exec_ pa_dotenv_vars_ pa_dotenv_line_ \
        pa_dotenv_key_ pa_dotenv_value_ pa_current_val_ \
        pa_dotenv_existing_vals_
}

# Find project directory containing a Python virtual environment file.
#
# For Pipenv, it respects the PIPENV_MAX_DEPTH, PIPENV_NO_INHERIT and
# PIPENV_PIPFILE environment variables.
#
# Outputs:
#   "$proj_type:$proj_dir" with:
#       - proj_type: the project type, either "pipenv" or "poetry".
#       - proj_dir:  the project root directory.
_pyvenv_activate_find_proj() {
    if [ -n "$PIPENV_PIPFILE" ] && [ -r "$PIPENV_PIPFILE" ]; then
        # If PIPENV_PIPFILE is set and the file is present, use it instead.
        _pyvenv_activate_safe_echo "pipenv:$PIPENV_PIPFILE"
        return 0
    fi

    pa_current_dir_="$PWD"

    if [ -n "$PIPENV_NO_INHERIT" ]; then
        # PIPENV_NO_INHERIT is set.
        pa_pipenv_max_depth_=1
    elif [ -z "$PIPENV_MAX_DEPTH" ]; then
        # Default PIPENV_MAX_DEPTH is 3 according to Pipenv documentation.
        pa_pipenv_max_depth_=3
    elif ! [ "$PIPENV_MAX_DEPTH" -ge 1 ] 2>/dev/null; then
        # PIPENV_MAX_DEPTH is not an integer or less than 1.
        pa_pipenv_max_depth_=1
    else
        # PIPENV_MAX_DEPTH is an integer greater or equal to 1.
        pa_pipenv_max_depth_="$PIPENV_MAX_DEPTH"
    fi

    pa_i_=0

    while true; do
        pa_proj_file_="$pa_current_dir_/Pipfile.lock"
        if [ "$pa_i_" -lt "$pa_pipenv_max_depth_" ] \
        && [ -r "$pa_proj_file_" ]; then
            # Pipfile has been found according to the max depth.
            _pyvenv_activate_safe_echo "pipenv:$pa_proj_file_"
            break
        fi

        pa_proj_file_="$pa_current_dir_/poetry.lock"
        if [ -r "$pa_current_dir_/poetry.lock" ]; then
            # Poetry has been found.
            _pyvenv_activate_safe_echo "poetry:$pa_proj_file_"
            break
        fi

        pa_proj_file_="$pa_current_dir_/$PYVENV_ACTIVATE_VENV_PATH_FILE_NAME"
        if [ -r "$pa_proj_file_" ]; then
            # Venv path file has been found.
            _pyvenv_activate_safe_echo "venv:$pa_proj_file_"
            break
        fi

        if [ -z "$pa_current_dir_" ] || [ "$pa_current_dir_" = "/" ]; then
            # We reached the root directory.
            break
        fi

        pa_i_=$((pa_i_ + 1))

        # Use command substitution to get the dirname.
        pa_current_dir_="${pa_current_dir_%/*}"
    done

    unset pa_current_dir_ pa_pipenv_max_depth_ pa_i_ pa_proj_file_
}

# Get python virtual environment directory of the project.
#
# Args:
#   proj_file: string: The path to the project file.
#   proj_type: string: The type of the project to activate, "pipenv",
#                      "poetry" or "venv".
# Outputs:
#   The virtual environment directory.
#
# Returns:
#   0 on success, 1 on error.
_pyvenv_activate_get_venv_dir() {
    pa_proj_file_="$1"
    pa_proj_type_="$2"

    case "$pa_proj_type_" in
        pipenv)
            if ! pipenv --venv; then
                unset pa_proj_file_ pa_proj_type_
                return 1
            fi
            ;;

        poetry)
            if ! (unset VIRTUAL_ENV; poetry env info -p); then
                unset pa_proj_file_ pa_proj_type_
                return 1
            fi
            ;;

        venv)
            # stat(1) is not in POSIX, the most portable way to get the rights
            # and owner of a file is to use ls and awk.
            # shellcheck disable=SC2012
            pa_proj_file_infos_="$(ls -ld "$pa_proj_file_" | \
                awk '{print $1,$3;}')"

            if [ "${pa_proj_file_infos_#* }" != "$(id -nu)" ]; then
                _pyvenv_activate_safe_echo \
                    "'$pa_proj_file_' is not owned by the current user" >&2
                unset pa_proj_file_ pa_proj_type_ pa_proj_file_infos_
                return 1
            fi

            if [ "${pa_proj_file_infos_% *}" != '-r--------' ]; then
                _pyvenv_activate_safe_echo \
                    "'$pa_proj_file_' has weak permission, expected read-only by owner (400)" >&2
                unset pa_proj_file_ pa_proj_type_ pa_proj_file_infos_
                return 1
            fi

            unset pa_proj_file_infos_

            if ! IFS= read -r pa_venv_dir_ < "$pa_proj_file_"; then
                _pyvenv_activate_safe_echo "unable to read '$pa_proj_file_'" >&2
                unset pa_proj_file_ pa_proj_type_
                return 1
            fi

            if [ "$pa_venv_dir_" = "${pa_venv_dir_#/}" ]; then
                _pyvenv_activate_safe_echo "'$pa_venv_dir_' is not an absolute path" >&2
                unset pa_proj_file_ pa_proj_type_ pa_venv_dir_
                return 1
            fi

            _pyvenv_activate_safe_echo "$pa_venv_dir_"
            unset pa_venv_dir_
            ;;

        *)
            _pyvenv_activate_safe_echo \
                "invalid python virtual environment project type $pa_proj_type_" >&2
            unset pa_proj_file_ pa_proj_type_
            return 1
            ;;
    esac

    unset pa_proj_file_ pa_proj_type_
    return 0
}


# Activate python virtual environment project in the current shell.
#
# Unlike `pipenv shell` or `poetry shell`, this function will not create a
# sub-shell, but will activate the python virtual environment directly the
# current shell.
#
# Args:
#   [proj_file]: string: The path to the python virtual environment project
#                        file.
#                        Default is to look for the file in the current
#                        directory.
#   [proj_type]: string: The type of the project to activate, "pipenv",
#                        "poetry" or "venv".
#                        If not set, it will be automatically detected.
#   [venv_dir]:  string: The path to the virtual environment directory to
#                        activate.
#                        Default is to use `pipenv --venv` or
#                        `poetry env info -p` in the project directory.
# Returns:
#   0 on success, 1 on error.
_pyvenv_activate_proj() {
    pa_proj_file_="$1"
    pa_proj_type_="$2"
    pa_venv_dir_="$3"

    if [ -z "$pa_proj_file_" ]; then
        pa_proj_="$(_pyvenv_activate_find_proj)"
        pa_proj_file_="${pa_proj_#*:}"
        pa_proj_type_="${pa_proj_%%:*}"
        unset pa_proj_

        if [ -z "$pa_proj_file_" ]; then
            _pyvenv_activate_safe_echo "unable to find a valid python virtual environment in $PWD" >&2
            unset pa_proj_file_ pa_proj_type_ pa_venv_dir_
            return 1
        fi
    fi

    if [ -z "$pa_proj_type_" ]; then
        pa_base_proj_file_name_="${pa_proj_file_##*/}"
        if [ "$pa_base_proj_file_name_" = "Pipfile.lock" ]; then
            pa_proj_type_="pipenv"
        elif [ "$pa_base_proj_file_name_" = "poetry.lock" ]; then
            pa_proj_type_="poetry"
        elif [ "$pa_base_proj_file_name_" = "$PYVENV_ACTIVATE_VENV_PATH_FILE_NAME" ]; then
            pa_proj_type_="venv"
        else
            _pyvenv_activate_safe_echo "unable to find python virtual environment project type for $pa_proj_file_" >&2
            unset pa_proj_file_ pa_proj_type_ pa_venv_dir_ pa_base_proj_file_name_
            return 1
        fi
        unset pa_base_proj_file_name_
    fi

    if [ -z "$pa_venv_dir_" ]; then
        if ! pa_venv_dir_="$(_pyvenv_activate_get_venv_dir \
            "$pa_proj_file_" "$pa_proj_type_")"; then
            unset pa_proj_file_ pa_proj_type_ pa_venv_dir_
            return 1
        fi
    fi

    if ! [ -f "$pa_venv_dir_/bin/activate" ]; then
        _pyvenv_activate_safe_echo "$pa_venv_dir_ is not a valid virtual environment" >&2
        unset pa_proj_file_ pa_proj_type_ pa_venv_dir_
        return 1
    fi

    if [ -n "$VIRTUAL_ENV" ] && [ "$VIRTUAL_ENV" != "$pa_venv_dir_" ]; then
        _pyvenv_activate_safe_echo "another virtual environment is already active" >&2
        unset pa_proj_file_ pa_proj_type_ pa_venv_dir_
        return 1
    fi

    if [ "$pa_proj_type_" = "pipenv" ]; then
        _pyvenv_activate_pipenv_load_dotenv "${pa_proj_file_%/*}" || return 1
        export PIPENV_ACTIVE=1
    elif [ "$pa_proj_type_" = "poetry" ]; then
        export POETRY_ACTIVE=1
    fi

    # shellcheck disable=SC1090,SC1091
    . "$pa_venv_dir_/bin/activate" || return 1

    unset pa_proj_file_ pa_proj_type_ pa_venv_dir_
    return 0
}

# Activate python virtual environment in the current shell.
#
# Unlike `pipenv shell` or `poetry shell`, this function will not create a
# sub-shell, but will activate the python virtual environment directly the
# current shell.
#
# Returns:
#   0 on success, 1 on error.
pyvenv_activate() {
    _pyvenv_activate_proj
}

# }}}
# {{{ Pyvenv deactivate

# Unload the dotenv file previous loaded by pyvenv_activate.
#
# Returns:
#   0 on success, 1 on error.
_pyvenv_deactivate_pipenv_unload_dotenv() {
    # Unset the variables set by the dotenv file.
    if [ -n "$_PYVENV_ACTIVATE_PIPENV_DOTENV_VARS" ]; then
        while IFS= read -r pa_var_; do
            unset "$pa_var_"
        done <<EOF
$_PYVENV_ACTIVATE_PIPENV_DOTENV_VARS
EOF
        unset pa_var_ _PYVENV_ACTIVATE_PIPENV_DOTENV_VARS
    fi

    # Restore the existing variables.
    if [ -n "$_PYVENV_ACTIVATE_PIPENV_DOTENV_EXISTING_VALS" ]; then
        pa_python_exec_="$(_pyvenv_activate_get_pipenv_python_exec)"
        if [ -z "$pa_python_exec_" ]; then
            _pyvenv_activate_safe_echo "unable to find python executable" >&2
            return 1
        fi

        # Read $_PYVENV_ACTIVATE_PIPENV_DOTENV_EXISTING_VALS line by line.
        while IFS= read -r pa_existing_line_; do
            # Split line by  '.
            IFS=" " read -r pa_existing_kind_ pa_existing_key_ pa_existing_val_ <<EOF
$pa_existing_line_
EOF

            # Decode the value.
            pa_existing_val_="$(_pyvenv_activate_pipenv_dotenv_decode_value \
                "$pa_python_exec_" "$pa_existing_val_")" || return 1

            # Export the variable or set it as a simple shell variable
            # depending of the kind.
            if [ "$pa_existing_kind_" = 'e' ]; then
                export "$pa_existing_key_=$pa_existing_val_"
            else
                eval "$pa_existing_key_=\"\$pa_existing_val_\""
            fi
        done <<EOF
$_PYVENV_ACTIVATE_PIPENV_DOTENV_EXISTING_VALS
EOF

        unset pa_existing_line_ pa_existing_kind_ pa_existing_key_ \
            _PYVENV_ACTIVATE_PIPENV_DOTENV_EXISTING_VALS
    fi
}

# Deactivate python virtual environment in the current shell.
#
# Returns:
#   0 on success, 1 on error.
pyvenv_deactivate() {
    if [ -n "$VIRTUAL_ENV" ]; then
        deactivate nondestructive || return 1
        unset -f deactivate
    fi
    unset PIPENV_ACTIVE
    _pyvenv_deactivate_pipenv_unload_dotenv || return 1
    unset POETRY_ACTIVE
    return 0
}

# }}}
# {{{ Pyvenv auto activate
# {{{ Check project

# Function to be run on prompt or when the current directory is changed to
# auto activate or deactivate the Python virtual environment.
#
# Returns:
#   0 on success, 1 on error.
pyvenv_auto_activate_check_proj() {
    pa_proj_="$(_pyvenv_activate_find_proj)"
    pa_proj_file_="${pa_proj_#*:}"
    pa_proj_type_="${pa_proj_%%:*}"
    unset pa_proj_

    if [ -n "$_PYVENV_AUTO_ACTIVATE_PROJ_FILE" ] \
    && [ "$pa_proj_file_" != "$_PYVENV_AUTO_ACTIVATE_PROJ_FILE" ]; then
        # Deactivate the virtual environment if we have left the project
        # directory.
        pyvenv_deactivate >&2 || return 1
        unset _PYVENV_AUTO_ACTIVATE_PROJ_FILE
    fi

    if [ -n "$pa_proj_file_" ] && [ -n "$pa_proj_type_" ] \
    && [ "$pa_proj_file_" != "$_PYVENV_AUTO_ACTIVATE_PROJ_FILE" ] \
    && [ -z "$VIRTUAL_ENV" ]; then
        pa_venv_dir_="$(_pyvenv_activate_get_venv_dir \
            "$pa_proj_file_" "$pa_proj_type_" 2>/dev/null)"

        if [ -n "$pa_venv_dir_" ]; then
            # Activate the virtual environment if we have entered a new pipenv
            # directory and that no virtual environment has been activated
            # before.
            export _PYVENV_AUTO_ACTIVATE_PROJ_FILE="$pa_proj_file_"
            _pyvenv_activate_proj "$pa_proj_file_" "$pa_proj_type_" \
                                  "$pa_venv_dir_" >&2 || return 1
        fi
    fi
    unset pa_proj_file_ pa_proj_type_ pa_venv_dir_
}

# }}}
# {{{ Enable

# Enable auto activate Python virtual environment by redefining the cd
# command.
#
# This should work on any POSIX shell, but there are some drawbacks.
# We need to redefine the command cd with our own function, and we can only
# check the project directory when changing the current directory.
#
# Args:
#   mode: string: The auto activate mode to use.
#
# Returns:
#   0 on success, 1 on error.
_pyvenv_auto_activate_enable_redefine_cd() {
    if [ "$1" = "prompt" ]; then
        _pyvenv_activate_safe_echo "prompt mode is not supported when redefining cd" >&2
        return 1
    fi

    # shellcheck disable=SC2039
    if [ "$(type cd)" != "cd is a shell builtin" ]; then
        _pyvenv_activate_safe_echo "command cd is already redefined" >&2
        return 1
    fi

    cd() {
        # shellcheck disable=SC2317
        _pyvenv_activate_builtin_cd "$@" && pyvenv_auto_activate_check_proj
    }

    return 0
}

# Enable auto activate Python virtual environment on change directory.
_pyvenv_auto_activate_bash_chpwd_cmd() {
    if [ "$_PYVENV_AUTO_ACTIVATE_OLD_PWD" != "$PWD" ]; then
        pyvenv_auto_activate_check_proj
        _PYVENV_AUTO_ACTIVATE_OLD_PWD="$PWD"
    fi
}

# Enable auto activate Python virtual environment for Bash.
#
# Args:
#   mode: string: The auto activate mode to use.
#
# Returns:
#   0 on success, 1 on error.
_pyvenv_auto_activate_enable_bash() {
    if [ "$1" = "chpwd" ]; then
        pa_cmd_="_pyvenv_auto_activate_bash_chpwd_cmd"
    else
        pa_cmd_="pyvenv_auto_activate_check_proj"
    fi

    _pyvenv_auto_activate_disable_bash || return 1
    PROMPT_COMMAND="${pa_cmd_}${PROMPT_COMMAND:+;$PROMPT_COMMAND}"

    unset pa_cmd_
    return 0
}

# Enable auto activate Python virtual environment for Zsh.
#
# Args:
#   mode: string: The auto activate mode to use.
#
# Returns:
#   0 on success, 1 on error.
_pyvenv_auto_activate_enable_zsh() {
    if [ "$1" = "chpwd" ]; then
        pa_hook_="chpwd"
    else
        pa_hook_="precmd"
    fi

    autoload -Uz add-zsh-hook || return 1
    _pyvenv_auto_activate_disable_zsh || return 1
    add-zsh-hook "$pa_hook_" pyvenv_auto_activate_check_proj || return 1

    unset pa_hook_
    return 0
}

# Enable auto activate Python virtual environment.
#
# Args:
#   [mode]: string: The auto activate mode to use.
#                   It can be one of the following:
#                   - prompt: The Python virtual environment is checked and
#                   activated on prompt.
#                   Since pyvenv_auto_activate_check_proj() is a no-op most of
#                   the time and is fast enough in that case, this is the best
#                   option when available.
#                   This mode is only supported for Bash and Zsh.
#                   - chpwd: The Python virtual environment is checked and
#                   activated when changing directory.
#                   - default: The default mode, use prompt mode when
#                   available, chpwd otherwise.
#
# Returns:
#   0 on success, 1 on error.
pyvenv_auto_activate_enable() {
    pa_mode_="${1:-default}"

    case "$pa_mode_" in
        prompt|chpwd|default)
            ;;
        *)
            _pyvenv_activate_safe_echo "unknow mode $pa_mode_" >&2
            return 1
            ;;
    esac


    if [ -n "$BASH_VERSION" ]; then
        _pyvenv_auto_activate_enable_bash "$pa_mode_" || return 1
    elif [ -n "$ZSH_VERSION" ]; then
        _pyvenv_auto_activate_enable_zsh "$pa_mode_" || return 1
    else
        _pyvenv_auto_activate_enable_redefine_cd "$pa_mode_" || return 1
    fi

    _PYVENV_AUTO_ACTIVATE_ENABLED=1

    unset pa_mode_
    return 0
}

# }}}
# {{{ Disable

# Disable auto activate Python virtual environment when redefining the cd
# command.
#
# Returns:
#   0 on success, 1 on error.
_pyvenv_auto_activate_disable_redefine_cd() {
    # shellcheck disable=SC2039
    if [ "$(type cd)" = "cd is a shell builtin" ]; then
        # Nothing to do.
        return 0
    fi

    unset -f cd || return 1
    return 0
}

# Disable auto activate Python virtual environment on prompt for Bash.
#
# Returns:
#   0 on success, 1 on error.
_pyvenv_auto_activate_disable_bash() {
    PROMPT_COMMAND="$(_pyvenv_activate_safe_echo "$PROMPT_COMMAND" | \
        sed -E -e 's/pyvenv_auto_activate_check_proj;?//g' \
               -e 's/_pyvenv_auto_activate_bash_chpwd_cmd;?//g')"
}

# Disable auto activate Python virtual environment on prompt for Zsh
#
# Returns:
#   0 on success, 1 on error.
_pyvenv_auto_activate_disable_zsh() {
    autoload -Uz add-zsh-hook || return 1
    add-zsh-hook -D precmd pyvenv_auto_activate_check_proj || return 1
    add-zsh-hook -D chpwd pyvenv_auto_activate_check_proj || return 1
    return 0
}

# Disable auto activate Python virtual environment.
#
# Returns:
#   0 on success, 1 on error.
pyvenv_auto_activate_disable() {
    if [ -n "$BASH_VERSION" ]; then
        _pyvenv_auto_activate_disable_bash || return 1
    elif [ -n "$ZSH_VERSION" ]; then
        _pyvenv_auto_activate_disable_zsh || return 1
    else
        _pyvenv_auto_activate_disable_redefine_cd || return 1
    fi
    unset _PYVENV_AUTO_ACTIVATE_ENABLED
}

# }}}
# }}}
# {{{ Pyvenv setup venv file path

# Setup pyvenv-activate to work with an existing python virtual environment.
#
# The virtual environment absolute path will be stored in a file named after
# the variable $PYVENV_ACTIVATE_VENV_PATH_FILE_NAME in the project directory.
#
# The file is created with read-only rights (400) for the owner.
#
# Args:
#   [venv_path]: string: The path to the virtual env to register.
#                        If not set, $VIRTUAL_ENV is used.
#   [proj_path]: string: The path to the project where to store the virtual
#                        environment path file.
#                        If not set, use the current directory.
# Returns:
#   0 on success, 1 on error.
pyvenv_setup_venv_file_path() {
    pa_venv_path_="$1"
    pa_proj_path_="$2"

    if [ -z "$pa_venv_path_" ]; then
        if [ -z "$VIRTUAL_ENV" ]; then
            _pyvenv_activate_safe_echo "no venv path provided and VIRTUAL_ENV variable not set" >&2
            unset pa_venv_path_ pa_proj_path_
            return 1
        fi
        pa_venv_path_="$VIRTUAL_ENV"
    fi

    if ! pa_venv_abs_path_="$(_pyvenv_activate_get_dir_abs_path "$pa_venv_path_")"; then
        _pyvenv_activate_safe_echo "unable to get absolute path of '$pa_venv_path_'" >&2
        unset pa_venv_path_ pa_proj_path_
        return 1
    fi
    pa_venv_path_="$pa_venv_abs_path_"
    unset pa_venv_abs_path_

    if ! [ -f "$pa_venv_path_/bin/activate" ]; then
        _pyvenv_activate_safe_echo "'$pa_venv_path_' is not a valid virtual environment" >&2
        unset pa_venv_path_ pa_proj_path_
        return 1
    fi

    if [ -z "$pa_proj_path_" ]; then
        pa_proj_path_="$PWD"
    fi

    if ! pa_proj_abs_path_="$(_pyvenv_activate_get_dir_abs_path "$pa_proj_path_")"; then
        _pyvenv_activate_safe_echo "unable to get absolute path of '$pa_proj_path_'" >&2
        unset pa_venv_path_ pa_proj_path_
        return 1
    fi
    pa_proj_path_="$pa_proj_abs_path_"
    unset pa_proj_abs_path_

    pa_venv_file_="$pa_proj_path_/$PYVENV_ACTIVATE_VENV_PATH_FILE_NAME"

    if [ -r "$pa_venv_file_" ]; then
        _pyvenv_activate_safe_echo \
            "'$pa_venv_file_' is already present, remove it before" \
            "calling pyvenv_setup_venv_file_path() again" >&2
        unset pa_venv_path_ pa_proj_path_ pa_venv_file_
        return 1
    fi

    # Write venv file path with right perms.
    _pyvenv_activate_safe_echo "$pa_venv_path_" > "$pa_venv_file_" || return 1
    chmod 400 "$pa_venv_file_" || return 1

    # Set auto activate if it is enabled, there is a virtual env activated and
    # if we are in the project.
    pa_abs_pwd_="$(_pyvenv_activate_get_dir_abs_path "$PWD")"
    if [ -n "$VIRTUAL_ENV" ] && \
        [ -n "$_PYVENV_AUTO_ACTIVATE_ENABLED" ] && \
        [ "${pa_abs_pwd_##"$pa_proj_path_"}" != "$pa_abs_pwd_" ]; then
        export _PYVENV_AUTO_ACTIVATE_PROJ_FILE="$pa_venv_file_"
    fi

    unset pa_venv_path_ pa_proj_path_ pa_venv_file_ pa_abs_pwd_
}

# }}}
# {{{ pipenv-activate compatibility

# Activate Pipenv environment in the current shell.
#
# Compatibility function with old pipenv-activate.sh.
#
# Unlike `pipenv shell`, this function will not create a sub-shell, but will
# activate the pipenv virtual environment directly the current shell.
#
# Returns:
#   0 on success, 1 on error.
pipenv_activate() {
    pyvenv_activate
}

# Deactivate Pipenv environment in the current shell.
#
# Compatibility function with old pipenv-activate.sh.
#
# Returns:
#   0 on success, 1 on error.
pipenv_deactivate() {
    pyvenv_deactivate
}

# Function to be run on prompt or when the current directory is changed to
# auto activate or deactivate the Pipenv environment.
#
# Compatibility function with old pipenv-activate.sh.
#
# Returns:
#   0 on success, 1 on error.
pipenv_auto_activate_check_proj() {
    pyvenv_auto_activate_check_proj
}

# Enable auto activate Pipenv environment.
#
# Compatibility function with old pipenv-activate.sh.
#
# Args:
#   [mode]: string: The auto activate mode to use.
#                   It can be one of the following:
#                   - prompt: The Python virtual environment is checked and
#                   activated on prompt.
#                   Since pyvenv_auto_activate_check_proj() is a no-op most of
#                   the time and is fast enough in that case, this is the best
#                   option when available.
#                   This mode is only supported for Bash and Zsh.
#                   - chpwd: The Python virtual environment is checked and
#                   activated when changing directory.
#                   - default: The default mode, use prompt mode when
#                   available, cd otherwise.
#
# Returns:
#   0 on success, 1 on error.
pipenv_auto_activate_enable() {
    pyvenv_auto_activate_enable "$1"
}

# Disable auto activate Pipenv environment.
#
# Compatibility function with old pipenv-activate.sh.
#
# Returns:
#   0 on success, 1 on error.
pipenv_auto_activate_disable() {
    pyvenv_auto_activate_disable
}

# }}}
