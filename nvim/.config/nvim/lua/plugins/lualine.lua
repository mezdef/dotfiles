return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    local colors = require("catppuccin.palettes").get_palette("mocha")
    local icons = LazyVim.config.icons

    local mode_colors = {
      n = colors.green,
      i = colors.text,
      v = colors.mauve,
      V = colors.mauve,
      ["\22"] = colors.mauve, -- ctrl-v block visual
      c = colors.red,
      R = colors.red,
    }

    local function mode_color()
      return mode_colors[vim.fn.mode()] or colors.green
    end

    opts.options = opts.options or {}
    opts.options.section_separators = { left = "", right = "" }
    opts.options.component_separators = { left = "", right = "" }

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
        function()
          local branch = vim.b.gitsigns_head or ""
          if branch ~= "" then
            return " " .. branch
          end
          local gs = vim.b.gitsigns_status_dict
          if gs then
            local parts = {}
            if (gs.added or 0) > 0 then table.insert(parts, icons.git.added .. gs.added) end
            if (gs.changed or 0) > 0 then table.insert(parts, icons.git.modified .. gs.changed) end
            if (gs.removed or 0) > 0 then table.insert(parts, icons.git.removed .. gs.removed) end
            if #parts > 0 then
              return table.concat(parts, " ")
            end
          end
          return ""
        end,
        color = function()
          return { bg = colors.surface1, fg = mode_color() }
        end,
      },
      {
        function()
          local filename = vim.fn.expand("%:t")
          if filename == "" then
            return "[No Name]"
          end
          if vim.bo.modified then
            return filename .. " ●"
          end
          return filename
        end,
        color = function()
          if vim.bo.modified then
            return { fg = colors.yellow }
          end
          return { fg = colors.subtext0 }
        end,
        padding = { left = 1, right = 1 },
      },
    }

    opts.sections.lualine_c = {}

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
        function()
          local buf = vim.api.nvim_get_current_buf()
          local ft = vim.bo[buf].filetype
          if ft == "" then
            return "? none"
          end
          local has_lsp = #vim.lsp.get_clients({ bufnr = buf }) > 0
          if has_lsp then
            local icon = require("mini.icons").get("filetype", ft)
            return icon .. " " .. ft
          end
          return "? " .. ft
        end,
        color = { fg = colors.subtext0 },
        padding = { left = 1, right = 1 },
      },
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
