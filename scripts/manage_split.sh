#!/bin/sh
set -e

PREF="/data_mirror/data_ce/null/0/com.tailscale.ipn/shared_prefs/unencrypted.xml"
BACKUP_DIR="/data/data/io.github.mangi.eta/files/skills/tailscale-split-tunnel/references"

if [ ! -f "$PREF" ]; then
    echo "Error: Tailscale shared_prefs not found at $PREF" >&2
    exit 1
fi

ACTION="$1"
shift || true

restart_tailscale() {
    echo "Restarting Tailscale..."
    am force-stop com.tailscale.ipn >/dev/null 2>&1 || true
    sleep 1
    monkey -p com.tailscale.ipn -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 || true
    echo "Tailscale restarted."
}

case "$ACTION" in
    list)
        echo "=== Tailscale Split Tunnel Status ==="
        MODE=$(grep -o 'name="allowSelectedApps" value="[^"]*"' "$PREF" | cut -d'"' -f4)
        if [ "$MODE" = "false" ]; then
            echo "Mode: Bypass/Exclude (Disallowed apps bypass VPN and direct connect)"
        else
            echo "Mode: Allowlist (Only selected apps use VPN)"
        fi
        COUNT=$(grep -c "<string>" "$PREF")
        echo "Total configured apps: $COUNT"
        echo "=== Package List ==="
        grep -o "<string>[^<]*</string>" "$PREF" | sed -e "s/<string>//g" -e "s/<\/string>//g" | sort
        ;;
    add)
        if [ $# -lt 1 ]; then
            echo "Usage: $0 add <package1> [package2 ...]" >&2
            exit 1
        fi
        TMP_LIST="/data/local/tmp/ts_split_merge.txt"
        grep -o "<string>[^<]*</string>" "$PREF" | sed -e "s/<string>//g" -e "s/<\/string>//g" > "$TMP_LIST"
        for pkg in "$@"; do
            echo "$pkg" >> "$TMP_LIST"
        done
        sort -u "$TMP_LIST" > "${TMP_LIST}.sorted"

        OWNER=$(stat -c "%u:%g" "$PREF")
        PERM=$(stat -c "%a" "$PREF")
        am force-stop com.tailscale.ipn >/dev/null 2>&1 || true

        {
            printf "<?xml version='1.0' encoding='utf-8' standalone='yes' ?>\n"
            printf "<map>\n"
            printf "    <boolean name=\"ableToStartVPN\" value=\"true\" />\n"
            printf "    <set name=\"disallowedApps\">\n"
            while IFS= read -r p; do
                [ -n "$p" ] && printf "        <string>%s</string>\n" "$p"
            done < "${TMP_LIST}.sorted"
            printf "    </set>\n"
            printf "    <boolean name=\"allowSelectedApps\" value=\"false\" />\n"
            printf "</map>\n"
        } > "${PREF}.tmp"

        mv "${PREF}.tmp" "$PREF"
        chown "$OWNER" "$PREF"
        chmod "$PERM" "$PREF"
        rm -f "$TMP_LIST" "${TMP_LIST}.sorted"

        restart_tailscale
        echo "Added successfully. Total: $(grep -c "<string>" "$PREF")"
        ;;
    remove)
        if [ $# -lt 1 ]; then
            echo "Usage: $0 remove <package1> [package2 ...]" >&2
            exit 1
        fi
        TMP_LIST="/data/local/tmp/ts_split_merge.txt"
        grep -o "<string>[^<]*</string>" "$PREF" | sed -e "s/<string>//g" -e "s/<\/string>//g" > "$TMP_LIST"
        for pkg in "$@"; do
            sed -i "/^$pkg$/d" "$TMP_LIST"
        done
        sort -u "$TMP_LIST" > "${TMP_LIST}.sorted"

        OWNER=$(stat -c "%u:%g" "$PREF")
        PERM=$(stat -c "%a" "$PREF")
        am force-stop com.tailscale.ipn >/dev/null 2>&1 || true

        {
            printf "<?xml version='1.0' encoding='utf-8' standalone='yes' ?>\n"
            printf "<map>\n"
            printf "    <boolean name=\"ableToStartVPN\" value=\"true\" />\n"
            printf "    <set name=\"disallowedApps\">\n"
            while IFS= read -r p; do
                [ -n "$p" ] && printf "        <string>%s</string>\n" "$p"
            done < "${TMP_LIST}.sorted"
            printf "    </set>\n"
            printf "    <boolean name=\"allowSelectedApps\" value=\"false\" />\n"
            printf "</map>\n"
        } > "${PREF}.tmp"

        mv "${PREF}.tmp" "$PREF"
        chown "$OWNER" "$PREF"
        chmod "$PERM" "$PREF"
        rm -f "$TMP_LIST" "${TMP_LIST}.sorted"

        restart_tailscale
        echo "Removed successfully. Total: $(grep -c "<string>" "$PREF")"
        ;;
    snapshot)
        cp -p "$PREF" "$BACKUP_DIR/unencrypted_snapshot.xml"
        grep -o "<string>[^<]*</string>" "$PREF" | sed -e "s/<string>//g" -e "s/<\/string>//g" | sort -u > "$BACKUP_DIR/disallowed_apps.txt"
        echo "Snapshot updated at $BACKUP_DIR"
        ;;
    restart)
        restart_tailscale
        ;;
    *)
        echo "Usage: $0 {list|add|remove|snapshot|restart}" >&2
        exit 1
        ;;
esac
