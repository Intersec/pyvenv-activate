#!/bin/sh
# Disable source following.
#   shellcheck disable=SC1090,SC1091


TEST_SCRIPT="$0"
TEST_DIR="$(dirname -- "$TEST_SCRIPT")"
. "$TEST_DIR/test_helpers"


ENV_C_VAR_A="foo"


setUp() {
    th_setUp || return 1
    unset PIPENV_MAX_DEPTH
    unset PIPENV_NO_INHERIT
    unset PIPENV_PIPFILE
}


th_register_test test_pipenv_run
test_pipenv_run() {
    # Check test environment is ok.
    assertNull "check NULL host venv" "$(th_get_pipenv_venv)"

    # Change directory to env A and check pipenv venv.
    cd -- "$TEST_ENVS_PIPENV/A" || fail "cd to env A"
    env_a_pipenv_venv="$(th_get_pipenv_venv)"
    assertNotNull "pipenv venv not NULL in env A" "$env_a_pipenv_venv"

    export PIPENV_MAX_DEPTH=2

    # Change directory to A/1
    cd -- "$TEST_ENVS_PIPENV/A/1" || fail "cd to env A/1"
    assertEquals "pipenv venv equals to env A in A/1 with max depth 2"\
        "$env_a_pipenv_venv" "$(th_get_pipenv_venv)"

    # Change directory to A/1/2
    cd -- "$TEST_ENVS_PIPENV/A/1/2" || fail "cd to env A/1/2"
    assertNull "pipenv venv NULL in A/1/2 with max depth 2"\
        "$(th_get_pipenv_venv)"

    export PIPENV_MAX_DEPTH=4

    # Change directory to A/1
    cd -- "$TEST_ENVS_PIPENV/A/1" || fail "cd to env A/1"
    assertEquals "pipenv venv equals to env A in A/1 with max depth 4"\
        "$env_a_pipenv_venv" "$(th_get_pipenv_venv)"

    # Change directory to A/1/2
    cd -- "$TEST_ENVS_PIPENV/A/1/2" || fail "cd to env A/1/2"
    assertEquals "pipenv venv equals to env A in A/1/2 with max depth 4"\
        "$env_a_pipenv_venv" "$(th_get_pipenv_venv)"

    # Change directory to A/1/2/3
    cd -- "$TEST_ENVS_PIPENV/A/1/2/3" || fail "cd to env A/1/2/3"
    assertEquals "pipenv venv equals to env A in A/1/2/3 with max depth 4"\
        "$env_a_pipenv_venv" "$(th_get_pipenv_venv)"

    # Change directory to A/1/2/3/4
    cd -- "$TEST_ENVS_PIPENV/A/1/2/3/4" || fail "cd to env A/1/2/3/4"
    assertNull "pipenv venv NULL in A/1/2/3/4 with max depth 4"\
        "$(th_get_pipenv_venv)"

    export PIPENV_MAX_DEPTH=0

    # Change directory to A/1
    cd -- "$TEST_ENVS_PIPENV/A/1" || fail "cd to env A/1"
    assertNull "pipenv venv NULL in A/1 with max depth 0"\
        "$(th_get_pipenv_venv)"

    # Change directory to A/
    cd -- "$TEST_ENVS_PIPENV/A/" || fail "cd to env A/"
    assertEquals "pipenv venv equals to env A in A/ with max depth 0"\
        "$env_a_pipenv_venv" "$(th_get_pipenv_venv)"

    unset PIPENV_MAX_DEPTH
    export PIPENV_NO_INHERIT=1

    # Change directory to A/1
    cd -- "$TEST_ENVS_PIPENV/A/1" || fail "cd to env A/1"
    assertNull "pipenv venv NULL in A/1 with no inherith"\
        "$(th_get_pipenv_venv)"

    # Change directory to A/
    cd -- "$TEST_ENVS_PIPENV/A/" || fail "cd to env A/"
    assertEquals "pipenv venv equals to env A in A/ with no inherit"\
        "$env_a_pipenv_venv" "$(th_get_pipenv_venv)"

    unset PIPENV_NO_INHERIT

    # Change directory to C/1
    cd -- "$TEST_ENVS_PIPENV/C/1" || fail "cd to env C/1"
    env_c_pipenv_venv="$(th_get_pipenv_venv)"
    assertNotNull "pipenv venv not NULL in env C/1" "$env_c_pipenv_venv"
    assertEquals "VAR A in env C/1" "$ENV_C_VAR_A" "$(th_get_env_var "VAR_A" 'pipenv run')"

    export PIPENV_PIPFILE="$TEST_ENVS_PIPENV/C/Pipfile"

    # Change directory to A/1/2 with PIPENV_PIPFILE to env C
    cd -- "$TEST_ENVS_PIPENV/A/1/2" || fail "cd to env A/1/2"
    assertEquals "pipenv venv equals to env C with PIPENV_FILE to env C in A/1/2"\
        "$env_c_pipenv_venv" "$(th_get_pipenv_venv)"
    assertEquals "VAR A with PIPENV_FILE to env C in A/1/2" "$ENV_C_VAR_A"\
        "$(th_get_env_var "VAR_A" 'pipenv run')"

    unset PIPENV_PIPFILE
}


th_register_test test_poetry_run
test_poetry_run() {
    # Check test environment is ok.
    assertNull "check NULL host venv" "$(th_get_poetry_venv)"

    # Change directory to env A and check poetry venv.
    cd -- "$TEST_ENVS_POETRY/A" || fail "cd to env A"
    env_a_poetry_venv="$(th_get_poetry_venv)"
    assertNotNull "poetry venv not NULL in env A" "$env_a_poetry_venv"

    # Check PIPENV_MAX_DEPTH has not effect with Poetry projects.
    export PIPENV_MAX_DEPTH=1
    cd -- "$TEST_ENVS_POETRY/A/1/2/3" || fail "cd to env A/1/2/3"
    assertEquals "PIPENV_MAX_DEPTH has not effect on poetry project env A"\
        "$env_a_poetry_venv" "$(th_get_poetry_venv)"
    unset PIPENV_MAX_DEPTH

    # Check PIPENV_NO_INHERIT has not effect with Poetry projects.
    export PIPENV_NO_INHERIT=1
    cd -- "$TEST_ENVS_POETRY/A/1/2/3" || fail "cd to env A/1/2/3"
    assertEquals "PIPENV_NO_INHERIT has not effect on poetry project env A"\
        "$env_a_poetry_venv" "$(th_get_poetry_venv)"
    unset PIPENV_NO_INHERIT
}


th_register_test test_pyvenv_activate_pipenv
test_pyvenv_activate_pipenv() {
    # Check test environment is ok.
    assertEquals "check host env" "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Change directory to env A and check pipenv venv.
    cd -- "$TEST_ENVS_PIPENV/A" || fail "cd to env A"
    pyvenv_activate || fail "pyvenv_activate in env A"
    env_a_python_path="$(th_get_python_path)"
    assertNotEquals "python path not equals to host in env A"\
        "$HOST_PYTHON_PATH" "$env_a_python_path"
    pyvenv_deactivate || fail "deactivate env A"

    export PIPENV_MAX_DEPTH=2

    # Change directory to A/1
    cd -- "$TEST_ENVS_PIPENV/A/1" || fail "cd to env A/1"
    pyvenv_activate || fail "pyvenv_activate in env A/1 with max depth 2"
    assertEquals "python path equals to env A in A/1 with max depth 2"\
        "$env_a_python_path" "$(th_get_python_path)"
    pyvenv_deactivate || fail "deactivate env A"

    # Change directory to A/1/2
    cd -- "$TEST_ENVS_PIPENV/A/1/2" || fail "cd to env A/1/2"
    pyvenv_activate 2>/dev/null \
        && fail "pyvenv_activate in A/1 with max depth 2 should fail"

    export PIPENV_MAX_DEPTH=4

    # Change directory to A/1
    cd -- "$TEST_ENVS_PIPENV/A/1" || fail "cd to env A/1"
    pyvenv_activate || fail "pyvenv_activate in env A/1 with max depth 4"
    assertEquals "python path equals to env A in A/1 with max depth 4"\
        "$env_a_python_path" "$(th_get_python_path)"
    pyvenv_deactivate || fail "deactivate env A"

    # Change directory to A/1/2
    cd -- "$TEST_ENVS_PIPENV/A/1/2" || fail "cd to env A/1/2"
    pyvenv_activate || fail "pyvenv_activate in env A/1/2 with max depth 4"
    assertEquals "python path equals to env A in A/1/2 with max depth 4"\
        "$env_a_python_path" "$(th_get_python_path)"
    pyvenv_deactivate || fail "deactivate env A"

    # Change directory to A/1/2/3
    cd -- "$TEST_ENVS_PIPENV/A/1/2/3" || fail "cd to env A/1/2/3"
    pyvenv_activate || fail "pyvenv_activate in env A/1/2/3 with max depth 4"
    assertEquals "python path equals to env A in A/1/2/3 with max depth 4"\
        "$env_a_python_path" "$(th_get_python_path)"
    pyvenv_deactivate || fail "deactivate env A"

    # Change directory to A/1/2/3/4
    cd -- "$TEST_ENVS_PIPENV/A/1/2/3/4" || fail "cd to env A/1/2/3/4"
    pyvenv_activate 2>/dev/null \
        && fail "pyvenv_activate in A/1/2/3/4 with max depth 4 should fail"

    export PIPENV_MAX_DEPTH=0

    # Change directory to A/1
    cd -- "$TEST_ENVS_PIPENV/A/1" || fail "cd to env A/1"
    pyvenv_activate 2>/dev/null \
        && fail "pyvenv_activate in A/1 with max depth 0 should fail"

    # Change directory to A/
    cd -- "$TEST_ENVS_PIPENV/A/" || fail "cd to env A/"
    pyvenv_activate || fail "pyvenv_activate in env A with max depth 0"
    assertEquals "python path equals to env A in A with max depth 0"\
        "$env_a_python_path" "$(th_get_python_path)"
    pyvenv_deactivate || fail "deactivate env A"

    unset PIPENV_MAX_DEPTH
    export PIPENV_NO_INHERIT=1

    # Change directory to A/1
    cd -- "$TEST_ENVS_PIPENV/A/1" || fail "cd to env A/1"
    pyvenv_activate 2>/dev/null \
        && fail "pyvenv_activate in A/1 with no inherit should fail"

    # Change directory to A/
    cd -- "$TEST_ENVS_PIPENV/A/" || fail "cd to env A/"
    pyvenv_activate || fail "pyvenv_activate in env A with no inherit"
    assertEquals "python path equals to env A in A with no inherit"\
        "$env_a_python_path" "$(th_get_python_path)"
    pyvenv_deactivate || fail "deactivate env A"

    unset PIPENV_NO_INHERIT

    # Change directory to C/1
    cd -- "$TEST_ENVS_PIPENV/C/1" || fail "cd to env C/1"
    pyvenv_activate || fail "pyvenv_activate in env C/1 with default max depth"
    env_c_python_path="$(th_get_python_path)"
    assertNotEquals "python path not equals to host in env C/1"\
        "$HOST_PYTHON_PATH" "$env_c_python_path"
    assertEquals "VAR A in env C/1" "$ENV_C_VAR_A" "$(th_get_env_var "VAR_A")"
    pyvenv_deactivate || fail "deactivate env C"

    export PIPENV_PIPFILE="$TEST_ENVS_PIPENV/C/Pipfile"

    # Change directory to A/1/2 with PIPENV_PIPFILE to env C
    cd -- "$TEST_ENVS_PIPENV/A/1/2" || fail "cd to env A/1/2"
    pyvenv_activate || fail "pyvenv_activate with PIPENV_PIPFILE to env C in A/1/2"
    assertEquals "pipenv path equals to env C with PIPENV_FILE to env C in A/1/2"\
        "$env_c_python_path" "$(th_get_python_path)"
    assertEquals "VAR A with PIPENV_FILE to env C in A/1/2" "$ENV_C_VAR_A"\
        "$(th_get_env_var "VAR_A")"
    pyvenv_deactivate || fail "deactivate env C"

    unset PIPENV_PIPFILE
}


th_register_test test_pyvenv_activate_poetry
test_pyvenv_activate_poetry() {
    # Check test environment is ok.
    assertEquals "check host env" "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Change directory to env A and check python path.
    cd -- "$TEST_ENVS_POETRY/A" || fail "cd to env A"
    pyvenv_activate || fail "pyvenv_activate in env A"
    env_a_python_path="$(th_get_python_path)"
    assertNotEquals "python path not equals to host in env A"\
        "$HOST_PYTHON_PATH" "$env_a_python_path"
    pyvenv_deactivate || fail "deactivate env A"

    # Check PIPENV_MAX_DEPTH has not effect with Poetry projects.
    export PIPENV_MAX_DEPTH=1
    cd -- "$TEST_ENVS_POETRY/A/1/2/3" || fail "cd to env A/1/2/3"
    pyvenv_activate || fail "pyvenv_activate in env A/1/2/3"
    assertEquals "PIPENV_MAX_DEPTH has not effect on poetry project env A"\
        "$env_a_python_path" "$(th_get_python_path)"
    pyvenv_deactivate || fail "deactivate env A"
    unset PIPENV_MAX_DEPTH

    # Check PIPENV_NO_INHERIT has not effect with Poetry projects.
    export PIPENV_NO_INHERIT=1
    cd -- "$TEST_ENVS_POETRY/A/1/2/3" || fail "cd to env A/1/2/3"
    pyvenv_activate || fail "pyvenv_activate in env A/1/2/3"
    assertEquals "PIPENV_NO_INHERIT has not effect on poetry project env A"\
        "$env_a_python_path" "$(th_get_python_path)"
    pyvenv_deactivate || fail "deactivate env A"
    unset PIPENV_NO_INHERIT
}


th_register_test test_pyvenv_activate_venv
test_pyvenv_activate_venv() {
    # Check test environment is ok.
    assertEquals "check host env" "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Change directory to env A and check python path.
    cd -- "$TEST_ENVS_VENV/A" || fail "cd to env A"
    th_pyvenv_setup_venv_file_path || fail "setup in env A"
    pyvenv_activate || fail "pyvenv_activate in env A"
    env_a_python_path="$(th_get_python_path)"
    assertNotEquals "python path not equals to host in env A"\
        "$HOST_PYTHON_PATH" "$env_a_python_path"
    pyvenv_deactivate || fail "deactivate env A"

    # Check PIPENV_MAX_DEPTH has not effect with virtualenv projects.
    export PIPENV_MAX_DEPTH=1
    cd -- "$TEST_ENVS_VENV/A/1/2/3" || fail "cd to env A/1/2/3"
    pyvenv_activate || fail "pyvenv_activate in env A/1/2/3"
    assertEquals "PIPENV_MAX_DEPTH has not effect on virtualenv project env A"\
        "$env_a_python_path" "$(th_get_python_path)"
    pyvenv_deactivate || fail "deactivate env A"
    unset PIPENV_MAX_DEPTH

    # Check PIPENV_NO_INHERIT has not effect with virtualenv projects.
    export PIPENV_NO_INHERIT=1
    cd -- "$TEST_ENVS_VENV/A/1/2/3" || fail "cd to env A/1/2/3"
    pyvenv_activate || fail "pyvenv_activate in env A/1/2/3"
    assertEquals "PIPENV_NO_INHERIT has not effect on virtualenv project env A"\
        "$env_a_python_path" "$(th_get_python_path)"
    pyvenv_deactivate || fail "deactivate env A"
    unset PIPENV_NO_INHERIT
}


th_register_auto_activate_tests test_pyvenv_auto_activate_pipenv
test_pyvenv_auto_activate_pipenv() {
    enable_cmd="$1"
    disable_cmd="$2"
    cd_cmd="$3"

    $enable_cmd || fail "enable auto activate"

    # Check test environment is ok.
    assertEquals "check host env" "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Change directory to env A and check python path.
    $cd_cmd -- "$TEST_ENVS_PIPENV/A" || fail "cd to env A"
    env_a_python_path="$(th_get_python_path)"
    assertNotEquals "python path not equals to host in env A after cd"\
        "$HOST_PYTHON_PATH" "$env_a_python_path"

    export PIPENV_MAX_DEPTH=2

    # Change directory to A/1.
    $cd_cmd -- "$TEST_ENVS_PIPENV/A/1" || fail "cd to env A/1"
    assertEquals "python path equals to env A in A/1 with max depth 2"\
        "$env_a_python_path" "$(th_get_python_path)"

    # Change directory to A/1/2
    $cd_cmd -- "$TEST_ENVS_PIPENV/A/1/2" || fail "cd to env A/1/2"
    assertEquals "python path equals to host in A/1 with max depth 2"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    export PIPENV_MAX_DEPTH=4

    # Change directory to A/1.
    $cd_cmd -- "$TEST_ENVS_PIPENV/A/1" || fail "cd to env A/1"
    assertEquals "python path equals to env A in A/1 with max depth 4"\
        "$env_a_python_path" "$(th_get_python_path)"

    # Change directory to A/1/2
    $cd_cmd -- "$TEST_ENVS_PIPENV/A/1/2" || fail "cd to env A/1/2"
    assertEquals "python path equals to env A in A/1/2 with max depth 4"\
        "$env_a_python_path" "$(th_get_python_path)"

    # Change directory to A/1/2/3
    $cd_cmd -- "$TEST_ENVS_PIPENV/A/1/2/3" || fail "cd to env A/1/2/3"
    assertEquals "python path equals to env A in A/1/2/3 with max depth 4"\
        "$env_a_python_path" "$(th_get_python_path)"

    # Change directory to A/1/2/3/4
    $cd_cmd -- "$TEST_ENVS_PIPENV/A/1/2/3/4" || fail "cd to env A/1/2/3/4"
    assertEquals "python path equals to host in A/1/2/3/4 with max depth 4"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    export PIPENV_MAX_DEPTH=0

    # Change directory to A/1.
    $cd_cmd -- "$TEST_ENVS_PIPENV/A/1" || fail "cd to env A/1"
    assertEquals "python path equals to host in A/1 with max depth 0"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Change directory to A/
    $cd_cmd -- "$TEST_ENVS_PIPENV/A/" || fail "cd to env A/"
    assertEquals "python path equals to env A in A/ with max depth 0"\
        "$env_a_python_path" "$(th_get_python_path)"

    unset PIPENV_MAX_DEPTH
    export PIPENV_NO_INHERIT=1

    # Change directory to A/1.
    $cd_cmd -- "$TEST_ENVS_PIPENV/A/1" || fail "cd to env A/1"
    assertEquals "python path equals to host in A/1 with no inherit"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Change directory to A/
    $cd_cmd -- "$TEST_ENVS_PIPENV/A/" || fail "cd to env A/"
    assertEquals "python path equals to env A in A/ with no inherit"\
        "$env_a_python_path" "$(th_get_python_path)"

    unset PIPENV_NO_INHERIT

    # Change directory to C/1
    $cd_cmd -- "$TEST_ENVS_PIPENV/C/1" || fail "cd to env C/1"
    env_c_python_path="$(th_get_python_path)"
    assertNotEquals "python path not equals to host in env C/1"\
        "$HOST_PYTHON_PATH" "$env_c_python_path"
    assertEquals "VAR A in env C/1" "$ENV_C_VAR_A" "$(th_get_env_var "VAR_A")"

    export PIPENV_PIPFILE="$TEST_ENVS_PIPENV/C/Pipfile"

    # Change directory to A/1/2 with PIPENV_PIPFILE to env C
    $cd_cmd -- "$TEST_ENVS_PIPENV/A/1/2" || fail "cd to env A/1/2"
    assertEquals "pipenv path equals to env C with PIPENV_FILE to env C in A/1/2"\
        "$env_c_python_path" "$(th_get_python_path)"
    assertEquals "VAR A with PIPENV_FILE to env C in A/1/2" "$ENV_C_VAR_A"\
        "$(th_get_env_var "VAR_A")"

    unset PIPENV_PIPFILE


    # Go back to envs tmpdir
    $cd_cmd -- "$TEST_ENVS_TMPDIR" || fail "cd to envs tmpdir"

    $disable_cmd || fail "disable auto activate"
}


th_register_auto_activate_tests test_pyvenv_auto_activate_poetry
test_pyvenv_auto_activate_poetry() {
    enable_cmd="$1"
    disable_cmd="$2"
    cd_cmd="$3"

    $enable_cmd || fail "enable auto activate"

    # Check test environment is ok.
    assertEquals "check host env" "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Change directory to env A and check python path.
    $cd_cmd -- "$TEST_ENVS_POETRY/A" || fail "cd to env A"
    env_a_python_path="$(th_get_python_path)"
    assertNotEquals "python path not equals to host in env A after cd"\
        "$HOST_PYTHON_PATH" "$env_a_python_path"

    # Check PIPENV_MAX_DEPTH has not effect with Poetry projects.
    export PIPENV_MAX_DEPTH=1
    $cd_cmd -- "$TEST_ENVS_POETRY/A/1/2/3" || fail "cd to env A/1/2/3"
    assertEquals "PIPENV_MAX_DEPTH has not effect on poetry project env A"\
        "$env_a_python_path" "$(th_get_python_path)"
    unset PIPENV_MAX_DEPTH

    # Check PIPENV_NO_INHERIT has not effect with Poetry projects.
    export PIPENV_NO_INHERIT=1
    $cd_cmd -- "$TEST_ENVS_POETRY/A/1/2/3" || fail "cd to env A/1/2/3"
    assertEquals "PIPENV_NO_INHERIT has not effect on poetry project env A"\
        "$env_a_python_path" "$(th_get_python_path)"
    unset PIPENV_NO_INHERIT

    # Go back to envs tmpdir
    $cd_cmd -- "$TEST_ENVS_TMPDIR" || fail "cd to envs tmpdir"

    $disable_cmd || fail "disable auto activate"
}


th_register_auto_activate_tests test_pyvenv_auto_activate_venv
test_pyvenv_auto_activate_venv() {
    enable_cmd="$1"
    disable_cmd="$2"
    cd_cmd="$3"

    th_pyvenv_setup_venv_file_path "$TEST_ENVS_VENV/A" || fail "setup in env A"

    $enable_cmd || fail "enable auto activate"

    # Check test environment is ok.
    assertEquals "check host env" "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Change directory to env A and check python path.
    $cd_cmd -- "$TEST_ENVS_VENV/A" || fail "cd to env A"
    env_a_python_path="$(th_get_python_path)"
    assertNotEquals "python path not equals to host in env A after cd"\
        "$HOST_PYTHON_PATH" "$env_a_python_path"

    # Check PIPENV_MAX_DEPTH has not effect with virtualenv projects.
    export PIPENV_MAX_DEPTH=1
    $cd_cmd -- "$TEST_ENVS_VENV/A/1/2/3" || fail "cd to env A/1/2/3"
    assertEquals "PIPENV_MAX_DEPTH has not effect on virtualenv project env A"\
        "$env_a_python_path" "$(th_get_python_path)"
    unset PIPENV_MAX_DEPTH

    # Check PIPENV_NO_INHERIT has not effect with virtualenv projects.
    export PIPENV_NO_INHERIT=1
    $cd_cmd -- "$TEST_ENVS_VENV/A/1/2/3" || fail "cd to env A/1/2/3"
    assertEquals "PIPENV_NO_INHERIT has not effect on virtualenv project env A"\
        "$env_a_python_path" "$(th_get_python_path)"
    unset PIPENV_NO_INHERIT

    # Go back to envs tmpdir
    $cd_cmd -- "$TEST_ENVS_TMPDIR" || fail "cd to envs tmpdir"

    $disable_cmd || fail "disable auto activate"
}


. "$TEST_DIR/shunit2/shunit2"
