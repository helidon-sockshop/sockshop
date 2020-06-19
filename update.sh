#!/bin/bash
#
# Copyright (c) 2020 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at
# http://oss.oracle.com/licenses/upl.
#
function inv {
    "$@"
    local status=$?
    if [ ${status} -ne 0 ]; then
        exit $?
    fi
    return ${status}
}

function handle_trap {
    echo "Terminating script..."
    exit 0
}

trap 'handle_trap' SIGINT

USE_HTTP=false

while getopts "hrsctda:u:l" opt;
do
    case ${opt} in
        h)
            USE_HTTP=true
            ;;
        s)
            DO_STATUS=true
            ;;
        c)
            DO_CHECKOUT=true
            ;;
        t)
            DO_STASH=true
            ;;
        d)
            DO_DIFF=true
            ;;
        a)  AFTER=$OPTARG
            ;;
        u)  UNTIL=$OPTARG
            ;;
        l)  DO_LOG=true
            ;;
        r)  UP_REMOTE=true
            ;;
        : )
            echo "Invalid option: $OPTARG requires an argument" 1>&2
            ;;
        \?) echo "Usage: update.sh [-h (use HTTPS to checkout)] [-s do git status instead of pull --rebase] [-t do git stash list instead of pull --rebase] [-a after -u until -l log]  [-d do git diff instead of pull --rebase]"
            [ $PS1 ] && return || exit;
            ;;
    esac
done
shift $((OPTIND -1))

PROJECTS=(
    "sockshop"
    "carts"
    "catalog"
    "orders"
    "payment"
    "shipping"
    "users"
)
BASE=$PWD

for i in "${PROJECTS[@]}"
do
    if [ ${UP_REMOTE} ]; then
        if [ ${USE_HTTP} ]; then
            git remote set-url origin https://github.com/helidon-sockshop/${i}.git
        else
            git remote set-url origin git@github.com:helidon-sockshop/${i}.git
        fi
        continue
    fi
    if [ ! -d ${i} ]; then
        if [ ${USE_HTTP} = true ]; then
            inv git clone https://github.com/helidon-sockshop/${i}.git
        else
            inv git clone git@github.com:helidon-sockshop/${i}.git
        fi
    fi
    if [ ${DO_DIFF} ]; then
        cd ${i}; echo "***${i}***"
        inv git --no-pager diff
        cd ${BASE}
    elif [ ${DO_STATUS} ]; then
        cd ${i}; echo "***${i}***"
        inv git status
        cd ${BASE}
    elif [ ${DO_CHECKOUT} ]; then
        cd ${i}; echo "***${i}***"
        inv git checkout $1
        cd ${BASE}
    elif [ ${DO_STASH} ]; then
        cd ${i}; echo "***${i}***"
        inv git --no-pager stash list
        cd ${BASE}
    elif [ ${DO_LOG} ]; then
        cd ${i}; echo "***${i}***"
        inv git --no-pager log --after="${AFTER}" --until="${UNTIL}"
        cd ${BASE}
    else
        cd ${i}
        echo "Pulling latest changes for ${i}"
        inv git pull --rebase
        cd ${BASE}
    fi
done
