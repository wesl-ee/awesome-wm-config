local theme_assets = require("beautiful.theme_assets")
local gears = require("gears")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi

local gfs = require("gears.filesystem")
local themes_path = gfs.get_themes_dir()
local naughty = require("naughty")

local theme = {}

theme.font          = "Noto Sans CJK JP 8"
theme.launcher_font          = "Noto Sans CJK JP 8"

theme.wallpaper = function(s)
    if s.index == 1 then
        gears.wallpaper.maximized("/home/wesl-ee/img/wp/QmcXS4K9ztqMEMtRq1U3YXfBe3xdhYgR48NhGfLq1n1D22", s)
    end
end

return theme
