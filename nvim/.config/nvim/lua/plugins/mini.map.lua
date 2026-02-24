return {
  "nvim-mini/mini.nvim",
  version = false, -- Use the latest 'main' branch
  config = function()
    -- Initialize mini.map
    require("mini.map").setup()

    -- Optional: Set keymaps to toggle it (e.g., <leader>mm)
    local map = require("mini.map")
    map.setup({
      integrations = {
        map.gen_integration.builtin_search(),
        map.gen_integration.diff(),
        map.gen_integration.diagnostic(),
      },
      symbols = { encode = map.gen_encode_symbols.dot("4x2") },
      window = { side = "right", width = 10, winblend = 100 }, -- Customize side/width
    })

    vim.keymap.set(
      "n",
      "<leader>mm",
      "<cmd>lua MiniMap.toggle()<CR>",
      { desc = "Toggle Minimap" }
    )
  end,
}
