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
ENV_C_VAR_E="toto
titi"


get_env_var() {
    env_var="$1"
    cmd_prefix="${2:-}"

    $cmd_prefix sh -c "echo \"\$$env_var\""
}


test_pipenv_run() {
    # Change directory to env C and check dotenv variables.
    cd -- "$TEST_ENVS_TMPDIR/C" || fail "cd to env C"
    assertEquals "VAR A in env C" "$ENV_C_VAR_A" "$(get_env_var "VAR_A" 'pipenv run')"
    assertEquals "VAR B in env C" "$ENV_C_VAR_B" "$(get_env_var "VAR_B" 'pipenv run')"
    assertEquals "VAR C in env C" "$ENV_C_VAR_C" "$(get_env_var "VAR_C" 'pipenv run')"
    assertEquals "VAR D in env C" "$ENV_C_VAR_D" "$(get_env_var "VAR_D" 'pipenv run')"
    assertEquals "VAR E in env C" "$ENV_C_VAR_E" "$(get_env_var "VAR_E" 'pipenv run')"

    # Change directory to env B and check dotenv variables.
    cd -- "$TEST_ENVS_TMPDIR/B" || fail "cd to env B"
    assertNull "VAR A in env B" "$(get_env_var "VAR_A" 'pipenv run')"
    assertNull "VAR B in env B" "$(get_env_var "VAR_B" 'pipenv run')"
    assertNull "VAR C in env B" "$(get_env_var "VAR_C" 'pipenv run')"
    assertNull "VAR D in env B" "$(get_env_var "VAR_D" 'pipenv run')"
    assertNull "VAR E in env B" "$(get_env_var "VAR_E" 'pipenv run')"
}


test_pipenv_activate() {
    # Change directory to env 3 and check dotenv variables.
    cd -- "$TEST_ENVS_TMPDIR/C" || fail "cd to env C"
    pipenv_activate || fail "pipenv_activate in env C"
    assertEquals "VAR A in env C" "$ENV_C_VAR_A" "$(get_env_var "VAR_A")"
    assertEquals "VAR B in env C" "$ENV_C_VAR_B" "$(get_env_var "VAR_B")"
    assertEquals "VAR C in env C" "$ENV_C_VAR_C" "$(get_env_var "VAR_C")"
    assertEquals "VAR D in env C" "$ENV_C_VAR_D" "$(get_env_var "VAR_D")"
    assertEquals "VAR E in env C" "$ENV_C_VAR_E" "$(get_env_var "VAR_E")"
    pipenv_deactivate || fail "deactivate env C"

    # Change directory to env B and check dotenv variables.
    cd -- "$TEST_ENVS_TMPDIR/B" || fail "cd to env B"
    pipenv_activate || fail "pipenv_activate in env B"
    assertNull "VAR A in env B" "$(get_env_var "VAR_A")"
    assertNull "VAR B in env B" "$(get_env_var "VAR_B")"
    assertNull "VAR C in env B" "$(get_env_var "VAR_C")"
    assertNull "VAR D in env B" "$(get_env_var "VAR_D")"
    assertNull "VAR E in env B" "$(get_env_var "VAR_E")"
    pipenv_deactivate || fail "deactivate env B"
}


th_test_pipenv_auto_activate() {
    enable_cmd="$1"
    disable_cmd="$2"
    cd_cmd="$3"

    $enable_cmd || fail "enable auto activate"

    # Change directory to env C and check dotenv variables.
    $cd_cmd -- "$TEST_ENVS_TMPDIR/C" || fail "cd to env C"
    assertEquals "VAR A in env C" "$ENV_C_VAR_A" "$(get_env_var "VAR_A")"
    assertEquals "VAR B in env C" "$ENV_C_VAR_B" "$(get_env_var "VAR_B")"
    assertEquals "VAR C in env C" "$ENV_C_VAR_C" "$(get_env_var "VAR_C")"
    assertEquals "VAR D in env C" "$ENV_C_VAR_D" "$(get_env_var "VAR_D")"
    assertEquals "VAR E in env C" "$ENV_C_VAR_E" "$(get_env_var "VAR_E")"

    # Change directory to env B and check dotenv variables.
    $cd_cmd -- "$TEST_ENVS_TMPDIR/B" || fail "cd to env B"
    assertNull "VAR A in env B" "$(get_env_var "VAR_A")"
    assertNull "VAR B in env B" "$(get_env_var "VAR_B")"
    assertNull "VAR C in env B" "$(get_env_var "VAR_C")"
    assertNull "VAR D in env B" "$(get_env_var "VAR_D")"
    assertNull "VAR E in env B" "$(get_env_var "VAR_E")"

    # Go back to envs tmpdir
    $cd_cmd -- "$TEST_ENVS_TMPDIR" || fail "cd to envs tmpdir"

    $disable_cmd || fail "disable auto activate"
}


suite() {
    suite_addTest 'test_pipenv_run'
    suite_addTest 'test_pipenv_activate'
    th_pipenv_auto_activate_suite
}


. "$TEST_DIR/shunit2/shunit2"
