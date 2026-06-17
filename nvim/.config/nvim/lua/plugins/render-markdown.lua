return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.nvim" },
  ft = "markdown",
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {
    anti_conceal = { enabled = true },
    bullet = {
      icons = { '•', '‣', '▪', '⬠' },
    },
    heading = {
      icons = { '# ', '## ', '### ', '#### ', '##### ', '###### ' },
      setext = false,
      backgrounds = {},
    },
    checkbox = {
      checked = {
        scope_highlight = 'RenderMarkdownCheckedLine',
      },
    },
    code = {
      style = 'full',
      highlight = 'RenderMarkdownCode',
    },
    on = {
      render = function(ctx)
        local ns = vim.api.nvim_create_namespace('rm_checked_children')
        vim.api.nvim_buf_clear_namespace(ctx.buf, ns, 0, -1)

        local ok, parser = pcall(vim.treesitter.get_parser, ctx.buf, 'markdown')
        if not ok then return end
        local trees = parser:parse()
        if not trees or not trees[1] then return end

        local function is_checked(node)
          if node:type() ~= 'list_item' then return false end
          for child in node:iter_children() do
            if child:type() == 'task_list_marker_checked' then return true end
          end
          return false
        end

        local function dim_descendants(node)
          for child in node:iter_children() do
            if child:type() == 'list_item' then
              local sr, sc, er, ec = child:range()
              vim.api.nvim_buf_set_extmark(ctx.buf, ns, sr, sc, {
                end_row = er,
                end_col = ec,
                hl_group = 'RenderMarkdownCheckedLine',
                priority = 150,
              })
            end
            dim_descendants(child)
          end
        end

        local function walk(node)
          if is_checked(node) then
            dim_descendants(node)
            return
          end
          for child in node:iter_children() do
            walk(child)
          end
        end

        walk(trees[1]:root())
      end,
    },
  },
}
