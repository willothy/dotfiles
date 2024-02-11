---@diagnostic disable: lowercase-global

backend = "glx"
vsync = true
detect_transient = false

animations = true
animation_stiffness = 100
animation_stiffness_tag_change = 100

animation_window_mass = 0.55
animation_dampening = 15
animation_clamping = true

active_opacity = 1
inactive_opacity = 1
inactive_opacity_override = false
frame_opacity = 1
detect_client_opacity = true

corner_radius = 12
detect_rounded_corners = false

blur_method = "dual_kawase"
blur_strength = 5
blur_radius = 5
blur_background_frame = true

animation_for_open_window = "zoom"
animation_for_unmap_window = "minimize"
animation_for_transient_window = "zoom"

animation_for_prev_tag = "slide-up"
animation_for_next_tag = "slide-down"
enable_fading_next_tag = true
enable_fading_prev_tag = true
