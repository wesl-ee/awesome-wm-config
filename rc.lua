-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi
local Gio = require("lgi").Gio
local hostname = io.popen("uname -n"):read()

awful.screen.set_auto_dpi_enabled(true)
math.randomseed(os.time())

-- Widgets
local cpu_widget = require("widgets.cpu-widget.cpu-widget")
local ram_widget = require("widgets.ram.ram")
local volume_widget = require("widgets.volume.volume")
local github_contributions_widget = require("widgets.github-contributions.github-contributions")
local notmuch_mail_widget = require("widgets.notmuch-mail.notmuch-mail")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
local hostThemeFilename = gears.filesystem.get_configuration_dir()
    .. "themes/"
    .. hostname
    .. "/theme.lua"
local defaultTheme = loadfile(gears.filesystem.get_configuration_dir()
    .. "themes/default/theme.lua")()
local hostTheme = loadfile(gears.filesystem.get_configuration_dir()
    .. "themes/"
    .. hostname
    .. "/theme.lua")

local theme = defaultTheme
if hostTheme then
    theme = gears.table.join(theme, hostTheme())
end

beautiful.init(theme)

terminal = "alacritty"
function brightness_up()
    awful.spawn("brightnessctl -d intel_backlight s 5%+")
    curr_brightness("Brightness Up")
end
function brightness_down()
    awful.spawn("brightnessctl -d intel_backlight s 5%-")
    curr_brightness("Brightness Down")
end
function brightness_min()
    awful.spawn("brightnessctl -d intel_backlight s 1%")
    curr_brightness("Min Brightness")
end
function brightness_max()
    awful.spawn("brightnessctl -d intel_backlight s 100%")
    curr_brightness("Max Brightness")
end
function show_random_image()
    local file = get_random_file_from_dir("img/cute", { "jpg", "png" })
    awful.spawn("sxiv img/cute/" .. file)
end
function curr_brightness(title)
    local filename = "/tmp/awesome-notify-brightness"
    local file = io.open(filename, "r")
    local id
    if file then
        id = file:read("*number")
        file:close()
    else
        id = naughty.get_next_notification_id()
        file = io.open(filename, "w")
        if file then
            file:write(id)
            file:close()
        end
    end
    awful.spawn.easy_async([[
        bash -c "printf $(((`brightnessctl g` * 100) / `brightnessctl m`))"
    ]],
    function(stdout)
        naughty.notify({
            title = title,
            text = "Currently " .. string.sub(stdout, 0, string.len(stdout) - 1) .. "%",
            replaces_id = id,
        })
    end)
end
screenshot_cmd = {
    snip = [[bash -c "
        datestr=$(date +%Y-%m-%d-%T)
        filename=${datestr}-snip.png
        scrot -s -f ~/img/screenshot/${filename} &&
        notify-send 'Screenshot saved!' "~/img/screenshot/${filename}"
    "]],
    screenshot = [[bash -c "
        datestr=$(date +%Y-%m-%d-%T)
        filename=${datestr}-screenshot.png
        scrot ~/img/screenshot/${filename} &&
        notify-send 'Screenshot saved!' "~/img/screenshot/${filename}"
    "]],
}
launcher = "rofi -dpi 1 -font \"" .. theme.launcher_font .. "\" -show run"
editor = os.getenv("EDITOR") or "vi"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod1"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.floating,
}
-- }}}

-- Keyboard map indicator and switcher
mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Create a textclock widget
mytextclock = wibox.widget.textclock()

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ modkey }, 1, function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end
                                          end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, function(t)
                                              if client.focus then
                                                  client.focus:toggle_tag(t)
                                              end
                                          end),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
                )

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag({ "い", "ろ", "は", "に", "ほ", "へ", "と", "ち", "り" }, s, awful.layout.layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.all,
        buttons = taglist_buttons
    }

    -- Create the wibox
    s.mywibox = awful.wibar({
        position = "top",
        screen = s,
    })

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            s.mylayoutbox,
            s.mytaglist,
            s.mypromptbox,
        },
        { layout = wibox.layout.fixed.horizontal },
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            cpu_widget({
                width = 70,
                step_width = 2,
                step_spacing = 0,
                color = "#a9bcff",
            }),
            ram_widget({
                widget_height = 10,
                widget_width = 50,
                widget_show_buf = false,
                color_free = "#a9bcff",
                color_used = "#a960ff",
                color_buf = "#a960ff",
            }),
            github_contributions_widget({
                username = 'wesl-ee',
                color_of_empty_cells = theme.bg_normal,
            }),
            notmuch_mail_widget({ }),
            mytextclock,
            volume_widget({
                widget_type = "vertical_bar",
                device = "default",
                main_color = theme.fg_normal,
                mute_color = theme.bg_normal,
                width = 20,
            }),
        },
    }
end)
-- }}}

-- {{{ Key bindings
globalkeys = gears.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
              {description = "view previous", group = "tag"}),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
              {description = "view next", group = "tag"}),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore,
              {description = "go back", group = "tag"}),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
        end,
        {description = "focus next by index", group = "client"}
    ),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
        end,
        {description = "focus previous by index", group = "client"}
    ),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end,
              {description = "swap with next client by index", group = "client"}),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end,
              {description = "swap with previous client by index", group = "client"}),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end,
              {description = "focus the next screen", group = "screen"}),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end,
              {description = "focus the previous screen", group = "screen"}),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"}),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey, "Shift"   }, "p", function () awful.spawn("passmenu") end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit,
              {description = "quit awesome", group = "awesome"}),
    awful.key({ modkey, "Shift"   }, "w", function () awful.spawn("dm-tool switch-to-greeter") end,
              {description = "switch to greeter", group = "awesome"}),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)          end,
              {description = "increase master width factor", group = "layout"}),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)          end,
              {description = "decrease master width factor", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end,
              {description = "increase the number of master clients", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end,
              {description = "decrease the number of master clients", group = "layout"}),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1, nil, true)    end,
              {description = "increase the number of columns", group = "layout"}),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1, nil, true)    end,
              {description = "decrease the number of columns", group = "layout"}),
    awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end,
              {description = "select next", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end,
              {description = "select previous", group = "layout"}),
    awful.key({ }, "Print", function () awful.spawn(screenshot_cmd.screenshot)  end,
              {description = "screenshot full", group = "layout"}),
    awful.key({ "Control"                  }, "Print", function () awful.spawn(screenshot_cmd.snip)  end,
              {description = "screenshot snip", group = "layout"}),
    awful.key({ }, "XF86MonBrightnessUp", brightness_up,
              {description = "brightness up", group = "layout"}),
    awful.key({ }, "XF86MonBrightnessDown", brightness_down,
              {description = "brightness down", group = "layout"}),
    awful.key({ "Shift" }, "XF86MonBrightnessDown", brightness_min,
              {description = "brightness min" }),
    awful.key({ "Shift" }, "XF86MonBrightnessUp", brightness_max,
              {description = "brightness max" }),
    awful.key({ modkey }, "i", show_random_image,
              {description = "show random image" }),

    awful.key({ modkey, "Control" }, "n",
              function ()
                  local c = awful.client.restore()
                  -- Focus restored client
                  if c then
                    c:emit_signal(
                        "request::activate", "key.unminimize", {raise = true}
                    )
                  end
              end,
              {description = "restore minimized", group = "client"}),

    -- Prompt
    awful.key({ modkey },            "r",     function () awful.screen.focused().mypromptbox:run() end,
              {description = "run prompt", group = "launcher"}),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run {
                    prompt       = "Run Lua code: ",
                    textbox      = awful.screen.focused().mypromptbox.widget,
                    exe_callback = awful.util.eval,
                    history_path = awful.util.get_cache_dir() .. "/history_eval"
                  }
              end,
              {description = "lua execute prompt", group = "awesome"}),
    -- Menubar
    awful.key({ modkey }, "p", function() awful.spawn(launcher) end,
              {description = "show the launcher", group = "launcher"})
)

clientkeys = gears.table.join(
    awful.key({ modkey,           }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end,
              {description = "close", group = "client"}),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ,
              {description = "toggle floating", group = "client"}),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
              {description = "move to master", group = "client"}),
    awful.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end,
              {description = "move to screen", group = "client"}),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
              {description = "toggle keep on top", group = "client"}),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end ,
        {description = "minimize", group = "client"}),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized = not c.maximized
            c:raise()
        end ,
        {description = "(un)maximize", group = "client"}),
    awful.key({ modkey, "Control" }, "m",
        function (c)
            c.maximized_vertical = not c.maximized_vertical
            c:raise()
        end ,
        {description = "(un)maximize vertically", group = "client"}),
    awful.key({ modkey, "Shift"   }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c:raise()
        end ,
        {description = "(un)maximize horizontally", group = "client"})
)

for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "view tag #"..i, group = "tag"}),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "toggle tag #" .. i, group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"}),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end

clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
    end),
    awful.button({ modkey }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.resize(c)
    end)
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen
     }
    },

    -- Floating clients.
    { rule_any = {
        instance = {
          "pinentry",
        },
        class = {
          "Arandr",
          "Sxiv",
          "Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
          },

        -- Note that the name property shown in xprop might be set slightly after creation of the client
        -- and the name shown there might not match defined rules here.
        name = {
          "Event Tester",  -- xev.
        },
        role = {
          "AlarmWindow",  -- Thunderbird's calendar.
          "ConfigManager",  -- Thunderbird's about:config.
          "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
      }, properties = {
          floating = true,
          placement = awful.placement.centered,
      }},

    -- Add titlebars to normal clients and dialogs
    { rule_any = {type = { "normal", "dialog" }
      }, properties = { titlebars_enabled = true }
    },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Terminals have weird gaps if this isn't here
    c.size_hints_honor = false

    if awesome.startup
      and not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", {raise = false})
end)

client.connect_signal("focus", function(c) c.border_focus = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

--- Get the name of a random file from a given directory.
-- @tparam string path The directory to search.
-- @tparam[opt] table exts Specific extensions to limit the search to. eg:`{ "jpg", "png" }`
--   If ommited, all files are considered.
-- @tparam[opt=false] boolean absolute_path Return the absolute path instead of the filename.
-- @treturn string|nil A randomly selected filename from the specified path (with
--   a specified extension if required) or nil if no suitable file is found. If `absolute_path`
--   is set, then a path is returned instead of a file name.
function get_random_file_from_dir(path, exts, absolute_path)
    local files, valid_exts = {}, {}

    -- Transforms { "jpg", ... } into { [jpg] = #, ... }
    if exts then for i, j in ipairs(exts) do valid_exts[j:lower():gsub("^[.]", "")] = i end end

    -- Build a table of files from the path with the required extensions
    local file_list = Gio.File.new_for_path(path):enumerate_children("standard::*", 0)

    -- This will happen when the directory doesn't exist.
    if not file_list then return nil end

    for file in function() return file_list:next_file() end do
        if file:get_file_type() == "REGULAR" then
            local file_name = file:get_display_name()

            if not exts or valid_exts[file_name:lower():match(".+%.(.*)$") or ""] then
               table.insert(files, file_name)
            end
        end
    end

    if #files == 0 then return nil end

    -- Return a randomly selected filename from the file table
    local file = files[math.random(#files)]

    return absolute_path and (path:gsub("[/]*$", "") .. "/" .. file) or file
end
-- }}}
