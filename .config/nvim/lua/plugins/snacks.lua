return {
  "folke/snacks.nvim",
  opts = {
    -- Configuración del Dashboard (ASCII Art)
    dashboard = {
      preset = {
        header = [[
▄▄ ▄▄ ▄▄ ▀██▀ ▄▄ ▄▄ ▄█ ▄▄ ██▀▄ 
██ ██ ██  ██  ██ ██ ██ ██ ██ ██
 ▀▀██ ██  ██  ██▀██ ██ ██ ██▀█▄
▄▄ ██ ██  ██  ██ ██ ██ ██ ██ ██
██▄▀▀ ██  ██  ██ ██ ▀▀▄▀▀ ██▄▀▀
        ]],
      },
    },
    -- Configuración del Picker / Explorer
    picker = {
      sources = {
        explorer = {
          layout = {
            layout = {
              position = "right",
            },
          },
        },
      },
    },
  },
}
