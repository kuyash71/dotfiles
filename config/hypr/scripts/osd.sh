#!/usr/bin/env bash
#
# swayosd-client sarmalayıcı: göstergeyi sadece odaktaki monitörde göster
# (varsayılan olarak tüm monitörlerde çıkıyor).

mon=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')
exec swayosd-client ${mon:+--monitor "$mon"} "$@"
