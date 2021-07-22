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
    py_path="$(th_get_python_path "$1")"

    $py_path <<EOF
try:
    import six
except ImportError:
    print("None")
else:
    print(six.__version__)
EOF
}


th_register_test test_pipenv_run
test_pipenv_run() {
    # Change directory to env A and check six version.
    cd -- "$TEST_ENVS_PIPENV/A" || fail "cd to env A"
    assertEquals "six version in env A" "$ENV_1_SIX_VERSION" \
        "$(get_six_version 'pipenv run')"

    # Change directory to env B and check six version.
    cd -- "$TEST_ENVS_PIPENV/B" || fail "cd to env B"
    assertEquals "six version in env B" "$ENV_2_SIX_VERSION" \
        "$(get_six_version 'pipenv run')"
}


th_register_test test_poetry_run
test_poetry_run() {
    # Change directory to env A and check six version.
    cd -- "$TEST_ENVS_POETRY/A" || fail "cd to env A"
    assertEquals "six version in env A" "$ENV_1_SIX_VERSION" \
        "$(get_six_version 'poetry run')"

    # Change directory to env B and check six version.
    cd -- "$TEST_ENVS_POETRY/B" || fail "cd to env B"
    assertEquals "six version in env B" "$ENV_2_SIX_VERSION" \
        "$(get_six_version 'poetry run')"
}


th_register_test test_manual_venv
test_manual_venv() {
    # Activate env A and check six version.
    th_activate_venv "$TEST_ENVS_VENV/A" || fail "activate env A"
    assertEquals "six version in env A" "$ENV_1_SIX_VERSION" \
        "$(get_six_version)"

    # Activate env B and check six version.
    th_activate_venv "$TEST_ENVS_VENV/B" || fail "activate env B"
    assertEquals "six version in env B" "$ENV_2_SIX_VERSION" \
        "$(get_six_version)"
}


th_register_test test_pyvenv_activate_pipenv
test_pyvenv_activate_pipenv() {
    # Change directory to env A and check six version.
    cd -- "$TEST_ENVS_PIPENV/A" || fail "cd to env A"
    pyvenv_activate || fail "pyvenv_activate in env A"
    assertEquals "six version in env A" "$ENV_1_SIX_VERSION" \
        "$(get_six_version)"
    pyvenv_deactivate || fail "deactivate env A"

    # Change directory to env B and check six version.
    cd -- "$TEST_ENVS_PIPENV/B" || fail "cd to env B"
    pyvenv_activate || fail "pyvenv_activate in env B"
    assertEquals "six version in env B" "$ENV_2_SIX_VERSION" \
        "$(get_six_version)"
    pyvenv_deactivate || fail "deactivate env B"
}


th_register_test test_pyvenv_activate_poetry
test_pyvenv_activate_poetry() {
    # Change directory to env A and check six version.
    cd -- "$TEST_ENVS_POETRY/A" || fail "cd to env A"
    pyvenv_activate || fail "pyvenv_activate in env A"
    assertEquals "six version in env A" "$ENV_1_SIX_VERSION" \
        "$(get_six_version)"
    pyvenv_deactivate || fail "deactivate env A"

    # Change directory to env B and check six version.
    cd -- "$TEST_ENVS_POETRY/B" || fail "cd to env B"
    pyvenv_activate || fail "pyvenv_activate in env B"
    assertEquals "six version in env B" "$ENV_2_SIX_VERSION" \
        "$(get_six_version)"
    pyvenv_deactivate || fail "deactivate env B"
}


th_register_test test_pyvenv_activate_venv
test_pyvenv_activate_venv() {
    # Change directory to env A and check six version.
    cd -- "$TEST_ENVS_VENV/A" || fail "cd to env A"
    th_pyvenv_setup_venv_file_path || fail "setup in env A"
    pyvenv_activate || fail "pyvenv_activate in env A"
    assertEquals "six version in env A" "$ENV_1_SIX_VERSION" \
        "$(get_six_version)"
    pyvenv_deactivate || fail "deactivate env A"

    # Change directory to env B and check six version.
    cd -- "$TEST_ENVS_VENV/B" || fail "cd to env B"
    th_pyvenv_setup_venv_file_path || fail "setup in env B"
    pyvenv_activate || fail "pyvenv_activate in env B"
    assertEquals "six version in env B" "$ENV_2_SIX_VERSION" \
        "$(get_six_version)"
    pyvenv_deactivate || fail "deactivate env B"
}


th_register_auto_activate_tests test_pyvenv_auto_activate_pipenv
test_pyvenv_auto_activate_pipenv() {
    enable_cmd="$1"
    disable_cmd="$2"
    cd_cmd="$3"

    $enable_cmd || fail "enable auto activate"

    # Change directory to env A and check six version.
    $cd_cmd -- "$TEST_ENVS_PIPENV/A" || fail "cd to env A"
    assertEquals "six version in env A" "$ENV_1_SIX_VERSION" \
        "$(get_six_version)"

    # Change directory to env B and check six version.
    $cd_cmd -- "$TEST_ENVS_PIPENV/B" || fail "cd to env B"
    assertEquals "six version in env B" "$ENV_2_SIX_VERSION" \
        "$(get_six_version)"

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

    # Change directory to env A and check six version.
    $cd_cmd -- "$TEST_ENVS_POETRY/A" || fail "cd to env A"
    assertEquals "six version in env A" "$ENV_1_SIX_VERSION" \
        "$(get_six_version)"

    # Change directory to env B and check six version.
    $cd_cmd -- "$TEST_ENVS_POETRY/B" || fail "cd to env B"
    assertEquals "six version in env B" "$ENV_2_SIX_VERSION" \
        "$(get_six_version)"

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
    th_pyvenv_setup_venv_file_path "$TEST_ENVS_VENV/B" || fail "setup in env A"

    $enable_cmd || fail "enable auto activate"

    # Change directory to env A and check six version.
    $cd_cmd -- "$TEST_ENVS_VENV/A" || fail "cd to env A"
    assertEquals "six version in env A" "$ENV_1_SIX_VERSION" \
        "$(get_six_version)"

    # Change directory to env B and check six version.
    $cd_cmd -- "$TEST_ENVS_VENV/B" || fail "cd to env B"
    assertEquals "six version in env B" "$ENV_2_SIX_VERSION" \
        "$(get_six_version)"

    # Go back to envs tmpdir
    $cd_cmd -- "$TEST_ENVS_TMPDIR" || fail "cd to envs tmpdir"

    $disable_cmd || fail "disable auto activate"
}


. "$TEST_DIR/shunit2/shunit2"
