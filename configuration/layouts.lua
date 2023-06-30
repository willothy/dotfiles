---@diagnostic disable: undefined-global
local awful = require("awful")
local bling = require("bling")

local function deck(offset)
	local deck = {
		name = "deck",
	}

	function deck.arrange(p)
		local area = p.workarea
		local t = p.tag or screen[p.screen].selected_tag
		local client_count = #p.clients

		if client_count == 1 then
			local c = p.clients[1]
			local g = {
				x = area.x,
				y = area.y,
				width = area.width,
				height = area.height,
			}
			p.geometries[c] = g
			return
		end

		local xoffset = area.width * offset / (client_count - 1)
		local yoffset = area.height * offset / (client_count - 1)

		local geometries = {}

		local focused = client.focus -- window id

		for idx = 1, client_count do
			local c = p.clients[idx]
			local g = {
				x = area.x + (idx - 1) * xoffset,
				y = area.y + (idx - 1) * yoffset,
				width = area.width - (math.abs(xoffset) * (client_count - 1)),
				height = area.height - (math.abs(yoffset) * (client_count - 1)),
			}
			p.geometries[c] = g
		end
	end
	return deck
end

local function set_layouts()
	tag.connect_signal("request::default_layouts", function()
		awful.layout.append_default_layouts({
			-- bling.layout.deck,
			-- bling.layout.mstab,
			awful.layout.suit.tile,
			deck(0.1),
			awful.layout.suit.tile.left,
			awful.layout.suit.tile.right,
			awful.layout.suit.magnifier,
			awful.layout.suit.floating,
			awful.layout.suit.tile.top,
			awful.layout.suit.tile.bottom,
			awful.layout.suit.max, -- numpad 0
		})
	end)
end

set_layouts()
