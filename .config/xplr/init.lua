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
	.. "/.config/xplr/?.lua;"

local cmd = string.format("[ -e '%s' ] || git clone '%s' '%s'", xpm_path, xpm_url, xpm_path)
os.execute(cmd)

require("xpm").setup({
	plugins = {
		"dtomvan/xpm.xplr",
		-- "sayanarijit/nvim-ctrl.xplr",
	},
	auto_install = true,
	auto_cleanup = true,
})

-- require("nvim").setup({
-- 	bin = "nvim",
-- 	mode = "default",
-- 	keys = {
-- 		["ctrl-e"] = "tabedit",
-- 		["e"] = "",
-- 	},
-- })
