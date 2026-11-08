return {
  "akinsho/horizon.nvim",
  name = "horizon",
  priority = 1000,
  config = function()
    require("horizon").setup({
      transparent = true,
    })
    vim.cmd("colorscheme horizon")
  end,
}
