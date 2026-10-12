return {
  {
    "rose-pine/neovim",
    name = "rose-pine",
    priority = 1000,
    opts = {
      dark_variant = "moon",
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
  {
    "f-person/auto-dark-mode.nvim",
    priority = 1000,
    config = function()
      local auto_dark_mode = require("auto-dark-mode")
      auto_dark_mode.setup({
        update_interval = 1000,
        set_dark_mode = function()
          vim.api.nvim_set_option_value("background", "dark", {})
          require("rose-pine").setup({ variant = "moon" })
          vim.cmd("colorscheme rose-pine")
        end,
        set_light_mode = function()
          vim.api.nvim_set_option_value("background", "light", {})
          require("rose-pine").setup({ variant = "dawn" })
          vim.cmd("colorscheme rose-pine")
        end,
      })
    end,
  },
}
