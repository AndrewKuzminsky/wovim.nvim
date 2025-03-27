local M = {}

vim.api.nvim_create_autocmd("FileType", {
  pattern = "wod",
  callback = function()
    require("syntax.wod") -- Load syntax rules
  end,
  group = vim.api.nvim_create_augroup("WODSyntax", { clear = true }),
})

function M.open_wo()
  local filename = vim.fn.expand("%:p")

  if filename:match("%.html$") then
    local wod_filename = filename:sub(1, -6) .. ".wod"

    if vim.fn.filereadable(wod_filename) == 1 then
      local current_window = vim.api.nvim_get_current_win()
      vim.cmd("vsplit | e " .. wod_filename)
      vim.bo.filetype = "wod"
      vim.api.nvim_set_current_win(current_window)
    else
      print("[WOVIM] No .wod found!")
    end
  end
end

vim.api.nvim_create_user_command("OpenWO", M.open_wo, {})

return M
