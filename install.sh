#!/bin/sh
# Run from an extracted, signed CudyRoute installation bundle.
set -eu
cd "$(dirname "$0")"
MODE=${1:---flash}
case "$MODE" in --flash|--app-only|--check|--disabled) ;; *) echo 'Использование: ./install.sh [--flash|--app-only|--check|--disabled]' >&2; exit 1;; esac
[ "$(id -u)" = 0 ] || { echo 'Запустите от root' >&2; exit 1; }
[ -f /etc/openwrt_release ] || { echo 'Это не OpenWrt' >&2; exit 1; }
. /etc/openwrt_release
[ "${DISTRIB_TARGET:-}" = mediatek/filogic ] || { echo 'Нужна платформа mediatek/filogic' >&2; exit 1; }
case "${DISTRIB_RELEASE:-}" in 25.12.*) ;; *) echo 'Эта сборка предназначена для OpenWrt 25.12.x' >&2; exit 1;; esac
command -v apk >/dev/null || { echo 'Нужен OpenWrt с APK' >&2; exit 1; }
command -v jsonfilter >/dev/null || { echo 'Нужен jsonfilter' >&2; exit 1; }
[ "$(cat /etc/apk/arch)" = aarch64_cortex-a53 ] || { echo 'Нужна архитектура aarch64_cortex-a53' >&2; exit 1; }
[ "$(cat /tmp/sysinfo/board_name)" = 'cudy,wr3000u-v1' ] || { echo 'Эта сборка предназначена для Cudy WR3000U v1' >&2; exit 1; }
sha256sum -c SHA256SUMS
[ "$(jsonfilter -i manifest.json -e '@.arch')" = aarch64_cortex-a53 ] || { echo 'Неверная архитектура комплекта' >&2; exit 1; }
FREE=$(df -Pk /overlay | awk 'NR==2 {printf "%.0f", $4*1024}')
TMP_FREE=$(df -Pk /tmp | awk 'NR==2 {printf "%.0f", $4*1024}')
MEM_FREE=$(awk '/^MemAvailable:/ {printf "%.0f", $2*1024}' /proc/meminfo)
APP=$(jsonfilter -i manifest.json -e '@.controller_size')
CORE=$(jsonfilter -i manifest.json -e '@.compressed_size')
CONTROLLER_RAW=$(jsonfilter -i manifest.json -e '@.controller_binary_size')
RAW=$(jsonfilter -i manifest.json -e '@.size')
REQUIRED=$((APP + CORE + 16*1024*1024))
[ "$MODE" != --app-only ] || REQUIRED=$((APP + 16*1024*1024))
printf 'Свободно flash: %s байт; требуется с резервом: %s байт\n' "$FREE" "$REQUIRED"
printf 'Свободно /tmp: %s байт; MemAvailable: %s байт\n' "$TMP_FREE" "$MEM_FREE"
[ "$FREE" -ge "$REQUIRED" ] || { echo 'Недостаточно flash. Освободите место или используйте --app-only с RAM-загрузкой ядра.' >&2; exit 1; }
if [ "$MODE" != --disabled ]; then
 [ "$TMP_FREE" -ge $((RAW + CONTROLLER_RAW + 24*1024*1024)) ] || { echo 'Недостаточно места в /tmp' >&2; exit 1; }
 [ "$MEM_FREE" -ge $((RAW + CONTROLLER_RAW + 64*1024*1024)) ] || { echo 'Недостаточно свободной RAM' >&2; exit 1; }
fi
[ "$MODE" != --check ] || { echo 'Проверка пройдена; роутер не изменён.'; exit 0; }
if [ "$MODE" != --disabled ] && { pidof sing-box >/dev/null 2>&1 || pidof xray >/dev/null 2>&1; } && [ ! -S /tmp/cudyroute/control.sock ]; then
 echo 'Работает другое VPN-ядро. Остановите его либо установите с --disabled.' >&2
 exit 1
fi
mkdir -p /etc/apk/keys
cp keys/cudyroute.pub /etc/apk/keys/cudyroute.pub
apk update
if [ "$MODE" = --disabled ]; then
 [ ! -S /tmp/cudyroute/control.sock ] || { echo 'Сначала остановите уже запущенный CudyRoute' >&2; exit 1; }
 apk add --no-scripts --no-commit-hooks ./cudyroute-core-1.14.2-r14.apk ./luci-app-cudyroute-0.4.0-r1.apk
 rm -f /etc/uci-defaults/90-cudyroute
 /etc/init.d/cudyroute disable
 mkdir -p /etc/cudyroute
 chmod 700 /etc/cudyroute
 [ -f /etc/cudyroute/settings.json ] || /usr/bin/cudyroute defaults > /etc/cudyroute/settings.json
 chmod 600 /etc/cudyroute/settings.json
 /etc/init.d/rpcd reload
 rm -f /tmp/luci-indexcache
 echo 'Установлено без запуска. VPN отключён на новой установке.'
 exit 0
elif [ "$MODE" = --app-only ]; then
 apk add ./luci-app-cudyroute-0.4.0-r1.apk
else
 apk add ./cudyroute-core-1.14.2-r14.apk ./luci-app-cudyroute-0.4.0-r1.apk
fi
echo 'Откройте LuCI → Сервисы → CudyRoute. На новой установке VPN отключён.'
