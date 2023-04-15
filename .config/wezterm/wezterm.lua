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

if wezterm.config_builder then
	config = wezterm.config_builder()
	setup(config)
end

return config
