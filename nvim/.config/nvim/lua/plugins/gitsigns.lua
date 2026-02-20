-- Add this to ~/.config/nvim/lua/plugins/gitsigns.lua
return {
  "lewis6991/gitsigns.nvim",
  keys = {
    { "<leader>gds", function() require("gitsigns").toggle_signs() end, desc = "Toggle gitsigns" },
  },
  opts = {
    current_line_blame = true,
    numhl = true,
    linehl = true,
    signs = {
      add          = { text = "" },
      change       = { text = "" },
      changedelete = { text = "" },
      untracked    = { text = "" },
    },
    -- current_line_blame_opts = {
    --   virt_text = true,
    --   virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
    --   delay = 1000,
    -- },
    -- signs = {
    --   add = { text = "▎" },
    --   change = { text = "▎" },
    --   delete = { text = "" },
    --   topdelete = { text = "" },
    --   changedelete = { text = "▎" },
    --   untracked = { text = "▎" },
    -- },
    -- signs_staged = {
    --   add = { text = "▎" },
    --   change = { text = "▎" },
    --   delete = { text = "" },
    --   topdelete = { text = "" },
    --   changedelete = { text = "▎" },
    -- },
  },
}
