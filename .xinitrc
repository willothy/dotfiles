#!/usr/bin/env bash
xrandr --output HDMI-1 --mode 1920x1080 --pos 0x0 --rotate normal --output DP-1 --mode 2560x1080 --pos 1920x0 --primary
exec awesome
