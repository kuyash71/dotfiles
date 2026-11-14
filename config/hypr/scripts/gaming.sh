#!/usr/bin/env bash
#
# Oyun modu: Hyprland kısayollarını kapatır, tuşlar doğrudan oyuna gider.
#   gaming.sh get      -> true/false
#   gaming.sh on|off
#   gaming.sh toggle   (SUPER+SHIFT+G)
#
# Mod, hyprland.lua'daki "gaming" submap'i. Control Panel'deki oyun kolu butonu
# toggle.sh üzerinden buraya gelir; durumu panel her açıldığında okunur.

active() { [[ $(hyprctl submap) == gaming ]]; }
on() { hyprctl dispatch 'hl.dsp.submap("gaming")' > /dev/null; }
off() { hyprctl dispatch 'hl.dsp.submap("reset")' > /dev/null; }

case $1 in
	get) active && echo true || echo false ;;
	on) on ;;
	off) off ;;
	toggle) if active; then off; else on; fi ;;
	*)
		echo "kullanım: $0 get|on|off|toggle" >&2
		exit 1
		;;
esac
