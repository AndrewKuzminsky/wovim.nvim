local M = {}

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

local api_index = {}
function M.parse(api_file_path)
  -- Load the file
  local api_content = table.concat(vim.fn.readfile(api_file_path), "\n")

  -- extract wodefinitions
  local wodefinitions = api_content:match("<wodefinitions>(.-)</wodefinitions>")
  local filename = vim.fn.fnamemodify(api_file_path, ":t:r") -- trim & root

  if wodefinitions then
    local bindings = {}
    for name in wodefinitions:gmatch('<binding%s+name="(.-)"') do
      -- print(filename .. " - inserting binding: " .. name)
      table.insert(bindings, name)
    end

    api_index[filename] = bindings
  end
end
-- end parse

function M.get_index()
  return api_index
end

function M.parse_all(filepaths)
  for _, path in ipairs(filepaths) do
    M.parse(path)
  end
  return api_index
end

return M
