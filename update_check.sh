#!/bin/bash
# shellcheck disable=SC2148
# update_check.sh — Check for updates on current branch
# Branches: master | beta | beta2 | ai-engine

_twm_check_update() {
    local branch
    branch=$(git -C "$(dirname "$0")" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "master")

    local remote_sha local_sha
    remote_sha=$(git -C "$(dirname "$0")" ls-remote origin "refs/heads/$branch" 2>/dev/null | awk '{print $1}')
    local_sha=$(git -C "$(dirname "$0")" rev-parse HEAD 2>/dev/null)

    case "$branch" in
        master)    local channel="master (stable)" ;;
        beta)      local channel="beta" ;;
        beta2)     local channel="beta2" ;;
        ai-engine) local channel="ai-engine (AI self-improvement)" ;;
        *)         local channel="$branch" ;;
    esac

    echo "Branch: $channel"
    if [ -z "$remote_sha" ]; then
        echo "[warn] Could not reach remote."
        return
    fi

    if [ "$remote_sha" = "$local_sha" ]; then
        echo "Up to date."
    else
        echo "Update available! Run update.sh to upgrade."
        echo "  local:  ${local_sha:0:7}"
        echo "  remote: ${remote_sha:0:7}"
    fi
}

_twm_check_update
