local wezterm = require("wezterm")

local M = {}

function M.is_nvim(pane)
	local var = pane:get_user_vars().IS_NVIM
	return var ~= nil and var == "true"
end

local function resize(win, pane, key, direction)
	if M.is_nvim(pane) then
		win:perform_action({
			SendKey = { key = key, mods = "ALT" },
		}, pane)
	else
		win:perform_action({
			AdjustPaneSize = {
				direction,
				3,
			},
		}, pane)
	end
end

wezterm.on("do-resize-left", function(win, pane)
	resize(win, pane, "h", "Left")
end)
wezterm.on("do-resize-right", function(win, pane)
	resize(win, pane, "l", "Right")
end)
wezterm.on("do-resize-up", function(win, pane)
	resize(win, pane, "k", "Up")
end)
wezterm.on("do-resize-down", function(win, pane)
	resize(win, pane, "j", "Down")
end)

local function move(win, pane, key, direction)
	if M.is_nvim(pane) then
		win:perform_action({
			SendKey = { key = key, mods = "CTRL" },
		}, pane)
	else
		local tab = win:mux_window():active_tab()
		local next_pane = tab and tab:get_pane_direction(direction)
		if next_pane and next_pane:pane_id() ~= pane:pane_id() then
			next_pane:activate()
		else
			local offset
			if direction == "Left" then
				offset = -1
			else
				offset = 1
			end

			if offset then
				win:perform_action({ ActivateTabRelative = offset }, pane)
			end
		end
	end
end

wezterm.on("do-move-left", function(win, pane)
	move(win, pane, "h", "Left")
end)
wezterm.on("do-move-right", function(win, pane)
	move(win, pane, "l", "Right")
end)
wezterm.on("do-move-up", function(win, pane)
	move(win, pane, "k", "Up")
end)
wezterm.on("do-move-down", function(win, pane)
	move(win, pane, "j", "Down")
end)

local mappings = {
	move = {
		h = "left",
		l = "right",
		j = "down",
		k = "up",
		UpArrow = "up",
		DownArrow = "down",
		LeftArrow = "left",
		RightArrow = "right",
	},
	resize = {
		h = "left",
		l = "right",
		-- j = "Down",
		-- k = "Up",
		UpArrow = "up",
		DownArrow = "down",
		LeftArrow = "left",
		RightArrow = "right",
	},
}

---@class Wezterm.Keymap
---@field key string
---@field mods string
---@field action any

---Add Neovim navigation mappings to Wezterm keymaps table
---@param keymaps Wezterm.Keymap[]
function M.apply_mappings(keymaps)
	-- creating a new action_callback for each mapping seems to break
	-- on hot-reload, so I've just created an event handler for each
	-- operation and the mappings just emit the events.
	for key, mapping in pairs(mappings.move) do
		table.insert(keymaps, {
			key = key,
			mods = "CTRL",
			action = wezterm.action.EmitEvent("do-move-" .. mapping),
		})
	end

	for key, mapping in pairs(mappings.resize) do
		table.insert(keymaps, {
			key = key,
			mods = "ALT",
			action = wezterm.action.EmitEvent("do-resize-" .. mapping),
		})
	end
end

return M
