-- EXAMPLE CLASSPATH
-- <?xml version="1.0" encoding="UTF-8"?>
-- <classpath>
-- 	<classpathentry kind="src" path="Sources"/>
--   <classpathentry combineaccessrules="false" kind="con" path="WOFramework/JavaEOAccess"/>
--   <classpathentry combineaccessrules="false" kind="con" path="WOFramework/JavaEOControl"/>
--   <classpathentry combineaccessrules="false" kind="con" path="WOFramework/JavaFoundation"/>
--   <classpathentry combineaccessrules="false" kind="con" path="WOFramework/JavaJDBCAdaptor"/>
--   <classpathentry combineaccessrules="false" kind="con" path="WOFramework/JavaWebObjects"/>
--   <classpathentry combineaccessrules="false" kind="con" path="WOFramework/JavaXML"/>
-- 	<classpathentry kind="con" path="org.eclipse.jdt.launching.JRE_CONTAINER"/>
-- 	<classpathentry kind="output" path="bin"/>
-- </classpath>

local M = {}
local uv = vim.loop

local function find_classpath()
  local path = vim.fn.expand("%:p:h") -- current file directory
  if path == "" then
    path = vim.loop.cwd() -- fallback to current working directory
  end

  while path do
    local candidate = path .. "/.classpath"
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

function M.get_classpath_entries()
  local classpath = find_classpath()
  if classpath then
    -- print("Found classpath at: " .. classpath)
    local file_content = table.concat(vim.fn.readfile(classpath), "\n")

    local classpath_entries = {}

    for kind, path in file_content:gmatch('<classpathentry.-kind="(.-)".-path="(.-)"') do
      if kind ~= "src" and not path:match("JRE_CONTAINER") and not path:match("bin") then
        local entry_name = vim.fn.fnamemodify(path, ":t:r") -- trim & root
        table.insert(classpath_entries, entry_name)
      end
    end

    return classpath_entries
  else
    print("[WOVIM] Cannot locate this Projects classpath.")
    return nil
  end
end

return M
