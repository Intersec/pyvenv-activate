#!/bin/sh
# Disable source following.
#   shellcheck disable=SC1090,SC1091
# Disable optional arguments.
#   shellcheck disable=SC2120


TEST_SCRIPT="$0"
TEST_DIR="$(dirname -- "$TEST_SCRIPT")"
. "$TEST_DIR/test_helpers"


ENV_1_VAR_A="foo"
ENV_1_VAR_B="bar"
ENV_1_VAR_C=""
ENV_1_VAR_D=""
ENV_1_VAR_E="toto
titi"


get_env_var() {
    env_var="$1"
    cmd_prefix="${2:-}"

    $cmd_prefix sh -c "echo \"\$$env_var\""
}


test_pipenv_run() {
    cd -- "$TEST_ENVS_TMPDIR/1" || return 1
    assertEquals "$ENV_1_VAR_A" "$(get_env_var "VAR_A" 'pipenv run')"
    assertEquals "$ENV_1_VAR_B" "$(get_env_var "VAR_B" 'pipenv run')"
    assertEquals "$ENV_1_VAR_C" "$(get_env_var "VAR_C" 'pipenv run')"
    assertEquals "$ENV_1_VAR_D" "$(get_env_var "VAR_D" 'pipenv run')"
    assertEquals "$ENV_1_VAR_E" "$(get_env_var "VAR_E" 'pipenv run')"

    cd -- "$TEST_ENVS_TMPDIR/2" || return 1
    assertNull "$(get_env_var "VAR_A" 'pipenv run')"
    assertNull "$(get_env_var "VAR_B" 'pipenv run')"
    assertNull "$(get_env_var "VAR_C" 'pipenv run')"
    assertNull "$(get_env_var "VAR_D" 'pipenv run')"
    assertNull "$(get_env_var "VAR_E" 'pipenv run')"
}


. "$TEST_DIR/shunit2/shunit2"
