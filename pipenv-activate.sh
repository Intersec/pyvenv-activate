#!/bin/sh
#
# pipenv-activate.sh is a script containing a set of functions to activate
# and deactivate a Pipenv environment directly within the current shell.


# {{{ Pipenv activate

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
_pipenv_activate_get_dotenv_variables() {
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
_pipenv_activate_dotenv_encode_value() {
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
_pipenv_activate_dotenv_decode_value() {
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

    pa_python_exec_="$(_pipenv_activate_get_pipenv_python)"

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
            pa_existing_val_="$(_pipenv_activate_dotenv_encode_value \
                "$pa_python_exec_" "$pa_existing_val_")"

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
        pa_dotenv_value_="$(_pipenv_activate_dotenv_decode_value \
            "$pa_python_exec_" "$pa_dotenv_value_")"

        # Export the value in the current environment.
        export "$pa_dotenv_key_=$pa_dotenv_value_"
    done <<EOF
$(_pipenv_activate_get_dotenv_variables "$pa_python_exec_" "$pa_dotenv_file_")
EOF

    # Set the list of variables to global variable.
    _PIPENV_ACTIVATE_DOTENV_VARS="$pa_dotenv_vars_"

    # Set the list of existing values to global variable.
    _PIPENV_ACTIVATE_DOTENV_EXISTING_VALS="$pa_dotenv_existing_vals_"

    unset pa_dotenv_file_ pa_python_exec_ pa_dotenv_vars_ pa_dotenv_line_ \
        pa_dotenv_key_ pa_dotenv_value_ pa_current_val_ \
        pa_dotenv_existing_vals_
}

# Find project directory containing a Pipenv file.
#
# It respects the PIPENV_MAX_DEPTH, PIPENV_NO_INHERIT and PIPENV_PIPFILE
# environment variables.
#
# Outputs:
#   The Pipenv project root directory.
_pipenv_activate_find_proj_dir() {
    if [ -z "$PIPENV_PIPFILE" ]; then
        pa_current_dir_="$PWD"

        if [ -z "$PIPENV_NO_INHERIT" ]; then
            # Default PIPENV_MAX_DEPTH is 3 according to Pipenv documentation.
            pa_max_depth_="${PIPENV_MAX_DEPTH:-3}"
        else
            pa_max_depth_=0
        fi
    else
        pa_current_dir_="$(dirname -- "$PIPENV_PIPFILE")"
        pa_max_depth_=0
    fi

    pa_i_=0

    while true; do
        # Always do it at least once regardless of max depth.
        if [ -r "$pa_current_dir_/Pipfile" ]; then
            echo "$pa_current_dir_"
            break
        fi

        if [ -z "$pa_current_dir_" ] || [ "$pa_current_dir_" = "/" ]; then
            break
        fi

        pa_i_=$((pa_i_ + 1))

        # Use ! to break if $pa_max_depth_ is not a number.
        if ! [ "$pa_i_" -lt "$pa_max_depth_" ]; then
            break
        fi

        # Use command substitution to get the dirname.
        pa_current_dir_="${pa_current_dir_%/*}"
    done

    unset pa_max_depth_ pa_current_dir_ pa_i_
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
        pa_proj_dir_="$(_pipenv_activate_find_proj_dir)"
        if [ -z "$pa_proj_dir_" ]; then
            # If the Pipenv project is not found, use $PWD to have a nice
            # error later on.
            pa_proj_dir_="$PWD"
        fi
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

    _pipenv_activate_load_dotenv "$pa_proj_dir_" || return 1

    export PIPENV_ACTIVE=1

    # shellcheck disable=SC1090
    . "$pa_venv_dir_/bin/activate" || return 1

    unset pa_proj_dir_ pa_venv_dir_
    return 0
}

# }}}
# {{{ Pipenv deactivate

# Unload the dotenv file previous loaded by pipenv_activate.
_pipenv_deactivate_unload_dotenv() {
    # Unset the variables set by the dotenv file.
    if [ -n "$_PIPENV_ACTIVATE_DOTENV_VARS" ]; then
        while IFS= read -r pa_var_; do
            unset "$pa_var_"
        done <<EOF
$_PIPENV_ACTIVATE_DOTENV_VARS
EOF
        unset pa_var_ _PIPENV_ACTIVATE_DOTENV_VARS
    fi

    # Restore the existing variables.
    if [ -n "$_PIPENV_ACTIVATE_DOTENV_EXISTING_VALS" ]; then
        pa_python_exec_="$(_pipenv_activate_get_pipenv_python)"

        # Read $_PIPENV_ACTIVATE_DOTENV_EXISTING_VALS line by line.
        while IFS= read -r pa_existing_line_; do
            # Split line by  '.
            IFS=" " read -r pa_existing_kind_ pa_existing_key_ pa_existing_val_ <<EOF
$pa_existing_line_
EOF

            # Decode the value.
            pa_existing_val_="$(_pipenv_activate_dotenv_decode_value \
                "$pa_python_exec_" "$pa_existing_val_")"

            # Export the variable or set it as a simple shell variable
            # depending of the kind.
            if [ "$pa_existing_kind_" = 'e' ]; then
                export "$pa_existing_key_=$pa_existing_val_"
            else
                eval "$pa_existing_key_=\"\$pa_existing_val_\""
            fi
        done <<EOF
$_PIPENV_ACTIVATE_DOTENV_EXISTING_VALS
EOF

        unset pa_existing_line_ pa_existing_kind_ pa_existing_key_ \
            _PIPENV_ACTIVATE_DOTENV_EXISTING_VALS
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
# {{{ Pipenv auto activate
# {{{ Check project

# Function to be run on prompt or when the current directory is changed to
# auto activate or deactivate the Pipenv environment.
#
# Returns:
#   0 on success, 1 on error.
pipenv_auto_activate_check_proj() {
    pa_proj_dir_="$(_pipenv_activate_find_proj_dir)"

    if [ -n "$_PIPENV_AUTO_ACTIVATE_PROJ_DIR" ] \
    && [ "$pa_proj_dir_" != "$_PIPENV_AUTO_ACTIVATE_PROJ_DIR" ]; then
        # Deactivate the virtual environment if we have left the pipenv
        # directory.
        pipenv_deactivate >&2 || return 1
        unset _PIPENV_AUTO_ACTIVATE_PROJ_DIR
    fi

    if [ -n "$pa_proj_dir_" ] \
    && [ "$pa_proj_dir_" != "$_PIPENV_AUTO_ACTIVATE_PROJ_DIR" ] \
    && [ -z "$VIRTUAL_ENV" ]; then
        pa_pipenv_env_="$(pipenv --venv 2>/dev/null)"
        if [ -n "$pa_pipenv_env_" ]; then
            # Activate the virtual environment if we have entered a new pipenv
            # directory and that no virtual environment has been activated
            # before.
            export _PIPENV_AUTO_ACTIVATE_PROJ_DIR="$pa_proj_dir_"
            pipenv_activate "$pa_proj_dir_" "$pa_pipenv_env_" >&2 || return 1
        fi
    fi
    unset pa_proj_dir_ pa_pipenv_env_
}

# }}}
# {{{ Enable

# Enable auto activate Pipenv environment by redefining the cd command.
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
_pipenv_auto_activate_enable_redefine_cd() {
    if [ "$1" = "prompt" ]; then
        echo "prompt mode is not supported when redefining cd" >&2
        return 1
    fi

    # shellcheck disable=SC2039
    if [ "$(type cd)" != "cd is a shell builtin" ]; then
        echo "command cd is already redefined" >&2
        return 1
    fi

    # Some shells use `builtin` for calling the original cd command, others
    # use `command`.
    # shellcheck disable=SC2039
    if (builtin echo "123" >/dev/null 2>&1); then
        cd() {
            # shellcheck disable=SC2039
            builtin cd "$@" && pipenv_auto_activate_check_proj
        }
    else
        cd() {
            command cd "$@" && pipenv_auto_activate_check_proj
        }
    fi

    return 0
}

# Enable auto activate Pipenv environment on change directory.
_pipenv_auto_activate_bash_chpwd_cmd() {
    if [ "$_PIPENV_AUTO_ACTIVATE_OLD_PWD" != "$PWD" ]; then
        pipenv_auto_activate_check_proj
        _PIPENV_AUTO_ACTIVATE_OLD_PWD="$PWD"
    fi
}

# Enable auto activate Pipenv environment for Bash.
#
# Args:
#   mode: string: The auto activate mode to use.
#
# Returns:
#   0 on success, 1 on error.
_pipenv_auto_activate_enable_bash() {
    if [ "$1" = "chpwd" ]; then
        pa_cmd_="_pipenv_auto_activate_bash_chpwd_cmd"
    else
        pa_cmd_="pipenv_auto_activate_check_proj"
    fi

    _pipenv_auto_activate_disable_bash || return 1
    PROMPT_COMMAND="${pa_cmd_}${PROMPT_COMMAND:+;$PROMPT_COMMAND}"

    unset pa_cmd_
    return 0
}

# Enable auto activate Pipenv environment for Zsh.
#
# Args:
#   mode: string: The auto activate mode to use.
#
# Returns:
#   0 on success, 1 on error.
_pipenv_auto_activate_enable_zsh() {
    if [ "$1" = "chpwd" ]; then
        pa_hook_="chpwd"
    else
        pa_hook_="precmd"
    fi

    autoload -Uz add-zsh-hook || return 1
    _pipenv_auto_activate_disable_zsh || return 1
    add-zsh-hook "$pa_hook_" pipenv_auto_activate_check_proj || return 1

    unset pa_hook_
    return 0
}

# Enable auto activate Pipenv environment.
#
# Args:
#   [mode]: string: The auto activate mode to use.
#                   It can be one of the following:
#                   - prompt: The Pipenv environment is checked and activated
#                   on prompt.
#                   Since pipenv_auto_activate_check_proj() is a no-op most of
#                   the time and is fast enough in that case, this is the best
#                   option when available.
#                   This mode is only supported for Bash and Zsh.
#                   - chpwd: The Pipenv environment is checked and activated
#                   when changing directory.
#                   - default: The default mode, use prompt mode when
#                   available, cd otherwise.
#
# Returns:
#   0 on success, 1 on error.
pipenv_auto_activate_enable() {
    pa_mode_="${1:-default}"

    case "$pa_mode_" in
        prompt|chpwd|default)
            ;;
        *)
            echo "unknow mode $pa_mode_" >&2
            return 1
            ;;
    esac


    if [ -n "$BASH_VERSION" ]; then
        _pipenv_auto_activate_enable_bash "$pa_mode_" || return 1
    elif [ -n "$ZSH_VERSION" ]; then
        _pipenv_auto_activate_enable_zsh "$pa_mode_" || return 1
    else
        _pipenv_auto_activate_enable_redefine_cd "$pa_mode_" || return 1
    fi

    unset pa_mode_
    return 0
}

# }}}
# {{{ Disable

# Disable auto activate Pipenv environment when redefining the cd command.
#
# Returns:
#   0 on success, 1 on error.
_pipenv_auto_activate_disable_redefine_cd() {
    # shellcheck disable=SC2039
    if [ "$(type cd)" = "cd is a shell builtin" ]; then
        # Nothing to do.
        return 0
    fi

    unset -f cd || return 1
    return 0
}

# Disable auto activate Pipenv environment on prompt for Bash.
#
# Returns:
#   0 on success, 1 on error.
_pipenv_auto_activate_disable_bash() {
    PROMPT_COMMAND="$(echo "$PROMPT_COMMAND" | \
        sed -E -e 's/pipenv_auto_activate_check_proj;?//g' \
               -e 's/_pipenv_auto_activate_bash_chpwd_cmd;?//g')"
}

# Disable auto activate Pipenv environment on prompt for Zsh
#
# Returns:
#   0 on success, 1 on error.
_pipenv_auto_activate_disable_zsh() {
    autoload -Uz add-zsh-hook || return 1
    add-zsh-hook -D precmd pipenv_auto_activate_check_proj || return 1
    add-zsh-hook -D chpwd pipenv_auto_activate_check_proj || return 1
    return 0
}

# Disable auto activate Pipenv environment.
#
# Returns:
#   0 on success, 1 on error.
pipenv_auto_activate_disable() {
    if [ -n "$BASH_VERSION" ]; then
        _pipenv_auto_activate_disable_bash
    elif [ -n "$ZSH_VERSION" ]; then
        _pipenv_auto_activate_disable_zsh
    else
        _pipenv_auto_activate_disable_redefine_cd
    fi
}

# }}}
# }}}
