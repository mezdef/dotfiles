return {
  "catppuccin/nvim",
  opts = {
    transparent_background = true, -- Enables general background transparency
    -- Optional: set floats (e.g. documentation popups) to transparent as well
    float = {
      transparent = true,
      solid = true,
    },
    custom_highlights = function(colors)
      return {
        Comment = { fg = colors.overlay1, italic = false }, -- Commented lines
        CursorLine = { bg = colors.surface1 }, -- Current line highlight
        Visual = { bg = colors.mauve, fg = colors.mantle }, -- Visual Block mode
        LineNr = { fg = colors.surface2 }, -- Color for normal line numbers
        CursorLineNr = { fg = colors.mauve, bold = false }, -- Color for the current line number
      }
    end,
  },
}
