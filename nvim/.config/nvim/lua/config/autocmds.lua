-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- When opened with a directory, cd into it and open file picker instead of netrw
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local arg = vim.fn.argv(0)
    if arg and arg ~= "" and vim.fn.isdirectory(arg) == 1 then
      vim.cmd("cd " .. vim.fn.fnameescape(arg))
      vim.cmd("bwipeout")
      vim.schedule(function()
        Snacks.picker.files({ root = false, hidden = true })
      end)
    end
  end,
})

-- Disable completion popup in markdown; toggle with <leader>mc
-- Disable spell in markdown (LazyVim enables it); toggle with <leader>ms
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.b.completion = false
    vim.opt_local.spell = false
    vim.keymap.set("n", "<leader>mc", function()
      vim.b.completion = not vim.b.completion
      vim.notify("Completion " .. (vim.b.completion and "enabled" or "disabled"), vim.log.levels.INFO)
    end, { buffer = true, desc = "Toggle Completion" })
    vim.keymap.set("n", "<leader>ms", function()
      vim.opt_local.spell = not vim.opt_local.spell:get()
      vim.notify("Spell " .. (vim.opt_local.spell:get() and "enabled" or "disabled"), vim.log.levels.INFO)
    end, { buffer = true, desc = "Toggle Spell" })
  end,
})
