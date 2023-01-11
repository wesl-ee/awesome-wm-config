local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local watch = require("awful.widget.watch")
local wibox = require("wibox")

local notmuch_mail_icon = wibox.widget {
    align = 'center',
    widget = wibox.widget.textbox
}
local notmuch_mail_text = wibox.widget {
    align = 'center',
    widget = wibox.widget.textbox
}
local notmuch_mail_widget = wibox.widget {
    notmuch_mail_icon,
    notmuch_mail_text,
    layout = wibox.layout.flex.vertical,
        spacing = 10,
            spacing_widget = wibox.widget.separator,
}

local function worker(_)
    watch(
        "notmuch count tag:unread", 20,
        function(_, stdout)
            local unread_emails_num = tonumber(stdout) or 0
            if (unread_emails_num > 0) then
                notmuch_mail_icon:set_text("📩")
                notmuch_mail_text:set_text(stdout)
            elseif (unread_emails_num == 0) then
                notmuch_mail_icon:set_text("✉️ ")
                notmuch_mail_text:set_text("No new mail")
            end
        end
    )

    return notmuch_mail_widget
end

return setmetatable(notmuch_mail_widget, { __call = function(_, ...)
    return worker(...)
end })

