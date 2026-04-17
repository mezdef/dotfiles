return {
  -- add catppuccin
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      -- your theme configurations here
      transparent_background = true,
    },
  },
  -- Configure LazyVim to load this theme
  {
    "LazyVim/LazyVim",
    opts = {
      -- Use flavour-specific name: nvim 0.12 ships a bundled `catppuccin`
      -- colorscheme in $VIMRUNTIME/colors that shadows the plugin's, but
      -- only the plugin provides `catppuccin-mocha` (etc).
      colorscheme = "catppuccin-mocha",
    },
  },
}
