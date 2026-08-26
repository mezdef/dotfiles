-- `n`/`N` repeat the last motion used: f, F, t, T, /, ?, *, # and the bracket
-- motions registered below.

-- Cached per id: gitsigns' on_attach runs per buffer, and an uncached create()
-- would leak a repeatable for every file opened.
local cache = {}

--- Register a next/prev pair with better-n and bind `]key` / `[key` to it.
--- Action fns receive v:count1 and must not return a value; better-n calls
--- `:match` on whatever comes back.
local function pair(id, key, next_fn, prev_fn, map_opts)
  local r = cache[id]
  if not r then
    r = require("better-n").create({ id = id, next = next_fn, prev = prev_fn })
    cache[id] = r
  end
  local function set(lhs, rhs, desc)
    vim.keymap.set(
      "n",
      lhs,
      rhs,
      vim.tbl_extend("force", map_opts or {}, {
        remap = true,
        silent = true,
        desc = desc,
      })
    )
  end
  set("]" .. key, r.next_key, "Next " .. id)
  set("[" .. key, r.prev_key, "Prev " .. id)
end

-- Mirrors LazyVim's diagnostic_goto (lazyvim/config/keymaps.lua).
local function diagnostic(next, severity)
  return function(count)
    vim.diagnostic.jump({
      count = (next and 1 or -1) * (count or 1),
      severity = severity and vim.diagnostic.severity[severity] or nil,
      float = true,
    })
  end
end

local function quickfix(next)
  return function(count)
    pcall(next and vim.cmd.cnext or vim.cmd.cprev, { count = count or 1 })
  end
end

-- Mirrors LazyVim's gitsigns maps, including the diff-mode fallback.
local function hunk(dir)
  return function(count)
    if vim.wo.diff then
      vim.cmd.normal({ dir == "next" and "]c" or "[c", bang = true })
    else
      require("gitsigns").nav_hunk(dir, { count = count or 1 })
    end
  end
end

return {
  {
    "jonatan-branting/nvim-better-n",
    event = "VeryLazy",
    opts = {},
    config = function(_, opts)
      local better_n = require("better-n")
      better_n.setup(opts)

      -- LazyVim maps n/N and the bracket motions on VeryLazy too and takes
      -- precedence; re-assert ours once VeryLazy has drained.
      vim.schedule(function()
        local o = { silent = true, expr = true, nowait = true }
        vim.keymap.set({ "n", "x", "o" }, "n", better_n.next, o)
        vim.keymap.set({ "n", "x", "o" }, "N", better_n.previous, o)

        pair("Diagnostic", "d", diagnostic(true), diagnostic(false))
        local err, warn = "ERROR", "WARN"
        pair("Error", "e", diagnostic(true, err), diagnostic(false, err))
        pair("Warning", "w", diagnostic(true, warn), diagnostic(false, warn))
        pair("Quickfix", "q", quickfix(true), quickfix(false))
      end)
    end,
  },

  -- flash char mode maps f/F/t/T and lazy-loads on `s`, clobbering better-n
  -- mid-session. Jump (s/S/r/R) is unaffected.
  {
    "folke/flash.nvim",
    opts = { modes = { char = { enabled = false } } },
  },

  -- LazyVim maps ]h/[h buffer-locally in on_attach, shadowing any global map.
  -- Wrap on_attach and rebind them to the better-n repeatable.
  {
    "lewis6991/gitsigns.nvim",
    opts = function(_, opts)
      local parent = opts.on_attach
      opts.on_attach = function(bufnr)
        if parent then
          parent(bufnr)
        end
        pair("Hunk", "h", hunk("next"), hunk("prev"), { buffer = bufnr })
      end
    end,
  },
}
