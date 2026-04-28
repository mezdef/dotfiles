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
    code = {
      style = 'full',
      highlight = 'RenderMarkdownCode',
    },
  },
}
