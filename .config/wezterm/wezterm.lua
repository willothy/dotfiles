local wezterm = require("wezterm")

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

local function popup(title, message, opts)
	opts = opts or {}
	if not opts.timeout_ms then
		opts.timeout_ms = 3000
	end
	local windows = wezterm.gui.gui_windows()
	if #windows < 1 then
		return
	end
	local window = windows[1]
	window:toast_notification(title, message, opts.url or nil, opts.timeout_ms)
end

local process_icons = {
	["docker"] = {
		Text = wezterm.nerdfonts.linux_docker,
	},
	["docker-compose"] = {
		Text = wezterm.nerdfonts.linux_docker,
	},
	["kuberlr"] = {
		Text = wezterm.nerdfonts.linux_docker,
	},
	["kubectl"] = {
		Text = wezterm.nerdfonts.linux_docker,
	},
	["nvim"] = {
		-- Text = wezterm.nerdfonts.custom_vim
		Text = wezterm.nerdfonts.custom_vim,
	},
	["vim"] = {
		Text = wezterm.nerdfonts.dev_vim,
	},
	["node"] = {
		Text = wezterm.nerdfonts.mdi_hexagon,
	},
	["zsh"] = {
		Text = wezterm.nerdfonts.dev_terminal,
	},
	["bash"] = {
		Text = wezterm.nerdfonts.cod_terminal_bash,
	},
	["btm"] = {
		Text = wezterm.nerdfonts.mdi_chart_donut_variant,
	},
	["htop"] = {
		Text = wezterm.nerdfonts.mdi_chart_donut_variant,
	},
	["cargo"] = {
		Text = wezterm.nerdfonts.dev_rust,
	},
	["go"] = {
		Text = wezterm.nerdfonts.mdi_language_go,
	},
	["lazydocker"] = {
		Text = wezterm.nerdfonts.linux_docker,
	},
	["git"] = {
		Text = wezterm.nerdfonts.dev_git,
	},
	["lua"] = {
		Text = wezterm.nerdfonts.seti_lua,
	},
	["wget"] = {
		Text = wezterm.nerdfonts.mdi_arrow_down_box,
	},
	["curl"] = {
		Text = wezterm.nerdfonts.mdi_flattr,
	},
	["gh"] = {
		Text = wezterm.nerdfonts.dev_github_badge,
	},
}

---Returns the dir relative to git root, or the original dir
local function get_git_root(dir)
	local function exists(file)
		local f = io.open(file)
		return f and io.close(f)
	end

	local function gitcheck(directory)
		local d = directory
		while #d > 0 and not exists(d .. "/.git") do
			d = d:gsub("/+[^/]*$", "")
		end
		return #d > 0 and d or directory
	end

	local gc = gitcheck(dir)
	if gc == dir then
		return dir
	else
		return dir:gsub(gc:gsub("%w+$", ""), ""):gsub("/$", "")
	end
end

local function get_current_working_dir(tab, max)
	local pwd = tab.active_pane.current_working_dir:gsub("%w+://%w+/", "/")
	pwd = get_git_root(pwd):gsub(os.getenv("HOME"), "~")
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

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	return {
		{ Text = get_process(tab) },
		{ Text = " " },
		{ Text = get_current_working_dir(tab, 14) },
		{ Text = " " },
	}
end)

wezterm.on("update-right-status", function(window)
	-- if not window:get_dimensions().is_full_screen then
	-- 	window:set_right_status("")
	-- 	return
	-- end

	window:set_right_status(wezterm.format({
		-- Pane info
		-- { Foreground = { Color = "#9196c2" } },
		-- { Text = string.format(" %s ", wezterm.nerdfonts.fa_chevron_right) },
		-- Time
		{ Attribute = { Intensity = "Bold" } },
		{ Foreground = { Color = "#9196c2" } },
		{ Text = wezterm.strftime(" %l:%M %p ") },
	}))
end)

if wezterm.config_builder then
	config = wezterm.config_builder()
	setup(config)
end

return config
