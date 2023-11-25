#!/usr/bin/env bash
xrandr --output DVI-D-0 --off --output HDMI-0 --mode 1920x1080 --pos 0x0 --rotate normal --output DP-0 --off --output DP-1 --off --output DP-2 --off --output DP-3 --off --output DP-4 --primary --mode 2560x1080 --pos 1920x0 --rotate normal --output DP-5 --off --output None-1-1 --off
exec awesome
