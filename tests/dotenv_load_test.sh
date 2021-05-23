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


test_pyvenv_activate() {
    # Change directory to env 3 and check dotenv variables.
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


th_test_pyvenv_auto_activate() {
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


suite() {
    suite_addTest 'test_pipenv_run'
    suite_addTest 'test_pyvenv_activate'
    th_pyvenv_auto_activate_suite
}


. "$TEST_DIR/shunit2/shunit2"
