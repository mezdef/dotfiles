return {
  "esmuellert/codediff.nvim",
  cmd = "CodeDiff",
  opts = {
    diff = {
      layout = "side-by-side",
      disable_inlay_hints = true,
      jump_to_first_change = true,
    },
    explorer = {
      initial_focus = "explorer",
      file_filter = {
        ignore = { ".git/**", ".jj/**" },
      },
    },
    keymaps = {
      explorer = {
        select = "l",
      },
    },
  },
  keys = {
    { "<leader>gdd", "<cmd>CodeDiff<cr>", desc = "CodeDiff status" },
    { "<leader>gdm", function()
        vim.fn.system({ "jj", "log", "-r", "main@origin", "--no-graph", "--template", " ", "--limit", "1" })
        local branch = vim.v.shell_error == 0 and "main" or "master"
        vim.cmd("CodeDiff " .. branch .. "...")
      end,
      desc = "CodeDiff against main/master",
    },
    { "<leader>gdf", "<cmd>CodeDiff file HEAD<cr>", desc = "CodeDiff current file" },
    { "<leader>gdh", "<cmd>CodeDiff history<cr>", desc = "CodeDiff history" },
  },
}
