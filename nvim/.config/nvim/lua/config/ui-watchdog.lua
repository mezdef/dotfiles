-- Diagnostic for the intermittent blank status line / file tree in a herdr or tmux split.
-- Records nvim's own geometry next to herdr's pane rect, because nvim 0.12 enables DEC mode
-- 2048 (in-band resize) and then discards SIGWINCH (tui.c sigwinch_cb), so a dropped resize
-- report leaves nvim permanently wrong about its size with no fallback. A `lines` that is too
-- large draws the global statusline (laststatus=3) below the visible area, which reads as blank.
-- Remove this file and its require in init.lua once the cause is settled.

local M = {}

local LOG = vim.fn.stdpath("cache") .. "/ui-watchdog.log"

local function pane_id()
  return vim.env.HERDR_PANE_ID or vim.env.TMUX_PANE or ""
end

-- nvim's view of itself, plus whether the two UI elements actually configured
local function snapshot(tag)
  local sl = vim.o.statusline or ""
  local tree_win
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local ft = vim.bo[vim.api.nvim_win_get_buf(w)].filetype
    if ft == "neo-tree" or ft == "minifiles" then
      tree_win = string.format("%dx%d", vim.api.nvim_win_get_width(w), vim.api.nvim_win_get_height(w))
    end
  end

  local errors = 0
  local ok, cfg = pcall(require, "lazy.core.config")
  if ok then
    for _, p in pairs(cfg.plugins) do
      if p._ and p._.error then errors = errors + 1 end
    end
  end

  return {
    tag = tag,
    time = os.date("%Y-%m-%dT%H:%M:%S"),
    pid = vim.fn.getpid(),
    pane = pane_id(),
    cols = vim.o.columns,
    lines = vim.o.lines,
    laststatus = vim.o.laststatus,
    -- empty means lualine never installed its statusline
    lualine = sl:find("lualine", 1, true) ~= nil,
    tree = tree_win or "none",
    colorscheme = vim.g.colors_name or "none",
    plugin_errors = errors,
  }
end

local function write(s, truth)
  local line = string.format(
    "%s %-10s pid=%-7d pane=%-10s nvim=%dx%d laststatus=%d lualine=%s tree=%s colors=%s plugin_errors=%d%s",
    s.time, s.tag, s.pid, s.pane == "" and "-" or s.pane, s.cols, s.lines,
    s.laststatus, tostring(s.lualine), s.tree, s.colorscheme, s.plugin_errors, truth or ""
  )
  vim.fn.writefile({ line }, LOG, "a")
  return line
end

-- Ground truth comes from herdr rather than the pty: nvim 0.12 runs a server plus a separate TUI
-- client, getpid() is the server, and the server has no controlling terminal, so a child process
-- cannot read the pane's winsize via /dev/tty. herdr gives each pane a 1-cell border on all four
-- sides once a tab holds more than one pane, and none when it holds exactly one. pane_count is
-- logged so that rule stays checkable against the raw rect.
local function with_truth(s, done)
  if vim.env.HERDR_PANE_ID == nil then
    return done("")
  end
  vim.system(
    { "herdr", "pane", "layout", "--pane", vim.env.HERDR_PANE_ID },
    { text = true },
    vim.schedule_wrap(function(res)
      if res.code ~= 0 then
        return done("  herdr=unreachable")
      end
      local okj, data = pcall(vim.json.decode, res.stdout)
      if not okj then
        return done("  herdr=unparsed")
      end
      local panes = vim.tbl_get(data, "result", "layout", "panes") or {}
      local border = #panes > 1 and 2 or 0
      for _, p in ipairs(panes) do
        if p.pane_id == vim.env.HERDR_PANE_ID then
          local w, h = p.rect.width - border, p.rect.height - border
          local verdict = (w == s.cols and h == s.lines) and "OK" or "MISMATCH"
          return done(string.format(
            "  rect=%dx%d panes=%d expected=%dx%d %s",
            p.rect.width, p.rect.height, #panes, w, h, verdict))
        end
      end
      done("  herdr=pane-not-found")
    end)
  )
end

local function record(tag, echo)
  local s = snapshot(tag)
  with_truth(s, function(truth)
    local line = write(s, truth)
    if echo then
      vim.notify(line, truth:find("MISMATCH") and vim.log.levels.WARN or vim.log.levels.INFO)
    end
  end)
end

function M.setup()
  vim.defer_fn(function() record("startup") end, 2500)
  vim.api.nvim_create_autocmd("VimResized", {
    callback = function() vim.defer_fn(function() record("resized") end, 250) end,
  })
  -- Run this the moment the UI looks wrong; it is the only snapshot taken at the failure.
  vim.api.nvim_create_user_command("UiWatchdog", function() record("manual", true) end, {})
end

return M
