-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Universal scroll: kanata ctrl layer maps C-u/d → Page Up/Down; remap to half-page
vim.keymap.set("n", "<PageUp>", "<C-u>")
vim.keymap.set("n", "<PageDown>", "<C-d>")
-- Hyper+g/G emits Home/End → top/bottom of file
vim.keymap.set("n", "<Home>", "gg")
vim.keymap.set("n", "<End>", "G")

-- Fuzzy file picker (matches tmux C-p for phaser)
vim.keymap.set("n", "<C-p>", function()
  Snacks.picker.files()
end, { desc = "Find Files" })

-- Move macro recording to Q to prevent accidental triggers
vim.keymap.set("n", "q", "<Nop>", { desc = "Disable accidental macro recording" })
vim.keymap.set("n", "Q", "q", { desc = "Record macro" })
vim.keymap.set("n", "<leader>q", function()
  require("quicker").toggle()
end, {
  desc = "Toggle quickfix",
})

-- Search & replace across quickfix files with per-match confirmation.
-- Workflow: populate qf list (snacks grep → <C-q>, or :grep), then <leader>sr.
-- Prefills pattern from last snacks qflist action or last vim search register.
vim.keymap.set("n", "<leader>sr", function()
  local pattern = (vim.g._qf_search_pattern ~= "" and vim.g._qf_search_pattern)
    or vim.fn.getreg("/")
    or ""
  -- Escape forward slashes so they don't break the :s delimiter
  pattern = pattern:gsub("/", "\\/")
  local cmd = ":cfdo %%s/" .. pattern .. "//gc | update"
  -- 12 <Left> moves places cursor in the replacement slot (before /gc | update)
  local left_keys = string.rep("<Left>", 12)
  local keys = vim.api.nvim_replace_termcodes(cmd .. left_keys, true, false, true)
  vim.api.nvim_feedkeys(keys, "n", false)
end, { desc = "Search & Replace (quickfix files)" })
