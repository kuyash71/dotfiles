#!/usr/bin/env bash
#
# SwayNC toggle butonları. SwayNC iç içe tırnaklı komutları doğru bölemediği
# için mantık burada duruyor.
#   toggle.sh <wifi|bt|dnd> get  -> true/false (update-command)
#   toggle.sh <wifi|bt|dnd> set  -> $SWAYNC_TOGGLE_STATE'e göre aç/kapat

on=false
[[ $SWAYNC_TOGGLE_STATE == true ]] && on=true

case $1:$2 in
	wifi:get) [[ $(nmcli radio wifi) == enabled ]] && echo true || echo false ;;
	wifi:set) $on && nmcli radio wifi on || nmcli radio wifi off ;;
	bt:get)   bluetoothctl show | grep -q "Powered: yes" && echo true || echo false ;;
	bt:set)   $on && bluetoothctl power on > /dev/null || bluetoothctl power off > /dev/null ;;
	dnd:get)  swaync-client -D ;;
	dnd:set)  $on && swaync-client -dn > /dev/null || swaync-client -df > /dev/null ;;
	*) echo "kullanım: $0 <wifi|bt|dnd> <get|set>" >&2; exit 1 ;;
esac
