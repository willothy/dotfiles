_G.version = "0.21.3"

local home = os.getenv("HOME")
local xpm_path = home .. "/.local/share/xplr/dtomvan/xpm.xplr"
local xpm_url = "https://github.com/dtomvan/xpm.xplr"

package.path = package.path
	.. ";"
	.. xpm_path
	.. "/?.lua;"
	.. xpm_path
	.. "/?/init.lua;"
	.. home
	.. "/projects/lua/?/init.lua;"
-- .. home
-- .. "/.config/xplr/?/init.lua;"

local cmd = string.format("[ -e '%s' ] || git clone '%s' '%s'", xpm_path, xpm_url, xpm_path)
os.execute(cmd)

require("xpm").setup({
	plugins = {
		"dtomvan/xpm.xplr",
		"sayanarijit/map.xplr",
		-- "willothy/command-mode.xplr",
		"sayanarijit/type-to-nav.xplr",
	},
	auto_install = true,
	auto_cleanup = true,
})

local command = require("command-mode")

command.setup({
	mode = "default",
	key = ":",
	remap_action_mode_to = {
		mode = "default",
		key = ";",
	},
})

local run_path = "/var/run/user/1000"

command.silent_cmd("edit", "open in editor", command.completers.path)(function(app, args)
	args = args:gsub("^%s+", "")
	local file
	if args ~= "" and xplr.util.exists(xplr.util.absolute(args)) then
		file = xplr.util.absolute(args)
	end
	file = file or app.focused_node.absolute_path
	---@return string?
	local function try_addr(addr)
		if addr and xplr.util.exists(addr) then
			return addr
		else
			return nil
		end
	end
	local addrs = {
		os.getenv("NVIM"),
		run_path
			.. "/wezterm.nvim-"
			.. os.getenv("WEZTERM_UNIX_SOCKET"):match("gui%-sock%-(%d+)")
			.. "-"
			.. app.pwd:gsub("/", "_"),
	}
	for _, addr in pairs(addrs) do
		local valid = try_addr(addr)
		if valid then
			return {
				{
					Call = {
						command = "nvim",
						args = {
							file,
						},
					},
				},
			}
		end
	end
	return {
		{
			Call = {
				command = "wezterm",
				args = {
					"cli",
					"split-pane",
					"--",
					"nvim",
					file,
				},
			},
		},
	}
end)

command.silent_cmd("cd", "change directory", command.completers.path)(function(app, args)
	if not xplr.util.is_dir(args) then
		if xplr.util.is_dir(app.pwd .. "/" .. args) then
			args = app.pwd .. "/" .. args
		else
			return {}
		end
	end
	return {
		{ ChangeDirectory = args },
	}
end)

command.cmd("q", "quit")(function()
	return {
		"Quit",
	}
end)
