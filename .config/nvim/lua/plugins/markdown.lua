return {
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
