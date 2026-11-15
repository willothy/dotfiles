return function(config, wezterm, cmd_palette)
	local process_icons = require("icons")
	local palette = require("colors")

	-- pane_info.foreground_process_name isn't helpful on NixOS because of store paths.
	-- calling get_foreground_process_info is supposedly slow, so cache the results by
	-- in a map of foreground_process_name -> get_foregoround_process_info().name.
	local pane_cache = {}

	local function pane_cache_get(pane_info)
		local proc_name = pane_info.foreground_process_name
		if pane_cache[proc_name] then
			return pane_cache[proc_name]
		end

		local title = wezterm.mux.get_pane(pane_info.pane_id):get_foreground_process_info().name
		title = title:match("^%s*(%S+)") or title

		pane_cache[proc_name] = title

		return title
	end

	wezterm.on("format-tab-title", function(tab, tabs, _panes, _config, hover, _max_width)
		local has_unseen_output = false
		for _, pane in ipairs(tab.panes) do
			if pane.has_unseen_output then
				has_unseen_output = true
				break
			end
		end

		local title = {}
		table.insert(title, {
			Background = { Color = "#1a1b26" },
		})
		if tab.tab_index == 0 then
			table.insert(title, {
				Text = " ",
			})
		end
		if has_unseen_output then
			table.insert(title, {
				Foreground = { Color = palette.lemon_chiffon },
			})
		elseif tab.is_active then
			table.insert(title, {
				Foreground = { Color = palette.turquoise },
			})
		else
			table.insert(title, {
				Foreground = { Color = "#9196c2" },
			})
		end

		local proc_title = pane_cache_get(tab.active_pane) or "bruh"

		if process_icons[proc_title] ~= nil then
			table.insert(title, {
				Text = wezterm.format({
					process_icons[proc_title],
					{ Text = " " },
				}),
			})
		else
			table.insert(title, {
				Text = wezterm.format({
					{ Text = "󰧟" },
					{ Text = " " },
				}),
			})
		end
		table.insert(title, {
			Foreground = {
				Color = "#9196c2",
			},
		})

		if hover then
			table.insert(title, {
				Attribute = { Underline = "Single" },
			})
		end
		table.insert(title, {
			Text = proc_title,
		})
		table.insert(title, {
			Attribute = { Underline = "None" },
		})
		if tab.tab_index + 1 < #tabs then
			table.insert(title, {
				Text = " ",
			})
		end
		return title
	end)

	wezterm.on("update-right-status", function(window, pane)
		local name = pane:get_user_vars().sesh_name
		if name and name ~= "" then
			name = string.format("%s %s", name, "∘")
		else
			name = ""
		end

		local nvim_icon = ""
		if pane:get_user_vars().IS_NVIM == "true" then
			nvim_icon = ""
		end
		local time = wezterm.strftime("%l:%M %p ")
		if time:sub(1, 1) ~= " " then
			nvim_icon = nvim_icon .. " "
		end

		window:set_right_status(wezterm.format({
			{ Attribute = { Intensity = "Bold" } },
			{ Foreground = { Color = "#9196c2" } },
			{ Text = nvim_icon },
			{ Text = name },
			{ Text = time },
		}))
	end)
end
