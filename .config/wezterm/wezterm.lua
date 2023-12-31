local wezterm = require("wezterm")
local nf = wezterm.nerdfonts
local act = wezterm.action
local sesh = require("sesh")

local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
	config:set_strict_mode(false)
end

config.webgpu_preferred_adapter = {
	backend = "Vulkan",
	device = 7040,
	device_type = "DiscreteGpu",
	driver = "NVIDIA",
	driver_info = "535.113.01",
	name = "NVIDIA GeForce GTX 1080",
	vendor = 4318,
}
config.front_end = "WebGpu"
-- config.front_end = "OpenGL"

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
		Text = nf.custom_vim,
	},
	["vim"] = {
		Text = nf.custom_vim, --nf.dev_vim,
	},
	["node"] = {
		Text = nf.md_hexagon,
	},
	["zsh"] = {
		Text = nf.md_lambda,
		-- Text = nf.dev_terminal_badge,
		-- Text = nf.mdi_apple_keyboard_command,
	},
	["bash"] = {
		Text = nf.cod_terminal_bash,
	},
	["btm"] = {
		Text = nf.md_chart_donut_variant,
	},
	["htop"] = {
		Text = nf.md_chart_donut_variant,
	},
	["cargo"] = {
		Text = nf.dev_rust,
	},
	["rust"] = {
		Text = nf.dev_rust,
	},
	["go"] = {
		Text = nf.md_language_go,
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
		Text = nf.md_arrow_down_box,
	},
	["curl"] = {
		Text = nf.md_flattr,
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

local function gitcheck(dir)
	if not exists(dir) then
		return nil
	end
	local prefix = "/"
	if dir:sub(#dir) == "/" then
		prefix = ""
	end
	while #dir > 1 and not exists(dir .. prefix .. ".git") do
		dir = dir:gsub("/+[^/]*$", "")
	end
	return #dir > 0 and dir or dir
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

local function get_current_working_dir(tab, max)
	local pane = tab.active_pane
	local pwd = tostring(pane.current_working_dir):gsub("file://%a+/", "/")

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
		return pwd
	end
	return pwd
end

local function get_proc_title(pane)
	return (pane.title or pane:get_foreground_process_name()):gsub("^%s+", ""):gsub("%s+$", ""):match("[^/]+$")
end

config.animation_fps = 30
config.max_fps = 60
config.font = wezterm.font_with_fallback({
	-- "Maple Mono NF",
	"Maple Mono",
	"FiraMono Nerd Font",
	-- "Bruh-Font",
})
config.underline_thickness = 1
config.underline_position = -2.0

-- config.allow_square_glyphs_to_overflow_width = "Always"
config.allow_square_glyphs_to_overflow_width = "Never"

-- config.default_prog = { "sesh", "attach", "tab", "--create" }

-- config.font = "Fira Code"
config.font_size = 12.0

config.color_scheme = "tokyonight"

config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.tab_max_width = 30

config.window_frame = {
	font = wezterm.font({ family = "Fira Code", weight = "Bold" }),
	font_size = 12.0,
	border_left_width = "0.0cell",
	border_right_width = "0.0cell",
	border_bottom_height = "0.10cell",
	border_bottom_color = "#1a1b26",
	border_top_height = "0.0cell",
}

-- config.window_background_opacity = 0.9
config.colors = {
	background = "#26283f",
	-- background = "#0d1117",
	-- cursor_bg = "#26283f",
}

config.inactive_pane_hsb = {
	saturation = 1.0,
	brightness = 1.0,
}

config.window_decorations = "RESIZE"

config.window_padding = {
	top = 5,
	-- bottom = 1,
	bottom = "0.0cell",
	left = 10,
	right = 8,
}

config.launch_menu = {
	-- {
	-- 	label = "Sesh: Select session",
	-- 	args = { "sesh", "select" },
	-- },
}

-- Equivalent to POSIX basename(3)
-- Given "/foo/bar" returns "bar"
-- Given "c:\\foo\\bar" returns "bar"
local function basename(s)
	return string.gsub(s, "(.*[/\\])(.*)", "%2")
end

local function is_vim(pane)
	-- local vim = {
	-- 	vim = true,
	-- 	nvim = true,
	-- }
	-- this is set by the plugin, and unset on ExitPre in Neovim
	return (pane:get_user_vars().IS_NVIM == "true") -- or vim[get_proc_title(pane)] == true
end

local direction_keys = {
	-- reverse lookup
	Up = "Up",
	Down = "Down",
	Left = "Left",
	Right = "Right",
	h = "Left",
	j = "Down",
	k = "Up",
	l = "Right",
	UpArrow = "Up",
	DownArrow = "Down",
	LeftArrow = "Left",
	RightArrow = "Right",
}

local function split_nav(resize_or_move, key)
	local mods = resize_or_move == "resize" and "ALT" or "CTRL"
	return {
		key = key,
		mods = mods,
		action = wezterm.action_callback(function(win, pane)
			local vim = is_vim(pane)

			local matches = {
				zellij = true,
				rx = true,
			}

			local exe = basename(pane:get_foreground_process_info().executable)
			if vim or matches[exe] then
				win:perform_action({
					SendKey = { key = key, mods = mods },
				}, pane)
				return
			end

			if resize_or_move == "resize" then
				win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
			else
				local dir = direction_keys[key]

				local tab = win:mux_window():active_tab()
				local next_pane = tab and tab:get_pane_direction(direction_keys[key])
				if next_pane and next_pane:pane_id() ~= pane:pane_id() then
					next_pane:activate()
				else
					local offset
					if dir == "Left" then
						offset = -1
					else --if dir == "Right" then
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

config.bypass_mouse_reporting_modifiers = "SHIFT"
config.disable_default_key_bindings = false

-- config.leader = { key = "w", mods = "CTRL", timeout_milliseconds = 1000 }
config.keys = {
	split_nav("move", "h"),
	split_nav("move", "j"),
	split_nav("move", "k"),
	split_nav("move", "l"),
	split_nav("resize", "h"),
	-- split_nav("resize", "j"),
	-- split_nav("resize", "k"),
	split_nav("resize", "l"),
	split_nav("move", "LeftArrow"),
	split_nav("move", "DownArrow"),
	split_nav("move", "UpArrow"),
	split_nav("move", "RightArrow"),
	split_nav("resize", "LeftArrow"),
	split_nav("resize", "RightArrow"),
	split_nav("resize", "DownArrow"),
	split_nav("resize", "UpArrow"),
	-- {
	-- 	key = "\\",
	-- 	mods = "CTRL",
	-- 	action = act.DisableDefaultAssignment,
	-- },
	{
		key = "[",
		mods = "CMD",
		action = act.ActivateTabRelative(-1),
	},
	{
		key = "]",
		mods = "CMD",
		action = act.ActivateTabRelative(1),
	},
	{
		key = "q",
		mods = "CMD",
		action = act.CloseCurrentTab({ confirm = true }),
	},
	{
		key = "n",
		mods = "CMD",
		action = act.SpawnTab("CurrentPaneDomain"),
	},
	{
		key = "`",
		mods = "CMD",
		action = sesh.attach.action,
	},
	{
		key = "p",
		mods = "CTRL|SHIFT",
		action = act.ActivateCommandPalette,
	},
	{
		key = "LeftArrow",
		mods = "CTRL|SHIFT",
		action = act.DisableDefaultAssignment,
	},
	{
		key = "RightArrow",
		mods = "CTRL|SHIFT",
		action = act.DisableDefaultAssignment,
	},
	{
		key = "Enter",
		mods = "ALT",
		action = act.DisableDefaultAssignment,
	},
	-- {
	-- 	key = "5",
	-- 	mods = "CTRL|ALT|SHIFT",
	-- 	action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
	-- },
	-- {
	-- 	key = "'",
	-- 	mods = "CTRL|ALT|SHIFT",
	-- 	action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	-- },
}

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

-- wezterm.on("open-uri", function(_window, _pane, uri)
-- 	wezterm.open_with(uri, "brave")
-- end)

wezterm.on("format-tab-title", function(tab, _tabs, _panes, _config, hover, _max_width)
	local has_unseen_output = false
	for _, pane in ipairs(tab.panes) do
		if pane.has_unseen_output then
			has_unseen_output = true
			break
		end
	end
	local title = get_proc_title(tab.active_pane)

	local icon
	if process_icons[title] ~= nil then
		icon = wezterm.format({
			{ Text = " " },
			process_icons[title],
			{ Text = " " },
		})
	else
		icon = wezterm.format({
			{ Text = string.format(" %s", title) },
		})
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
		{ Text = icon },
		{ Foreground = { Color = "#9196c2" } },
		{ Text = tab.tab_title == "" and title or tab.tab_title },
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

local function make_right_status(window, pane)
	local pwd = ""
	if pane ~= nil then
		local panewd = tostring(pane:get_current_working_dir())
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
			entries = wezterm.read_dir(pwd .. "/")
			if exists(pwd .. "/src/") then
				for _, v in ipairs(wezterm.read_dir(pwd .. "/src/")) do
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
		-- elseif pwd == wezterm.home_dir .. "/" or pwd == wezterm.home_dir then
		-- 	-- icon = nf.seti_shell
		-- 	-- icon = nf.mdi_home_circle
		-- 	icon_txt = nf.md_lambda
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
			icon_txt = nf.md_language_go
			icon_col = palette.pale_azure
		end
	end

	window:set_right_status(wezterm.format({
		{ Attribute = { Intensity = "Bold" } },
		{ Foreground = { Color = "#9196c2" } },
		{
			Text = (function()
				local name = pane:get_user_vars().sesh_name
				if name == nil or name == "" then
					return ""
				else
					return string.format("%s %s", name, "∘")
				end
			end)(),
		},
		{ Text = wezterm.strftime("%l:%M %p ") },
		{ Foreground = { Color = icon_col } },
		{ Text = icon_txt or "" },
		{ Text = " " },
	}))
end

wezterm.on("update-right-status", make_right_status)

wezterm.on("augment-command-palette", function(_window, _pane)
	return {
		sesh.create,
		sesh.attach,
	}
end)

wezterm.on("new-tab-button-click", function(window, pane, button, _default_action)
	if button == "Left" then
		window:perform_action(sesh.create.action, pane)
		return false
	end
end)

-- wezterm.on("window-focus-changed", function(window)
-- 	we["WEZTERM_TAB"] = window:active_tab():tab_id()
-- end)

-- local mux = wezterm.mux
-- wezterm.on("gui-attached", function()
-- 	local workspace = mux.get_active_workspace()
-- 	for _, win in ipairs(mux.all_windows()) do
-- 		if win:get_workspace() == workspace then
-- 			config.set_environment_variables.WEZTERM_TAB = win:active_tab()
-- 		end
-- 	end
-- end)

config.hyperlink_rules = {
	-- linkify email addresses
	-- Compiled-in default. Used if you don't specify any hyperlink_rules.
	{ regex = [[\b\w+@[\w-]+(\.[\w-]+)+\b]], format = "mailto:$0" },
	-- file:// URI
	-- Compiled-in default. Used if you don't specify any hyperlink_rules.
	{ regex = [[\bfile://\S*\b]], format = "$0" },

	-- Make username/project paths clickable. This implies paths like the following are for GitHub.
	-- ( "nvim-treesitter/nvim-treesitter" | wbthomason/packer.nvim | wez/wezterm | "wez/wezterm.git" )
	-- As long as a full URL hyperlink regex exists above this it should not match a full URL to
	-- GitHub or GitLab / BitBucket (i.e. https://gitlab.com/user/project.git is still a whole clickable URL)
	{ regex = [["([\w\d]{1}[-\w\d]+)(/){1}([-\w\d\.]+)"]], format = "https://www.github.com/$1/$3" },

	{ regex = [[localhost:(\d+)]], format = "http://localhost:$1" },
}

local x = "localhost:23233"

config.warn_about_missing_glyphs = false

config.enable_kitty_keyboard = true

return config
