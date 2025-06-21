local M = {}
local session_setup_called = false

M.config = {
  api_paths = {},
}

function M.setup(user_config)
  M.config = vim.tbl_deep_extend("force", M.config, user_config or {})

  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "html", "wod" },
    callback = function()
      local filename = vim.fn.expand("%:p")

      -- Get the parent directory of the file
      local parent_dir = vim.fn.fnamemodify(filename, ":p:h")
      -- Check if the parent directory ends with ".wo"
      if parent_dir:match(".+/.+%.wo$") then
        -- Automatically require the "wovim" module
        if not session_setup_called then
          session_setup_called = true
          require("wovim_core").setup(M.config)
          vim.api.nvim_command("OpenWO") -- open accompanying .wod file in vsplit
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = "*.wod",
    callback = function()
      vim.bo.filetype = "wod" -- Set filetype to 'wod'
    end,
  })
end

return M
