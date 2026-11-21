#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$HOME/.local/share/globe-switcher"
BIN_PATH="$INSTALL_DIR/globe-switcher"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_DST="$LAUNCH_AGENTS_DIR/local.globe-switcher.plist"
STATE_FILE="$INSTALL_DIR/.original_fn_usage_type"
LABEL="local.globe-switcher"
UID_VAL=$(id -u)

check_requirements() {
    if [[ "$(uname -m)" != "arm64" ]]; then
        echo "❌ Error: Globe Switcher supports only Apple Silicon Macs (M1/M2/M3/M4+, arm64). Current architecture: $(uname -m)." >&2
        exit 1
    fi
    local os_major
    os_major=$(sw_vers -productVersion | cut -d. -f1)
    if [[ -z "$os_major" || "$os_major" -lt 13 ]]; then
        echo "❌ Error: macOS 13.0 or newer is required (detected $(sw_vers -productVersion))." >&2
        exit 1
    fi
}

install_or_build_binary() {
    mkdir -p "$INSTALL_DIR"
    local tmp_bin="$BIN_PATH.tmp.$$"
    if [[ -f "$SCRIPT_DIR/globe-switcher" ]]; then
        cp -f "$SCRIPT_DIR/globe-switcher" "$tmp_bin"
    elif [[ -f "$SCRIPT_DIR/GlobeSwitcher.swift" ]]; then
        if ! command -v swiftc >/dev/null 2>&1; then
            echo "❌ Error: swiftc not found. Install Xcode Command Line Tools (xcode-select --install) or use the Apple Shortcut." >&2
            exit 1
        fi
        swiftc -O -parse-as-library -target arm64-apple-macos13.0 "$SCRIPT_DIR/GlobeSwitcher.swift" -o "$tmp_bin"
        strip -x "$tmp_bin" 2>/dev/null || true
    elif [[ -x "$BIN_PATH" ]]; then
        return 0
    else
        echo "❌ Error: Neither globe-switcher binary nor GlobeSwitcher.swift found in $SCRIPT_DIR." >&2
        exit 1
    fi
    chmod +x "$tmp_bin"
    /usr/bin/codesign -s - -f "$tmp_bin" >/dev/null 2>&1 || true
    mv -f "$tmp_bin" "$BIN_PATH"
}

ensure_plist() {
    mkdir -p "$LAUNCH_AGENTS_DIR"
    cat > "$PLIST_DST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>local.globe-switcher</string>
    <key>ProgramArguments</key>
    <array>
        <string>$BIN_PATH</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>ProcessType</key>
    <string>Interactive</string>
    <key>LegacyTimers</key>
    <true/>
</dict>
</plist>
EOF
}

save_original_state_if_needed() {
    if [[ ! -f "$STATE_FILE" ]]; then
        local current_val
        current_val=$("$BIN_PATH" --get-fn 2>/dev/null || echo "1")
        if [[ "$current_val" == "0" || -z "$current_val" ]]; then
            current_val="1"
        fi
        echo "$current_val" > "$STATE_FILE"
    fi
}

get_original_state() {
    local val="1"
    if [[ -f "$STATE_FILE" ]]; then
        val=$(cat "$STATE_FILE")
    fi
    if [[ "$val" == "0" || -z "$val" ]]; then
        val="1"
    fi
    echo "$val"
}

stop_agent() {
    if launchctl print "gui/$UID_VAL/$LABEL" >/dev/null 2>&1; then
        launchctl bootout "gui/$UID_VAL/$LABEL" 2>/dev/null || true
        for _ in {1..20}; do
            launchctl print "gui/$UID_VAL/$LABEL" >/dev/null 2>&1 || break
            sleep 0.05
        done
    fi
}

wait_for_agent_running() {
    for _ in {1..20}; do
        if launchctl print "gui/$UID_VAL/$LABEL" 2>/dev/null | grep -q "state = running"; then
            return 0
        fi
        sleep 0.05
    done
    return 1
}

case "${1:-status}" in
    on|enable|install)
        check_requirements
        stop_agent
        install_or_build_binary
        set +e
        "$BIN_PATH" --self-test >/dev/null 2>&1
        test_rc=$?
        set -e
        if [[ $test_rc -eq 2 ]]; then
            echo "❌ Error: Less than 2 keyboard input sources are enabled in macOS System Settings -> Keyboard -> Input Sources." >&2
            exit 1
        elif [[ $test_rc -ne 0 ]]; then
            echo "❌ Error: globe-switcher binary failed self-test (exit code $test_rc) on macOS $(sw_vers -productVersion)." >&2
            exit 1
        fi
        save_original_state_if_needed
        ensure_plist
        launchctl bootstrap "gui/$UID_VAL" "$PLIST_DST"
        launchctl kickstart -kp "gui/$UID_VAL/$LABEL" >/dev/null 2>&1 || true
        if ! wait_for_agent_running; then
            orig_val=$(get_original_state)
            stop_agent
            rm -f "$PLIST_DST"
            "$BIN_PATH" --set-fn "$orig_val" >/dev/null 2>&1 || true
            echo "❌ Error: Background LaunchAgent failed to start. Original Globe key setting (AppleFnUsageType=$orig_val) was preserved." >&2
            exit 1
        fi
        "$BIN_PATH" --set-fn 0
        echo "✅ globe-switcher ENABLED (LaunchAgent running, center HUD banner disabled)."
        ;;

    off|disable)
        install_or_build_binary
        orig_val=$(get_original_state)
        stop_agent
        "$BIN_PATH" --set-fn "$orig_val"
        echo "⏸️  globe-switcher PAUSED (restored AppleFnUsageType=$orig_val)."
        ;;

    uninstall|rollback)
        install_or_build_binary
        orig_val=$(get_original_state)
        stop_agent
        rm -f "$PLIST_DST"
        "$BIN_PATH" --set-fn "$orig_val"
        rm -rf "$INSTALL_DIR"
        echo "🧹 Full rollback complete: LaunchAgent & files removed, restored AppleFnUsageType=$orig_val."
        ;;

    status)
        install_or_build_binary
        fn_val=$("$BIN_PATH" --get-fn 2>/dev/null || echo "unknown")
        echo "Current TISGetFnUsageType: $fn_val (0 = intercepted by globe-switcher, 1 = default macOS HUD)"
        if launchctl print "gui/$UID_VAL/$LABEL" 2>/dev/null | grep -q "state = running"; then
            echo "Agent $LABEL: RUNNING"
        else
            echo "Agent $LABEL: STOPPED"
        fi
        ;;

    *)
        echo "Usage: $0 {on|off|status|uninstall}"
        exit 1
        ;;
esac
