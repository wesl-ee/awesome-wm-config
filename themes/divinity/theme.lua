local theme_assets = require("beautiful.theme_assets")
local gears = require("gears")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi

local gfs = require("gears.filesystem")
local themes_path = gfs.get_themes_dir()
local naughty = require("naughty")

local theme = {}

theme.wallpaper = function(s)
    -- Horizontal
    if s.index == 1 then
        gears.wallpaper.maximized("/home/w/img/wp/bafkreien5twpk7fo3wybvywprtdc6ghm7dcjtubfaq5xehm676yfkdqvfa", s)
    end
    -- Vertical
    if s.index == 2 then
        gears.wallpaper.maximized("/home/w/img/wp/bafkreicrwwqell7sbe2yhna7koogx57mydekvr3qup6lq7s4osatvtqa3i", s)
    end
end

return theme
