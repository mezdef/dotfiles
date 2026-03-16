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
        Normal = { fg = colors.subtext1 },
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
        SpellBad = { sp = blend(colors.pink, colors.base, 0.4), undercurl = true, fg = "NONE" },
        SpellCap = { sp = blend(colors.pink, colors.base, 0.4), undercurl = true, fg = "NONE" },
        SpellLocal = { sp = blend(colors.pink, colors.base, 0.4), undercurl = true, fg = "NONE" },
        SpellRare = { sp = blend(colors.pink, colors.base, 0.4), undercurl = true, fg = "NONE" },
        RenderMarkdownLink = { fg = colors.blue },
        ["@markup.link"] = { fg = colors.blue },
        ["@markup.link.label"] = { fg = colors.blue },
        ["@markup.link.label.markdown_inline"] = { fg = colors.blue },
        ["@markup.link.url"] = { fg = colors.blue },
        RenderMarkdownBullet = { fg = colors.mauve },
        RenderMarkdownUnchecked = { fg = colors.mauve },
        RenderMarkdownChecked = { fg = colors.mauve },
        RenderMarkdownTodo = { fg = colors.mauve },
        RenderMarkdownH1 = { fg = colors.green },
        RenderMarkdownH2 = { fg = colors.green },
        RenderMarkdownH3 = { fg = colors.green },
        ["@markup.heading.1.markdown"] = { fg = colors.text },
        ["@markup.heading.2.markdown"] = { fg = colors.text },
        ["@markup.heading.3.markdown"] = { fg = colors.text },
        ["@markup.heading.4.markdown"] = { fg = colors.text },
        ["@markup.heading.5.markdown"] = { fg = colors.text },
        ["@markup.heading.6.markdown"] = { fg = colors.text },
        RenderMarkdownH1Bg = { bg = colors.surface0 },
        RenderMarkdownH2Bg = { bg = colors.surface0 },
        RenderMarkdownH3Bg = { bg = colors.surface0 },
        RenderMarkdownH4Bg = { bg = colors.surface0 },
        RenderMarkdownH5Bg = { bg = colors.surface0 },
        RenderMarkdownH6Bg = { bg = colors.surface0 },
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
