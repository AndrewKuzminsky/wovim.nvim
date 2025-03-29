local M = {}

local function create_floating_window(config)
  -- create a buffer
  local buf = vim.api.nvim_create_buf(false, true) -- no file, scratch buffer
  local win = vim.api.nvim_open_win(buf, true, config)

  return { buf = buf, win = win }
end

local create_window_configurations = function(window_scale)
  local centered_width = math.floor(vim.o.columns * window_scale)
  local centered_height = math.floor(vim.o.lines * window_scale)

  local centered_col = math.floor((vim.o.columns - centered_width) / 2)
  local centered_row = math.floor((vim.o.lines - centered_height) / 2)

  return {
    popup_window = {
      relative = "editor",
      width = centered_width,
      height = centered_height,
      style = "minimal",
      col = centered_col,
      row = centered_row,
      zindex = 1,
    },
    header = {
      relative = "editor",
      width = centered_width,
      height = 1,
      style = "minimal",
      col = centered_col,
      row = 13,
      zindex = 2,
    },
  }
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "wod",
  callback = function()
    require("syntax.wod").setup() -- Load syntax rules for .wod files
  end,
  group = vim.api.nvim_create_augroup("WODSyntax", { clear = true }),
})

function M.open_wo()
  local filename = vim.fn.expand("%:p")
  if filename:match("%.html$") then
    local wod_filename = filename:sub(1, -6) .. ".wod"

    if vim.fn.filereadable(wod_filename) == 1 then
      local current_window = vim.api.nvim_get_current_win()

      vim.g.wovim_original_file = filename -- <-- Save for later

      vim.cmd("vsplit | e " .. wod_filename)
      vim.bo.filetype = "wod"
      vim.api.nvim_set_current_win(current_window)
    else
      print("[WOVIM] No .wod found!") -- no accompanying .wod file for .html file
    end
  end
end

vim.api.nvim_create_user_command("OpenWO", M.open_wo, {})

-- TODO: Implement Telescope search functionality.
function M.open_wod()
  local function parse_wod_components(wod_filename)
    local lines = vim.fn.readfile(wod_filename)
    local components = {}
    local max_name_len = 0
    local max_type_len = 0

    for _, line in ipairs(lines) do
      local name, wotype = line:match("^([%w_]+):%s*(%w+)%s*{")
      if name and wotype then
        table.insert(components, {
          name = name,
          type = wotype,
          display = name .. ": " .. wotype,
        })
        max_name_len = math.max(max_name_len, #name)
        max_type_len = math.max(max_type_len, #wotype)
      end
    end

    -- Format components into aligned columns
    local formatted = {}
    for _, comp in ipairs(components) do
      local padded_name = comp.name .. string.rep(" ", max_name_len - #comp.name)
      local padded_type = comp.type .. string.rep(" ", max_type_len - #comp.type)
      table.insert(formatted, padded_name .. " : " .. padded_type)
    end

    return {
      raw = components,
      formatted = formatted,
      max_name_len = max_name_len,
      max_type_len = max_type_len,
    }
  end

  local filename = vim.g.wovim_original_file or vim.fn.expand("%:p")
  local wod_filename = filename:gsub("%.html$", ".wod")

  if vim.fn.filereadable(wod_filename) ~= 1 then
    vim.notify(".wod file doesn't exist: " .. wod_filename, vim.log.levels.WARN)
    return
  end

  -- Parse components
  local components = parse_wod_components(wod_filename)

  -- Create floating window
  local window_scale = 0.4
  local window_config = create_window_configurations(window_scale)
  local header_window = create_floating_window(window_config.header)
  local wod_window = create_floating_window(window_config.popup_window)

  -- Set window content
  local title = "WOVIM - WOD Manager"
  local padding = string.rep(" ", (window_config.popup_window.width - #title) / 2)
  vim.api.nvim_buf_set_lines(header_window.buf, 0, -1, false, { padding .. title })
  vim.api.nvim_buf_set_lines(wod_window.buf, 0, -1, false, components.formatted)

  -- Close on 'q'
  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(wod_window.win, true)
    vim.api.nvim_win_close(header_window.win, true)
  end, { buffer = wod_window.buf })

  -- Refresh on <leader>r
  vim.keymap.set("n", "<leader>r", function()
    local new_components = parse_wod_components(wod_filename)
    vim.api.nvim_buf_set_lines(wod_window.buf, 0, -1, false, new_components.formatted)
  end, { buffer = wod_window.buf })
end

vim.api.nvim_create_user_command("OpenWOD", M.open_wod, {})

return M
