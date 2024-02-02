local wezterm = require("wezterm")
local action = wezterm.action

local sesh = require("sesh")

local keymap = {}

function keymap.sesh(map)
	map({
		key = "`",
		mods = "CMD",
		action = sesh.attach.action,
	})
end

function keymap.tabs(map)
	map({
		key = "[",
		mods = "CMD",
		action = action.ActivateTabRelative(-1),
	}, {
		key = "]",
		mods = "CMD",
		action = action.ActivateTabRelative(1),
	}, {
		key = "q",
		mods = "CMD",
		action = action.CloseCurrentTab({ confirm = true }),
	}, {
		key = "n",
		mods = "CMD",
		action = action.SpawnTab("CurrentPaneDomain"),
	})
end

function keymap.disabled(map)
	map({
		key = "LeftArrow",
		mods = "CTRL|SHIFT",
		action = action.DisableDefaultAssignment,
	}, {
		key = "RightArrow",
		mods = "CTRL|SHIFT",
		action = action.DisableDefaultAssignment,
	}, {
		key = "Enter",
		mods = "ALT",
		action = action.DisableDefaultAssignment,
	}, {
		key = "w",
		mods = "CMD",
		action = action.DisableDefaultAssignment,
	})
end

local M = {}

---Create keymaps.
---
---Automatically added to the environment of keymap
---group functions.
---@alias MapBuilder fun(...: Wezterm.Keymap): ...

---Add main mappings to Wezterm keymaps table
---@param keymaps Wezterm.Keymap[]
function M.apply_mappings(keymaps)
	local function map(...)
		local n = select("#", ...)
		for i = 1, n do
			local map_tbl = select(i, ...)
			table.insert(keymaps, map_tbl)
		end
	end
	for _, group in pairs(keymap) do
		group(map)
	end
end

return M
