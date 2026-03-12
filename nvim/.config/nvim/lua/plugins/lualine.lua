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
    opts.options.component_separators = { left = "›", right = "‹" }

    opts.sections.lualine_a = {
      {
        "mode",
        separator = " ",
        padding = { left = 2, right = 2 },
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

    local icons = LazyVim.config.icons

    opts.sections.lualine_c = {
      {
        function()
          local root = LazyVim.root.get({ normalize = true })
          local cwd = LazyVim.root.cwd()
          if root == cwd then
            return ""
          end
          return " " .. vim.fs.basename(root)
        end,
        cond = function()
          return LazyVim.root.get({ normalize = true }) ~= LazyVim.root.cwd()
        end,
        color = { fg = colors.blue },
      },
      -- {
      --   "diagnostics",
      --   symbols = {
      --     error = icons.diagnostics.Error,
      --     warn = icons.diagnostics.Warn,
      --     info = icons.diagnostics.Info,
      --     hint = icons.diagnostics.Hint,
      --   },
      -- },
      {
        "filetype",
        icon_only = true,
        separator = "",
        padding = { left = 0, right = 0 },
      },
      {
        function(self)
          local filepath = vim.fn.expand("%:~:.")
          local parts = vim.split(filepath, "/")
          local filename
          if #parts <= 3 then
            filename = filepath
          else
            filename = table.concat({ "…", parts[#parts - 2], parts[#parts - 1], parts[#parts] }, "/")
          end
          if filename == "" then
            return ""
          end
          if vim.bo.modified then
            return LazyVim.lualine.format(self, filename .. "", "MatchParen")
          end
          return LazyVim.lualine.format(self, filename, "Bold")
        end,
        padding = { left = 0, right = 1 },
      },
    }

    opts.sections.lualine_x = {
      Snacks.profiler.status(),
      {
        function()
          return require("noice").api.status.command.get()
        end,
        cond = function()
          return package.loaded["noice"]
            and require("noice").api.status.command.has()
        end,
        color = function()
          return { fg = Snacks.util.color("Statement") }
        end,
      },
      {
        function()
          return require("noice").api.status.mode.get()
        end,
        cond = function()
          return package.loaded["noice"]
            and require("noice").api.status.mode.has()
        end,
        color = function()
          return { fg = Snacks.util.color("Constant") }
        end,
      },
      {
        function()
          return "  " .. require("dap").status()
        end,
        cond = function()
          return package.loaded["dap"] and require("dap").status() ~= ""
        end,
        color = function()
          return { fg = Snacks.util.color("Debug") }
        end,
      },
      {
        require("lazy.status").updates,
        cond = require("lazy.status").has_updates,
        color = function()
          return { fg = Snacks.util.color("Special") }
        end,
      },
      {
        "diff",
        symbols = {
          added = icons.git.added,
          modified = icons.git.modified,
          removed = icons.git.removed,
        },
        source = function()
          local gitsigns = vim.b.gitsigns_status_dict
          if gitsigns then
            return {
              added = gitsigns.added,
              modified = gitsigns.changed,
              removed = gitsigns.removed,
            }
          end
        end,
      },
    }

    opts.sections.lualine_y = {
      {
        "progress",
        separator = " ",
        padding = { left = 1, right = 1 },
        color = function()
          return { bg = colors.surface1, fg = mode_color() }
        end,
      },
    }

    opts.sections.lualine_z = {
      {
        "location",
        separator = " ",
        padding = { left = 1, right = 1 },
        color = function()
          return { bg = mode_color(), fg = colors.base, gui = "bold" }
        end,
      },
    }

    return opts
  end,
}
