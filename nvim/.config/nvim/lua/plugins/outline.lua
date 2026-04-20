return {
  "hedyhli/outline.nvim",
  cmd = { "Outline", "OutlineOpen" },
  keys = {
    { "<leader>cs", "<cmd>Outline<cr>", desc = "Toggle Outline" },
  },
  opts = {
    outline_window = {
      position = "left",
    },
  },
}
