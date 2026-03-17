-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Disable spell (and word suggestions) in markdown; toggle with <leader>ms
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.spell = false
    vim.keymap.set("n", "<leader>ms", function()
      vim.opt_local.spell = not vim.opt_local.spell:get()
      vim.notify("Spell " .. (vim.opt_local.spell:get() and "enabled" or "disabled"), vim.log.levels.INFO)
    end, { buffer = true, desc = "Toggle Spell" })
  end,
})
