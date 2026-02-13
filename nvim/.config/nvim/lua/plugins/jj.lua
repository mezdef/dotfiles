return {
  "nicolasgb/jj.nvim",
  dependencies = {
    "folke/snacks.nvim", -- Optional, only needed if you use pickers

    -- One of these two if you want to use them as your diff backend
    "esmuellert/codediff.nvim",
    "sindrets/diffview.nvim",
  },

  config = function()
    local jj = require("jj")
    jj.setup({
      terminal = {
        cursor_render_delay = 10, -- Adjust if cursor position isn't restoring correctly
      },
      diff = {
        backend = "codediff",
      },
      cmd = {
        describe = {
          editor = {
            type = "buffer",
            keymaps = {
              close = { "q", "<Esc>", "<C-c>" }, -- Enable <Esc> in the editor
            },
          },
        },
        bookmark = {
          prefix = "feat/",
        },
        keymaps = {
          log = {
            checkout = "<CR>",
            describe = "d",
            diff = "<S-d>",
            abandon = "<S-a>",
            fetch = "<S-f>",
          },
          status = {
            open_file = "<CR>",
            restore_file = "<S-x>",
          },
          close = { "q", "<Esc>" },
        },
      },
      highlights = {
        -- Customize colors if desired
        modified = { fg = "#89ddff" },
      },
    })

    -- Core commands
    local cmd = require("jj.cmd")
    vim.keymap.set("n", "<leader>jd", cmd.describe, { desc = "JJ describe" })
    vim.keymap.set("n", "<leader>jl", cmd.log, { desc = "JJ log" })
    vim.keymap.set("n", "<leader>jj", cmd.log, { desc = "JJ log" })
    vim.keymap.set("n", "<leader>je", cmd.edit, { desc = "JJ edit" })
    vim.keymap.set("n", "<leader>jn", cmd.new, { desc = "JJ new" })
    vim.keymap.set("n", "<leader>js", cmd.status, { desc = "JJ status" })
    vim.keymap.set("n", "<leader>sj", cmd.squash, { desc = "JJ squash" })
    vim.keymap.set("n", "<leader>ju", cmd.undo, { desc = "JJ undo" })
    vim.keymap.set("n", "<leader>jy", cmd.redo, { desc = "JJ redo" })
    vim.keymap.set("n", "<leader>jr", cmd.rebase, { desc = "JJ rebase" })
    vim.keymap.set(
      "n",
      "<leader>jbc",
      cmd.bookmark_create,
      { desc = "JJ bookmark create" }
    )
    vim.keymap.set(
      "n",
      "<leader>jbd",
      cmd.bookmark_delete,
      { desc = "JJ bookmark delete" }
    )
    vim.keymap.set(
      "n",
      "<leader>jbm",
      cmd.bookmark_move,
      { desc = "JJ bookmark move" }
    )
    vim.keymap.set("n", "<leader>ja", cmd.abandon, { desc = "JJ abandon" })
    vim.keymap.set("n", "<leader>jf", cmd.fetch, { desc = "JJ fetch" })
    vim.keymap.set("n", "<leader>jp", cmd.push, { desc = "JJ push" })
    vim.keymap.set(
      "n",
      "<leader>jpr",
      cmd.open_pr,
      { desc = "JJ open PR from bookmark in current revision or parent" }
    )
    vim.keymap.set("n", "<leader>jpl", function()
      cmd.open_pr({ list_bookmarks = true })
    end, { desc = "JJ open PR listing available bookmarks" })

    -- Diff commands
    local diff = require("jj.diff")
    vim.keymap.set("n", "<leader>df", function()
      diff.open_vdiff()
    end, { desc = "JJ diff current buffer" })
    vim.keymap.set("n", "<leader>dF", function()
      diff.open_hsplit()
    end, { desc = "JJ hdiff current buffer" })

    -- Pickers
    local picker = require("jj.picker")
    vim.keymap.set("n", "<leader>gj", function()
      picker.status()
    end, { desc = "JJ Picker status" })
    vim.keymap.set("n", "<leader>jgh", function()
      picker.file_history()
    end, { desc = "JJ Picker history" })

    -- Some functions like `log` can take parameters
    vim.keymap.set("n", "<leader>jL", function()
      cmd.log({
        revisions = "'all()'", -- equivalent to jj log -r ::
      })
    end, { desc = "JJ log all" })

    -- This is an alias i use for moving bookmarks its so good
    vim.keymap.set("n", "<leader>jt", function()
      cmd.j("tug")
      cmd.log({})
    end, { desc = "JJ tug" })
  end,
}
