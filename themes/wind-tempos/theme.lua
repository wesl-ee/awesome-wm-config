local theme_assets = require("beautiful.theme_assets")
local gears = require("gears")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi

local gfs = require("gears.filesystem")
local themes_path = gfs.get_themes_dir()
local naughty = require("naughty")

local theme = {}

theme.wallpaper = function(s)
    if s.index == 1 then
        gears.wallpaper.maximized("/home/wesl-ee/img/wp/Qma6e6x1otdYJ2trxkrzC2pEMujHPyWEQ2b8UJFUT1RJMw", s)
    end
end

return theme
