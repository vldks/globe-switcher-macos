#!/bin/zsh
set -euo pipefail

PROJECT_DIR="/Users/vladkas/.gemini/antigravity/scratch/globe-switcher"
BIN_PATH="$PROJECT_DIR/globe-switcher"
PLIST_SRC="$PROJECT_DIR/local.globe-switcher.plist"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_DST="$LAUNCH_AGENTS_DIR/local.globe-switcher.plist"
STATE_FILE="$PROJECT_DIR/.original_fn_usage_type"
LABEL="local.globe-switcher"
UID_VAL=$(id -u)

save_original_state_if_needed() {
    if [[ ! -f "$STATE_FILE" ]]; then
        local current_val
        current_val=$("$BIN_PATH" --get-fn 2>/dev/null || echo "1")
        if [[ "$current_val" == "0" || -z "$current_val" ]]; then
            current_val="1"
        fi
        echo "$current_val" > "$STATE_FILE"
        echo "Сохранено исходное значение AppleFnUsageType: $current_val"
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

case "${1:-status}" in
    on|enable|install)
        save_original_state_if_needed
        mkdir -p "$LAUNCH_AGENTS_DIR"
        cp -f "$PLIST_SRC" "$PLIST_DST"
        stop_agent
        "$BIN_PATH" --set-fn 0
        launchctl bootstrap "gui/$UID_VAL" "$PLIST_DST"
        launchctl kickstart -kp "gui/$UID_VAL/$LABEL" >/dev/null 2>&1 || true
        echo "✅ globe-switcher ВКЛЮЧЕН (автозапуск при входе активен, большой баннер отключен)."
        ;;

    off|disable)
        orig_val=$(get_original_state)
        stop_agent
        "$BIN_PATH" --set-fn "$orig_val"
        echo "⏸️  globe-switcher ВЫКЛЮЧЕН (возвращено исходное поведение AppleFnUsageType=$orig_val)."
        ;;

    uninstall|rollback)
        orig_val=$(get_original_state)
        stop_agent
        rm -f "$PLIST_DST"
        "$BIN_PATH" --set-fn "$orig_val"
        rm -f "$STATE_FILE"
        echo "🧹 Выполнен полный хирургический откат: LaunchAgent удалён, восстановлен AppleFnUsageType=$orig_val."
        ;;

    status)
        fn_val=$("$BIN_PATH" --get-fn 2>/dev/null || echo "неизвестно")
        echo "Текущий TISGetFnUsageType: $fn_val (0 = перехват нашим агентом, 1 = стандартный баннер macOS)"
        if launchctl print "gui/$UID_VAL/$LABEL" >/dev/null 2>&1; then
            echo "Статус агента $LABEL: РАБОТАЕТ (активен в launchd)"
        else
            echo "Статус агента $LABEL: ОСТАНОВЛЕН"
        fi
        ;;

    *)
        echo "Использование: $0 {on|off|status|uninstall}"
        exit 1
        ;;
esac
