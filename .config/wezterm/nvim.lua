local wezterm = require("wezterm")

local M = {}

function M.is_nvim(pane)
	-- local vim = {
	-- 	vim = true,
	-- 	nvim = true,
	-- }
	-- this is set by the plugin, and unset on ExitPre in Neovim
	local var = pane:get_user_vars().IS_NVIM
	return var ~= nil and var == "true"
end

local function resize(key, mapping)
	return {
		key = key,
		mods = "ALT",
		action = wezterm.action_callback(function(win, pane)
			if M.is_nvim(pane) then
				win:perform_action({
					SendKey = { key = key, mods = "ALT" },
				}, pane)
			else
				win:perform_action({
					AdjustPaneSize = {
						mapping,
						3,
					},
				}, pane)
			end
		end),
	}
end

local function move(key, mapping)
	return {
		key = key,
		mods = "CTRL",
		action = wezterm.action_callback(function(win, pane)
			if M.is_nvim(pane) then
				win:perform_action({
					SendKey = { key = key, mods = "CTRL" },
				}, pane)
			else
				local tab = win:mux_window():active_tab()
				local next_pane = tab and tab:get_pane_direction(mapping)
				if next_pane and next_pane:pane_id() ~= pane:pane_id() then
					next_pane:activate()
				else
					local offset
					if mapping == "Left" then
						offset = -1
					else
						offset = 1
					end

					if offset then
						win:perform_action({ ActivateTabRelative = offset }, pane)
					end
				end
			end
		end),
	}
end

local mappings = {
	move = {
		h = "Left",
		l = "Right",
		j = "Down",
		k = "Up",
		UpArrow = "Up",
		DownArrow = "Down",
		LeftArrow = "Left",
		RightArrow = "Right",
	},
	resize = {
		h = "Left",
		l = "Right",
		-- j = "Down",
		-- k = "Up",
		UpArrow = "Up",
		DownArrow = "Down",
		LeftArrow = "Left",
		RightArrow = "Right",
	},
}

---@class Wezterm.Keymap
---@field key string
---@field mods string
---@field action any

---Add Neovim navigation mappings to Wezterm keymaps table
---@param keymaps Wezterm.Keymap[]
function M.apply_mappings(keymaps)
	for key, mapping in pairs(mappings.move) do
		table.insert(keymaps, move(key, mapping))
	end

	for key, mapping in pairs(mappings.resize) do
		table.insert(keymaps, resize(key, mapping))
	end
end

return M
