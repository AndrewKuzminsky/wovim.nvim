local M = {}

local api_index = {}

function M.get_index()
  return api_index
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
  local path_sep = package.config:sub(1, 1)

  -- data/wovim
  local directory = vim.fn.stdpath("data") .. path_sep .. "wovim"
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
  local path_sep = package.config:sub(1, 1)
  -- data/wovim
  local directory = vim.fn.stdpath("data") .. path_sep .. "wovim"
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

  -- extract wodefinitions
  local wodefinitions = api_content:match("<wodefinitions>(.-)</wodefinitions>")
  local filename = vim.fn.fnamemodify(api_file_path, ":t:r") -- trim & root

  if wodefinitions then
    write_component_file(filename, wodefinitions)
  end
end
-- end parse

function M.parse_all(filepaths)
  vim.notify("[WOVIM] Building WOVIM Data...")
  for _, path in ipairs(filepaths) do
    -- print("Parsing .. " .. path)
    M.parse(path)
  end
  vim.notify("[WOVIM] Completed Building/Rebuilding WOVIM Data!")
  -- return api_index
end
-- end parse_all

return M
