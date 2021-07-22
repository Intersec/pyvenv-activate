#!/bin/sh
# Disable source following.
#   shellcheck disable=SC1090,SC1091


TEST_SCRIPT="$0"
TEST_DIR="$(dirname -- "$TEST_SCRIPT")"
. "$TEST_DIR/test_helpers"


th_register_test test_pipenv_run
test_pipenv_run() {
    # Check test environment is ok.
    assertEquals "check host env" "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Change directory to env A and check python path with `pipenv run`.
    cd -- "$TEST_ENVS_PIPENV/A" || fail "cd to env A"
    assertEquals "python path equals to host in env A without pipenv run"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    env_1_python_path="$(th_get_python_path 'pipenv run')"
    assertNotEquals "python path not equals to host in env A with pipenv run"\
        "$HOST_PYTHON_PATH" "$env_1_python_path"

    # Change directory to env B and check python path with `pipenv run`.
    cd -- "$TEST_ENVS_PIPENV/B" || fail "cd to env B"
    assertEquals "python path equals to host in env B without pipenv run"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    env_2_python_path="$(th_get_python_path 'pipenv run')"
    assertNotEquals "python path not equals to host in env B with pipenv run"\
        "$HOST_PYTHON_PATH" "$env_2_python_path"
    assertNotEquals "python path not equals to env A in env B with pipenv run"\
        "$env_1_python_path" "$env_2_python_path"
}


th_register_test test_poetry_run
test_poetry_run() {
    # Check test environment is ok.
    assertEquals "check host env" "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Change directory to env A and check python path with `poetry run`.
    cd -- "$TEST_ENVS_POETRY/A" || fail "cd to env A"
    assertEquals "python path equals to host in env A without poetry run"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    env_1_python_path="$(th_get_python_path 'poetry run')"
    assertNotEquals "python path not equals to host in env A with poetry run"\
        "$HOST_PYTHON_PATH" "$env_1_python_path"

    # Change directory to env B and check python path with `poetry run`.
    cd -- "$TEST_ENVS_POETRY/B" || fail "cd to env B"
    assertEquals "python path equals to host in env B without poetry run"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    env_2_python_path="$(th_get_python_path 'poetry run')"
    assertNotEquals "python path not equals to host in env B with poetry run"\
        "$HOST_PYTHON_PATH" "$env_2_python_path"
    assertNotEquals "python path not equals to env A in env B with poetry run"\
        "$env_1_python_path" "$env_2_python_path"
}


th_register_test test_venv_manual
test_venv_manual() {
    # Check test environment is ok.
    assertEquals "check host env" "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Activate env A and check python path.
    th_activate_venv "$TEST_ENVS_VENV/A" || fail "activate env A"
    env_1_python_path="$(th_get_python_path)"
    assertNotEquals "python path not equals to host in env A"\
        "$HOST_PYTHON_PATH" "$env_1_python_path"

    # Change directory to env B and check python path.
    th_activate_venv "$TEST_ENVS_VENV/B" || fail "activate env B"
    env_2_python_path="$(th_get_python_path)"
    assertNotEquals "python path not equals to host in env B"\
        "$HOST_PYTHON_PATH" "$env_2_python_path"
    assertNotEquals "python path not equals to env A in env B"\
        "$env_1_python_path" "$env_2_python_path"
}


th_register_test test_pyvenv_activate_pipenv
test_pyvenv_activate_pipenv() {
    # Check test environment is ok.
    assertEquals "check host env" "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Cannot activate non virtual environment with pyvenv_activate
    pyvenv_activate "$TEST_ENVS_PIPENV" 2>/dev/null \
        && fail "pyvenv_activate without valid virtualenv should fail"
    assertEquals "python path to host after pyvenv_activate without valid virtualenv"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Change directory to env A and check python path with `pyvenv_activate`.
    cd -- "$TEST_ENVS_PIPENV/A" || fail "cd to env A"
    assertEquals "python path equals to host in env A without pyvenv_activate"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    pyvenv_activate || fail "pyvenv_activate in env A"
    env_1_python_path="$(th_get_python_path)"
    assertNotEquals "python path not equals to host in env A with pyvenv_activate"\
        "$HOST_PYTHON_PATH" "$env_1_python_path"

    # Change directory to env B
    cd -- "$TEST_ENVS_PIPENV/B" || fail "cd to env B"

    # Since we have not yet deactivate the pyvenv environment of env A, we
    # should still get the python path of env A.
    assertEquals "python path equals to env A in env B without python_activate"\
        "$env_1_python_path" "$(th_get_python_path)"

    # Cannot activate env B while env A is still active.
    pyvenv_activate 2>/dev/null \
        && fail "pyvenv_activate in env B with env A still active should fail"
    assertEquals "python path to env A after invalid pyvenv_activate in env B"\
        "$env_1_python_path" "$(th_get_python_path)"

    # Deactivate the pyvenv environment of env A, we get the host python path.
    pyvenv_deactivate || fail "deactivate env A"
    assertEquals "python path equals to host after pyvenv_deactivate of env A"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Use `pyvenv_activate` in env B.
    pyvenv_activate || fail "pyvenv_activate in env B"

    # Check python path in env B with `pyvenv_activate`.
    env_2_python_path="$(th_get_python_path)"
    assertNotEquals "python path not equals to host in env B with pyvenv_activate"\
        "$HOST_PYTHON_PATH" "$env_2_python_path"
    assertNotEquals "python path not equals to env A in env B with pyvenv_activate"\
        "$env_1_python_path" "$env_2_python_path"

    # `pipenv run` should be a no operations when the pipenv environment is
    # already loaded with `pipenv_activate`.
    assertEquals "pipenv run no op in env B with pyvenv_activate"\
        "$env_2_python_path" "$(th_get_python_path 'pipenv run')"

    # Using `pyvenv_activate` twice in the same environment has no effects and
    # should not fail.
    pyvenv_activate || fail "pyvenv_activate twice should not fail"
    assertEquals "pyvenv_activate twice no op "\
        "$env_2_python_path" "$(th_get_python_path)"

    # Deactivate env B
    pyvenv_deactivate || fail "pyvenv_deactivate env B"

    # Using `pyvenv_deactivate` twice has no effect and should not fail.
    pyvenv_deactivate || fail "pyvenv_deactivate no op"

    # Check python path is the host one after pyvenv_deactivate.
    assertEquals "python path to host after pyvenv_deactivate"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"
}


th_register_test test_pyvenv_activate_poetry
test_pyvenv_activate_poetry() {
    # Check test environment is ok.
    assertEquals "check host env" "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Cannot activate non virtual environment with pyvenv_activate
    pyvenv_activate "$TEST_ENVS_POETRY" 2>/dev/null \
        && fail "pyvenv_activate without valid virtualenv should fail"
    assertEquals "python path to host after pyvenv_activate without valid virtualenv"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Change directory to env A and check python path with `pyvenv_activate`.
    cd -- "$TEST_ENVS_POETRY/A" || fail "cd to env A"
    assertEquals "python path equals to host in env A without pyvenv_activate"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    pyvenv_activate || fail "pyvenv_activate in env A"
    env_1_python_path="$(th_get_python_path)"
    assertNotEquals "python path not equals to host in env A with pyvenv_activate"\
        "$HOST_PYTHON_PATH" "$env_1_python_path"

    # Change directory to env B
    cd -- "$TEST_ENVS_POETRY/B" || fail "cd to env B"

    # Since we have not yet deactivate the pyvenv environment of env A, we
    # should still get the python path of env A.
    assertEquals "python path equals to env A in env B without python_activate"\
        "$env_1_python_path" "$(th_get_python_path)"

    # Cannot activate env B while env A is still active.
    pyvenv_activate 2>/dev/null \
        && fail "pyvenv_activate in env B with env A still active should fail"
    assertEquals "python path to env A after invalid pyvenv_activate in env B"\
        "$env_1_python_path" "$(th_get_python_path)"

    # Deactivate the pyvenv environment of env A, we get the host python path.
    pyvenv_deactivate || fail "deactivate env A"
    assertEquals "python path equals to host after pyvenv_deactivate of env A"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Use `pyvenv_activate` in env B.
    pyvenv_activate || fail "pyvenv_activate in env B"

    # Check python path in env B with `pyvenv_activate`.
    env_2_python_path="$(th_get_python_path)"
    assertNotEquals "python path not equals to host in env B with pyvenv_activate"\
        "$HOST_PYTHON_PATH" "$env_2_python_path"
    assertNotEquals "python path not equals to env A in env B with pyvenv_activate"\
        "$env_1_python_path" "$env_2_python_path"

    # `poetry run` should be a no operations when the poetry environment is
    # already loaded with `poetry_activate`.
    assertEquals "poetry run no op in env B with pyvenv_activate"\
        "$env_2_python_path" "$(th_get_python_path 'poetry run')"

    # Using `pyvenv_activate` twice in the same environment has no effects and
    # should not fail.
    pyvenv_activate || fail "pyvenv_activate twice should not fail"
    assertEquals "pyvenv_activate twice no op "\
        "$env_2_python_path" "$(th_get_python_path)"

    # Deactivate env B
    pyvenv_deactivate || fail "pyvenv_deactivate env B"

    # Using `pyvenv_deactivate` twice has no effect and should not fail.
    pyvenv_deactivate || fail "pyvenv_deactivate no op"

    # Check python path is the host one after pyvenv_deactivate.
    assertEquals "python path to host after pyvenv_deactivate"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"
}


th_register_test test_pyvenv_activate_venv
test_pyvenv_activate_venv() {
    th_pyvenv_setup_venv_file_path "$TEST_ENVS_VENV/A" || fail "setup in env A"
    th_pyvenv_setup_venv_file_path "$TEST_ENVS_VENV/B" || fail "setup in env B"

    # Check test environment is ok.
    assertEquals "check host env" "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Cannot activate non virtual environment with pyvenv_activate
    pyvenv_activate "$TEST_ENVS_VENV" 2>/dev/null \
        && fail "pyvenv_activate without valid virtualenv should fail"
    assertEquals "python path to host after pyvenv_activate without valid virtualenv"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Change directory to env A and check python path with `pyvenv_activate`.
    cd -- "$TEST_ENVS_VENV/A" || fail "cd to env A"
    assertEquals "python path equals to host in env A without pyvenv_activate"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    pyvenv_activate || fail "pyvenv_activate in env A"
    env_1_python_path="$(th_get_python_path)"
    assertNotEquals "python path not equals to host in env A with pyvenv_activate"\
        "$HOST_PYTHON_PATH" "$env_1_python_path"

    # Change directory to env B
    cd -- "$TEST_ENVS_VENV/B" || fail "cd to env B"

    # Since we have not yet deactivate the pyvenv environment of env A, we
    # should still get the python path of env A.
    assertEquals "python path equals to env A in env B without python_activate"\
        "$env_1_python_path" "$(th_get_python_path)"

    # Cannot activate env B while env A is still active.
    pyvenv_activate 2>/dev/null \
        && fail "pyvenv_activate in env B with env A still active should fail"
    assertEquals "python path to env A after invalid pyvenv_activate in env B"\
        "$env_1_python_path" "$(th_get_python_path)"

    # Deactivate the pyvenv environment of env A, we get the host python path.
    pyvenv_deactivate || fail "deactivate env A"
    assertEquals "python path equals to host after pyvenv_deactivate of env A"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Use `pyvenv_activate` in env B.
    pyvenv_activate || fail "pyvenv_activate in env B"

    # Check python path in env B with `pyvenv_activate`.
    env_2_python_path="$(th_get_python_path)"
    assertNotEquals "python path not equals to host in env B with pyvenv_activate"\
        "$HOST_PYTHON_PATH" "$env_2_python_path"
    assertNotEquals "python path not equals to env A in env B with pyvenv_activate"\
        "$env_1_python_path" "$env_2_python_path"

    # Using `pyvenv_activate` twice in the same environment has no effects and
    # should not fail.
    pyvenv_activate || fail "pyvenv_activate twice should not fail"
    assertEquals "pyvenv_activate twice no op "\
        "$env_2_python_path" "$(th_get_python_path)"

    # Deactivate env B
    pyvenv_deactivate || fail "pyvenv_deactivate env B"

    # Using `pyvenv_deactivate` twice has no effect and should not fail.
    pyvenv_deactivate || fail "pyvenv_deactivate no op"

    # Check python path is the host one after pyvenv_deactivate.
    assertEquals "python path to host after pyvenv_deactivate"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"
}


th_register_auto_activate_tests test_pyvenv_auto_activate_pipenv
test_pyvenv_auto_activate_pipenv() {
    enable_cmd="$1"
    disable_cmd="$2"
    cd_cmd="$3"

    $enable_cmd || fail "enable auto activate"

    # Check test environment is ok.
    assertEquals "check host env" "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Change directory to envs tmpdir does nothing.
    $cd_cmd -- "$TEST_ENVS_PIPENV" || fail "cd to envs tmpdir"
    assertEquals "python path equals to host in envs tmpdir after cd"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Change directory to env A and check python path.
    $cd_cmd -- "$TEST_ENVS_PIPENV/A" || fail "cd to env A"
    env_1_python_path="$(th_get_python_path)"
    assertNotEquals "python path not equals to host in env A after cd"\
        "$HOST_PYTHON_PATH" "$env_1_python_path"

    # Change directory to envs tmpdir and check python path.
    $cd_cmd -- "$TEST_ENVS_PIPENV" || fail "cd to envs tmpdir"
    assertEquals "python path equals to host in envs tmpdir after cd"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Change directory to env B and check python path.
    $cd_cmd -- "$TEST_ENVS_PIPENV/B" || fail "cd to env B"
    env_2_python_path="$(th_get_python_path)"
    assertNotEquals "python path not equals to host in env B after cd"\
        "$HOST_PYTHON_PATH" "$env_2_python_path"
    assertNotEquals "python path not equals to env A in env B after cd"\
        "$env_1_python_path" "$env_2_python_path"

    # Get back to env A directly and check python path.
    $cd_cmd -- "$TEST_ENVS_PIPENV/A" || fail "cd to env A"
    assertEquals "python path equals to env A back from env B after cd"\
        "$(th_get_python_path)" "$env_1_python_path"

    # Change directory to envs tmpdir and check python path.
    $cd_cmd -- "$TEST_ENVS_PIPENV" || fail "cd to envs tmpdir"
    assertEquals "python path equals to host in envs tmpdir after cd"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    $disable_cmd || fail "disable auto activate"

    # Change directory in env A and check python path.
    $cd_cmd -- "$TEST_ENVS_PIPENV/A" || fail "cd to env A"
    assertEquals "python path equals to host in env A after cd"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

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

    # Change directory to envs tmpdir does nothing.
    $cd_cmd -- "$TEST_ENVS_POETRY" || fail "cd to envs tmpdir"
    assertEquals "python path equals to host in envs tmpdir after cd"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Change directory to env A and check python path.
    $cd_cmd -- "$TEST_ENVS_POETRY/A" || fail "cd to env A"
    env_1_python_path="$(th_get_python_path)"
    assertNotEquals "python path not equals to host in env A after cd"\
        "$HOST_PYTHON_PATH" "$env_1_python_path"

    # Change directory to envs tmpdir and check python path.
    $cd_cmd -- "$TEST_ENVS_POETRY" || fail "cd to envs tmpdir"
    assertEquals "python path equals to host in envs tmpdir after cd"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Change directory to env B and check python path.
    $cd_cmd -- "$TEST_ENVS_POETRY/B" || fail "cd to env B"
    env_2_python_path="$(th_get_python_path)"
    assertNotEquals "python path not equals to host in env B after cd"\
        "$HOST_PYTHON_PATH" "$env_2_python_path"
    assertNotEquals "python path not equals to env A in env B after cd"\
        "$env_1_python_path" "$env_2_python_path"

    # Get back to env A directly and check python path.
    $cd_cmd -- "$TEST_ENVS_POETRY/A" || fail "cd to env A"
    assertEquals "python path equals to env A back from env B after cd"\
        "$(th_get_python_path)" "$env_1_python_path"

    # Change directory to envs tmpdir and check python path.
    $cd_cmd -- "$TEST_ENVS_POETRY" || fail "cd to envs tmpdir"
    assertEquals "python path equals to host in envs tmpdir after cd"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    $disable_cmd || fail "disable auto activate"

    # Change directory in env A and check python path.
    $cd_cmd -- "$TEST_ENVS_POETRY/A" || fail "cd to env A"
    assertEquals "python path equals to host in env A after cd"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

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
    th_pyvenv_setup_venv_file_path "$TEST_ENVS_VENV/B" || fail "setup in env B"

    $enable_cmd || fail "enable auto activate"

    # Check test environment is ok.
    assertEquals "check host env" "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Change directory to envs tmpdir does nothing.
    $cd_cmd -- "$TEST_ENVS_VENV" || fail "cd to envs tmpdir"
    assertEquals "python path equals to host in envs tmpdir after cd"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Change directory to env A and check python path.
    $cd_cmd -- "$TEST_ENVS_VENV/A" || fail "cd to env A"
    env_1_python_path="$(th_get_python_path)"
    assertNotEquals "python path not equals to host in env A after cd"\
        "$HOST_PYTHON_PATH" "$env_1_python_path"

    # Change directory to envs tmpdir and check python path.
    $cd_cmd -- "$TEST_ENVS_VENV" || fail "cd to envs tmpdir"
    assertEquals "python path equals to host in envs tmpdir after cd"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Change directory to env B and check python path.
    $cd_cmd -- "$TEST_ENVS_VENV/B" || fail "cd to env B"
    env_2_python_path="$(th_get_python_path)"
    assertNotEquals "python path not equals to host in env B after cd"\
        "$HOST_PYTHON_PATH" "$env_2_python_path"
    assertNotEquals "python path not equals to env A in env B after cd"\
        "$env_1_python_path" "$env_2_python_path"

    # Get back to env A directly and check python path.
    $cd_cmd -- "$TEST_ENVS_VENV/A" || fail "cd to env A"
    assertEquals "python path equals to env A back from env B after cd"\
        "$(th_get_python_path)" "$env_1_python_path"

    # Change directory to envs tmpdir and check python path.
    $cd_cmd -- "$TEST_ENVS_VENV" || fail "cd to envs tmpdir"
    assertEquals "python path equals to host in envs tmpdir after cd"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    $disable_cmd || fail "disable auto activate"

    # Change directory in env A and check python path.
    $cd_cmd -- "$TEST_ENVS_VENV/A" || fail "cd to env A"
    assertEquals "python path equals to host in env A after cd"\
        "$HOST_PYTHON_PATH" "$(th_get_python_path)"

    # Go back to envs tmpdir
    $cd_cmd -- "$TEST_ENVS_TMPDIR" || fail "cd to envs tmpdir"

    $disable_cmd || fail "disable auto activate"
}


. "$TEST_DIR/shunit2/shunit2"
