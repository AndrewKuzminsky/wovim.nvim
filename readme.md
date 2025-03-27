## How to Install
- Simply add the following to your /plugins/ directory as `wovim.lua` and let *LazyVim* handle the rest.
```
return {
  "AndrewKuzminsky/wovim.nvim",
  config = function()
    require("wovim")
  end,
}
```
```
