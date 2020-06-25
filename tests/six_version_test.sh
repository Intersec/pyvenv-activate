#!/bin/sh
# Disable source following.
#   shellcheck disable=SC1090,SC1091
# Disable optional arguments.
#   shellcheck disable=SC2120


TEST_SCRIPT="$0"
TEST_DIR="$(dirname -- "$TEST_SCRIPT")"
. "$TEST_DIR/test_helpers"


ENV_1_SIX_VERSION="1.15.0"
ENV_2_SIX_VERSION="None"


get_six_version() {
    cmd_prefix="${1:-}"

    $cmd_prefix python <<EOF
try:
    import six
except ImportError:
    print("None")
else:
    print(six.__version__)
EOF
}


test_pipenv_run() {
    # Change directory to env 1 and check six version.
    cd -- "$TEST_ENVS_TMPDIR/1" || fail "cd to env 1"
    assertEquals "six version in env 1" "$ENV_1_SIX_VERSION" \
        "$(get_six_version 'pipenv run')"

    # Change directory to env 2 and check six version.
    cd -- "$TEST_ENVS_TMPDIR/2" || fail "cd to env 2"
    assertEquals "six version in env 2" "$ENV_2_SIX_VERSION" \
        "$(get_six_version 'pipenv run')"
}


test_pipenv_activate() {
    # Change directory to env 1 and check six version.
    cd -- "$TEST_ENVS_TMPDIR/1" || fail "cd to env 1"
    pipenv_activate || fail "pipenv_activate in env 1"
    assertEquals "six version in env 1" "$ENV_1_SIX_VERSION" \
        "$(get_six_version)"
    pipenv_deactivate || fail "deactivate env 1"

    # Change directory to env 2 and check six version.
    cd -- "$TEST_ENVS_TMPDIR/2" || fail "cd to env 2"
    pipenv_activate || fail "pipenv_activate in env 2"
    assertEquals "six version in env 2" "$ENV_2_SIX_VERSION" \
        "$(get_six_version)"
    pipenv_deactivate || fail "deactivate env 2"
}


th_test_pipenv_auto_activate() {
    enable_cmd="$1"
    disable_cmd="$2"
    cd_cmd="$3"

    $enable_cmd || fail "enable auto activate"

    # Change directory to env 1 and check six version.
    $cd_cmd -- "$TEST_ENVS_TMPDIR/1" || fail "cd to env 1"
    assertEquals "six version in env 1" "$ENV_1_SIX_VERSION" \
        "$(get_six_version)"

    # Change directory to env 2 and check six version.
    $cd_cmd -- "$TEST_ENVS_TMPDIR/2" || fail "cd to env 2"
    assertEquals "six version in env 2" "$ENV_2_SIX_VERSION" \
        "$(get_six_version)"

    # Go back to envs tmpdir
    $cd_cmd -- "$TEST_ENVS_TMPDIR" || fail "cd to envs tmpdir"

    $disable_cmd || fail "disable auto activate"
}


test_pipenv_auto_activate_check_proj() {
    th_test_pipenv_auto_activate_check_proj
}


test_pipenv_auto_activate_redefine_cd() {
    th_test_pipenv_auto_activate_redefine_cd
}


test_pipenv_auto_activate_bash_prompt() {
    th_test_pipenv_auto_activate_bash_prompt
}


test_pipenv_auto_activate_bash_chpwd() {
    th_test_pipenv_auto_activate_bash_chpwd
}


test_pipenv_auto_activate_zsh_prompt() {
    th_test_pipenv_auto_activate_zsh_prompt
}


test_pipenv_auto_activate_zsh_chpwd() {
    th_test_pipenv_auto_activate_zsh_chpwd
}


. "$TEST_DIR/shunit2/shunit2"
