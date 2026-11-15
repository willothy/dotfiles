return function(config, wezterm)
	local action = wezterm.action

	local function map(m)
		table.insert(config.keys, {
			key = m.key,
			mods = m.mods,
			action = m.action,
		})
	end

	-- Tabs
	map({
		key = "[",
		mods = "CMD",
		action = action.ActivateTabRelative(-1),
	})
	map({
		key = "]",
		mods = "CMD",
		action = action.ActivateTabRelative(1),
	})
	map({
		key = "q",
		mods = "CMD",
		action = action.CloseCurrentTab({ confirm = true }),
	})
	map({
		key = "n",
		mods = "CMD",
		action = action.SpawnTab("CurrentPaneDomain"),
	})

	-- Disabled defaults
	map({
		key = "LeftArrow",
		mods = "CTRL|SHIFT",
		action = action.DisableDefaultAssignment,
	})
	map({
		key = "RightArrow",
		mods = "CTRL|SHIFT",
		action = action.DisableDefaultAssignment,
	})
	map({
		key = "Enter",
		mods = "ALT",
		action = action.DisableDefaultAssignment,
	})
	map({
		key = "w",
		mods = "CMD",
		action = action.DisableDefaultAssignment,
	})
end
