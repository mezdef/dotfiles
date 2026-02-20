return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewClose" },
  config = function()
    require("diffview").setup({
      enhanced_diff_hl = true,
      view = {
        default = {
          winbar_info = true,
          disable_diagnostics = true,
        },
        file_history = {
          disable_diagnostics = true,
        },
      },
      hooks = {
        diff_buf_read = function(bufnr)
          vim.treesitter.stop(bufnr)
          vim.bo[bufnr].syntax = ""
        end,
        diff_buf_win_enter = function(bufnr, winid, ctx)
          -- In the old/base pane (symbol "a"), lines marked DiffAdd are actually
          -- deleted lines (present in old, not in new) → remap to DiffviewDelete (red)
          local diff_add = ctx.symbol == "a" and "DiffviewDelete" or "DiffviewAdd"
          vim.wo[winid].winhighlight = table.concat({
            "Normal:DiffviewNormal",
            "DiffAdd:" .. diff_add,
            "DiffDelete:DiffviewDelete",
            "DiffChange:DiffviewChange",
            "DiffText:DiffviewText",
          }, ",")
        end,
        view_closed = function()
          require("gitsigns").change_base(nil, true)
        end,
      },
    })

    vim.opt.fillchars:append("diff: ")

    local function toggle_diffview(open_cmd, gs_base)
      if next(require("diffview.lib").views) == nil then
        vim.cmd(open_cmd)
        require("gitsigns").change_base(gs_base, true)
      else
        vim.cmd("DiffviewClose")
        require("gitsigns").change_base(nil, true)
      end
    end

    local function get_default_branch_jj()
      vim.fn.system({ "jj", "log", "-r", "main@origin", "--no-graph", "--template", " ", "--limit", "1" })
      if vim.v.shell_error == 0 then
        return "origin/main"
      end
      return "origin/master"
    end

    vim.keymap.set("n", "<leader>gdd", function()
      toggle_diffview("DiffviewOpen", nil)
    end, { desc = "Toggle Diffview" })

    vim.keymap.set("n", "<leader>gq", "<cmd>DiffviewClose<cr>", { desc = "Diffview Close" })

    vim.keymap.set("n", "<leader>gdm", function()
      local branch = get_default_branch_jj()
      toggle_diffview("DiffviewOpen " .. branch, branch)
    end, { desc = "Toggle Diff against master/main (jj)" })
  end,
}
