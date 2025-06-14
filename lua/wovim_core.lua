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
  vim.keymap.set("n", "<leader>bw", M.browse_wod, {
    noremap = true,
    silent = true,
    desc = "Open WOD Component Browser",
  })

  vim.keymap.set("n", "<leader>be", M.edit_wod, {
    noremap = true,
    silent = true,
    desc = "Edit WOD",
  })
end
-- end setup

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
-- end open_wo

vim.api.nvim_create_user_command("OpenWO", M.open_wo, {})

-- Edit the WOD, adding component definitions
-- FIXME: Needs to be flexible...but how to parse all available components to the project?
function M.edit_wod()
  -- TODO:
  -- Access WOComponent Libraries from configured directories in plugin config
  -- Perhaps bundle default WO stuff too rather than manually hooking it up?

  -- Define available component types
  local component_types = {
    "WOConditional",
    "WOForm",
    "WORepetition",
    "WOHyperlink",
    "WOText",
    "WOCheckBox",
    "WOPopUpButton",
    "WORadioButton",
    "WOSubmitButton",
    "WOTextField",
    "WOHiddenField",
    "WOPasswordField",
    "WOTextarea",
  }

  -- Get current file paths
  local html_file = vim.api.nvim_buf_get_name(0)
  local wod_file = html_file:gsub("%.html$", ".wod")

  -- First select component type
  vim.ui.select(component_types, {
    prompt = "Add Component:",
  }, function(selected_type)
    if not selected_type then
      return
    end

    -- Get tag name with validation
    vim.ui.input({
      prompt = "Enter tag name for " .. selected_type .. ": ",
      default = "",
      validate = function(input)
        return input:match("^[a-zA-Z][a-zA-Z0-9_]*$") ~= nil or "Invalid name (letters/numbers/underscore only)"
      end,
    }, function(tag_name)
      if not tag_name or tag_name == "" then
        return
      end

      -- Remember current window and cursor position
      local original_win = vim.api.nvim_get_current_win()
      local original_pos = vim.api.nvim_win_get_cursor(original_win)

      -- 1. Insert HTML tag
      local html_tag = string.format('<webobject name="%s"></webobject>', tag_name)
      vim.api.nvim_buf_set_text(
        0,
        original_pos[1] - 1,
        original_pos[2],
        original_pos[1] - 1,
        original_pos[2],
        { html_tag }
      )

      -- 2. Format WOD definition
      local wod_definition = {
        tag_name .. ": " .. selected_type .. " {",
        "    // TODO: Add bindings",
        "}",
      }

      -- Find existing WOD window if open
      local wod_win
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)) == wod_file then
          wod_win = win
          break
        end
      end

      -- Handle WOD file update
      local function update_wod()
        local buf = vim.fn.bufadd(wod_file)
        vim.fn.bufload(buf)

        -- Check if file exists and has content
        local exists = vim.fn.filereadable(wod_file) == 1
        if exists then
          local last_line = vim.api.nvim_buf_line_count(buf)
          local last_line_content = vim.api.nvim_buf_get_lines(buf, last_line - 1, last_line, false)[1]

          -- Add newline if last line isn't empty
          if last_line_content ~= "" then
            table.insert(wod_definition, 1, "")
          end
        end

        -- Append the new definition
        vim.api.nvim_buf_set_lines(buf, -1, -1, false, wod_definition)

        -- Save if this is a different buffer than current
        if vim.api.nvim_get_current_buf() ~= buf then
          vim.api.nvim_buf_call(buf, function()
            vim.cmd("w")
          end)
        end
      end

      -- Update WOD without disturbing windows
      if wod_win then
        -- WOD is already visible in a window
        local prev_win = vim.api.nvim_get_current_win()
        vim.api.nvim_set_current_win(wod_win)
        update_wod()
        vim.api.nvim_set_current_win(prev_win)
      else
        -- WOD not visible - update silently
        update_wod()
      end

      -- Restore cursor position in HTML
      vim.api.nvim_set_current_win(original_win)
      vim.api.nvim_win_set_cursor(original_win, { original_pos[1], original_pos[2] + #'<webobject name="' })

      vim.notify(string.format("Added %s component '%s'", selected_type, tag_name))
    end)
  end)
end
-- end edit_wod

vim.api.nvim_create_user_command("EditWOD", M.edit_wod, {})

-- Browse the WOD using Telescope
function M.browse_wod(opts)
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
      prompt_title = "WOD Browser (" .. #components.raw .. ")",
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
        -- TODO: Indentation
        define_preview = function(self, entry)
          local indented_lines = wod_parser.indent_wod_definition(entry.value.definition)
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, indented_lines)
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
-- end browse_wod

vim.api.nvim_create_user_command("OpenWOD", M.browse_wod, {})

-- FIXME: doesnt work
--
-- Jump to WOD Definitions using gd
-- local function goto_wod_definition()
--   local line = vim.fn.getline(".")
--   -- Match patterns like <webobject name="Conditional3">
--   local name = line:match('<webobject%s+name="([^"]+)"')
--   if not name then
--     return
--   end
--
--   -- Find .wod file in same directory
--   local wod_file = vim.fn.expand("%:p:r") .. ".wod"
--   if vim.fn.filereadable(wod_file) == 0 then
--     return
--   end
--
--   -- Search for the pattern "name: WOConditional" in wod file
--   local bufnr = vim.fn.bufnr(wod_file, true)
--   if bufnr == -1 then
--     return
--   end
--
--   -- Save current position
--   vim.fn.setpos("''", vim.fn.getpos("."))
--
--   -- Switch to wod file buffer
--   vim.api.nvim_set_current_buf(bufnr)
--
--   -- Search for the definition
--   local found = false
--   for i, l in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
--     if l:match("^" .. name .. ":") then
--       vim.fn.cursor(i, 1)
--       found = true
--       break
--     end
--   end
--
--   if not found then
--     -- Return to original position if not found
--     vim.cmd("buffer #")
--     vim.fn.setpos(".", vim.fn.getpos("''"))
--     print("Definition not found in .wod file")
--   end
-- end
-- end goto_wod_definition

-- vim.api.nvim_set_keymap("n", "gd", "<cmd>lua goto_wod_definition()<CR>", { noremap = true, silent = true })

-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "html",
--   callback = function()
--     vim.keymap.set("n", "gd", goto_wod_definition, { buffer = true, noremap = true, silent = true })
--   end,
-- })

return M
