#!/bin/bash

# ── Ayarlar ───────────────────────────────────────────────────────────────────
MAX_ITEMS=50          # Rofi'de gösterilecek maksimum element sayısı
CACHE_DIR="/tmp/cliphist-thumbs"
ICON_DIR="$CACHE_DIR/icons"
ICON_IMG="$ICON_DIR/img_thumb"
ICON_SHORT="$ICON_DIR/short_text.png"
ICON_LONG="$ICON_DIR/long_text.png"
FONT_NAME="JetBrainsMono Nerd Font"
# ─────────────────────────────────────────────────────────────────────────────

mkdir -p "$ICON_DIR"

# Metin ikonlarını oluştur (yoksa)
generate_text_icon() {
    local label="$1" out="$2" fg="$3" bg="$4"
    [ -f "$out" ] && return
    convert -size 48x48 xc:"$bg" \
        -fill "$fg" -font "$FONT_NAME" -pointsize 22 \
        -gravity Center -annotate 0 "$label" \
        "$out" 2>/dev/null
}

generate_text_icon "󰧮" "$ICON_SHORT" "#cdd6f4" "#1e1e2e"
generate_text_icon "󰦨" "$ICON_LONG"  "#cdd6f4" "#1e1e2e"

# cliphist listesini al ve MAX_ITEMS ile sınırla
mapfile -t entries < <(cliphist list | head -n "$MAX_ITEMS")

rofi_input=""
num=0

for entry in "${entries[@]}"; do
    raw_id="${entry%%$'\t'*}"
    content="${entry#*$'\t'}"

    # Görselleri tespit et
    if echo "$entry" | cliphist decode 2>/dev/null | file - 2>/dev/null | grep -qiE 'image|png|jpeg|gif|webp'; then
        thumb="$ICON_DIR/img_${raw_id}.png"
        if [ ! -f "$thumb" ]; then
            echo "$entry" | cliphist decode 2>/dev/null | \
                convert - -thumbnail 48x48^ -gravity Center -extent 48x48 "$thumb" 2>/dev/null \
                || cp "$ICON_SHORT" "$thumb"
        fi
        num=$((num + 1))
        rofi_input+="${num}. [Görsel]\0icon\x1f${thumb}\n"
    else
        clean=$(echo "$content" | tr '\n' ' ' | sed 's/  */ /g' | cut -c1-80)
        num=$((num + 1))
        if [ ${#content} -gt 150 ]; then
            rofi_input+="${num}. ${clean}\0icon\x1f${ICON_LONG}\n"
        else
            rofi_input+="${num}. ${clean}\0icon\x1f${ICON_SHORT}\n"
        fi
    fi
done

# Rofi — sabit yükseklik, ikonlar sol kolonda
chosen=$(echo -en "$rofi_input" | rofi -dmenu -p " Pano Geçmişi" \
    -show-icons \
    -theme-str 'window { width: 620px; }' \
    -theme-str 'listview { lines: 10; fixed-height: true; dynamic: false; }' \
    -theme-str 'element { padding: 6px 8px; }' \
    -theme-str 'element-icon { size: 36px; margin: 0 8px 0 0; }' \
    -theme-str 'element-text { vertical-align: 0.5; }' \
    -theme-str 'inputbar { padding: 8px 12px; }')

[ -z "$chosen" ] && exit 0

index=$(echo "$chosen" | grep -oP '^\d+')
[ -z "$index" ] && exit 0

original="${entries[$((index - 1))]}"
echo "$original" | cliphist decode | wl-copy

notify-send " Pano" "Panoya kopyalandı!" -t 1500