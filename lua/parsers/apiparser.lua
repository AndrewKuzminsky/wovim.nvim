local M = {}
local path_sep = package.config:sub(1, 1)

local api_index = {}

function M.get_index()
  return api_index
end

local project_name = nil

function M.project_name()
  return project_name
end

function M.set_project_name(value)
  project_name = value
end

--- @type boolean
-- Controls if we want to use app-specific dirs via dictated by the .classpath
-- Defaults to `true` as its more performative, `false` uses global framework behavior
local use_app_directories = true

function M.use_app_directories()
  return use_app_directories
end

function M.set_use_app_directories(value)
  use_app_directories = value
end

-- EXAMPLE .API DEFINITION
-- <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
-- <wodefinitions>
-- 	<wo wocomponentcontent = "true" class = "AjaxGrid.java">
--     <binding name = "displayGroup"/>
--     <binding name = "configurationData"/>
--     <binding name = "selectedObjects"/>
--     <binding name = "willUpdate"/>
--     <binding name = "afterUpdate"/>
--     <binding name = "reverteffect"/>
--     <binding name = "endeffect"/>
--     <binding name = "zindex"/>
--     <binding name = "keyPress"/>
--     <binding name = "revert" defaults = "Boolean" />
--     <binding name = "snap"/>
--     <binding name = "class"/>
-- 	</wo>
-- </wodefinitions>
local function write_component_file(filename, wodefinitions)
  -- data/wovim
  local directory = nil

  if use_app_directories then
    directory = vim.fn.stdpath("data") .. path_sep .. "wovim" .. path_sep .. M.project_name()
  else
    directory = vim.fn.stdpath("data") .. path_sep .. "wovim"
  end
  -- data/wovim/AjaxGrid.xml

  local filepath = directory .. path_sep .. filename .. ".xml"

  vim.fn.mkdir(directory, "p") -- create our directory if necessary
  local file = io.open(filepath, "w+")
  local indent = string.rep(" ", 2) -- 2 spaces
  if file then
    -- <AjaxGrid>
    file:write("<" .. filename .. ">" .. "\n")

    for name in wodefinitions:gmatch('<binding%s+name="(.-)"') do
      -- <binding name="displayGroup"></binding>
      file:write(indent .. '<binding name="' .. name .. '"></binding>\n')
    end
    -- </AjaxGrid>
    file:write("</" .. filename .. ">" .. "\n")
    file:close()
  else
    print("[WOVIM] Error: Could not open file " .. filepath)
  end
end

-- EXAMPLE DEFINITION FOR CENTRALISED RETRIEVAL
-- <ERPPieChart>
--   <binding name="height"></binding>
--   <binding name="width"></binding>
--   <binding name="items"></binding>
--   <binding name="type"></binding>
--   <binding name="nameKey"></binding>
--   <binding name="valueKey"></binding>
--   <binding name="dataset"></binding>
--   <binding name="orientation"></binding>
--   <binding name="showUrls"></binding>
--   <binding name="showLegends"></binding>
--   <binding name="showToolTips"></binding>
--   <binding name="chart"></binding>
--   <binding name="configuration"></binding>
--   <binding name="showLabels"></binding>
-- </ERPPieChart>
function M.read_component_file(filename)
  -- data/wovim
  local directory = nil
  if use_app_directories then
    directory = vim.fn.stdpath("data") .. path_sep .. "wovim" .. path_sep .. M.project_name()
  else
    directory = vim.fn.stdpath("data") .. path_sep .. "wovim"
  end
  -- data/wovim/AjaxGrid.xml
  local filepath = directory .. path_sep .. filename .. ".xml"

  -- open the file for reading
  local file = io.open(filepath, "r")
  local bindings = {}

  if file then
    local content = file:read("*all") -- content into a string
    for name in content:gmatch('<binding%s+name="(.-)"') do
      table.insert(bindings, name)
    end
    file:close()
  else
    print("[WOVIM] Error: Could not open file " .. filepath)
  end

  api_index[filename] = bindings
end
-- end read_component_file

-- Parses a .api file
function M.parse(api_file_path)
  -- Load the file
  local api_content = table.concat(vim.fn.readfile(api_file_path), "\n")
  local wodefinitions = api_content:match("<wodefinitions>(.-)</wodefinitions>")
  local filename = vim.fn.fnamemodify(api_file_path, ":t:r") -- trim & root

  if wodefinitions then
    write_component_file(filename, wodefinitions)
  end
end
-- end parse

function M.parse_all(filepaths)
  if use_app_directories then
    vim.notify("[WOVIM] Building APP WOVIM Data...")
  else
    vim.notify("[WOVIM] Building WOVIM Data...")
  end

  for _, path in ipairs(filepaths) do
    M.parse(path)
  end
  vim.notify("[WOVIM] Completed Building/Rebuilding WOVIM Data!")
end
-- end parse_all

return M
