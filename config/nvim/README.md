# nvim

Neovim config (lazy.nvim). Two plugins + theme-engine integration:

- **nvim-treesitter** (`lua/plugins/treesitter.lua`) — real syntax highlighting.
  Parsers auto-install on first file open; `:TSUpdate` to refresh.
- **nvim-colorizer** (`lua/plugins/colorizer.lua`) — shows swatches behind hex
  colors (handy when editing themes).
- **generated_theme** — `init.lua` ends with
  `pcall(function() require("generated_theme") end)`. That file is written by the
  [`themes`](../../themes) engine (`~/.config/nvim/lua/generated_theme.lua`)
  from the active theme's palette, so nvim matches your desktop across **all 28
  themes** — no per-theme colorscheme plugins needed. Switching with
  `theme <name>` live-reloads any running nvim.

## Install
Copy to `~/.config/nvim/`. First launch installs lazy + plugins. Then run
`theme <name>` once so `generated_theme.lua` exists. Needs a C compiler
(`gcc`) for treesitter parsers.
