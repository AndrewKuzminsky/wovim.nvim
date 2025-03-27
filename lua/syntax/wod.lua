local M = {}

function M.setup()
  if vim.b.current_syntax then
    print("[WOVIM - Syntax] Unnecessary call to syntax setup.")
    return
  end

  -- Component Bindings & Names
  vim.api.nvim_command("syntax keyword wodKeywords condition action item list value")
  vim.api.nvim_command('syntax match wodProperty "\\v\\w+\\ze\\s*\\=" contains=wodKeywords')

  -- Component Type
  vim.api.nvim_command('syntax match wodTypes "\\v<(WO|ERXWO|Ajax)\\w+"')
  -- FIXME: not functional
  vim.api.nvim_command('syntax match wodDefinition "\\v:\\s*\\zs\\w+\\ze\\s*\\{" contains=wodTypes')

  vim.api.nvim_command('syntax match wodComponent "^\\w+\\d*:"')
  vim.api.nvim_command('syntax match wodComponent "\\v^\\w+\\d*:" contains=wodType')

  -- Structure
  vim.api.nvim_command('syntax match wodBraces "[{}]"')
  vim.api.nvim_command('syntax match wodSemicolon ";"')

  -- Highlighting
  vim.api.nvim_command("highlight link wodKeywords Keyword")
  vim.api.nvim_command("highlight link wodProperty Operator")

  vim.api.nvim_command("highlight link wodComponent Identifier")
  vim.api.nvim_command("highlight link wodType Type")
  vim.api.nvim_command("highlight link wodTypes Type")
  vim.api.nvim_command("highlight link wodDefinition Type")

  vim.api.nvim_command("highlight link wodBraces Delimiter")
  vim.api.nvim_command("highlight link wodSemicolon Delimiter")

  vim.b.current_syntax = "wod"
end

return M
