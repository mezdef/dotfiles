-- Extend snacks to capture the picker search query whenever results are sent to
-- the quickfix list. Stored in vim.g._qf_search_pattern for use by <leader>sr.
return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      actions = {
        qflist = function(picker)
          vim.g._qf_search_pattern = picker.input.filter.search or ""
          require("snacks.picker.actions").qflist(picker)
        end,
        qflist_all = function(picker)
          vim.g._qf_search_pattern = picker.input.filter.search or ""
          require("snacks.picker.actions").qflist_all(picker)
        end,
      },
    },
  },
}
