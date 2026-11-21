#!/bin/zsh
set -euo pipefail

INSTALL_DIR="$HOME/.local/share/globe-switcher"
BIN_PATH="$INSTALL_DIR/globe-switcher"
PLIST_PATH="$HOME/Library/LaunchAgents/local.globe-switcher.plist"
STATE_FILE="$INSTALL_DIR/.original_fn_usage_type"
LABEL="local.globe-switcher"
UID_VAL=$(id -u)
ACTION="${1:-status}"

# Атомарная установка бинарника через временный файл (предотвращает конфликт vnode cs_blob в XNU на Apple Silicon)
install_binary() {
    mkdir -p "$INSTALL_DIR"
    local tmp_bin="$BIN_PATH.tmp.$$"
    echo "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" | base64 -d | gunzip > "$tmp_bin"
    chmod +x "$tmp_bin"
    /usr/bin/codesign -s - -f "$tmp_bin" >/dev/null 2>&1 || true
    mv -f "$tmp_bin" "$BIN_PATH"
}

ensure_binary_if_missing() {
    if [[ ! -x "$BIN_PATH" ]]; then
        install_binary
    fi
}

check_requirements() {
    if [[ "$(uname -m)" != "arm64" ]]; then
        cat <<EOF
❌ Неподдерживаемый процессор
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Globe Switcher работает только на Mac с чипами Apple Silicon (M1/M2/M3/M4+, arm64).
Текущая архитектура: $(uname -m).
Настройки системы не изменялись.
EOF
        exit 0
    fi
    local os_major
    os_major=$(sw_vers -productVersion | cut -d. -f1)
    if [[ -z "$os_major" || "$os_major" -lt 13 ]]; then
        cat <<EOF
❌ Неподдерживаемая версия macOS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Требуется macOS 13.0 или новее (обнаружена $(sw_vers -productVersion)).
Настройки системы не изменялись.
EOF
        exit 0
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

stop_agent() {
    if launchctl print "gui/$UID_VAL/$LABEL" >/dev/null 2>&1; then
        launchctl bootout "gui/$UID_VAL/$LABEL" 2>/dev/null || true
        for _ in {1..20}; do
            launchctl print "gui/$UID_VAL/$LABEL" >/dev/null 2>&1 || break
            sleep 0.05
        done
    fi
}

ensure_plist() {
    mkdir -p "$HOME/Library/LaunchAgents"
    cat > "$PLIST_PATH" <<EOF
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

case "$ACTION" in
    on)
        check_requirements
        stop_agent
        install_binary
        set +e
        "$BIN_PATH" --self-test >/dev/null 2>&1
        test_rc=$?
        set -e
        if [[ $test_rc -eq 2 ]]; then
            cat <<EOF
❌ Нужно минимум 2 раскладки клавиатуры
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Добавьте хотя бы 2 источника ввода в Системных настройках → Клавиатура → Источники ввода и запустите команду снова.
Настройки системы не изменялись.
EOF
            exit 0
        elif [[ $test_rc -ne 0 ]]; then
            cat <<EOF
❌ Ошибка самопроверки бинарника
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
globe-switcher не смог инициализироваться на macOS $(sw_vers -productVersion) (код $test_rc).
Настройки системы не изменялись.
EOF
            exit 0
        fi
        if [[ ! -f "$STATE_FILE" ]]; then
            cur=$("$BIN_PATH" --get-fn 2>/dev/null || echo "1")
            [[ "$cur" == "0" || -z "$cur" ]] && cur="1"
            echo "$cur" > "$STATE_FILE"
        fi
        ensure_plist
        launchctl bootstrap "gui/$UID_VAL" "$PLIST_PATH"
        launchctl kickstart -kp "gui/$UID_VAL/$LABEL" >/dev/null 2>&1 || true
        if ! wait_for_agent_running; then
            orig="1"
            [[ -f "$STATE_FILE" ]] && orig=$(cat "$STATE_FILE")
            [[ "$orig" == "0" || -z "$orig" ]] && orig="1"
            stop_agent
            rm -f "$PLIST_PATH"
            "$BIN_PATH" --set-fn "$orig" >/dev/null 2>&1 || true
            cat <<EOF
❌ Фоновый агент не смог запуститься
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
launchd не удалось запустить local.globe-switcher.
Ваша исходная настройка клавиши 🌐 Globe (AppleFnUsageType=$orig) сохранена.
EOF
            exit 0
        fi
        "$BIN_PATH" --set-fn 0
        echo "✅ Включено! Клавиша 🌐 Globe теперь переключает язык мгновенно без большого баннера по центру экрана (комбинация 🌐 + Delete и работа при активном Caps Lock сохранены)."
        ;;
    off)
        stop_agent
        ensure_binary_if_missing
        orig="1"
        [[ -f "$STATE_FILE" ]] && orig=$(cat "$STATE_FILE")
        [[ "$orig" == "0" || -z "$orig" ]] && orig="1"
        "$BIN_PATH" --set-fn "$orig"
        echo "⏸️ Выключено. Возвращено стандартное поведение клавиши 🌐 Globe (AppleFnUsageType=$orig)."
        ;;
    status)
        ensure_binary_if_missing
        fn_val=$("$BIN_PATH" --get-fn 2>/dev/null || echo "1")
        if launchctl print "gui/$UID_VAL/$LABEL" >/dev/null 2>&1; then
            echo "🟢 Статус: АКТИВЕН (работает в фоне, автозапуск включён).
Активный режим HIToolbox (TISGetFnUsageType) = $fn_val (большой баннер отключён)."
        else
            echo "⚪️ Статус: ВЫКЛЮЧЕН.
Активный режим HIToolbox (TISGetFnUsageType) = $fn_val."
        fi
        ;;
    uninstall)
        stop_agent
        ensure_binary_if_missing
        orig="1"
        [[ -f "$STATE_FILE" ]] && orig=$(cat "$STATE_FILE")
        [[ "$orig" == "0" || -z "$orig" ]] && orig="1"
        rm -f "$PLIST_PATH"
        "$BIN_PATH" --set-fn "$orig"
        rm -rf "$INSTALL_DIR"
        echo "🧹 Полный хирургический откат завершён! Все файлы удалены, возвращена заводская настройка (AppleFnUsageType=$orig)."
        ;;
esac
