-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices.

-- For example, changing the initial geometry for new windows:
config.initial_cols = 150
config.initial_rows = 40

-- or, changing the font size and color scheme.
config.font_size = 15
config.font = wezterm.font("CodeNewRoman Nerd Font")
--config.color_scheme = "Horizon Dark (base16)"
--config.color_scheme = "catppuccin-mocha"
-- Función para detectar si macOS está en modo oscuro
local function is_dark_mode()
	if wezterm.gui then
		-- get_appearance() devuelve 'Dark', 'Light', 'DarkHighContrast', etc.
		return wezterm.gui.get_appearance():find("Dark") ~= nil
	end
	return true -- Por defecto oscuro si no se puede detectar la GUI
end

-- Selección dinámica de temas
if is_dark_mode() then
	--config.color_scheme = "catppuccin-mocha" -- Tema oscuro
	config.color_scheme = "Rosé Pine Moon (Gogh)" -- Tema oscuro
else
	config.color_scheme = "Rosé Pine Dawn (Gogh)" -- Tema claro
end
--Tabs

config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "RESIZE"
--config.integrated_title_button_style = "MacOsNative"

-- Finally, return the configuration to wezterm:
return config
