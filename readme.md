## Requirements
- Neovim
- lazy.nvim

## How to Install (via lazy.nvim)
**I highly suggest using the [LazyVim](https://www.lazyvim.org/installation) neovim distro since it comes prepackaged with lazy.nvim and a bunch of useful nvim plugins.**
- Simply add the following to your /plugins/ directory as `wovim.lua` and let *LazyVim* handle the rest.

```
return {
  "AndrewKuzminsky/wovim.nvim",
  config = function()
    require("wovim")
  end,
}
