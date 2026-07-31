return {
  {
    "catgoose/nvim-colorizer.lua",
    event = "BufReadPre",
    opts = {
      filetypes = {
        "*",
      },
      user_default_options = {
        RGB = true,
        RRGGBB = true,
        RRGGBBAA = true,
        AARRGGBB = true,
        names = false,
        rgb_fn = true,
        hsl_fn = true,
        css = true,
        css_fn = true,

        -- Shows the actual color behind the hex code
        mode = "background",
      },
    },
  },
}
