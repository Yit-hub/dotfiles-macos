return {
  -- Rose Pine for dark mode
  {
    "catppuccin/nvim.nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      variant = "auto",
      dark_variant = "main",
      enable = {
        terminal = true,
        legacy_highlights = true,
        migrations = true,
      },
      styles = {
        transparency = false,
      },
    },
  },

  -- Solarized for light mode
  {
    "maxmx03/solarized.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("solarized").setup({
        transparent = {
          enabled = false,
        },
        palette = "solarized",
        styles = {
          functions = { italic = true },
          keywords = { italic = true },
        },
      })
    end,
  },

  -- Auto theme detection
  {
    "f-person/auto-dark-mode.nvim",
    priority = 1000,
    config = function()
      local auto_dark_mode = require("auto-dark-mode")

      auto_dark_mode.setup({
        update_interval = 1000,
        set_dark_mode = function()
          vim.api.nvim_set_option_value("background", "dark", {})
          vim.cmd("colorscheme catppuccin")
        end,
        set_light_mode = function()
          vim.api.nvim_set_option_value("background", "light", {})
          vim.cmd("colorscheme solarized")
        end,
      })
    end,
  },
}
