return {

  -- TPOPE ESSENTIALS
  { "tpope/vim-surround" },
  --{ "tpope/vim-commentary" },
  { "matze/vim-move" },
  { "mbbill/undotree" },

  -- AUTOPAIRS
  {
    "windwp/nvim-autopairs",
    config = true,
  },

  -- SPECTRE (Project-wide Search & Replace)
--   {
--     "nvim-pack/nvim-spectre",
--     keys = {
--         { "<leader>sr", function() require("spectre").open() end, desc = "Spectre Global Replace" },
--         { "<leader>sw", function() require("spectre").open_visual({ select_word = true }) end, desc = "Spectre Replace Word" },
--     },
-- }

}
