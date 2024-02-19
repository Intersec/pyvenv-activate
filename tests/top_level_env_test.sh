#!/bin/sh
# Disable source following.
#   shellcheck disable=SC1090,SC1091
# Command appears to be unreachable.
#   shellcheck disable=SC2317


TEST_SCRIPT="$0"
TEST_DIR="$(dirname -- "$TEST_SCRIPT")"
. "$TEST_DIR/test_helpers"


th_register_test test_pyvenv_activate_pipenv
test_pyvenv_activate_pipenv() {
    # Activate top-level environment
    export PYVENV_ACTIVATE_TOP_LEVEL_ENV=1

    # Check test environment is ok.
    assertEquals "check host env" "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Change directory to env D
    cd -- "$TEST_ENVS_PIPENV/D" || fail "cd to env D"

    # Use `pyvenv_activate` in env D.
    pyvenv_activate || fail "pyvenv_activate in env D"

    # Check python path in env D with `pyvenv_activate`.
    env_d_python_path="$(th_get_python_path)"
    assertNotEquals "python path not equals to host in env D with pyvenv_activate"\
        "$HOST_PYTHON_PATH" "$env_d_python_path"

    # Change directory to D/Sub
    cd -- "$TEST_ENVS_PIPENV/D/Sub" || fail "cd to D/Sub"

    # Using `pyvenv_activate` in D/Sub has no effects as the current
    # environment should be env D, and should not fail.
    pyvenv_activate || fail "pyvenv_activate in D/Sub after cd should not fail"

    # Check python path in D/Sub should be env D with `pyvenv_activate`.
    env_d_sub_python_path="$(th_get_python_path)"
    assertNotEquals "python path not equals to host in D/Sub with pyvenv_activate"\
        "$HOST_PYTHON_PATH" "$env_d_python_path"
    assertEquals "python path in D/Sub should be equal to env D"\
        "$env_d_python_path" "$env_d_sub_python_path"

    # Deactivate the pyvenv environment of env D in D/Sub, we get the host
    # python path.
    pyvenv_deactivate || fail "deactivate env D in env D/Sub"
    assertEquals "python path equals to host after pyvenv_deactivate of env D in D/Sub"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Using `pyvenv_activate` in D/Sub should activate env D.
    pyvenv_activate || fail "pyvenv_activate in D/Sub after cd should not fail"
    assertEquals "python path in D/Sub should be equal to env D after pyvenv_activate"\
        "$env_d_python_path" "$(th_get_python_path)"

    # Change directory to env D
    cd -- "$TEST_ENVS_PIPENV/D" || fail "cd to env D"

    # Using `pyvenv_activate` in D has no effects as the current
    # environment should be env D, and should not fail.
    pyvenv_activate || fail "pyvenv_activate in D after cd should not fail"

    # We should still be in env D
    assertEquals "python path equals to env D after cd"\
        "$env_d_python_path" "$(th_get_python_path)"

    # Deactivate the pyvenv environment of env D, we get the host python path.
    pyvenv_deactivate || fail "deactivate env D"
    assertEquals "python path equals to host after pyvenv_deactivate of env D"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Restore default lowest level environment
    export PYVENV_ACTIVATE_TOP_LEVEL_ENV=0
}


th_register_test test_pyvenv_activate_poetry
test_pyvenv_activate_poetry() {
    # Activate top-level environment
    export PYVENV_ACTIVATE_TOP_LEVEL_ENV=1

    # Check test environment is ok.
    assertEquals "check host env" "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Change directory to env D
    cd -- "$TEST_ENVS_POETRY/D" || fail "cd to env D"

    # Use `pyvenv_activate` in env D.
    pyvenv_activate || fail "pyvenv_activate in env D"

    # Check python path in env D with `pyvenv_activate`.
    env_d_python_path="$(th_get_python_path)"
    assertNotEquals "python path not equals to host in env D with pyvenv_activate"\
        "$HOST_PYTHON_PATH" "$env_d_python_path"

    # Change directory to D/Sub
    cd -- "$TEST_ENVS_POETRY/D/Sub" || fail "cd to D/Sub"

    # Using `pyvenv_activate` in D/Sub has no effects as the current
    # environment should be env D, and should not fail.
    pyvenv_activate || fail "pyvenv_activate in D/Sub after cd should not fail"

    # Check python path in D/Sub should be env D with `pyvenv_activate`.
    env_d_sub_python_path="$(th_get_python_path)"
    assertNotEquals "python path not equals to host in D/Sub with pyvenv_activate"\
        "$HOST_PYTHON_PATH" "$env_d_python_path"
    assertEquals "python path in D/Sub should be equal to env D"\
        "$env_d_python_path" "$env_d_sub_python_path"

    # Deactivate the pyvenv environment of env D in D/Sub, we get the host
    # python path.
    pyvenv_deactivate || fail "deactivate env D in env D/Sub"
    assertEquals "python path equals to host after pyvenv_deactivate of env D in D/Sub"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Using `pyvenv_activate` in D/Sub should activate env D.
    pyvenv_activate || fail "pyvenv_activate in D/Sub after cd should not fail"
    assertEquals "python path in D/Sub should be equal to env D after pyvenv_activate"\
        "$env_d_python_path" "$(th_get_python_path)"

    # Change directory to env D
    cd -- "$TEST_ENVS_POETRY/D" || fail "cd to env D"

    # Using `pyvenv_activate` in D has no effects as the current
    # environment should be env D, and should not fail.
    pyvenv_activate || fail "pyvenv_activate in D after cd should not fail"

    # We should still be in env D
    assertEquals "python path equals to env D after cd"\
        "$env_d_python_path" "$(th_get_python_path)"

    # Deactivate the pyvenv environment of env D, we get the host python path.
    pyvenv_deactivate || fail "deactivate env D"
    assertEquals "python path equals to host after pyvenv_deactivate of env D"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Restore default lowest level environment
    export PYVENV_ACTIVATE_TOP_LEVEL_ENV=0
}


th_register_test test_pyvenv_activate_venv
test_pyvenv_activate_venv() {
    # Activate top-level environment
    export PYVENV_ACTIVATE_TOP_LEVEL_ENV=1

    th_pyvenv_setup_venv_file_path "$TEST_ENVS_VENV/D" || fail "setup in env D"
    th_pyvenv_setup_venv_file_path "$TEST_ENVS_VENV/D/Sub" || fail "setup in env D/Sub"

    # Check test environment is ok.
    assertEquals "check host env" "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Change directory to env D
    cd -- "$TEST_ENVS_VENV/D" || fail "cd to env D"

    # Use `pyvenv_activate` in env D.
    pyvenv_activate || fail "pyvenv_activate in env D"

    # Check python path in env D with `pyvenv_activate`.
    env_d_python_path="$(th_get_python_path)"
    assertNotEquals "python path not equals to host in env D with pyvenv_activate"\
        "$HOST_PYTHON_PATH" "$env_d_python_path"

    # Change directory to D/Sub
    cd -- "$TEST_ENVS_VENV/D/Sub" || fail "cd to D/Sub"

    # Using `pyvenv_activate` in D/Sub has no effects as the current
    # environment should be env D, and should not fail.
    pyvenv_activate || fail "pyvenv_activate in D/Sub after cd should not fail"

    # Check python path in D/Sub should be env D with `pyvenv_activate`.
    env_d_sub_python_path="$(th_get_python_path)"
    assertNotEquals "python path not equals to host in D/Sub with pyvenv_activate"\
        "$HOST_PYTHON_PATH" "$env_d_python_path"
    assertEquals "python path in D/Sub should be equal to env D"\
        "$env_d_python_path" "$env_d_sub_python_path"

    # Deactivate the pyvenv environment of env D in D/Sub, we get the host
    # python path.
    pyvenv_deactivate || fail "deactivate env D in env D/Sub"
    assertEquals "python path equals to host after pyvenv_deactivate of env D in D/Sub"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Using `pyvenv_activate` in D/Sub should activate env D.
    pyvenv_activate || fail "pyvenv_activate in D/Sub after cd should not fail"
    assertEquals "python path in D/Sub should be equal to env D after pyvenv_activate"\
        "$env_d_python_path" "$(th_get_python_path)"

    # Change directory to env D
    cd -- "$TEST_ENVS_VENV/D" || fail "cd to env D"

    # Using `pyvenv_activate` in D has no effects as the current
    # environment should be env D, and should not fail.
    pyvenv_activate || fail "pyvenv_activate in D after cd should not fail"

    # We should still be in env D
    assertEquals "python path equals to env D after cd"\
        "$env_d_python_path" "$(th_get_python_path)"

    # Deactivate the pyvenv environment of env D, we get the host python path.
    pyvenv_deactivate || fail "deactivate env D"
    assertEquals "python path equals to host after pyvenv_deactivate of env D"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Restore default lowest level environment
    export PYVENV_ACTIVATE_TOP_LEVEL_ENV=0
}


th_register_auto_activate_tests test_pyvenv_auto_activate_pipenv
test_pyvenv_auto_activate_pipenv() {
    enable_cmd="$1"
    disable_cmd="$2"
    cd_cmd="$3"

    # Activate top-level environment
    export PYVENV_ACTIVATE_TOP_LEVEL_ENV=1

    # Enable auto activate
    $enable_cmd || fail "enable auto activate"

    # Check test environment is ok.
    assertEquals "check host env" "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Change directory to env D
    $cd_cmd -- "$TEST_ENVS_PIPENV/D" || fail "cd to env D"

    # Check python path in env D.
    env_d_python_path="$(th_get_python_path)"
    assertNotEquals "python path not equals to host in env D after cd"\
        "$HOST_PYTHON_PATH" "$env_d_python_path"

    # Change directory to D/Sub
    $cd_cmd -- "$TEST_ENVS_PIPENV/D/Sub" || fail "cd to D/Sub"

    # The current environment should still be env D.
    env_d_sub_python_path="$(th_get_python_path)"
    assertEquals "python path in D/Sub should be equal to env D"\
        "$env_d_python_path" "$env_d_sub_python_path"

    # Change directory to env D
    $cd_cmd -- "$TEST_ENVS_PIPENV/D" || fail "cd to env D"

    # The current environment should still be env D.
    assertEquals "python path equals to env D back from D/Sub after cd"\
        "$env_d_python_path" "$(th_get_python_path)"

    # Change directory to envs tmpdir and check python path.
    $cd_cmd -- "$TEST_ENVS_PIPENV" || fail "cd to envs tmpdir"
    assertEquals "python path equals to host in envs tmpdir after cd"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Disable auto activate
    $disable_cmd || fail "disable auto activate"

    # Restore default lowest level environment
    export PYVENV_ACTIVATE_TOP_LEVEL_ENV=0
}


th_register_auto_activate_tests test_pyvenv_auto_activate_poetry
test_pyvenv_auto_activate_poetry() {
    enable_cmd="$1"
    disable_cmd="$2"
    cd_cmd="$3"

    # Activate top-level environment
    export PYVENV_ACTIVATE_TOP_LEVEL_ENV=1

    # Enable auto activate
    $enable_cmd || fail "enable auto activate"

    # Check test environment is ok.
    assertEquals "check host env" "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Change directory to env D
    $cd_cmd -- "$TEST_ENVS_POETRY/D" || fail "cd to env D"

    # Check python path in env D.
    env_d_python_path="$(th_get_python_path)"
    assertNotEquals "python path not equals to host in env D after cd"\
        "$HOST_PYTHON_PATH" "$env_d_python_path"

    # Change directory to D/Sub
    $cd_cmd -- "$TEST_ENVS_POETRY/D/Sub" || fail "cd to D/Sub"

    # The current environment should still be env D.
    env_d_sub_python_path="$(th_get_python_path)"
    assertEquals "python path in D/Sub should be equal to env D"\
        "$env_d_python_path" "$env_d_sub_python_path"

    # Change directory to env D
    $cd_cmd -- "$TEST_ENVS_POETRY/D" || fail "cd to env D"

    # The current environment should still be env D.
    assertEquals "python path equals to env D back from D/Sub after cd"\
        "$env_d_python_path" "$(th_get_python_path)"

    # Change directory to envs tmpdir and check python path.
    $cd_cmd -- "$TEST_ENVS_POETRY" || fail "cd to envs tmpdir"
    assertEquals "python path equals to host in envs tmpdir after cd"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Disable auto activate
    $disable_cmd || fail "disable auto activate"

    # Restore default lowest level environment
    export PYVENV_ACTIVATE_TOP_LEVEL_ENV=0
}


th_register_auto_activate_tests test_pyvenv_auto_activate_venv
test_pyvenv_auto_activate_venv() {
    enable_cmd="$1"
    disable_cmd="$2"
    cd_cmd="$3"

    th_pyvenv_setup_venv_file_path "$TEST_ENVS_VENV/D" || fail "setup in env D"
    th_pyvenv_setup_venv_file_path "$TEST_ENVS_VENV/D/Sub" || fail "setup in env D/Sub"

    # Activate top-level environment
    export PYVENV_ACTIVATE_TOP_LEVEL_ENV=1

    # Enable auto activate
    $enable_cmd || fail "enable auto activate"

    # Check test environment is ok.
    assertEquals "check host env" "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Change directory to env D
    $cd_cmd -- "$TEST_ENVS_VENV/D" || fail "cd to env D"

    # Check python path in env D.
    env_d_python_path="$(th_get_python_path)"
    assertNotEquals "python path not equals to host in env D after cd"\
        "$HOST_PYTHON_PATH" "$env_d_python_path"

    # Change directory to D/Sub
    $cd_cmd -- "$TEST_ENVS_VENV/D/Sub" || fail "cd to D/Sub"

    # The current environment should still be env D.
    env_d_sub_python_path="$(th_get_python_path)"
    assertEquals "python path in D/Sub should be equal to env D"\
        "$env_d_python_path" "$env_d_sub_python_path"

    # Change directory to env D
    $cd_cmd -- "$TEST_ENVS_VENV/D" || fail "cd to env D"

    # The current environment should still be env D.
    assertEquals "python path equals to env D back from D/Sub after cd"\
        "$env_d_python_path" "$(th_get_python_path)"

    # Change directory to envs tmpdir and check python path.
    $cd_cmd -- "$TEST_ENVS_VENV" || fail "cd to envs tmpdir"
    assertEquals "python path equals to host in envs tmpdir after cd"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Disable auto activate
    $disable_cmd || fail "disable auto activate"

    # Restore default lowest level environment
    export PYVENV_ACTIVATE_TOP_LEVEL_ENV=0
}


. "$TEST_DIR/shunit2/shunit2"
