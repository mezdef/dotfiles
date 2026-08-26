-- Live markdown + mermaid browser preview via ~/.claude/scripts/md-preview.mjs
-- Replaces iamcco/markdown-preview.nvim (disabled in lua/plugins/markdown-preview.lua).
-- Renders mermaid inline, live-reloads on save, and sends no-store so the browser never
-- shows a stale render.

local script = vim.fn.expand("~/.claude/scripts/md-preview.mjs")
local port = 8347
local job = nil -- one active preview at a time

local function bun()
  local b = vim.fn.exepath("bun")
  return b ~= "" and b or "bun"
end

local function stop()
  if job then
    vim.fn.jobstop(job)
    job = nil
    vim.notify("md-preview stopped", vim.log.levels.INFO)
  end
end

local function open()
  local file = vim.fn.expand("%:p")
  if file == "" then
    vim.notify("md-preview: current buffer has no file", vim.log.levels.WARN)
    return
  end
  stop()
  job = vim.fn.jobstart({ bun(), script, file, tostring(port) }, {
    on_exit = function()
      job = nil
    end,
  })
  if job <= 0 then
    job = nil
    vim.notify("md-preview: failed to start (is `bun` on PATH?)", vim.log.levels.ERROR)
    return
  end
  vim.notify("md-preview → http://localhost:" .. port, vim.log.levels.INFO)
end

local function toggle()
  if job then
    stop()
  else
    open()
  end
end

vim.api.nvim_create_user_command("MdPreview", open, { desc = "Live markdown+mermaid browser preview" })
vim.api.nvim_create_user_command("MdPreviewStop", stop, { desc = "Stop the markdown preview" })
vim.api.nvim_create_user_command("MdPreviewToggle", toggle, { desc = "Toggle the markdown preview" })

-- <leader>mp on markdown buffers (matches the old plugin's binding)
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "md", "mdx" },
  callback = function(ev)
    vim.keymap.set(
      "n",
      "<leader>mp",
      toggle,
      { buffer = ev.buf, desc = "Markdown Preview Toggle" }
    )
  end,
})

-- Stop the server when nvim exits so it doesn't linger.
vim.api.nvim_create_autocmd("VimLeavePre", { callback = stop })
