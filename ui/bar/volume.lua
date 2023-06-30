local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local beautiful = require("beautiful")
local spawn = awful.spawn
local dpi = beautiful.xresources.apply_dpi
-- local icons = require("theme.icons")
local clickable_container = require("ui.clickable_container")
local helpers = require("helpers")

local icon = wibox.widget({
	layout = wibox.layout.align.vertical,
	expand = "none",
	nil,
	{
		image = beautiful.volume_on,
		resize = true,
		widget = wibox.widget.imagebox,
	},
	nil,
})

local action_level = wibox.widget({
	{
		{
			icon,
			margins = dpi(5),
			widget = wibox.container.margin,
		},
		widget = clickable_container,
	},
	bg = beautiful.groups_bg,
	shape = helpers.mkroundedrect(),--[[ function(cr, width, height)
		gears.shape.rounded_rect(cr, width, height, beautiful.groups_radius)
	end ]]
	widget = wibox.container.background,
})

local slider = wibox.widget({
	nil,
	{
		id = "volume_slider",
		bar_shape = helpers.mkroundedrect(),
		bar_height = dpi(24),
		bar_color = "#ffffff20",
		bar_active_color = "#f2f2f2",
		handle_color = "#f2f2f2", -- "#ffffff",
		handle_shape = gears.shape.circle,
		handle_width = dpi(24),
		shape_clip = true,
		maximum = 100,
		widget = wibox.widget.slider,
	},
	nil,
	expand = "none",
	forced_height = dpi(24),
	layout = wibox.layout.align.vertical,
})

local volume_slider = slider.volume_slider

volume_slider:connect_signal("property::value", function()
	local volume_level = volume_slider:get_value()

	spawn("amixer -D pulse sset Master " .. volume_level .. "%", false)
	-- awful.spawn("pactl set-sink-volume @DEFAULT_SINK@ " .. volume_level .. "%")

	-- Update volume osd
	-- awesome.emit_signal("module::volume_osd", volume_level)
end)

volume_slider:buttons(gears.table.join(
	awful.button({}, 4, nil, function()
		if volume_slider:get_value() > 100 then
			volume_slider:set_value(100)
			return
		end
		volume_slider:set_value(volume_slider:get_value() + 5)
	end),
	awful.button({}, 5, nil, function()
		if volume_slider:get_value() < 0 then
			volume_slider:set_value(0)
			return
		end
		volume_slider:set_value(volume_slider:get_value() - 5)
	end)
))

local update_slider = function()
	awful.spawn.easy_async_with_shell([[bash -c "amixer -D pulse sget Master"]], function(stdout)
		local volume = string.match(stdout, "(%d?%d?%d)%%")
		volume_slider:set_value(tonumber(volume))
	end)
end

-- Update on startup
update_slider()

local action_jump = function()
	local sli_value = volume_slider:get_value()
	local new_value = 0

	if sli_value >= 0 and sli_value < 50 then
		new_value = 50
	elseif sli_value >= 50 and sli_value < 100 then
		new_value = 100
	else
		new_value = 0
	end
	volume_slider:set_value(new_value)
end

action_level:buttons(awful.util.table.join(awful.button({}, 1, nil, function()
	action_jump()
end)))

-- The emit will come from the global keybind
awesome.connect_signal("widget::volume", function()
	update_slider()
end)

-- The emit will come from the OSD
awesome.connect_signal("widget::volume:update", function(value)
	volume_slider:set_value(tonumber(value))
end)

local volume_setting = wibox.widget({
	layout = wibox.layout.fixed.horizontal,
	-- {
	-- 	layout = wibox.layout.align.vertical,
	-- 	expand = "none",
	-- 	nil,
	-- 	{
	-- 		layout = wibox.layout.fixed.horizontal,
	-- 		forced_height = dpi(24),
	-- 		forced_width = dpi(24),
	-- 		action_level,
	-- 	},
	-- 	nil,
	-- },
	slider,
})

local popup = awful.popup({
	ontop = true,
	visible = false,
	-- shape = helpers.mkroundedrect(),
	maximum_width = 300,
	offset = {
		y = 5,
		x = -5,
	},
	-- placement = awful.placement.top_right,
	widget = volume_setting,
	shape = helpers.mkroundedrect(50),
	shape_clip = true,
})

local with_volume = function(f)
	awful.spawn.easy_async_with_shell([[bash -c "amixer -D pulse sget Master"]], function(stdout)
		local volume = string.match(stdout, "(%d?%d?%d)%%")
		f(volume)
	end)
end

local t = gears.timer({
	timeout = 1,
	autostart = false,
	single_shot = true,
	callback = function()
		with_volume(function(vol)
			popup.visible = false
			return false
		end)
	end,
})

awesome.connect_signal("widget::volume::toggle", function()
	popup.offset = {
		y = 48,
		x = -15,
	}
	popup:move_next_to(screen.primary.geometry)
	popup.visible = not popup.visible
end)

local set = false
awesome.connect_signal("widget::volume::show", function(click)
	-- popup.screen = screen.primary
	if t.started then
		t:stop()
		t:again()
	else
		if click and not set then
			popup.offset = {
				y = 9,
				x = -15,
			}
			popup:move_next_to(mouse.current_widget_geometry)
			set = true
		end
		t:start()
	end
	if set == false then
		popup.offset = {
			y = 48,
			x = -15,
		}
		popup:move_next_to(screen.primary.geometry)
		set = true
	end
	popup.visible = true
	-- t:start()
	-- popup:move_next_to(mouse.current_widget_geometry)
end)

awesome.connect_signal("widget::volume::hide", function()
	popup.visible = false
end)

popup:connect_signal("mouse::enter", function()
	t:stop()
end)

popup:connect_signal("mouse::leave", function()
	t:again()
	-- popup.visible = false
end)

return popup
