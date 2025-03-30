vim.api.nvim_create_autocmd("FileType", {
  pattern = { "html", "wod" },

  callback = function()
    local filename = vim.fn.expand("%:p")

    -- Get the parent directory of the file
    local parent_dir = vim.fn.fnamemodify(filename, ":p:h")
    -- Check if the parent directory ends with ".wo"
    if parent_dir:match(".+/.+%.wo$") then
      -- Automatically require the "wovim" module
      require("wovim_core").setup()
      vim.api.nvim_command("OpenWO") -- open accompanying .wod file in vsplit
    end
  end,
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*.wod",
  callback = function()
    vim.bo.filetype = "wod" -- Set filetype to 'wod'
  end,
})
