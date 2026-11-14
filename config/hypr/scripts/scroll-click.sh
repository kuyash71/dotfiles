#!/usr/bin/env bash
#
# Fare tekerleği yukarı = sol tık, aşağı = sağ tık (geçici)
#   scroll-click on|off     aç / kapat (~/.local/bin'deki bağlantı üzerinden)
#   scroll-click            değiştir (SUPER+SHIFT+C)
#
# Kısayollar config'e yazılmaz, çalışma anında eklenir: Hyprland yeniden
# başlayınca ya da config yenilenince normale döner. submap_universal
# sayesinde oyun modunda da çalışır.
# ignore_mods: Shift/Ctrl basılıyken de tıklasın (yoksa kısayol eşleşmez,
# hareket normal kaydırma olur).
#
# scroll_event_delay: Hyprland bir tekerlek kısayolundan sonra bu süre (ms)
# boyunca gelen olayları normal kaydırma olarak uygulamaya geçiriyor. Mod açıkken
# 0 olmalı, yoksa kaydırma sürer ve tık hızı sınırlanır. Kapanınca varsayılana döner.

active() {
	hyprctl binds -j | jq -e '[.[] | select(.key == "mouse_up" and .modmask == 0)] | length > 0' > /dev/null
}

on() {
	hyprctl eval 'hl.config({ binds = { scroll_event_delay = 0 } })
		hl.bind("mouse_up", hl.dsp.send_shortcut({ mods = "", key = "mouse:272" }), { submap_universal = true, ignore_mods = true })
		hl.bind("mouse_down", hl.dsp.send_shortcut({ mods = "", key = "mouse:273" }), { submap_universal = true, ignore_mods = true })' > /dev/null
	swayosd-client --custom-message "Tekerlek: sol / sağ tık" --custom-icon input-mouse-symbolic
}

off() {
	hyprctl eval 'hl.unbind("mouse_up") hl.unbind("mouse_down")
		hl.config({ binds = { scroll_event_delay = 300 } })' > /dev/null
	swayosd-client --custom-message "Tekerlek normal" --custom-icon input-mouse-symbolic
}

case ${1:-toggle} in
	on) active || on ;;
	off) active && off ;;
	toggle) if active; then off; else on; fi ;;
	*)
		echo "kullanım: $0 [on|off|toggle]" >&2
		exit 1
		;;
esac
exit 0
