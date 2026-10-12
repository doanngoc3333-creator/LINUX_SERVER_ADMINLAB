#!/bin/bash

SERVICE="${1:-nginx}" # chon dich vu kiem tra, mac dinh nginx
REPORT="$HOME/incident-$(date +%Y%m%d-%H%M%S).log"

case "$SERVICE" in
    nginx|ssh|smbd) ;;
    *) echo "Usage: $0 {nginx|ssh|smbd}"; exit 1 ;;
esac

{
    echo "=== INCIDENT RESPONSE ==="
    date
    echo "Service: $SERVICE" # in ra service kiem tra

    if ! systemctl is-active --quiet "$SERVICE"; then # kiem tra service
        echo "[INCIDENT] $SERVICE is inactive"
        echo "[ACTION] Attempting restart"

        if sudo systemctl restart "$SERVICE"; then
            echo "[RESTART] Command succeeded"
        else
            echo "[RESTART] Command failed"
        fi
    else
        echo "[STATUS] Service is already active"
    fi

    if systemctl is-active --quiet "$SERVICE"; then
        echo "[VERIFY] ACTIVE"
        echo "[RESULT] Service operational"
    else
        echo "[VERIFY] INACTIVE"
        echo "[RESULT] Incident unresolved"
    fi
} 2>&1 | tee "$REPORT"
