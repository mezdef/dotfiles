-- `n`/`N` repeat the last motion used: f, F, t, T, /, ?, *, #
return {
  {
    "jonatan-branting/nvim-better-n",
    event = "VeryLazy",
    opts = {},
    config = function(_, opts)
      local better_n = require("better-n")
      better_n.setup(opts)

      -- LazyVim also maps n/N on VeryLazy and takes precedence; re-assert ours
      -- once VeryLazy has drained.
      vim.schedule(function()
        local o = { silent = true, expr = true, nowait = true }
        vim.keymap.set({ "n", "x", "o" }, "n", better_n.next, o)
        vim.keymap.set({ "n", "x", "o" }, "N", better_n.previous, o)
      end)
    end,
  },

  -- flash char mode maps f/F/t/T and lazy-loads on `s`, clobbering better-n
  -- mid-session. Jump (s/S/r/R) is unaffected.
  {
    "folke/flash.nvim",
    opts = { modes = { char = { enabled = false } } },
  },
}
