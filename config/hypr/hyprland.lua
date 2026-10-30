-- Hyprland 0.57+ Lua config.
-- 0.57 hyprlang (.conf) desteğini kaldırdı; bu dosya eski hyprland.conf'un
-- birebir çevirisi. hyprland.conf artık okunmuyor, sadece arşiv olarak duruyor.
-- Söz dizimi: /usr/share/hypr/stubs/hl.meta.lua ve https://wiki.hypr.land/configuring/

------------------
---- MONITORS ----
------------------

hl.monitor({ output = "eDP-1", mode = "1920x1080@144", position = "0x0",    scale = 1.25 })
hl.monitor({ output = "DP-1",  mode = "1920x1080@60",  position = "1536x0", scale = 1.25 })


---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "kitty"
local fileManager = "dolphin"
local menu        = "rofi -show drun -show-icons"


-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_MENU_PREFIX")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_MENU_PREFIX")
    hl.exec_cmd("kbuildsycoca6")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("waypaper --restore")
    hl.exec_cmd("waybar")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("~/.config/hypr/scripts/start-mcontrolcenter.sh")
    hl.exec_cmd("flatpak run app.zen_browser.zen")
    hl.exec_cmd("wl-paste --type text --watch cliphist --max-items 200 store")
    hl.exec_cmd("wl-paste --type image --watch cliphist --max-items 50 store")

    hl.exec_cmd("mullvad lockdown-mode set off")
    hl.exec_cmd("swaync")
    hl.exec_cmd("swayosd-server")

    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")

    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 20")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "20")

hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("XDG_MENU_PREFIX", "arch-")


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 3,
        gaps_out = 10,

        border_size = 2,

        col = {
            active_border   = { colors = { "rgba(b4befeaa)", "rgba(eec41a77)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },

        resize_on_border = false,
        allow_tearing    = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 0.98,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = "rgba(1a1a1aee)",
        },

        blur = {
            enabled           = true,
            size              = 5,
            passes            = 3,
            ignore_opacity    = true,
            noise             = 0.0,
            contrast          = 1.1,
            xray              = false,
            new_optimizations = true,

            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})

hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}    } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}  } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,    bezier = "quick" })

hl.config({
    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo   = false,
    },

    xwayland = {
        force_zero_scaling = true,
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    cursor = {
        no_hardware_cursors = true,
    },

    input = {
        kb_layout  = "tr",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = -0.4, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.gesture({ fingers = 2, direction = "horizontal", action = "workspace" })


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(terminal))
hl.bind("CTRL + SHIFT + Z",    hl.dsp.exec_cmd("flatpak run app.zen_browser.zen"))
hl.bind("CTRL + W",            hl.dsp.window.close())
hl.bind("CTRL + SPACE",        hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + TAB",   hl.dsp.window.float({ action = "toggle" }))
hl.bind("ALT + SPACE",         hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P",     hl.dsp.window.pseudo())              -- dwindle
hl.bind(mainMod .. " + J",     hl.dsp.layout("togglesplit"))        -- dwindle
hl.bind(mainMod .. " + B",     hl.dsp.exec_cmd("killall -SIGUSR2 waybar"))
hl.bind(mainMod .. " + L",     hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + F",     hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + O",     hl.dsp.window.float({ action = "toggle" }))

hl.bind(mainMod .. " + V",         hl.dsp.exec_cmd("~/.config/hypr/scripts/clipboard.sh"))
hl.bind(mainMod .. " + N",         hl.dsp.exec_cmd("swaync-client -t -sw"))   -- Bildirim merkezi
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("swaync-client -d -sw"))   -- Rahatsız Etme

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + T",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.window.move({ workspace = "special:magic" }))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- --- HYPRSHOT KISAYOLLARI ---
hl.bind("PRINT",                   hl.dsp.exec_cmd("hyprshot -m output"))
hl.bind(mainMod .. " + PRINT",     hl.dsp.exec_cmd("hyprshot -m window"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("hyprshot -m region -o ~/Documents/HyprShot"))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Multimedia tuşları — SwayOSD: değişikliği yapar ve ekranda gösterge çıkarır
local osd = "~/.config/hypr/scripts/osd.sh "
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd(osd .. "--output-volume raise --max-volume 100"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd(osd .. "--output-volume lower"),                  { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd(osd .. "--output-volume mute-toggle"),            { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd(osd .. "--input-volume mute-toggle"),             { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(osd .. "--brightness raise"),                     { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(osd .. "--brightness lower"),                     { locked = true, repeating = true })
hl.bind("Caps_Lock",             hl.dsp.exec_cmd(osd .. "--caps-lock"),                            { release = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- --- Rofi Blur Kuralı ---
hl.layer_rule({
    name  = "rofi-blur",
    match = { namespace = "rofi" },
    blur  = true,
})

-- --- SwayNC: kontrol paneli (blur + sağdan içeri kayar) ---
hl.layer_rule({
    name         = "swaync-panel",
    match        = { namespace = "swaync-control-center" },
    blur         = true,
    ignore_alpha = 0.3,
    animation    = "slide right",
})

-- --- SwayNC: açılır bildirimler ---
hl.layer_rule({
    name         = "swaync-popups",
    match        = { namespace = "swaync-notification-window" },
    blur         = true,
    ignore_alpha = 0.3,
})

-- --- SwayOSD: ses/parlaklık göstergesi (blur yok, bkz. swayosd/style.css) ---
hl.layer_rule({
    name      = "swayosd",
    match     = { namespace = "swayosd" },
    animation = "popin 90%",
})

-- Monitor 1 (eDP-1) - Sol Ekran
hl.workspace_rule({ workspace = "1", monitor = "eDP-1", default = true })
hl.workspace_rule({ workspace = "2", monitor = "eDP-1" })
hl.workspace_rule({ workspace = "3", monitor = "eDP-1" })

-- Monitor 2 (DP-1) - Sağ Ekran
hl.workspace_rule({ workspace = "4", monitor = "DP-1", default = true })
hl.workspace_rule({ workspace = "5", monitor = "DP-1" })
hl.workspace_rule({ workspace = "6", monitor = "DP-1" })

-- --- Gsimplecal (Takvim) ---
hl.window_rule({
    name  = "gsimplecal-fix",
    match = { class = "^(gsimplecal)$" },

    float = true,
    pin   = true,
    move  = "cursor -50% 5%",
})

hl.window_rule({
    name  = "waybar-popups-small",
    match = { class = ".*(pavucontrol|nm-connection-editor|blueman-manager).*" },

    float  = true,
    center = true,
    size   = "400 500",
})

hl.window_rule({
    name  = "waybar-popups-large",
    match = { class = "^(missioncenter)$" },

    float  = true,
    center = true,
    size   = "700 600",
})

hl.window_rule({
    -- Ignore maximize requests from all apps.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

-- TeamViewer (XWayland) diyalogları ekran dışı koordinatlarda doğuyor.
-- Parola penceresi görünmeyince bağlantı "Authenticating"de asılı kalıyor.
hl.window_rule({
    name  = "teamviewer-dialogs-center",
    match = {
        class = "^(TeamViewer)$",
        title = "^(TeamViewer Authentication)$",
    },

    float  = true,
    center = true,
})
