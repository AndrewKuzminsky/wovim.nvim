## Requirements
- [neovim](https://neovim.io/)
- [lazy.nvim](https://github.com/folke/lazy.nvim)

## How to Install (via lazy.nvim)
**I highly suggest using [LazyVim](https://www.lazyvim.org/installation) as it comes with lazy.nvim and a bunch of useful nvim plugins.**

Simply add the following to your /plugins/ directory as `wovim.lua` and let **lazy.nvim** handle the rest.
```
return {
  "AndrewKuzminsky/wovim.nvim",
  config = function()
    require("wovim")
  end,
}
