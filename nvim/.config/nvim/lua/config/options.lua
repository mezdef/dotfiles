-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- nvim 0.12 + lazy.nvim: lazy removes vim._load_package (the nvim runtime loader)
-- and its replacement cache_loader returns {} in fast events. The conceal_line
-- decoration provider fires in a fast event and needs vim.hl — pre-load it here
-- (non-fast context) so package.loaded has it before any fast event fires.
require('vim.hl')

vim.opt.relativenumber = true
vim.o.timeoutlen = 300
vim.opt.scrolloff = 10
vim.opt.guicursor = "n-c-o:block-NormalCursor,v-ve:block-VisualCursor,i-ci-sm:ver25-InsertCursor,r-cr:hor20"
