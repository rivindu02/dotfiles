-- Hyprland Lua Config
-- Based on official example + personal config
-- https://wiki.hypr.land/Configuring/Start/

require("monitors")
require("workspaces")


---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "ghostty"
local fileManager = "ghostty -e yazi"
local browser     = "brave"


-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("swww-daemon && swww img /home/rivindu02/Pictures/Wallpapers/wallhaven-rqyp17.jpg --transition-type none")
    hl.exec_cmd("sleep 0.5 && hyprctl setcursor Bibata-Modern-Classic 24")
    hl.exec_cmd("waybar")
    hl.exec_cmd("swaync")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("mkdir -p /tmp/cliphist-store")
    hl.exec_cmd("wl-paste --type text --watch ~/.config/scripts/cliphist-secure-store.sh")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("~/.config/scripts/gcal-notify.sh")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("~/.config/scripts/battery-warn.sh")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("NIXOS_OZONE_WL", "1")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("GTK_CSD", "0")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("CLIPHIST_MAX_ITEMS", "50")


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 8,

        border_size = 3,

        col = {
            active_border   = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },

        resize_on_border = true,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding       = 8,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 0.85,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 1,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        background_color         = 0x000000,
    },

    input = {
        kb_layout    = "us",
        repeat_rate  = 25,
        repeat_delay = 300,
        follow_mouse = 1,
        sensitivity  = 0,

        touchpad = {
            natural_scroll = true,
            scroll_factor  = 0.2,
            tap_to_click   = true,
        },
    },
})


--------------------
---- ANIMATIONS ----
--------------------

hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default"       })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint"  })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint"  })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear"  })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear"  })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick"         })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint"  })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear"  })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear"  })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,    bezier = "quick"         })


--------------------
---- DEVICE --------
--------------------

hl.device({
    name          = "usb-gaming-mouse-",
    accel_profile = "flat",
    sensitivity   = 0.0,
    scroll_factor = 1.0,
})


--------------------
---- GESTURES ------
--------------------

-- 3-finger horizontal = switch workspace
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- 3-finger down = open rofi launcher
hl.gesture({
    fingers   = 3,
    direction = "down",
    action    = function()
        hl.exec_cmd("pkill rofi || /home/rivindu02/.config/rofi/launchers/type-1/launcher.sh")
    end,
})

-- 4-finger up = volume up
hl.gesture({
    fingers   = 4,
    direction = "up",
    action    = function()
        hl.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+")
    end,
})

-- 4-finger down = volume down
hl.gesture({
    fingers   = 4,
    direction = "down",
    action    = function()
        hl.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")
    end,
})


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"
local secondMod = "SUPER + SHIFT"

hl.bind(mainMod .. " + Q",     hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + B",     hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + C",     hl.dsp.window.close())
hl.bind(mainMod .. " + E",     hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + F",     hl.dsp.window.float({ action = "toggle" }))
hl.bind(secondMod .. " + F",   hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mainMod .. " + P",     hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/presentation"))
hl.bind(mainMod .. " + J",     hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd("/home/rivindu02/.config/rofi/launchers/type-1/launcher.sh || pkill rofi"))
hl.bind(secondMod .. " + Space", hl.dsp.exec_cmd("/home/rivindu02/.config/rofi/launchers/type-1/launcher2.sh  || pkill rofi"))
hl.bind(mainMod .. " + M",     hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/powermenu"))
hl.bind(mainMod .. " + l",     hl.dsp.exec_cmd("hyprlock"))

-- Clipboard
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("cliphist list | rofi -dmenu -display-columns 2 -theme ~/.config/rofi/launchers/type-1/style.rasi | cliphist decode | bash -c 'touch /tmp/cliphist-silent && wl-copy'"))
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("bash -c 'touch /tmp/cliphist-silent && wl-paste -p --no-newline | wl-copy'"))

-- Utilities
hl.bind(mainMod .. " + N",          hl.dsp.exec_cmd("swaync-client -t -sw"))
hl.bind(mainMod .. " + period",     hl.dsp.exec_cmd("/home/rivindu02/.local/bin/bemoji-rofi"))
hl.bind(mainMod .. " + SHIFT + S",  hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/screenshot"))
hl.bind(mainMod .. " + SHIFT + T",  hl.dsp.exec_cmd("OCR4Linux --lang eng"))
hl.bind(mainMod .. " + D",          hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/define"))
hl.bind(mainMod .. " + W",          hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/writ"))
hl.bind(mainMod .. " + U",          hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/bookmark"))
hl.bind(mainMod .. " + I",          hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/psearch"))
hl.bind(mainMod .. " + S",          hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/search"))

-- Focus
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left"  }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up"    }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down"  }))

-- Workspaces
for i = 1, 10 do
	local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + CTRL + S", hl.dsp.workspace.toggle_special("magic"))

-- Mouse workspace scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

---- Function keys ----
-- Volume & brightness
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Media
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Screenshot
hl.bind("Print",          hl.dsp.exec_cmd("bash -c 'FILE=~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png && grim $FILE && wl-copy < $FILE && notify-send \"Screenshot\" \"Saved & copied to clipboard\" -i $FILE -t 2000'"), { locked = true })

-- Launcher
hl.bind("XF86Launch1",    hl.dsp.exec_cmd("ghostty --class=btop_float -e btop"), { locked = true })


------------------------------
------- WINDOW RULES ---------
------------------------------

hl.window_rule({
	-- Ignore maximize requests from all apps. You'll probably like this.
	name = "suppress-maximize-events",
	match = { class = ".*" },

	suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})

-- hl.window_rule({
--     name   = "float-btop",
--     match  = { class = "btop" },
--     float  = true,
--     size   = "900 600",
--     center = true,
-- })
--
-- hl.window_rule({
--     name   = "writ-float",
--     match  = { class = "writ_float" },
--     float  = true,
--     size   = "700 450",
--     center = true,
-- })
--
-- -- Zoom
-- hl.window_rule({ name = "zoom-menu",             match = { title = "^(menu window)$",                   class = "^(zoom)$" }, stay_focused = true  })
-- hl.window_rule({ name = "zoom-confirm",          match = { title = "^(confirm window)$",                class = "^(zoom)$" }, stay_focused = true  })
-- hl.window_rule({ name = "zoom-annotate-toolbar", match = { title = "^(annotate_toolbar)$",              class = "^(Zoom)$" }, float = true         })
-- hl.window_rule({ name = "zoom-as-toolbar",       match = { title = "^(as_toolbar)$",                    class = "^(Zoom)$" }, float = true         })
-- hl.window_rule({ name = "zoom-main",             match = { title = "^(Zoom Workplace)",                 class = "^(Zoom)$" }, border_size = 0, rounding = 0 })
-- hl.window_rule({ name = "zoom-meeting",          match = { title = "^(Meeting)$",                       class = "^(Zoom)$" }, border_size = 0      })
-- hl.window_rule({ name = "zoom-video-window",     match = { title = "^(zoom_linux_float_video_window)$", class = "^(Zoom)$" }, float = true         })
-- hl.window_rule({ name = "zoom-leave",            match = { title = "^(Leave meeting panel)$",           class = "^(Zoom)$" }, float = true         })
-- hl.window_rule({ name = "zoom-annotation",       match = { title = "^(Annotation - Zoom)$",             class = "^(Zoom)$" }, float = true, no_blur = true })


------------------------------
---- LAYER RULES -------------
------------------------------

-- SwayNC
hl.layer_rule({ match = { namespace = "swaync-control-center"      }, blur = true, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "swaync-notification-window" }, blur = true, ignore_alpha = 0.5 })

-- Rofi
hl.layer_rule({ match = { namespace = "rofi" }, blur = true, ignore_alpha = 0.5 })
