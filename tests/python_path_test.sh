#!/bin/sh
# Disable source following.
#   shellcheck disable=SC1090,SC1091
# Disable optional arguments.
#   shellcheck disable=SC2120
# Disable which non-standard.
#   shellcheck disable=SC2230


TEST_SCRIPT="$0"
TEST_DIR="$(dirname -- "$TEST_SCRIPT")"
. "$TEST_DIR/test_helpers"


get_python_path() {
    cmd_prefix="${1:-}"

    $cmd_prefix which python
}

oneTimeSetUp() {
    th_oneTimeSetUp
    HOST_PYTHON_PATH="$(get_python_path)"
}


test_pipenv_run() {
    assertEquals "$(get_python_path)" "$HOST_PYTHON_PATH"

    cd -- "$TEST_ENVS_TMPDIR/1" || return 1
    assertEquals "$HOST_PYTHON_PATH" "$(get_python_path)"
    env_1_python_path="$(get_python_path 'pipenv run')"
    assertNotEquals "$HOST_PYTHON_PATH" "$env_1_python_path" 

    cd -- "$TEST_ENVS_TMPDIR/2" || return 1
    assertEquals "$HOST_PYTHON_PATH" "$(get_python_path)"
    env_2_python_path="$(get_python_path 'pipenv run')"
    assertNotEquals "$HOST_PYTHON_PATH" "$env_2_python_path"
    assertNotEquals "$env_1_python_path" "$env_2_python_path"
}


. "$TEST_DIR/shunit2/shunit2"
