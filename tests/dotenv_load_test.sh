#!/bin/sh
# Disable source following.
#   shellcheck disable=SC1090,SC1091
# Disable optional arguments.
#   shellcheck disable=SC2120


TEST_SCRIPT="$0"
TEST_DIR="$(dirname -- "$TEST_SCRIPT")"
. "$TEST_DIR/test_helpers"


ENV_C_VAR_A="foo"
ENV_C_VAR_B="bar"
ENV_C_VAR_C=""
ENV_C_VAR_D=""
ENV_C_VAR_E="toto\\'\"
titi	"
ENV_C_VAR_F="plop\\'\"
plip"
ENV_C_VAR_G="plup\\'\"
plap"

TEST_VAR_F="foo\\'\"
bar"
TEST_VAR_G="toto\\'\"
tata"


setUp() {
    th_setUp || return 1
    VAR_F="$TEST_VAR_F"
    export VAR_G="$TEST_VAR_G"
}


test_pipenv_run() {
    # Change directory to env C and check dotenv variables.
    cd -- "$TEST_ENVS_PIPENV/C" || fail "cd to env C"
    assertEquals "VAR A in env C" "$ENV_C_VAR_A" "$(th_get_env_var "VAR_A" 'pipenv run')"
    assertEquals "VAR B in env C" "$ENV_C_VAR_B" "$(th_get_env_var "VAR_B" 'pipenv run')"
    assertEquals "VAR C in env C" "$ENV_C_VAR_C" "$(th_get_env_var "VAR_C" 'pipenv run')"
    assertEquals "VAR D in env C" "$ENV_C_VAR_D" "$(th_get_env_var "VAR_D" 'pipenv run')"
    assertEquals "VAR E in env C" "$ENV_C_VAR_E" "$(th_get_env_var "VAR_E" 'pipenv run')"
    assertEquals "VAR F in env C" "$ENV_C_VAR_F" "$(th_get_env_var "VAR_F" 'pipenv run')"
    assertEquals "VAR G in env C" "$ENV_C_VAR_G" "$(th_get_env_var "VAR_G" 'pipenv run')"
    assertEquals "VAR F in shell env" "$TEST_VAR_F" "$VAR_F"
    assertEquals "VAR G in shell env" "$TEST_VAR_G" "$VAR_G"

    # Change directory to env B and check dotenv variables.
    cd -- "$TEST_ENVS_PIPENV/B" || fail "cd to env B"
    assertNull "VAR A in env B" "$(th_get_env_var "VAR_A" 'pipenv run')"
    assertNull "VAR B in env B" "$(th_get_env_var "VAR_B" 'pipenv run')"
    assertNull "VAR C in env B" "$(th_get_env_var "VAR_C" 'pipenv run')"
    assertNull "VAR D in env B" "$(th_get_env_var "VAR_D" 'pipenv run')"
    assertNull "VAR E in env B" "$(th_get_env_var "VAR_E" 'pipenv run')"
    assertNull "VAR F in env B" "$(th_get_env_var "VAR_F" 'pipenv run')"
    assertEquals "VAR G in env B" "$TEST_VAR_G" "$(th_get_env_var "VAR_G" 'pipenv run')"
    assertEquals "VAR F in shell env" "$TEST_VAR_F" "$VAR_F"
    assertEquals "VAR G in shell env" "$TEST_VAR_G" "$VAR_G"
}


test_poetry_run() {
    # Change directory to env C and check dotenv variables.
    # Poetry should not load .env file.
    cd -- "$TEST_ENVS_POETRY/C" || fail "cd to env C"
    assertNull "VAR A in env C" "$(th_get_env_var "VAR_A" 'poetry run')"
    assertNull "VAR B in env C" "$(th_get_env_var "VAR_B" 'poetry run')"
    assertNull "VAR C in env C" "$(th_get_env_var "VAR_C" 'poetry run')"
    assertNull "VAR D in env C" "$(th_get_env_var "VAR_D" 'poetry run')"
    assertNull "VAR E in env C" "$(th_get_env_var "VAR_E" 'poetry run')"
    assertNull "VAR F in env C" "$(th_get_env_var "VAR_F" 'poetry run')"
    assertEquals "VAR G in env C" "$TEST_VAR_G" "$(th_get_env_var "VAR_G" 'poetry run')"
    assertEquals "VAR F in shell env" "$TEST_VAR_F" "$VAR_F"
    assertEquals "VAR G in shell env" "$TEST_VAR_G" "$VAR_G"

    # Change directory to env B and check dotenv variables.
    cd -- "$TEST_ENVS_POETRY/B" || fail "cd to env B"
    assertNull "VAR A in env B" "$(th_get_env_var "VAR_A" 'poetry run')"
    assertNull "VAR B in env B" "$(th_get_env_var "VAR_B" 'poetry run')"
    assertNull "VAR C in env B" "$(th_get_env_var "VAR_C" 'poetry run')"
    assertNull "VAR D in env B" "$(th_get_env_var "VAR_D" 'poetry run')"
    assertNull "VAR E in env B" "$(th_get_env_var "VAR_E" 'poetry run')"
    assertNull "VAR F in env B" "$(th_get_env_var "VAR_F" 'poetry run')"
    assertEquals "VAR G in env B" "$TEST_VAR_G" "$(th_get_env_var "VAR_G" 'poetry run')"
    assertEquals "VAR F in shell env" "$TEST_VAR_F" "$VAR_F"
    assertEquals "VAR G in shell env" "$TEST_VAR_G" "$VAR_G"
}


test_venv_manual() {
    # Activate env C and check dotenv variables.
    # virtualenv should not load .env file.
    th_activate_venv "$TEST_ENVS_VENV/C" || fail "activate env C"
    assertNull "VAR A in env C" "$(th_get_env_var "VAR_A")"
    assertNull "VAR B in env C" "$(th_get_env_var "VAR_B")"
    assertNull "VAR C in env C" "$(th_get_env_var "VAR_C")"
    assertNull "VAR D in env C" "$(th_get_env_var "VAR_D")"
    assertNull "VAR E in env C" "$(th_get_env_var "VAR_E")"
    assertNull "VAR F in env C" "$(th_get_env_var "VAR_F")"
    assertEquals "VAR G in env C" "$TEST_VAR_G" "$(th_get_env_var "VAR_G")"
    assertEquals "VAR F in shell env" "$TEST_VAR_F" "$VAR_F"
    assertEquals "VAR G in shell env" "$TEST_VAR_G" "$VAR_G"

    # Activate env B and check dotenv variables.
    th_activate_venv "$TEST_ENVS_VENV/B" || fail "activate env B"
    assertNull "VAR A in env B" "$(th_get_env_var "VAR_A")"
    assertNull "VAR B in env B" "$(th_get_env_var "VAR_B")"
    assertNull "VAR C in env B" "$(th_get_env_var "VAR_C")"
    assertNull "VAR D in env B" "$(th_get_env_var "VAR_D")"
    assertNull "VAR E in env B" "$(th_get_env_var "VAR_E")"
    assertNull "VAR F in env B" "$(th_get_env_var "VAR_F")"
    assertEquals "VAR G in env B" "$TEST_VAR_G" "$(th_get_env_var "VAR_G")"
    assertEquals "VAR F in shell env" "$TEST_VAR_F" "$VAR_F"
    assertEquals "VAR G in shell env" "$TEST_VAR_G" "$VAR_G"
}


test_pyvenv_activate_pipenv() {
    # Change directory to env C and check dotenv variables.
    cd -- "$TEST_ENVS_PIPENV/C" || fail "cd to env C"
    pyvenv_activate || fail "pyvenv_activate in env C"
    assertEquals "VAR A in env C" "$ENV_C_VAR_A" "$(th_get_env_var "VAR_A")"
    assertEquals "VAR B in env C" "$ENV_C_VAR_B" "$(th_get_env_var "VAR_B")"
    assertEquals "VAR C in env C" "$ENV_C_VAR_C" "$(th_get_env_var "VAR_C")"
    assertEquals "VAR D in env C" "$ENV_C_VAR_D" "$(th_get_env_var "VAR_D")"
    assertEquals "VAR E in env C" "$ENV_C_VAR_E" "$(th_get_env_var "VAR_E")"
    assertEquals "VAR F in env C" "$ENV_C_VAR_F" "$(th_get_env_var "VAR_F")"
    assertEquals "VAR G in env C" "$ENV_C_VAR_G" "$(th_get_env_var "VAR_G")"
    assertEquals "VAR F in shell env" "$ENV_C_VAR_F" "$VAR_F"
    assertEquals "VAR G in shell env" "$ENV_C_VAR_G" "$VAR_G"
    pyvenv_deactivate || fail "pyvenv_deactivate env C"

    # Change directory to env B and check dotenv variables.
    cd -- "$TEST_ENVS_PIPENV/B" || fail "cd to env B"
    pyvenv_activate || fail "pyvenv_activate in env B"
    assertNull "VAR A in env B" "$(th_get_env_var "VAR_A")"
    assertNull "VAR B in env B" "$(th_get_env_var "VAR_B")"
    assertNull "VAR C in env B" "$(th_get_env_var "VAR_C")"
    assertNull "VAR D in env B" "$(th_get_env_var "VAR_D")"
    assertNull "VAR E in env B" "$(th_get_env_var "VAR_E")"
    assertNull "VAR F in env B" "$(th_get_env_var "VAR_F")"
    assertEquals "VAR G in env B" "$TEST_VAR_G" "$(th_get_env_var "VAR_G")"
    assertEquals "VAR F in shell env" "$TEST_VAR_F" "$VAR_F"
    assertEquals "VAR G in shell env" "$TEST_VAR_G" "$VAR_G"
    pyvenv_deactivate || fail "pyvenv_deactivate env B"
}


test_pyvenv_activate_poetry() {
    # Change directory to env C and check dotenv variables.
    # Poetry should not load .env file.
    cd -- "$TEST_ENVS_POETRY/C" || fail "cd to env C"
    pyvenv_activate || fail "pyvenv_activate in env C"
    assertNull "VAR A in env C" "$(th_get_env_var "VAR_A")"
    assertNull "VAR B in env C" "$(th_get_env_var "VAR_B")"
    assertNull "VAR C in env C" "$(th_get_env_var "VAR_C")"
    assertNull "VAR D in env C" "$(th_get_env_var "VAR_D")"
    assertNull "VAR E in env C" "$(th_get_env_var "VAR_E")"
    assertNull "VAR F in env C" "$(th_get_env_var "VAR_F")"
    assertEquals "VAR G in env C" "$TEST_VAR_G" "$(th_get_env_var "VAR_G")"
    assertEquals "VAR F in shell env" "$TEST_VAR_F" "$VAR_F"
    assertEquals "VAR G in shell env" "$TEST_VAR_G" "$VAR_G"
    pyvenv_deactivate || fail "pyvenv_deactivate env C"

    # Change directory to env B and check dotenv variables.
    cd -- "$TEST_ENVS_POETRY/B" || fail "cd to env B"
    pyvenv_activate || fail "pyvenv_activate in env B"
    assertNull "VAR A in env B" "$(th_get_env_var "VAR_A")"
    assertNull "VAR B in env B" "$(th_get_env_var "VAR_B")"
    assertNull "VAR C in env B" "$(th_get_env_var "VAR_C")"
    assertNull "VAR D in env B" "$(th_get_env_var "VAR_D")"
    assertNull "VAR E in env B" "$(th_get_env_var "VAR_E")"
    assertNull "VAR F in env B" "$(th_get_env_var "VAR_F")"
    assertEquals "VAR G in env B" "$TEST_VAR_G" "$(th_get_env_var "VAR_G")"
    assertEquals "VAR F in shell env" "$TEST_VAR_F" "$VAR_F"
    assertEquals "VAR G in shell env" "$TEST_VAR_G" "$VAR_G"
    pyvenv_deactivate || fail "pyvenv_deactivate env B"
}


test_pyvenv_activate_venv() {
    # Change directory to env C and check dotenv variables.
    # virtualenv should not load .env file.
    cd -- "$TEST_ENVS_VENV/C" || fail "cd to env C"
    th_pyvenv_setup_venv || fail "setup in env C"
    pyvenv_activate || fail "pyvenv_activate in env C"
    assertNull "VAR A in env C" "$(th_get_env_var "VAR_A")"
    assertNull "VAR B in env C" "$(th_get_env_var "VAR_B")"
    assertNull "VAR C in env C" "$(th_get_env_var "VAR_C")"
    assertNull "VAR D in env C" "$(th_get_env_var "VAR_D")"
    assertNull "VAR E in env C" "$(th_get_env_var "VAR_E")"
    assertNull "VAR F in env C" "$(th_get_env_var "VAR_F")"
    assertEquals "VAR G in env C" "$TEST_VAR_G" "$(th_get_env_var "VAR_G")"
    assertEquals "VAR F in shell env" "$TEST_VAR_F" "$VAR_F"
    assertEquals "VAR G in shell env" "$TEST_VAR_G" "$VAR_G"
    pyvenv_deactivate || fail "pyvenv_deactivate env C"

    # Change directory to env B and check dotenv variables.
    cd -- "$TEST_ENVS_VENV/B" || fail "cd to env B"
    th_pyvenv_setup_venv || fail "setup in env B"
    pyvenv_activate || fail "pyvenv_activate in env B"
    assertNull "VAR A in env B" "$(th_get_env_var "VAR_A")"
    assertNull "VAR B in env B" "$(th_get_env_var "VAR_B")"
    assertNull "VAR C in env B" "$(th_get_env_var "VAR_C")"
    assertNull "VAR D in env B" "$(th_get_env_var "VAR_D")"
    assertNull "VAR E in env B" "$(th_get_env_var "VAR_E")"
    assertNull "VAR F in env B" "$(th_get_env_var "VAR_F")"
    assertEquals "VAR G in env B" "$TEST_VAR_G" "$(th_get_env_var "VAR_G")"
    assertEquals "VAR F in shell env" "$TEST_VAR_F" "$VAR_F"
    assertEquals "VAR G in shell env" "$TEST_VAR_G" "$VAR_G"
    pyvenv_deactivate || fail "pyvenv_deactivate env B"
}


th_test_pyvenv_auto_activate_pipenv() {
    enable_cmd="$1"
    disable_cmd="$2"
    cd_cmd="$3"

    $enable_cmd || fail "enable auto activate"

    # Change directory to env C and check dotenv variables.
    $cd_cmd -- "$TEST_ENVS_PIPENV/C" || fail "cd to env C"
    assertEquals "VAR A in env C" "$ENV_C_VAR_A" "$(th_get_env_var "VAR_A")"
    assertEquals "VAR B in env C" "$ENV_C_VAR_B" "$(th_get_env_var "VAR_B")"
    assertEquals "VAR C in env C" "$ENV_C_VAR_C" "$(th_get_env_var "VAR_C")"
    assertEquals "VAR D in env C" "$ENV_C_VAR_D" "$(th_get_env_var "VAR_D")"
    assertEquals "VAR E in env C" "$ENV_C_VAR_E" "$(th_get_env_var "VAR_E")"
    assertEquals "VAR F in env C" "$ENV_C_VAR_F" "$(th_get_env_var "VAR_F")"
    assertEquals "VAR G in env C" "$ENV_C_VAR_G" "$(th_get_env_var "VAR_G")"
    assertEquals "VAR F in shell env" "$ENV_C_VAR_F" "$VAR_F"
    assertEquals "VAR G in shell env" "$ENV_C_VAR_G" "$VAR_G"

    # Change directory to env B and check dotenv variables.
    $cd_cmd -- "$TEST_ENVS_PIPENV/B" || fail "cd to env B"
    assertNull "VAR A in env B" "$(th_get_env_var "VAR_A")"
    assertNull "VAR B in env B" "$(th_get_env_var "VAR_B")"
    assertNull "VAR C in env B" "$(th_get_env_var "VAR_C")"
    assertNull "VAR D in env B" "$(th_get_env_var "VAR_D")"
    assertNull "VAR E in env B" "$(th_get_env_var "VAR_E")"
    assertNull "VAR F in env B" "$(th_get_env_var "VAR_F")"
    assertEquals "VAR G in env B" "$TEST_VAR_G" "$(th_get_env_var "VAR_G")"
    assertEquals "VAR F in shell env" "$TEST_VAR_F" "$VAR_F"
    assertEquals "VAR G in shell env" "$TEST_VAR_G" "$VAR_G"

    # Go back to envs tmpdir
    $cd_cmd -- "$TEST_ENVS_TMPDIR" || fail "cd to envs tmpdir"

    $disable_cmd || fail "disable auto activate"
}


th_test_pyvenv_auto_activate_poetry() {
    enable_cmd="$1"
    disable_cmd="$2"
    cd_cmd="$3"

    $enable_cmd || fail "enable auto activate"

    # Change directory to env C and check dotenv variables.
    # Poetry should not load .env file.
    $cd_cmd -- "$TEST_ENVS_POETRY/C" || fail "cd to env C"
    assertNull "VAR A in env C" "$(th_get_env_var "VAR_A")"
    assertNull "VAR B in env C" "$(th_get_env_var "VAR_B")"
    assertNull "VAR C in env C" "$(th_get_env_var "VAR_C")"
    assertNull "VAR D in env C" "$(th_get_env_var "VAR_D")"
    assertNull "VAR E in env C" "$(th_get_env_var "VAR_E")"
    assertNull "VAR F in env C" "$(th_get_env_var "VAR_F")"
    assertEquals "VAR G in env C" "$TEST_VAR_G" "$(th_get_env_var "VAR_G")"
    assertEquals "VAR F in shell env" "$TEST_VAR_F" "$VAR_F"
    assertEquals "VAR G in shell env" "$TEST_VAR_G" "$VAR_G"

    # Change directory to env B and check dotenv variables.
    $cd_cmd -- "$TEST_ENVS_POETRY/B" || fail "cd to env B"
    assertNull "VAR A in env B" "$(th_get_env_var "VAR_A")"
    assertNull "VAR B in env B" "$(th_get_env_var "VAR_B")"
    assertNull "VAR C in env B" "$(th_get_env_var "VAR_C")"
    assertNull "VAR D in env B" "$(th_get_env_var "VAR_D")"
    assertNull "VAR E in env B" "$(th_get_env_var "VAR_E")"
    assertNull "VAR F in env B" "$(th_get_env_var "VAR_F")"
    assertEquals "VAR G in env B" "$TEST_VAR_G" "$(th_get_env_var "VAR_G")"
    assertEquals "VAR F in shell env" "$TEST_VAR_F" "$VAR_F"
    assertEquals "VAR G in shell env" "$TEST_VAR_G" "$VAR_G"

    # Go back to envs tmpdir
    $cd_cmd -- "$TEST_ENVS_TMPDIR" || fail "cd to envs tmpdir"

    $disable_cmd || fail "disable auto activate"
}


th_test_pyvenv_auto_activate_venv() {
    enable_cmd="$1"
    disable_cmd="$2"
    cd_cmd="$3"

    th_pyvenv_setup_venv "$TEST_ENVS_VENV/A" || fail "setup in env A"
    th_pyvenv_setup_venv "$TEST_ENVS_VENV/B" || fail "setup in env B"

    $enable_cmd || fail "enable auto activate"

    # Change directory to env C and check dotenv variables.
    # virtualenv should not load .env file.
    $cd_cmd -- "$TEST_ENVS_VENV/C" || fail "cd to env C"
    assertNull "VAR A in env C" "$(th_get_env_var "VAR_A")"
    assertNull "VAR B in env C" "$(th_get_env_var "VAR_B")"
    assertNull "VAR C in env C" "$(th_get_env_var "VAR_C")"
    assertNull "VAR D in env C" "$(th_get_env_var "VAR_D")"
    assertNull "VAR E in env C" "$(th_get_env_var "VAR_E")"
    assertNull "VAR F in env C" "$(th_get_env_var "VAR_F")"
    assertEquals "VAR G in env C" "$TEST_VAR_G" "$(th_get_env_var "VAR_G")"
    assertEquals "VAR F in shell env" "$TEST_VAR_F" "$VAR_F"
    assertEquals "VAR G in shell env" "$TEST_VAR_G" "$VAR_G"

    # Change directory to env B and check dotenv variables.
    $cd_cmd -- "$TEST_ENVS_VENV/B" || fail "cd to env B"
    assertNull "VAR A in env B" "$(th_get_env_var "VAR_A")"
    assertNull "VAR B in env B" "$(th_get_env_var "VAR_B")"
    assertNull "VAR C in env B" "$(th_get_env_var "VAR_C")"
    assertNull "VAR D in env B" "$(th_get_env_var "VAR_D")"
    assertNull "VAR E in env B" "$(th_get_env_var "VAR_E")"
    assertNull "VAR F in env B" "$(th_get_env_var "VAR_F")"
    assertEquals "VAR G in env B" "$TEST_VAR_G" "$(th_get_env_var "VAR_G")"
    assertEquals "VAR F in shell env" "$TEST_VAR_F" "$VAR_F"
    assertEquals "VAR G in shell env" "$TEST_VAR_G" "$VAR_G"

    # Go back to envs tmpdir
    $cd_cmd -- "$TEST_ENVS_TMPDIR" || fail "cd to envs tmpdir"

    $disable_cmd || fail "disable auto activate"
}


suite() {
    suite_addTest 'test_pipenv_run'
    suite_addTest 'test_poetry_run'
    suite_addTest 'test_venv_manual'
    suite_addTest 'test_pyvenv_activate_pipenv'
    suite_addTest 'test_pyvenv_activate_poetry'
    suite_addTest 'test_pyvenv_activate_venv'
    th_pyvenv_auto_activate_suite 'pipenv' 'poetry' 'venv'
}


. "$TEST_DIR/shunit2/shunit2"
