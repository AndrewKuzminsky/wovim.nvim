local wod_parser = require("wodparser")
-- TELESCOPE
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local telescope_config = require("telescope.config").values

local M = {}

function M.setup()
  -- Keybindings
  vim.keymap.set("n", "<leader>bw", M.open_wod, {
    noremap = true,
    silent = true,
    desc = "Open WOD Browser",
  })
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

function M.open_wod(opts)
  opts = opts or {}

  local filename = vim.g.wovim_original_file or vim.fn.expand("%:p")
  local wod_filename = filename:gsub("%.html$", ".wod")

  if vim.fn.filereadable(wod_filename) ~= 1 then
    vim.notify(".wod file doesn't exist: " .. wod_filename, vim.log.levels.WARN)
    return
  end

  -- Parse components
  local components = wod_parser.parse(wod_filename)

  -- Telescope Picker
  pickers
    .new(opts, {
      prompt_title = "WOD Browser(" .. #components.raw .. ")",
      finder = finders.new_table({
        results = components.raw,
        entry_maker = function(entry)
          return {
            value = entry,
            display = string.format(
              "%-" .. components.max_name_len .. "s : %-" .. components.max_type_len .. "s",
              entry.name,
              entry.type
            ),
            ordinal = entry.name .. " " .. entry.type,
            -- Track the starting line number of each component
            line_number = entry.line_number or 1, -- Fallback to line 1 if unset
            definition = entry.definition,
          }
        end,
      }),
      sorter = telescope_config.generic_sorter(opts),
      previewer = previewers.new_buffer_previewer({
        title = "Component Definition",
        define_preview = function(self, entry)
          local lines = vim.split(entry.value.definition, "\n")
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
          vim.bo[self.state.bufnr].filetype = "wod"
        end,
      }),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          -- Find the window with the .wod file
          local target_win = nil
          local target_buf = vim.fn.bufnr(wod_filename)

          for _, win in ipairs(vim.api.nvim_list_wins()) do
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.api.nvim_buf_get_name(buf) == wod_filename then
              target_win = win
              break
            end
          end

          if target_win then
            -- Switch to the window and set cursor position
            vim.api.nvim_set_current_win(target_win)
            if selection and selection.value and selection.value.line_number then
              -- Set the target window for our cursor
              vim.api.nvim_win_set_cursor(target_win, { selection.value.line_number, 0 })
              vim.cmd("normal! zz") -- Center Buffer

              -- Highlights the selection temporarily on jump
              local ns = vim.api.nvim_create_namespace("wod_jump")
              vim.api.nvim_buf_add_highlight(target_buf, ns, "Search", selection.value.line_number - 1, 0, -1)
              vim.defer_fn(function()
                vim.api.nvim_buf_clear_namespace(target_buf, ns, 0, -1)
              end, 1500)
            end
          else
            -- Open in vertical split if none exist as a fallback
            vim.cmd("vsplit " .. vim.fn.fnameescape(wod_filename))
            if selection and selection.value and selection.value.line_number then
              vim.api.nvim_win_set_cursor(0, { selection.value.line_number, 0 })
              vim.cmd("normal! zz")
            end
          end
        end)
        return true
      end,
      layout_strategy = "horizontal",
      layout_config = {
        width = 0.9,
        height = 0.8,
        prompt_position = "top",
        preview_width = 0.5,
        mirror = false,
      },
      sorting_strategy = "ascending",
    })
    :find()
end

vim.api.nvim_create_user_command("OpenWOD", M.open_wod, {})

return M
