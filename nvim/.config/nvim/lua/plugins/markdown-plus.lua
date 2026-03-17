return {
  "yousefhadder/markdown-plus.nvim",
  ft = "markdown",
  init = function()
    vim.g.maplocalleader = vim.g.mapleader
  end,
  opts = {
    list = {
      smart_outdent = false,
    },
  },
}
