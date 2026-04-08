return {
  "yousefhadder/markdown-plus.nvim",
  ft = "markdown",
  init = function()
    vim.g.maplocalleader = vim.g.maplocalleader or "\\"
  end,
  keys = {
    { "<leader>mx", "<Plug>(MarkdownPlusToggleCheckbox)", ft = "markdown", desc = "Toggle checkbox" },
    { "<leader>mx", "<Plug>(MarkdownPlusToggleCheckbox)", mode = "x", ft = "markdown", desc = "Toggle checkbox" },
  },
  opts = {
    list = {
      smart_outdent = false,
    },
  },
}
