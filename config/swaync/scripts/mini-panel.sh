#!/usr/bin/env bash
#
# Control Panel'in soluna açılan mini paneller (güç menüsü / bildirim filtresi)
#   mini-panel.sh power|notif   menüyü aç / kapat
#   mini-panel.sh daemon        arka plan sürecini başlat (Hyprland autostart)
#
# Asıl iş minipanel.py'de; sürekli çalışıyor ve buradan sinyal alıyor
# (power → SIGUSR1, notif → SIGUSR2). Süreç yoksa başlatılıp menü hemen açılır.
# gtk4-layer-shell, Python'dan kullanılırken libwayland'den önce yüklenmek
# zorunda; bu yüzden LD_PRELOAD.

PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/kvara-minipanel.pid"

start() {
	exec env LD_PRELOAD=/usr/lib/libgtk4-layer-shell.so GSK_RENDERER=cairo \
		python3 "$HOME/.config/swaync/scripts/minipanel.py" daemon "$@"
}

running_pid() {
	local pid
	pid=$(cat "$PIDFILE" 2>/dev/null) || return 1
	# PID dosyası eskimiş olabilir: gerçekten minipanel.py mi?
	grep -qa minipanel.py "/proc/$pid/cmdline" 2>/dev/null && echo "$pid"
}

case $1 in
	power | notif)
		if pid=$(running_pid); then
			[[ $1 == power ]] && kill -USR1 "$pid" || kill -USR2 "$pid"
		else
			start "$1"
		fi
		;;
	daemon)
		running_pid > /dev/null && exit 0
		start
		;;
	*)
		echo "kullanım: $0 power|notif|daemon" >&2
		exit 1
		;;
esac
