return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "lua", "python", "bash", "fish", "json", "jsonc", "yaml", "toml",
          "markdown", "markdown_inline", "vim", "vimdoc", "c", "html", "css",
          "javascript", "diff", "gitcommit",
        },
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },
}
