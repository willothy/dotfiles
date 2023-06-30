-- autostart, just runs `autostart.sh`

local awful = require("awful")
local gfs = require("gears.filesystem")

local conf = gfs.get_configuration_dir()

local picom_cfg = conf .. "assets/picom/picom.conf"
awful.spawn("picom --config " .. picom_cfg .. " -b")

awful.spawn("nm-applet")
awful.spawn.with_shell("lxpolkit")
