local M = {}

function M.parse(wod_filename)
  -- Read file with universal newline support
  local lines = vim.fn.readfile(wod_filename)
  local components = {}
  local current_component = nil
  local max_name_len = 0
  local max_type_len = 0

  for line_num, line in ipairs(lines) do
    -- Normalize line endings and clean input
    line = line:gsub("\r$", ""):gsub("^%s*(.-)%s*$", "%1")

    -- More robust pattern matching that handles:
    -- 1. Component names with numbers (Component1)
    -- 2. Various spacing patterns
    -- 3. Optional whitespace before {
    local name, wotype = line:match("^([%a_][%w_]*):%s*([%a][%w]*)%s*{?$")
    if name and wotype then
      -- Finalize previous component if exists
      if current_component then
        current_component.definition = table.concat(current_component.lines, "\n")
        table.insert(components, current_component)
      end

      -- Start new component
      current_component = {
        name = name,
        type = wotype,
        lines = { line },
        line_number = line_num,
        display = name .. ": " .. wotype,
      }

      max_name_len = math.max(max_name_len, #name)
      max_type_len = math.max(max_type_len, #wotype)
    elseif current_component then
      if line:match("^%s*}%s*$") then
        -- End of component
        table.insert(current_component.lines, line)
        current_component.definition = table.concat(current_component.lines, "\n")
        table.insert(components, current_component)
        current_component = nil
      else
        -- Component body line
        table.insert(current_component.lines, line)
      end
    end
  end

  -- Handle any remaining component (unclosed)
  if current_component then
    current_component.definition = table.concat(current_component.lines, "\n")
    table.insert(components, current_component)
  end

  -- Create aligned display format
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
-- end parse

-- Indents for .WOComponent Definitions in the Preview
function M.indent_wod_definition(def)
  local lines = vim.split(def, "\n", { plain = true })
  local indent = 0
  local result = {}

  for _, line in ipairs(lines) do
    local trimmed = vim.trim(line)

    -- Decrease indent before line if it starts with }
    if trimmed:match("^}") then
      indent = indent - 1
    end

    -- Apply indent
    table.insert(result, string.rep("  ", math.max(indent, 0)) .. trimmed)

    -- Increase indent after line if it ends with {
    if trimmed:match("{$") then
      indent = indent + 1
    end
  end

  return result
end
-- end indent_wod_definition

return M
