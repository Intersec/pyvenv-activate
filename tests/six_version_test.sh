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
    cmd_prefix="${1:-}"

    $cmd_prefix python <<EOF
try:
    import six
except ImportError:
    print("None")
else:
    print(six.__version__)
EOF
}


test_pipenv_run() {
    cd -- "$TEST_ENVS_TMPDIR/1" || return 1
    assertEquals "$ENV_1_SIX_VERSION" "$(get_six_version 'pipenv run')"

    cd -- "$TEST_ENVS_TMPDIR/2" || return 1
    assertEquals "$ENV_2_SIX_VERSION" "$(get_six_version 'pipenv run')"
}


. "$TEST_DIR/shunit2/shunit2"
