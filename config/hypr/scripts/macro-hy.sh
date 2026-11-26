#!/usr/bin/env bash
#
# Oyunlar için makro, açıkken:
#   ALT + orta tık   W + D + sol tık basılı tut / bırak
#   SHIFT + orta tık  sol tık basılı tut / bırak
#
#   macro-hy on|off     makroyu aç / kapat (~/.local/bin'deki bağlantı üzerinden)
#   macro-hy            değiştir
#   macro-hy press      W + D + sol tık (ALT + orta tık bunu çalıştırır)
#   macro-hy click      sol tık (SHIFT + orta tık bunu çalıştırır)
#
# Basılı tutma Hyprland kısayoluyla yapılamıyor (send_shortcut bas-bırak
# gönderiyor); bu yüzden macro-hy.py sanal klavye + fare oluşturup tuşları
# tutuyor, buradan sinyal alıyor. Kısayollar scroll-click gibi çalışma anında
# eklenir; submap_universal sayesinde oyun modunda da çalışır. Kapatınca
# basılı tuş kalmaz. Sol tıka kısayol bağlanmıyor: sanal sol tık basılıyken
# gerçek sol tık yutuluyor, bırakmak imkansızlaşıyordu.

PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/kvara-macro-hy.pid"
DIR="$(dirname "$(readlink -f "$0")")"

running_pid() {
	local pid
	pid=$(cat "$PIDFILE" 2>/dev/null) || return 1
	# PID dosyası eskimiş olabilir: gerçekten macro-hy.py mi?
	grep -qa macro-hy.py "/proc/$pid/cmdline" 2>/dev/null && echo "$pid"
}

bind() {
	hyprctl eval 'hl.bind("'"$1"' + mouse:274", hl.dsp.exec_cmd("'"$DIR"'/macro-hy.sh '"$2"'"), { submap_universal = true })' > /dev/null
}

on() {
	# nohup: terminal kapanınca (SIGHUP) süreç de kapanmasın
	nohup python3 "$DIR/macro-hy.py" < /dev/null &> /dev/null &
	echo $! > "$PIDFILE"
	bind ALT press
	bind SHIFT click
	swayosd-client --custom-message "Makro açık: ALT+orta = W+D+sol tık, SHIFT+orta = sol tık" --custom-icon input-mouse-symbolic
}

off() {
	hyprctl eval 'hl.unbind("ALT + mouse:274")' > /dev/null
	hyprctl eval 'hl.unbind("SHIFT + mouse:274")' > /dev/null
	kill "$1"
	rm -f "$PIDFILE"
	swayosd-client --custom-message "Makro kapalı" --custom-icon input-mouse-symbolic
}

case ${1:-toggle} in
	on) running_pid > /dev/null || on ;;
	off) pid=$(running_pid) && off "$pid" ;;
	toggle) if pid=$(running_pid); then off "$pid"; else on; fi ;;
	press) pid=$(running_pid) && kill -USR1 "$pid" ;;
	click) pid=$(running_pid) && kill -USR2 "$pid" ;;
	*)
		echo "kullanım: $0 [on|off|toggle|press|click]" >&2
		exit 1
		;;
esac
exit 0
