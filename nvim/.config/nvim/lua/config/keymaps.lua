-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
-- vim.keymap.del("n", "<leader>gd")
vim.keymap.set("n", "<leader>q", function()
  require("quicker").toggle()
end, {
  desc = "Toggle quickfix",
})
-- Diffview
vim.keymap.set("n", "<leader>gd", function()
  if next(require("diffview.lib").views) == nil then
    vim.cmd("DiffviewOpen")
  else
    vim.cmd("DiffviewClose")
  end
end, { desc = "Toggle Diffview window" })

local function get_default_branch_jj()
  vim.fn.system({ "jj", "log", "-r", "main@origin", "--no-graph", "--template", " ", "--limit", "1" })
  if vim.v.shell_error == 0 then
    return "origin/main"
  end
  return "origin/master"
end

vim.keymap.set("n", "<leader>dm", function()
  local branch = get_default_branch_jj()
  vim.cmd("DiffviewOpen " .. branch)
end, { desc = "Diff against master/main branch" })
