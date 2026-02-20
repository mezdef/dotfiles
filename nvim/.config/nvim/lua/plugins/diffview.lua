return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewClose" },
  config = function()
    require("diffview").setup({
      hooks = {
        view_closed = function()
          require("gitsigns").change_base(nil, true)
        end,
      },
    })

    vim.api.nvim_set_hl(0, "DiffAdd", { bg = "#20303b" })
    vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#37222c" })
    vim.api.nvim_set_hl(0, "DiffChange", { bg = "#1f2231" })
    vim.api.nvim_set_hl(0, "DiffText", { bg = "#394b70" })
    vim.opt.fillchars = vim.opt.fillchars + ""

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
