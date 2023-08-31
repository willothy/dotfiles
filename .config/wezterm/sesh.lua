local wezterm = require("wezterm")

local sesh = {}

sesh.create = {
	brief = "Sesh: Create session",
	icon = "mdi_plus",
	action = wezterm.action.PromptInputLine({
		description = "Enter new session name",
		action = wezterm.action_callback(function(window, pane, line)
			window:perform_action(
				wezterm.action.SpawnCommandInNewTab({
					args = { "sesh", "start", "--name", line },
					set_environment_variables = {
						PATH = os.getenv("PATH") .. ":" .. os.getenv("HOME") .. "/.cargo/bin",
					},
				}),
				pane
			)
		end),
	}),
}

sesh.attach = {
	brief = "Sesh: Attach to session",
	icon = "seti_shell",
	action = wezterm.action.SpawnCommandInNewTab({
		args = { "sesh", "select" },
		set_environment_variables = {
			PATH = os.getenv("PATH") .. ":" .. os.getenv("HOME") .. "/.cargo/bin",
		},
	}),
}

return sesh
