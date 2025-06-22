local M = {}
local uv = vim.loop

local function find_build_xml()
  local path = vim.fn.expand("%:p:h") -- current file directory
  if path == "" then
    path = vim.loop.cwd() -- fallback to current working directory
  end

  while path do
    local candidate = path .. "/build.xml"
    local stat = uv.fs_stat(candidate)
    if stat and stat.type == "file" then
      return candidate
    end

    local parent = uv.fs_realpath(path .. "/..")
    if not parent or parent == path then
      break
    end
    path = parent
  end

  return nil
end

function M.get_project_name()
  local build_xml_path = find_build_xml()
  if build_xml_path then
    -- print("Found build.xml at: " .. build_xml_path)
    local file_content = table.concat(vim.fn.readfile(build_xml_path), "\n")
    -- extract Project Name
    local project_name = nil
    for line in file_content:gmatch("[^\r\n]+") do
      if line:match("<project%s") then
        project_name = line:match('name%s*=%s*"([^"]+)"')
        break
      end
    end

    return project_name
  else
    print("[WOVIM] Cannot locate build.xml in parent directories.")
    return nil
  end
end

return M
