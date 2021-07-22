#!/bin/sh
# Disable source following.
#   shellcheck disable=SC1090,SC1091
# Disable optional arguments.
#   shellcheck disable=SC2120


TEST_SCRIPT="$0"
TEST_DIR="$(dirname -- "$TEST_SCRIPT")"
. "$TEST_DIR/test_helpers"


oneTimeSetUp() {
    th_oneTimeSetUp || return 1
    TEST_ENVS_B_SETUP_FILE="$TEST_ENVS_VENV/B/$PYVENV_ACTIVATE_SETUP_FILE_NAME"
}


th_register_test test_venv_setup_func
test_venv_setup_func() {
    rm -f -- "$TEST_ENVS_B_SETUP_FILE"

    # Create setup file in env B with absolute paths
    pyvenv_setup "$TEST_ENVS_VENV/B/.pyvenv_venv" "$TEST_ENVS_VENV/B" || \
        fail "unable to create setup file in env B with absolute paths"
    test -r "$TEST_ENVS_B_SETUP_FILE" || \
        fail "setup file in env B was not created"

    rm -f -- "$TEST_ENVS_B_SETUP_FILE"

    # Create setup file in env B with relative paths
    cd -- "$TEST_ENVS_VENV/B" || fail "cd to env B"
    pyvenv_setup ".pyvenv_venv" "." || \
        fail "unable to create setup file in env B with relative paths"
    test -r "$TEST_ENVS_B_SETUP_FILE" || \
        fail "setup file in env B was not created"

    rm -f -- "$TEST_ENVS_B_SETUP_FILE"

    # Unable to setup file in env B with default paths without activated
    # virtual environment
    pyvenv_setup 2>/dev/null && \
        fail "should not be able to create setup file in env B with default
            paths without activated virtual environment"
    test -r "$TEST_ENVS_B_SETUP_FILE" && \
        fail "setup file in env B should not have been created"

    # Create setup file in env B with default paths
    th_activate_venv "$TEST_ENVS_VENV/B" || fail "activate env B"
    pyvenv_setup || \
        fail "unable to create setup file in env B with default paths"
    test -r "$TEST_ENVS_B_SETUP_FILE" || \
        fail "setup file in env B was not created"
    deactivate nondestructive
    unset -f deactivate

    rm -f -- "$TEST_ENVS_B_SETUP_FILE"
}


th_register_test test_venv_setup_file_activate_perms
test_venv_setup_file_activate_perms() {
    # Create setup file in env B
    cd -- "$TEST_ENVS_VENV/B" || fail "cd to env B"
    th_pyvenv_setup_venv || fail "setup in env B"

    # Set wrong perms to setup file
    chmod 644 "$TEST_ENVS_B_SETUP_FILE" || \
        fail "set perms of setup file in env B"

    # pyvenv_activate should fail with setup file with wrong permission
    pyvenv_activate 2>/dev/null && \
        fail "pyvenv_activate in env B with wrong perms on setup file should fail"

    # Reset valid perms to setup file
    chmod 400 "$TEST_ENVS_B_SETUP_FILE" || \
        fail "set perms of setup file in env B"

    # pyvenv_activate should be ok
    pyvenv_activate || fail "pyvenv_activate in env B"

    pyvenv_deactivate || fail "pyvenv_deactivate env B"
}


th_register_test test_venv_setup_file_activate_abs_path
test_venv_setup_file_activate_abs_path() {
    cd -- "$TEST_ENVS_VENV/B" || fail "cd to env B"

    # Set relative path in setup file
    rm -f -- "$TEST_ENVS_B_SETUP_FILE"
    echo ".pyvenv_venv" > "$TEST_ENVS_B_SETUP_FILE"
    chmod 400 "$TEST_ENVS_B_SETUP_FILE" || \
        fail "set perms of setup file in env B"

    # pyvenv_activate should fail with setup file with relative path
    pyvenv_activate 2>/dev/null && \
        fail "pyvenv_activate in env B with relative path in setup file should fail"

    # Set absolute path in setup file
    rm -f -- "$TEST_ENVS_B_SETUP_FILE"
    echo "$PWD/.pyvenv_venv" > "$TEST_ENVS_B_SETUP_FILE"
    chmod 400 "$TEST_ENVS_B_SETUP_FILE" || \
        fail "set perms of setup file in env B"

    # pyvenv_activate should be ok
    pyvenv_activate || fail "pyvenv_activate in env B"

    pyvenv_deactivate || fail "pyvenv_deactivate env B"
}


th_register_test test_venv_setup_in_virtual_env
test_venv_setup_in_virtual_env() {
    rm -f -- "$TEST_ENVS_B_SETUP_FILE"
    assertEquals "check host env" "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Change directory to env B and manually activate
    cd -- "$TEST_ENVS_VENV/B" || fail "cd to env B"
    th_activate_venv || fail "activate env B"

    # Check env B python path
    env_b_python_path="$(th_get_python_path)"
    assertNotEquals "python path not equals to host in env B"\
        "$HOST_PYTHON_PATH" "$env_b_python_path"

    # pyvenv_activate should fail without setup file
    pyvenv_activate 2>/dev/null && \
        fail "pyvenv_activate in env B without setup file"

    # Setup pyvenv with activated virtual env in env B
    pyvenv_setup || fail "pyvenv_setup in env B with activated virtual env"

    # pyvenv_activate should be ok and no op
    pyvenv_activate || fail "pyvenv_activate in env B"
    assertEquals "python path should not be changed in env B after pyvenv_activate"\
        "$env_b_python_path" "$(th_get_python_path)"

    # pyvenv_deactivate should disable the virtual env
    pyvenv_deactivate || fail "pyvenv_deactivate env B"
    assertEquals "python path should equals to host after pyvenv_deactivate"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # pyvenv_activate should be ok
    pyvenv_activate || fail "pyvenv_activate in env B"
    assertEquals "python path should be equals to env B after pyvenv_activate"\
        "$env_b_python_path" "$(th_get_python_path)"

    pyvenv_deactivate || fail "pyvenv_deactivate env B"
}


th_register_auto_activate_tests test_venv_setup_auto_activate
test_venv_setup_auto_activate() {
    enable_cmd="$1"
    disable_cmd="$2"
    cd_cmd="$3"

    rm -f -- "$TEST_ENVS_B_SETUP_FILE"

    $enable_cmd || fail "enable auto activate"

    assertEquals "check host env" "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Change directory to env B
    $cd_cmd -- "$TEST_ENVS_VENV/B" || fail "cd to env B"

    # Virtual environment should not be activated
    assertEquals "python path should equals to host without setup file"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Manual activate virtual environment
    th_activate_venv || fail "activate env B"
    env_b_python_path="$(th_get_python_path)"
    assertNotEquals "python path not equals to host in env B"\
        "$HOST_PYTHON_PATH" "$env_b_python_path"

    # Setup pyvenv with activated virtual env in env B
    pyvenv_setup || fail "pyvenv_setup in env B with activated virtual env"
    assertEquals "python path not equals to env B"\
        "$env_b_python_path" "$(th_get_python_path)"

    # Change directory to envs tmpdir and check python path
    $cd_cmd -- "$TEST_ENVS_VENV" || fail "cd to envs tmpdir"
    assertEquals "python path equals to host in envs tmpdir after cd"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Go back to env B and check python path
    $cd_cmd -- "$TEST_ENVS_VENV/B" || fail "cd to env B"
    assertEquals "python path not equals to env B"\
        "$env_b_python_path" "$(th_get_python_path)"

    $cd_cmd -- "$TEST_ENVS_VENV" || fail "cd to envs tmpdir"

    $disable_cmd || fail "disable auto activate"
}


. "$TEST_DIR/shunit2/shunit2"
