#!/usr/bin/env bash
#
# Hangi uygulamalar bildirim gönderebilir?
#   log   -> SwayNC "scripts" tarafından her bildirimde çağrılır; uygulama
#            adını bilinen uygulamalar listesine ekler
#   toggle <uygulama> -> uygulamanın bildirimlerini aç / kapat
#                        (NOTIFICATIONS çarkı: mini-panel.sh notif → minipanel.py)
#
# Kapatılan uygulamalar config.json'daki "notification-visibility" altına
# "block: <ad>" anahtarıyla state=ignored olarak yazılır (bildirim hiç gelmez).

CONFIG="$HOME/.config/swaync/config.json"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/swaync"
KNOWN="$STATE_DIR/known-apps"
PREFIX="block: "

blocked_apps() {
	jq -r --arg p "$PREFIX" \
		'(."notification-visibility" // {}) | keys[] | select(startswith($p)) | ltrimstr($p)' \
		"$CONFIG"
}

regex_escape() {
	sed 's/[][\.*^$+?(){}|\/]/\\&/g' <<< "$1"
}

toggle() {
	local app=$1 key="$PREFIX$1" tmp
	tmp=$(mktemp)
	if blocked_apps | grep -qxF -- "$app"; then
		jq --arg k "$key" 'del(."notification-visibility"[$k])' "$CONFIG" > "$tmp"
	else
		jq --arg k "$key" --arg re "^$(regex_escape "$app")\$" \
			'."notification-visibility"[$k] = {state: "ignored", "app-name": $re}' \
			"$CONFIG" > "$tmp"
	fi
	# Bozuk JSON yazıp SwayNC'yi açılmaz hale getirmeyelim
	if jq -e . "$tmp" > /dev/null 2>&1; then
		cat "$tmp" > "$CONFIG"
	fi
	rm -f "$tmp"
	swaync-client -R > /dev/null 2>&1
}

case $1 in
	log)
		[[ -n $SWAYNC_APP_NAME ]] || exit 0
		mkdir -p "$STATE_DIR"
		grep -qxF -- "$SWAYNC_APP_NAME" "$KNOWN" 2>/dev/null ||
			printf '%s\n' "$SWAYNC_APP_NAME" >> "$KNOWN"
		exit 0
		;;
	toggle)
		[[ -n $2 ]] && toggle "$2"
		;;
	*)
		echo "kullanım: $0 log|toggle <uygulama>" >&2
		exit 1
		;;
esac
