#!/usr/bin/env bash
#
# SwayNC Mullvad butonu
#   update  -> durumu oku, buton rengini (mullvad-state.css) güncelle, true/false yaz
#   toggle  -> daemon kapalıysa başlat + bağlan, bağlıysa kes (daemon açık kalır)
#   daemon  -> mini buton: daemon'u aç / kapat (kapatmadan önce VPN'i keser)
#   daemon-state -> mini butonun toggle durumu için true/false yaz
#
# Renkler: yeşil = bağlı, kırmızı = daemon açık ama VPN kapalı,
#          gri = daemon kapalı, altın = bağlanıyor

CSS="$HOME/.config/swaync/mullvad-state.css"
BTN=".control-center .apps flowboxchild:nth-child(1) > button"
MINI=".control-center .mvd flowboxchild > button"

state() {
	local s
	s=$(timeout 2 mullvad status 2>/dev/null) || { echo off; return; }
	case "$s" in
		Connected*)                 echo on ;;
		Connecting* | Reconnecting*) echo connecting ;;
		*)                          echo disconnected ;;
	esac
}

write_css() {
	local bg fg
	case $1 in
		on)           bg="#a6e3a1"; fg="#11111b" ;;
		connecting)   bg="#e5c283"; fg="#11111b" ;;
		disconnected) bg="#f38ba8"; fg="#11111b" ;;
		*)            bg="#45475a"; fg="#a6adc8" ;;
	esac
	# Mini daemon butonu: daemon açıksa yeşil, kapalıysa gri simge
	local mini="#a6e3a1"
	[[ $1 == off ]] && mini="#6c7086"
	local new="/* $1 — mullvad.sh tarafından otomatik yazılır */
$BTN, $BTN:hover { background: $bg; color: $fg; }
$BTN:hover { filter: brightness(1.1); }
$MINI, $MINI:hover { color: $mini; }"
	if [[ "$(cat "$CSS" 2>/dev/null)" != "$new" ]]; then
		printf '%s\n' "$new" > "$CSS"
		# update-command içinden çağrılabiliyoruz: SwayNC komut çıktısını
		# okurken CSS'i yeniden yüklemek onu çökertebiliyor. Bu yüzden
		# yeniden yüklemeyi biz döndükten sonra, arka planda yap.
		setsid -f sh -c 'sleep 0.3; swaync-client -rs' > /dev/null 2>&1
	fi
}

case $1 in
	update)
		s=$(state)
		write_css "$s"
		[[ $s == on ]] && echo true || echo false
		;;
	toggle)
		s=$(state)
		case $s in
			off)
				write_css connecting
				systemctl start mullvad-daemon || { write_css off; exit 1; }
				for _ in {1..20}; do
					mullvad status > /dev/null 2>&1 && break
					sleep 0.5
				done
				mullvad connect
				;;
			disconnected) mullvad connect ;;
			*)            mullvad disconnect ;;
		esac
		# Durum oturana kadar rengi canlı güncelle (en fazla ~15 sn)
		for _ in {1..30}; do
			sleep 0.5
			s=$(state)
			write_css "$s"
			[[ $s == on || $s == disconnected ]] && break
		done
		;;
	daemon-state)
		[[ $(state) == off ]] && echo false || echo true
		;;
	daemon)
		if [[ $(state) == off ]]; then
			systemctl start mullvad-daemon || exit 1
			want=disconnected
		else
			mullvad disconnect > /dev/null 2>&1
			systemctl stop mullvad-daemon || exit 1
			want=off
		fi
		# Yeni durum oturana kadar renkleri güncelle (en fazla ~10 sn)
		for _ in {1..20}; do
			sleep 0.5
			s=$(state)
			write_css "$s"
			[[ $s == "$want" || ($want == disconnected && $s == on) ]] && break
		done
		;;
	*)
		echo "kullanım: $0 update|toggle|daemon|daemon-state" >&2
		exit 1
		;;
esac
