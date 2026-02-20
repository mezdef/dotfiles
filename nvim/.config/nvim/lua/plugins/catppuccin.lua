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
        CursorLine = { bg = colors.surface1 }, -- Current line highlight
        Visual = { bg = colors.mauve, fg = colors.mantle }, -- Visual Block mode
        LineNr = { fg = colors.surface2 }, -- Color for normal line numbers
        CursorLineNr = { fg = colors.mauve, bold = false }, -- Color for the current line number
        GitSignsAddNr = { fg = colors.green },
        GitSignsChangeNr = { fg = colors.yellow },
        GitSignsDeleteNr = { fg = colors.red },
        GitSignsChangeLn = { bg = blend(colors.yellow, colors.base, 0.2) },
        -- Set colors for diffview, applied via a hook
        DiffviewNormal = { fg = colors.subtext0 },
        DiffviewAdd = {
          fg = colors.green,
          bg = blend(colors.green, colors.base, 0.2),
        },
        DiffviewDelete = {
          bg = blend(colors.red, colors.base, 0.15),
          fg = colors.red,
        },
        DiffviewChange = {
          -- fg = colors.yellow,
          -- bg = blend(colors.yellow, colors.base, 0.2),
        },
        DiffviewText = {
          fg = colors.yellow,
          bg = blend(colors.yellow, colors.base, 0.25),
        },
      }
    end,
    integrations = {
      diffview = true, -- Enable the diffview integration
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
