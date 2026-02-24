return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    local colors = require("catppuccin.palettes").get_palette("mocha")

    local mode_colors = {
      n = colors.green,
      i = colors.text,
      v = colors.mauve,
      V = colors.mauve,
      ["\22"] = colors.mauve, -- ctrl-v block visual
      c = colors.peach,
      R = colors.red,
    }

    local function mode_color()
      return mode_colors[vim.fn.mode()] or colors.green
    end

    opts.options = opts.options or {}
    opts.options.section_separators = { left = "", right = "" }

    opts.sections.lualine_a = {
      {
        "mode",
        color = function()
          return { bg = mode_color(), fg = colors.base, gui = "bold" }
        end,
      },
    }

    opts.sections.lualine_b = {
      {
        "branch",
        color = function()
          return { bg = colors.surface1, fg = mode_color() }
        end,
      },
    }

    opts.sections.lualine_y = {
      {
        "progress",
        separator = " ",
        padding = { left = 1, right = 0 },
        color = function()
          return { bg = colors.surface1, fg = mode_color() }
        end,
      },
    }

    opts.sections.lualine_z = {
      {
        "location",
        color = function()
          return { bg = mode_color(), fg = colors.base }
        end,
      },
    }

    return opts
  end,
}
