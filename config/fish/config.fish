source /usr/share/cachyos-fish-config/cachyos-config.fish

function dolphin
    command dolphin . >/dev/null 2>&1 & disown
end

alias ffetch="fastfetch"

alias cls="printf '\033c'"

function hypdot
    subl ~/.config/hypr/hyprland.conf
end

alias vpn-on='sudo systemctl start mullvad-daemon && mullvad connect'

alias vpn-off='mullvad disconnect && sudo systemctl stop mullvad-daemon'

alias drone-env='distrobox enter drone-env'
