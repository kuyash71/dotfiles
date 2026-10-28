#!/usr/bin/env bash
#
# MControlCenter'ı aç. Uygulama tek örnekli: zaten çalışıyorsa ikinci örnek
# "Another instance ... is already running" deyip kapanır ve pencereyi
# göstermez. Bu yüzden çalışan örneğin tray öğesini D-Bus ile "tıklıyoruz".

# Pencere zaten açıksa ona odaklan
if hyprctl clients -j | grep -q '"class": "mcontrolcenter"'; then
	hyprctl dispatch focuswindow class:mcontrolcenter > /dev/null
	exit 0
fi

pid=$(pgrep -x mcontrolcenter | head -1)
if [[ -z $pid ]]; then
	setsid -f mcontrolcenter > /dev/null 2>&1
	exit 0
fi

# Çalışan örneğin D-Bus bağlantılarından StatusNotifierItem sunanı bul
for conn in $(busctl --user list --no-legend | awk -v p="$pid" '$2 == p && $1 ~ /^:/ {print $1}'); do
	if busctl --user call "$conn" /StatusNotifierItem \
		org.kde.StatusNotifierItem Activate ii 0 0 > /dev/null 2>&1; then
		exit 0
	fi
done

# Tray öğesi yoksa son çare: yeniden başlat (açılışta pencere gösterilir)
pkill -x mcontrolcenter
sleep 0.5
setsid -f mcontrolcenter > /dev/null 2>&1
