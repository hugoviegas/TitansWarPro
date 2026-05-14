#!/bin/bash
# shellcheck disable=SC2148
# update.sh — TitansWarPro updater
# Branches: master | beta | beta2 | ai-engine

TWM_REPO="https://raw.githubusercontent.com/hugoviegas/TitansWarPro"

_twm_update() {
    local branch
    branch=$(git -C "$(dirname "$0")" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "master")

    case "$branch" in
        master)    echo "Channel: master (stable)" ;;
        beta)      echo "Channel: beta" ;;
        beta2)     echo "Channel: beta2" ;;
        ai-engine) echo "Channel: ai-engine (AI self-improvement)" ;;
        *)         echo "Channel: $branch" ;;
    esac

    echo "Updating from branch: $branch ..."
    if command -v git &>/dev/null && git -C "$(dirname "$0")" rev-parse --git-dir &>/dev/null; then
        git -C "$(dirname "$0")" pull origin "$branch" --ff-only
    else
        echo "[warn] git not available — manual update required"
    fi
}

_twm_update
