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
        gears.wallpaper.maximized("/home/w/img/wp/QmQRUFTicaw24gVAyrdcVHUYKy8A4jdr49KwxxCzmQXnwc", s)
    end
    if s.index == 2 then
        gears.wallpaper.maximized("/home/w/img/wp/QmdtHf8AfxUQwfnK6Z1J7EoBNByLiagqDWU9eM3g8DgJtx", s)
    end
end

return theme
