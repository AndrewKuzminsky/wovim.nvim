local M = {}

function M.parse(wod_filename)
  local lines = vim.fn.readfile(wod_filename)
  local components = {}
  local current_component = nil
  local max_name_len = 0
  local max_type_len = 0

  -- Use ipairs with index to get line numbers
  for line_num, line in ipairs(lines) do
    local name, wotype = line:match("^([%w_]+):%s*(%w+)%s*{")
    if name and wotype then
      -- Save previous component if exists
      if current_component then
        current_component.definition = table.concat(current_component.lines, "\n")
        table.insert(components, current_component)
      end
      -- Start new component with line number
      current_component = {
        name = name,
        type = wotype,
        lines = { line },
        line_number = line_num, -- This is now properly set
        display = name .. ": " .. wotype,
      }
      max_name_len = math.max(max_name_len, #name)
      max_type_len = math.max(max_type_len, #wotype)
    elseif current_component and line:match("^%s*}") then
      -- End of component
      table.insert(current_component.lines, line)
      current_component.definition = table.concat(current_component.lines, "\n")
      table.insert(components, current_component)
      current_component = nil
    elseif current_component then
      -- Component body line
      table.insert(current_component.lines, line)
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

return M
