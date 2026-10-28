#!/bin/bash

if hyprctl clients | grep -q 'app.zen_browser.zen'; then
    if hyprctl clients -j | grep -q '"special:zen"'; then
        hyprctl dispatch togglespecialworkspace zen
    else
        hyprctl dispatch movetoworkspace special:zen
    fi
else
    flatpak run app.zen_browser.zen &
    sleep 1.5
    hyprctl dispatch movetoworkspace special:zen
fi