return {
  "catppuccin/nvim",
  opts = {
    transparent_background = true, -- Enables general background transparency
    -- Optional: set floats (e.g. documentation popups) to transparent as well
    float = {
      transparent = true,
    },
    custom_highlights = function(colors)
      local blend = require("catppuccin.utils.colors").blend
      return {
        Comment = { fg = colors.overlay1, italic = false }, -- Commented lines
        ["@comment"] = { fg = colors.overlay1, italic = false },
        CursorLine = { bg = colors.surface1 }, -- Current line highlight
        Visual = { bg = colors.mauve, fg = colors.mantle }, -- Visual Block mode
        LineNr = { fg = colors.surface2 }, -- Color for normal line numbers
        CursorLineNr = { fg = colors.mauve, bold = false }, -- Color for the current line number
        GitSignsAddNr = { fg = colors.green },
        GitSignsChangeNr = { fg = colors.yellow },
        GitSignsDeleteNr = { fg = colors.red },
        GitSignsChangeLn = { bg = blend(colors.yellow, colors.base, 0.2) },
        -- Diff highlights (used by codediff.nvim and built-in diff mode)
        DiffAdd = { bg = blend(colors.green, colors.base, 0.2) },
        DiffDelete = { bg = blend(colors.red, colors.base, 0.15) },
        DiffChange = { bg = blend(colors.yellow, colors.base, 0.15) },
        DiffText = { bg = blend(colors.yellow, colors.base, 0.3) },
        MiniMapNormal = { bg = "NONE" },
        MiniMapSymbolView = { bg = "NONE" },
        NormalCursor = { bg = colors.green, fg = colors.base },
        InsertCursor = { bg = colors.text, fg = colors.base },
        VisualCursor = { bg = colors.mauve, fg = colors.base },
      }
    end,
    integrations = {
      cmp = true,
      gitsigns = true,
      nvimtree = true,
      treesitter = true,
      notify = false,
      mini = {
        enabled = true,
        indentscope_color = "",
      },
      -- Other integrations can be listed here
    },
  },
}
