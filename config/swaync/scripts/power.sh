#!/usr/bin/env bash
#
# SwayNC güç butonları. Kapat / yeniden başlat / çıkış onay ister.

confirm() {
	local ans
	ans=$(notify-send -u critical -a "Control Panel" -i system-shutdown \
		-A yes="Evet" -A no="Vazgeç" "Emin misin?" "$1")
	[[ $ans == yes ]]
}

# Oturum uwsm ile başlatıldıysa uwsm üzerinden, değilse doğrudan Hyprland'den çık
logout_session() {
	if uwsm check is-active > /dev/null 2>&1; then
		uwsm stop
	else
		hyprctl dispatch 'hl.dsp.exit()'
	fi
}

case $1 in
	lock)     swaync-client -cp; hyprlock ;;
	suspend)  swaync-client -cp; systemctl suspend ;;
	logout)   confirm "Oturum kapatılacak."         && logout_session ;;
	reboot)   confirm "Bilgisayar yeniden başlatılacak." && systemctl reboot ;;
	poweroff) confirm "Bilgisayar kapatılacak."     && systemctl poweroff ;;
esac
