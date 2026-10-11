-- ╔══════════════════════════════════════════════════╗
-- ║      swayimg init.lua — Gruvbox Material Dark    ║
-- ╚══════════════════════════════════════════════════╝
--
-- Only overrides live here; every built-in default (PgDown/PgUp, +/-, [ ], m,
-- s, t, f, Enter, Esc, ...) still works. Full defaults: /usr/share/swayimg/example.lua
--
-- Added keys (viewer):
--   h / l, Space / Shift+Space   previous / next image
--   g / G                        first / last image
--   z                            toggle fit-to-window / real size (100%)
--   y                            copy image to clipboard
--   Shift+y                      copy file path to clipboard
--   o                            open yazi with this file selected
--   r                            reload image from disk
--   Delete                       move file to trash (~/.local/share/Trash, restorable)
--   q                            quit
-- Added keys (gallery): h j k l move, g / G first / last, y, Shift+y, o, Delete, q
--
-- Mouse: left-drag an image into a browser/chat/file manager to drop the file there.
--        Pan a zoomed image with scroll, arrow keys or middle-drag.

-- Gruvbox Material palette (0xAARRGGBB)
local bg      = 0xff1d2021
local surface = 0xff32302f
local fg      = 0xffd4be98
local blue    = 0xff7daea3

--------------------------------------------------------------------------------
-- General
--------------------------------------------------------------------------------
swayimg.decoration = false               -- Hyprland draws the border
swayimg.imagelist.adjacent = true        -- open one file, browse its whole folder
swayimg.dnd_button = "MouseLeft"         -- normal drag = drag-and-drop the file out
swayimg.viewer.drag_button = "MouseMiddle" -- panning moves off the left button

swayimg.text.font = "CaskaydiaMono Nerd Font"
swayimg.text.size = 18
swayimg.text.color = fg
swayimg.text.shadow = 0xa0000000
swayimg.text.timeout = 3                 -- info overlay fades after 3 s (t shows it again)

swayimg.viewer.set_window_background(bg)
swayimg.viewer.set_image_chessboard(16, 0xff282828, surface) -- transparency pattern

swayimg.gallery.window_color = bg
swayimg.gallery.unselected_color = 0xff282828
swayimg.gallery.selected_color = surface
swayimg.gallery.border_color = blue
swayimg.gallery.border_size = 3
swayimg.gallery.thumb_size = 220
swayimg.gallery.pstore = true            -- cache thumbnails on disk, big folders open faster

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------
-- Single-quote a path for the shell
local function q(s)
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

local function status(msg)
  swayimg.text.status = msg
end

local function copy_image(img)
  if not img then return end
  os.execute("wl-copy < " .. q(img.path))
  status("Copied image")
end

local function copy_path(img)
  if not img then return end
  os.execute("printf %s " .. q(img.path) .. " | wl-copy")
  status("Copied path")
end

local function open_yazi(img)
  if not img then return end
  os.execute("ghostty -e yazi " .. q(img.path) .. " >/dev/null 2>&1 &")
end

local function trash(img)
  if not img then return end
  if os.execute("gio trash " .. q(img.path)) then
    swayimg.imagelist.remove(img.path)
    status("Moved to trash")
  else
    status("Trash failed")
  end
end

--------------------------------------------------------------------------------
-- Viewer keys
--------------------------------------------------------------------------------
local v = swayimg.viewer

v.on_key("l",           function() v.open("next") end)
v.on_key("h",           function() v.open("prev") end)
v.on_key("space",       function() v.open("next") end)
v.on_key("Shift+space", function() v.open("prev") end)
v.on_key("g",           function() v.open("first") end)
v.on_key("Shift+g",     function() v.open("last") end)

local real_size = false
v.on_key("z", function()
  real_size = not real_size
  v.set_fix_scale(real_size and "real" or "optimal")
end)

v.on_key("y",            function() copy_image(v.get_image()) end)
v.on_key("Shift+y",      function() copy_path(v.get_image()) end)
v.on_key("o",            function() open_yazi(v.get_image()) end)
v.on_key("r",            function() v.reload() end)
v.on_key("Delete",       function() trash(v.get_image()) end)
v.on_key("q",            function() swayimg.exit() end)

--------------------------------------------------------------------------------
-- Gallery keys
--------------------------------------------------------------------------------
local gl = swayimg.gallery

gl.on_key("h",            function() gl.select("left") end)
gl.on_key("j",            function() gl.select("down") end)
gl.on_key("k",            function() gl.select("up") end)
gl.on_key("l",            function() gl.select("right") end)
gl.on_key("g",            function() gl.select("first") end)
gl.on_key("Shift+g",      function() gl.select("last") end)
gl.on_key("y",            function() copy_image(gl.get_image()) end)
gl.on_key("Shift+y",      function() copy_path(gl.get_image()) end)
gl.on_key("o",            function() open_yazi(gl.get_image()) end)
gl.on_key("Delete",       function() trash(gl.get_image()) end)
gl.on_key("q",            function() swayimg.exit() end)

--------------------------------------------------------------------------------
-- Slideshow
--------------------------------------------------------------------------------
swayimg.slideshow.timeout = 4
swayimg.slideshow.on_key("q", function() swayimg.exit() end)
