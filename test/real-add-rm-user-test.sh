#!/bin/bash

# Integration test script for testing various operations against live
# facebook API.  Before running, register two separate facebook
# applications, and provide their registered names as command-line
# arguments.

fbtu='ruby -I./lib ./bin/fbtu'

fatal () {
    echo >&2 "ERROR: $*"
    exit 1
}

fail () {
    tput bold
    tput setaf 1
    echo >&2 "not ok - $*"
    tput sgr0
    exit 1
}

ok () {
    tput setaf 2
    echo "ok - $*"
    tput sgr0
}

should_succeed () {
    name="$1"
    shift
    if "$@"; then
        ok "$name"
    else
        fail "$name"
    fi
}

should_fail () {
    name="should fail: $1"
    shift
    if ! "$@"; then
        ok "$name"
    else
        fail "$name"
    fi
}

if [ $# != 2 ]; then
    echo >&2 "Usage: $0 APP-A APP-B"
    exit 1
fi

appA="$1"
appB="$2"

for app in "$appA" "$appB"; do
    if ! $fbtu users list -a "$app"; then
        echo >&2 "$app doesn't appear to be a valid app; aborting."
        exit 1
    fi
    ok "$appA is a valid app"
done

if uid=$(
    $fbtu users create --app "$appA" |
    awk '/^User ID/ { print $3 }'
)
then
    ok "created user with ID $uid"
else
    fail "create user"
fi

should_succeed "change user name via $appA" \
    $fbtu users change \
    --app "$appA" \
    --user "$uid" \
    --name "Joe"

should_fail "change user name via $appB" \
    $fbtu users change \
    --app "$appB" \
    --user "$uid" \
    --name "Sir Joe"

should_fail "add user from $appB to $appA" \
    $fbtu apps add-user \
    --from-app "$appB" \
    --to-app "$appA" \
    --user "$uid"

should_succeed "add user from $appA to $appB" \
    $fbtu apps add-user \
    --from-app "$appA" \
    --to-app "$appB" \
    --user "$uid"

should_fail "rm user via $appA" \
    $fbtu user rm --app "$appA" --user "$uid"

should_fail "rm user via $appB" \
    $fbtu user rm --app "$appB" --user "$uid"

should_succeed "disassociate user from $appB" \
    $fbtu apps rm-user --app "$appB" --user "$uid"

should_fail "disassociate user from $appA" \
    $fbtu apps rm-user --app "$appA" --user "$uid"

should_succeed "rm user via $appA" \
    $fbtu user rm --app "$appA" --user "$uid"
