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
    # Check test environment is ok.
    assertEquals "check host env" "$HOST_PYTHON_PATH" "$(get_python_path)"

    # Change directory in env 1 and check python path with `pipenv run`.
    cd -- "$TEST_ENVS_TMPDIR/1" || fail "cd to env 1"
    assertEquals "python path equals to host in env 1 without pipenv run"\
        "$HOST_PYTHON_PATH" "$(get_python_path)"

    env_1_python_path="$(get_python_path 'pipenv run')"
    assertNotEquals "python path not equals to host in env 1 with pipenv run"\
        "$HOST_PYTHON_PATH" "$env_1_python_path"

    # Change directory in env 2 and check python path with `pipenv run`.
    cd -- "$TEST_ENVS_TMPDIR/2" || fail "cd to env 2"
    assertEquals "python path equals to host in env 2 without pipenv run"\
        "$HOST_PYTHON_PATH" "$(get_python_path)"

    env_2_python_path="$(get_python_path 'pipenv run')"
    assertNotEquals "python path not equals to host in env 2 with pipenv run"\
        "$HOST_PYTHON_PATH" "$env_2_python_path"
    assertNotEquals "python path not equals to env 1 in env 2 with pipenv run"\
        "$env_1_python_path" "$env_2_python_path"
}


. "$TEST_DIR/shunit2/shunit2"
