## Requirements
- [neovim](https://neovim.io/)
- [lazy.nvim](https://github.com/folke/lazy.nvim)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

## How to Install (via lazy.nvim)
**I highly suggest using [LazyVim](https://www.lazyvim.org/installation) as it comes with lazy.nvim and a bunch of useful nvim plugins.**

Simply add the following to your /plugins/ directory as `wovim.lua` and let **lazy.nvim** handle the rest.
```lua
return {
  "AndrewKuzminsky/wovim.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    require("wovim")
  end,
}
