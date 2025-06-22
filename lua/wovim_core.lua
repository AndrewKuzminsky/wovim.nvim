local api_parser = require("parsers.apiparser")
local buildparser = require("parsers.buildparser")
local classpathparser = require("parsers.classpathparser")
local wod_parser = require("parsers.wodparser")

-- TELESCOPE
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local telescope_config = require("telescope.config").values

-- TODO: I DONT want to double handle .api files as .xml files... rewrite this soon?

local M = {}
M.api_paths = nil
M.use_app_directories = true
M.api_bindings = api_parser.get_index()

-- TODO: Rename these to something with more clarity
local unique_set = {}
local unique_list = {}

local session_project_name = nil
local seen_project = {}

---@type boolean
-- define the style of inserted brackets
--`false` = K&R
--`true`  = Allman
local use_allman_style = false

function M.setup(user_config)
  M.api_paths = user_config.api_paths
  M.use_app_directories = user_config.use_app_directories or true
  api_parser.set_use_app_directories(user_config.use_app_directories or true)
  use_allman_style = user_config.use_allman_style or false

  local path_sep = package.config:sub(1, 1)
  local project_name = nil

  if M.use_app_directories then
    if not session_project_name then
      project_name = buildparser.get_project_name()
      session_project_name = project_name
    else
      project_name = session_project_name
    end

    api_parser.set_project_name(session_project_name)

    -- INFO: seen_project[project_name] is session based so its likely always true... hmmm
    if not seen_project[project_name] then
      seen_project[project_name] = true
      local directory = vim.fn.stdpath("data") .. path_sep .. "wovim" .. path_sep .. project_name
      -- read all files inside this directory
      local preexisting_filepaths = vim.fn.glob(directory .. "/**/*.xml", false, true)
      for _, filepath in ipairs(preexisting_filepaths) do
        if not unique_set[filepath] then
          unique_set[filepath] = true
          table.insert(unique_list, filepath)
        end
      end
    end
  else -- Not Using App Directories
    local directory = vim.fn.stdpath("data") .. path_sep .. "wovim"
    -- read all files inside this directory
    local preexisting_filepaths = vim.fn.glob(directory .. "/**/*.xml", false, true)
    for _, filepath in ipairs(preexisting_filepaths) do
      if not unique_set[filepath] then
        unique_set[filepath] = true
        table.insert(unique_list, filepath)
      end
    end
  end

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

  vim.keymap.set("n", "<leader>x,", M.build_wovim_data, {
    noremap = true,
    silent = true,
    desc = "Build WOVIM Data",
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

-- WARNING: This is a potentially expensive operation, do this sparingly!
-- Setup / rebuild wovim data
function M.build_wovim_data()
  if M.use_app_directories then
    local classpath_entries = nil
    -- Look at frameworks in our api_paths based on our classpath entries
    classpath_entries = classpathparser.get_classpath_entries()
    local frameworks = {}
    for _, entry in ipairs(classpath_entries or {}) do
      local entry_name = vim.fn.fnamemodify(entry, ":t:r") -- trim & root
      frameworks[entry_name] = true
    end

    -- empty the built list
    unique_list = {}

    for _, dir in ipairs(M.api_paths or {}) do
      -- print("Checking Directory: " .. dir)
      local all_dirs = vim.fn.glob(dir .. "/**/", true, true)
      for _, subdir in ipairs(all_dirs) do
        -- strip any trailing slashes
        local trimmed_subdir = vim.fn.fnamemodify(subdir:gsub("/$", ""), ":t:r")
        if frameworks[trimmed_subdir] then
          local filepaths = vim.fn.glob(subdir .. "/**/*.api", false, true)
          for _, filepath in ipairs(filepaths) do
            if not unique_set[filepath] then
              unique_set[filepath] = true
              table.insert(unique_list, filepath)
            end
          end
        end
      end
    end
  else -- Global Approach
    -- Setup Unique List incase we need to rebuild / build wovim data
    for _, dir in ipairs(M.api_paths or {}) do
      local filepaths = vim.fn.glob(dir .. "/**/*.api", false, true)
      for _, filepath in ipairs(filepaths) do
        if not unique_set[filepath] then
          unique_set[filepath] = true
          table.insert(unique_list, filepath)
        end
      end
    end
  end

  api_parser.parse_all(unique_list)
end
-- end open_wo

vim.api.nvim_create_user_command("BuildWOVIM", M.build_wovim_data, {})

-- Edit the WOD, adding component definitions
function M.edit_wod()
  -- Define available component types
  local component_types = {}
  local seen_filenames = {}

  for _, unique_api_file in ipairs(unique_list) do
    local filename = vim.fn.fnamemodify(unique_api_file, ":t:r")
    -- Probably not quite necessary anymore...good defense against duplicate component names though.
    -- may be a good idea to make this unique per framework?
    if not seen_filenames[filename] then
      table.insert(component_types, filename)
      seen_filenames[filename] = true
    end
  end

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
      local wod_definition = {}

      if use_allman_style then
        table.insert(wod_definition, tag_name .. ": " .. selected_type)
        table.insert(wod_definition, "{")
      else
        table.insert(wod_definition, tag_name .. ": " .. selected_type .. " {")
      end
      table.insert(wod_definition, "    // TODO: setup bindings")

      -- If the selected type hasnt been read yet...read it and it should automatically be added to our global table
      -- TODO: what happens when the table gets too big? should a size limit be set?
      if not M.api_bindings[selected_type] or vim.tbl_isempty(M.api_bindings[selected_type]) then
        api_parser.read_component_file(selected_type)
      end

      for _, binding in pairs(M.api_bindings[selected_type] or {}) do
        table.insert(wod_definition, "    " .. binding .. " = ;") -- Adjust formatting as needed
      end

      -- Close the block
      table.insert(wod_definition, "}")

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
          -- local target_buf = vim.fn.bufnr(wod_filename)

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

return M
