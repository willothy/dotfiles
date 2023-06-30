pcall(require, "luarocks.loader")

require("awful.autofocus")
local menubar = require("menubar")

terminal = "wezterm"
explorer = "nautilus"
browser = "brave"
launcher = "rofi -show drun"
editor = os.getenv("EDITOR") or "nvim"
visual_editor = os.getenv("EDITOR") or "nvim"
editor_cmd = terminal .. " -e " .. editor
modkey = "Mod4" -- super, the windows key

-- Set the terminal for applications that require it
menubar.utils.terminal = terminal

require("signal.global")
require("autostart")
require("configuration")
require("ui")
