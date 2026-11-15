return function(config, wezterm, cmd_palette)
	local function is_nvim(pane)
		local var = pane:get_user_vars().IS_NVIM
		return var ~= nil and var == "true"
	end

	---@class Wezterm.Keymap
	---@field key string
	---@field mods string
	---@field action any

	local direction_keys = {
		Left = "h",
		Down = "j",
		Up = "k",
		Right = "l",
	}

	local key_directions = {
		h = "Left",
		j = "Down",
		k = "Up",
		l = "Right",
		-- LeftArrow = "Left",
		-- DownArrow = "Down",
		-- UpArrow = "Up",
		-- RightArrow = "Right",
	}

	for key, direction in pairs(key_directions) do
		table.insert(config.keys, {
			key = key,
			mods = "CTRL",
			action = wezterm.action_callback(function(win, pane)
				if is_nvim(pane) then
					win:perform_action({
						SendKey = { key = direction_keys[direction], mods = "CTRL" },
					}, pane)
				else
					local tab = win:mux_window():active_tab()
					local next_pane = tab:get_pane_direction(direction)
					if next_pane and next_pane:tab():tab_id() == pane:tab():tab_id() then
						next_pane:activate()
					else
						local offset
						if direction == "Left" then
							offset = -1
						elseif direction == "Right" then
							offset = 1
						end

						if offset then
							win:perform_action({ ActivateTabRelative = offset }, pane)
						end
					end
				end
			end),
		})
		table.insert(config.keys, {
			key = key,
			mods = "ALT",
			action = wezterm.action_callback(function(win, pane)
				if is_nvim(pane) then
					win:perform_action({
						SendKey = { key = direction_keys[key], mods = "ALT" },
					}, pane)
				else
					win:perform_action({
						AdjustPaneSize = {
							direction,
							3,
						},
					}, pane)
				end
			end),
		})
	end
end
