#!/bin/sh
# Generated release asset: update the LuCI frontend without restarting VPN.
set -eu
[ "$(id -u)" = 0 ] || { echo 'Запустите от root' >&2; exit 1; }
UI_TARGET=/www/luci-static/resources/view/cudyroute/main.js
[ -f "$UI_TARGET" ] || { echo 'Интерфейс CudyRoute не установлен' >&2; exit 1; }
UI_TASK_DIR=$(mktemp -d /tmp/cudyroute-ui.XXXXXX)
trap 'rm -rf "$UI_TASK_DIR"' EXIT INT TERM
UI_URL=https://github.com/@REPO@/releases/download/@TAG@/cudyroute-ui.js
if command -v curl >/dev/null 2>&1; then
 curl -fL --retry 2 --connect-timeout 15 --max-time 90 "$UI_URL" -o "$UI_TASK_DIR/main.js"
else
 wget -O "$UI_TASK_DIR/main.js" "$UI_URL"
fi
printf '%s  %s\n' '@SHA@' "$UI_TASK_DIR/main.js" | sha256sum -c -
mkdir -p /etc/cudyroute/ui-backups
chmod 700 /etc/cudyroute/ui-backups
UI_BACKUP=$(mktemp /etc/cudyroute/ui-backups/main.js.XXXXXX)
cp "$UI_TARGET" "$UI_BACKUP"
chmod 600 "$UI_BACKUP"
cp "$UI_TASK_DIR/main.js" "$UI_TARGET.new"
chmod 644 "$UI_TARGET.new"
mv -f "$UI_TARGET.new" "$UI_TARGET"
printf 'Интерфейс обновлён. Резервная копия: %s\nОбновите страницу браузера: Ctrl+F5.\n' "$UI_BACKUP"
