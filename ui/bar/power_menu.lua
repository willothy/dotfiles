local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")
local helpers = require("helpers")
local dpi = beautiful.xresources.apply_dpi

local wh_power_menu = {
	{
		name = "Logout",
		icon = beautiful.logout_icon,
		fn = awesome.quit,
	},
	{
		name = "Reboot",
		icon = beautiful.reboot_icon,
		fn = function()
			awful.spawn("sudo /sbin/shutdown -r now")
		end,
	},
	{
		name = "Shutdown",
		icon = beautiful.poweroff_icon,
		fn = function()
			awesome.quit()
		end,
	},
}

local popup = awful.popup({
	ontop = true,
	visible = false,
	shape = helpers.mkroundedrect(),
	-- maximum_width = 300,
	offset = { y = 5 },
	bg = beautiful.bg_normal .. "af",
	widget = {},
})
local rows = { layout = wibox.layout.fixed.vertical }
for _, item in ipairs(wh_power_menu) do
	local row = wibox.widget({
		{
			{
				{
					{
						image = item.icon,
						markup = "<b>" .. item.name .. "</b>",
						forced_width = 16,
						forced_height = 16,
						widget = wibox.widget.imagebox,
					},
					{
						text = item.name,
						markup = "<b>" .. item.name .. "</b>",
						widget = wibox.widget.textbox,
					},
					spacing = 12,
					layout = wibox.layout.fixed.horizontal,
				},
				left = 16,
				right = 16,
				top = 8,
				bottom = 8,
				widget = wibox.container.margin,
			},
			bg = beautiful.bg_normal .. "5f",
			shape = helpers.mkroundedrect(),
			widget = wibox.container.background,
		},
		top = 6,
		bottom = 6,
		left = 6,
		right = 6,
		widget = wibox.container.margin,
	})
	row:buttons(awful.util.table.join(awful.button({}, 1, function()
		popup.visible = not popup.visible
		if item.cmd then
			awful.spawn.with_shell(item.cmd)
		elseif item.fn then
			item.fn()
		end
	end)))
	row:connect_signal("mouse::enter", function(c)
		c.widget:set_bg(beautiful.bg_focus .. "5f")
		-- c.bg = beautiful.bg_focus
	end)
	row:connect_signal("mouse::leave", function(c)
		c.widget:set_bg(beautiful.bg_normal .. "5f")
		-- c.bg = beautiful.bg_normal
	end)
	table.insert(rows, row)
end
popup:connect_signal("mouse::leave", function()
	popup.visible = false
end)
popup:setup(rows)
return popup
