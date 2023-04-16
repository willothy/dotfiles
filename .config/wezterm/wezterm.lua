local wezterm = require("wezterm")
local nf = wezterm.nerdfonts

local config = {}

local function setup(cfg)
	--[[ cfg.default_prog = {
		"wsl.exe",
		"-d",
		distro,
		"-u",
		user,
		"--cd",
		"~",
	}
	cfg.default_cwd = "~" ]]
	cfg.animation_fps = 30
	cfg.max_fps = 30
	cfg.font = wezterm.font_with_fallback({
		"Fira Code",
		--"octicons",
		--"FontAwesome",
	})
	cfg.font_size = 12.0

	cfg.color_scheme = "tokyonight"

	cfg.enable_tab_bar = true
	cfg.use_fancy_tab_bar = false
	cfg.tab_bar_at_bottom = true
	cfg.tab_max_width = 30

	cfg.window_frame = {
		font = wezterm.font({ family = "Fira Code", weight = "Bold" }),
		font_size = 12.0,
	}

	--cfg.dpi = 90

	--cfg.allow_square_glyphs_to_overflow_width = "WhenFollowedBySpace"
	cfg.allow_square_glyphs_to_overflow_width = "Always"

	-- config.window_background_opacity = 0.92
	config.window_background_gradient = {
		colors = { "#26283f" },
	}

	config.window_decorations = "RESIZE"

	config.keys = {
		{
			key = "[",
			mods = "CMD",
			action = wezterm.action.ActivateTabRelative(-1),
		},
		{
			key = "]",
			mods = "CMD",
			action = wezterm.action.ActivateTabRelative(1),
		},
		{
			key = "q",
			mods = "CMD",
			action = wezterm.action.CloseCurrentTab({ confirm = true }),
		},
		{
			key = "n",
			mods = "CMD",
			action = wezterm.action.SpawnTab("CurrentPaneDomain"),
		},
		{
			key = "d",
			mods = "CMD",
			action = wezterm.action.DetachDomain("CurrentPaneDomain"),
		},
	}
end

local function _popup(title, message, opts)
	opts = opts or {}
	if not opts.timeout_ms then
		opts.timeout_ms = 3000
	end
	local windows = wezterm.gui.gui_windows()
	if #windows < 1 then
		return
	end
	local window = windows[1]
	window:toast_notification(title, message, opts.url or "https://github.com/", opts.timeout_ms)
end

local process_icons = {
	["docker"] = {
		Text = nf.linux_docker,
	},
	["docker-compose"] = {
		Text = nf.linux_docker,
	},
	["kuberlr"] = {
		Text = nf.linux_docker,
	},
	["kubectl"] = {
		Text = nf.linux_docker,
	},
	["nvim"] = {
		-- Text = nf.custom_vim
		Text = nf.custom_vim,
	},
	["vim"] = {
		Text = nf.dev_vim,
	},
	["node"] = {
		Text = nf.mdi_hexagon,
	},
	["zsh"] = {
		Text = nf.dev_terminal_badge,
		-- Text = nf.mdi_apple_keyboard_command,
	},
	["bash"] = {
		Text = nf.cod_terminal_bash,
	},
	["btm"] = {
		Text = nf.mdi_chart_donut_variant,
	},
	["htop"] = {
		Text = nf.mdi_chart_donut_variant,
	},
	["cargo"] = {
		Text = nf.dev_rust,
	},
	["rust"] = {
		Text = nf.dev_rust,
	},
	["go"] = {
		Text = nf.mdi_language_go,
	},
	["lazydocker"] = {
		Text = nf.linux_docker,
	},
	["git"] = {
		Text = nf.dev_git,
	},
	["lua"] = {
		Text = nf.seti_lua,
	},
	["wget"] = {
		Text = nf.mdi_arrow_down_box,
	},
	["curl"] = {
		Text = nf.mdi_flattr,
	},
	["gh"] = {
		Text = nf.dev_github_badge,
	},
}

---https://github.com/willothy/minimus/blob/main/lua/minimus/palette.lua
local palette = {
	turquoise = "#5de4c7",
	tiffany_blue = "#85e2da",
	pale_azure = "#89ddff",
	uranian_blue = "#add7ff",
	powder_blue = "#91b4d5",
	cadet_gray = "#8da3bf",
	cool_gray = "#7f92aa",
	raisin_black = "#1b1e28",
	colombia_blue = "#c5d2df",
	persian_red = "#be3937",
	lemon_chiffon = "#fffac2",
	tea_rose = "#e8b1b0",
	lavender_pink = "#fcc5e9",
	pale_purple = "#fee4fc",
	pale_turquoise = "#baf5e8", --"#d0e9f5",
	white = "#f1f1f1",
	black = "#1f1f1f",
	----------------------
	gunmetal = "#303340",
	dark_blue = "#26283f",
	----------------------
	rosewater = "#F5E0DC",
	flamingo = "#F2CDCD",
	pink = "#F5C2E7",
	mauve = "#CBA6F7",
	red = "#F38BA8",
	maroon = "#EBA0AC",
	peach = "#FAB387",
	yellow = "#F9E2AF",
	green = "#A6E3A1",
	teal = "#94E2D5",
	sky = "#89DCEB",
	sapphire = "#74C7EC",
	blue = "#89B4FA",
	lavender = "#B4BEFE",
	---------------------
	text = "#e4f0fb",
}

local function exists(file)
	local f = io.open(file)
	return f and io.close(f)
end

-- Lua implementation of PHP scandir function
function scandir(directory)
	local i, t, popen = 0, {}, io.popen
	local pfile = popen('ls -a "' .. directory .. '"')
	for filename in pfile:lines() do
		i = i + 1
		t[i] = filename
	end
	pfile:close()
	return t
end

local function gitcheck(directory)
	local d = directory
	if not exists(d) then
		return nil
	end
	while #d > 1 and not exists(d .. "/.git") do
		d = d:gsub("/+[^/]*$", "")
	end
	return #d > 0 and d or directory
end

---Returns the dir relative to git root, or the original dir
local function get_git_root(dir, truncate_base)
	local gc = gitcheck(dir)
	if not gc then
		return dir
	end
	if gc == dir then
		if truncate_base == false then
			return dir
		else
			return dir:match(".*/([^/]+)[/]?$")
		end
	else
		local base = gc:gsub("%w+[/]?$", "")
		if base == "" then
			return dir
		end
		return dir:gsub(base, "")
	end
end

local HOME = wezterm.home_dir

local pane_cwd_cache = {}

local function get_current_working_dir(tab, max)
	local pane = tab.active_pane
	local pwd = ""

	if pane_cwd_cache[pane.pane_id] ~= nil then
		pwd = pane_cwd_cache[pane.pane_id]
	else
		pwd = pane.current_working_dir:gsub("%w+://%w+/", "/")
	end

	-- pwd = get_git_root(pwd, false)
	pwd = pwd:gsub(HOME, "~")
	if pwd == "~/" then
		return "~"
	end
	if max ~= nil and #pwd > max then
		local split = {}
		for part in string.gmatch(pwd, "[^/]+") do
			table.insert(split, part)
		end
		local newlen = #pwd
		for i = 1, math.max(1, #split - 1) do
			local len = #split[i]
			if string.sub(split[i], 1, 1) == "." then
				split[i] = string.sub(split[i], 1, 3)
				newlen = (newlen - len) + 3
			else
				split[i] = string.sub(split[i], 1, 2)
				newlen = (newlen - len) + 2
			end
			if newlen <= max then
				break
			end
		end
		pwd = ""
		for i = 1, #split - 1 do
			pwd = pwd .. split[i] .. "/"
		end
		pwd = pwd .. split[#split]
		-- return string.format("~/%s/%s", split[2], split[#split])
		return pwd
	end
	return pwd
end

local function get_process(tab)
	local process_name = string.gsub(tab.active_pane.foreground_process_name, "(.*[/\\])(.*)", "%2")

	if process_icons[process_name] ~= nil then
		return wezterm.format({
			{ Text = " " },
			process_icons[process_name],
			{ Text = " " },
		})
	else
		return wezterm.format({
			{ Text = string.format("%s", process_name) },
		})
	end
end

wezterm.on("open-uri", function(_window, _pane, uri)
	wezterm.open_with(uri, "chromium")
end)

wezterm.on("format-tab-title", function(tab, _tabs, _panes, _config, hover, max_width)
	local has_unseen_output = false
	for _, pane in ipairs(tab.panes) do
		if pane.has_unseen_output then
			has_unseen_output = true
			break
		end
	end
	return {
		hover and {
			Background = { Color = "#2a2e36" },
		} or "ResetAttributes",
		{
			Foreground = {
				Color = has_unseen_output and palette.lemon_chiffon
					or (tab.is_active and palette.turquoise or "#9196c2"),
			},
		},
		{ Text = get_process(tab) },
		{ Foreground = { Color = "#9196c2" } },
		{ Text = " " },
		-- { Text = tab.active_pane.current_working_dir },
		{ Text = get_current_working_dir(tab, math.min(max_width, 14)) },
		{ Text = " " },
	}
end)

local function find(list, item)
	for i, v in ipairs(list) do
		if type(item) == "function" then
			if item(v) == true then
				return i
			end
		else
			if v == item then
				return i
			end
		end
	end
	return nil
end

local entries_cache = {}

wezterm.on("update-right-status", function(window, pane)
	-- if not window:get_dimensions().is_full_screen then
	-- 	window:set_right_status("")
	-- 	return
	-- end
	local pwd = ""
	if pane ~= nil then
		local panewd = pane:get_current_working_dir()
		if panewd and panewd ~= "" then
			pwd = get_git_root(panewd:gsub("%w+://%w+/", "/"), false)
		end
	end

	local icon_txt = "✦"
	local icon_col = palette.turquoise
	if pwd ~= "" and exists(pwd) then
		-- check if timestamp was more than 10 seconds ago
		local entries
		if
			entries_cache[pwd] == nil
			or entries_cache[pwd].timestamp ~= nil
			or entries_cache[pwd].timestamp + 10 < os.time()
		then
			entries_cache[pwd] = nil
			entries = scandir(pwd .. "/")
			if exists(pwd .. "/src/") then
				for _, v in ipairs(scandir(pwd .. "/src/")) do
					table.insert(entries, v)
				end
			end
			entries_cache[pwd] = {
				timestamp = os.time(),
				entries = entries,
			}
		else
			entries = entries_cache[pwd].entries
		end
		if
			exists(pwd .. "/Cargo.toml")
			or find(entries, function(v)
					if string.sub(v, -3, -1) == ".rs" then
						return true
					end
					return false
				end)
				~= nil
		then
			icon_txt = nf.seti_rust
			icon_col = palette.peach
		elseif
			exists(pwd .. "/init.lua")
			-- or exists(pwd .. "/lua/")
			or find(entries, function(v)
					if string.sub(v, -4, -1) == ".lua" then
						return true
					end
					return false
				end)
				~= nil
		then
			icon_txt = nf.seti_lua
			icon_col = palette.blue
		elseif pwd == wezterm.home_dir .. "/" then
			-- icon = nf.seti_shell
			-- icon = nf.mdi_home_circle
			icon_txt = nf.mdi_lambda
		elseif
			exists(pwd .. "/package.json")
			or exists(pwd .. "/node_modules")
			or find(entries, function(v)
					if string.sub(v, -3, -1) == ".js" then
						return true
					end
					return false
				end)
				~= nil
		then
			icon_txt = nf.dev_javascript_badge
			icon_col = palette.yellow
		elseif exists(pwd .. "/go.mod") then
			icon_txt = nf.mdi_language_go
			icon_col = palette.pale_azure
		end
	end

	window:set_right_status(wezterm.format({
		{ Attribute = { Intensity = "Bold" } },
		{ Foreground = { Color = "#9196c2" } },
		{ Text = wezterm.strftime(" %l:%M %p ") },
		{ Foreground = { Color = icon_col } },
		{ Text = icon_txt or "" },
		{ Text = "  " },
	}))
end)

if wezterm.config_builder then
	config = wezterm.config_builder()
	setup(config)
end

return config
