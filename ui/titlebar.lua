---@diagnostic disable: undefined-global

local awful = require("awful")
local beautiful = require("beautiful")
local wibox = require("wibox")
local xresources = require("beautiful.xresources")

local dpi = xresources.apply_dpi

local lgi = require("lgi")
local gsurface = require("gears.surface")
local gdk = lgi.require("Gdk", "3.0")
gdk.init({})
local get_default_root_window = gdk.get_default_root_window
local pixbuf_get_from_surface = gdk.pixbuf_get_from_surface
local pixbuf_get_from_window = gdk.pixbuf_get_from_window

-- Lifted from awesome-wm-nice
-- Determines the dominant color of the client's top region
local init = false
local function get_dominant_color(client)
	local color
	-- gsurface(client.content):write_to_png(
	--     "/home/mutex/nice/" .. client.class .. "_" .. client.instance .. ".png")
	local pb
	local bytes
	local tally = {}
	local content = gsurface(client.content)
	local cgeo = client:geometry()
	local x_offset = 2
	local y_offset = 2
	local x_lim = math.floor(cgeo.width / 2)
	for x_pos = 0, x_lim, 2 do
		for y_pos = 0, 8, 1 do
			pb = pixbuf_get_from_surface(content, x_offset + x_pos, y_offset + y_pos, 1, 1)
			bytes = pb:get_pixels()
			color = "#"
				.. bytes
					:gsub(".", function(c)
						return ("%02x"):format(c:byte())
					end)
					:sub(1, 6)
			if not tally[color] then
				tally[color] = 1
			else
				tally[color] = tally[color] + 1
			end
		end
	end
	local mode
	local mode_c = 0
	for kolor, kount in pairs(tally) do
		if kount > mode_c then
			mode_c = kount
			mode = kolor
		end
	end
	color = mode
	return color
end

client.connect_signal("request::titlebars", function(c)
	if c.instance == "spad" then
		return
	end

	local color = get_dominant_color(c)

	local titlebar = awful.titlebar(c, {
		position = "top",
		size = 28,
		bg_focus = c.class == "org.wezfurlong.wezterm" and beautiful.dark_blue or color,
		bg_normal = c.class == "org.wezfurlong.wezterm" and beautiful.dark_blue or color,
	})

	local title_actions = {
		awful.button({}, 1, function()
			c:activate({
				context = "titlebar",
				action = "mouse_move",
			})
		end),
		awful.button({}, 3, function()
			c:activate({
				context = "titlebar",
				action = "mouse_resize",
			})
		end),
	}

	local buttons_loader = {
		layout = wibox.layout.fixed.horizontal,
		buttons = title_actions,
	}

	local function padded_button(button, margins)
		margins = margins or {
			left = 4,
			right = 4,
		}
		margins.top = 8
		margins.bottom = 8

		return wibox.widget({
			button,
			top = margins.top,
			bottom = margins.bottom,
			left = margins.left,
			right = margins.right,
			widget = wibox.container.margin,
		})
	end

	-- local left_dummy_bar = awful.titlebar(c, {
	-- 	position = "left",
	-- 	size = 0,
	-- 	bg_focus = beautiful.dark_blue,
	-- 	bg_normal = beautiful.dark_blue,
	-- })
	-- left_dummy_bar:setup({
	-- 	layout = wibox.layout.fixed.vertical,
	-- })
	-- local right_dummy_bar = awful.titlebar(c, {
	-- 	position = "right",
	-- 	size = 0,
	-- 	bg_focus = beautiful.dark_blue,
	-- 	bg_normal = beautiful.dark_blue,
	-- })
	-- right_dummy_bar:setup({
	-- 	layout = wibox.layout.fixed.vertical,
	-- })
	-- local bottom_dummy_bar = awful.titlebar(c, {
	-- 	position = "bottom",
	-- 	size = 0,
	-- 	bg_focus = beautiful.dark_blue,
	-- 	bg_normal = beautiful.dark_blue,
	-- })
	-- bottom_dummy_bar:setup({
	-- 	layout = wibox.layout.fixed.horizontal,
	-- })
	titlebar:setup({
		{
			padded_button(awful.titlebar.widget.closebutton(c), {
				right = 4,
				left = 12,
			}),
			padded_button(awful.titlebar.widget.minimizebutton(c)),
			padded_button(awful.titlebar.widget.maximizedbutton(c)),
			layout = wibox.layout.fixed.horizontal,
		},
		buttons_loader,
		buttons_loader,
		layout = wibox.layout.align.horizontal,
	})
end)
