vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- live markdown+mermaid browser preview (:MdPreview / <leader>mp) — replaces markdown-preview.nvim
require("config.md-preview")

-- temporary: catches the intermittent blank statusline / file tree in a split (:UiWatchdog)
require("config.ui-watchdog").setup()
