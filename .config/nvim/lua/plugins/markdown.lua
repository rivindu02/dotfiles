return {
  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    keys = {
      { "<leader>z", "<cmd>ZenMode<CR>", desc = "Toggle centered reading view" },
    },
    opts = {
      window = {
        width = 90,
        options = {
          wrap = true,
          linebreak = true,
          number = false,
          relativenumber = false,
          signcolumn = "no",
          foldcolumn = "0",
        },
      },
      plugins = {
        twilight = { enabled = false },
      },
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    config = function()
      require("render-markdown").setup({
        preset = "obsidian",
        html    = { enabled = false },
        latex   = { enabled = false },
        heading = {
          backgrounds = { "", "", "", "", "", "" },
          icons       = { "▌ ", "▌ ", "▌ ", "▌ ", "▌ ", "▌ " },
        },
        code = {
          width     = "block",
          left_pad  = 2,
          right_pad = 2,
        },
      })
    end,
  },
}
