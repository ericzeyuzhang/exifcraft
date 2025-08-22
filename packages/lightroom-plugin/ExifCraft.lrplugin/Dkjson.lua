-- Simple JSON library for Lightroom plugins (refactored from Dkjson.lua)

local Dkjson = {}

-- JSON encoding
function Dkjson.encode(data, state)
  state = state or {}
  local indent = state.indent and "  " or ""
  local encode_value
  
  local function encode_string(str)
    local result = '"'
    for i = 1, #str do
      local c = str:sub(i, i)
      if c == '"' then
        result = result .. '\\"'
      elseif c == '\\' then
        result = result .. '\\\\'
      elseif c == '\n' then
        result = result .. '\\n'
      elseif c == '\r' then
        result = result .. '\\r'
      elseif c == '\t' then
        result = result .. '\\t'
      else
        result = result .. c
      end
    end
    return result .. '"'
  end
  
  local function encode_table(tbl, level)
    level = level or 0
    local indent_str = indent:rep(level)
    local next_indent = indent:rep(level + 1)
    
    if next(tbl) == nil then
      return '{}'
    end
    
    local is_array = true
    for k, _ in pairs(tbl) do
      if type(k) ~= "number" or k < 1 or k > #tbl then
        is_array = false
        break
      end
    end
    
    if is_array then
      local result = '[\n'
      for i, v in ipairs(tbl) do
        if i > 1 then
          result = result .. ',\n'
        end
        result = result .. next_indent .. encode_value(v, level + 1)
      end
      return result .. '\n' .. indent_str .. ']'
    else
      local result = '{\n'
      local first = true
      for k, v in pairs(tbl) do
        if not first then
          result = result .. ',\n'
        end
        first = false
        result = result .. next_indent .. encode_string(tostring(k)) .. ': ' .. encode_value(v, level + 1)
      end
      return result .. '\n' .. indent_str .. '}'
    end
  end
  
  function encode_value(val, level)
    local t = type(val)
    if t == "nil" then
      return "null"
    elseif t == "boolean" then
      return val and "true" or "false"
    elseif t == "number" then
      if val ~= val then
        return "null"
      elseif val >= math.huge then
        return "null"
      elseif val <= -math.huge then
        return "null"
      else
        return tostring(val)
      end
    elseif t == "string" then
      return encode_string(val)
    elseif t == "table" then
      return encode_table(val, level)
    else
      error("unsupported type: " .. t)
    end
  end
  
  return encode_value(data, 0)
end

-- JSON decoding (simplified)
function Dkjson.decode(str)
  local i = 1
  local parse_value
  local parse_string
  
  local function skip_whitespace()
    while i <= #str and str:sub(i, i):match("%s") do
      i = i + 1
    end
  end

  local function parse_object()
    i = i + 1
    local result = {}
    
    skip_whitespace()
    if str:sub(i, i) == '}' then
      i = i + 1
      return result
    end
    
    while true do
      skip_whitespace()
      if str:sub(i, i) ~= '"' then
        error("Expected string key")
      end
      
      local key = parse_string()
      skip_whitespace()
      
      if str:sub(i, i) ~= ':' then
        error("Expected colon")
      end
      i = i + 1
      
      local value = parse_value()
      result[key] = value
      
      skip_whitespace()
      if str:sub(i, i) == '}' then
        i = i + 1
        return result
      elseif str:sub(i, i) == ',' then
        i = i + 1
      else
        error("Expected comma or closing brace")
      end
    end
  end

  function parse_string()
    i = i + 1
    local result = ""
    while i <= #str do
      local c = str:sub(i, i)
      if c == '"' then
        i = i + 1
        return result
      elseif c == '\\' then
        i = i + 1
        local next_c = str:sub(i, i)
        if next_c == '"' or next_c == '\\' or next_c == '/' then
          result = result .. next_c
        elseif next_c == 'n' then
          result = result .. '\n'
        elseif next_c == 'r' then
          result = result .. '\r'
        elseif next_c == 't' then
          result = result .. '\t'
        end
      else
        result = result .. c
      end
      i = i + 1
    end
    error("Unterminated string")
  end
  
  local function parse_array()
    i = i + 1
    local result = {}
    
    skip_whitespace()
    if str:sub(i, i) == ']' then
      i = i + 1
      return result
    end
    
    while true do
      table.insert(result, parse_value())
      
      skip_whitespace()
      if str:sub(i, i) == ']' then
        i = i + 1
        return result
      elseif str:sub(i, i) == ',' then
        i = i + 1
      else
        error("Expected comma or closing bracket")
      end
    end
  end

  
  local function parse_number()
    local start = i
    while i <= #str and str:sub(i, i):match("[%d%.%-%+eE]") do
      i = i + 1
    end
    local num_str = str:sub(start, i - 1)
    local num = tonumber(num_str)
    if not num then
      error("Invalid number: " .. num_str)
    end
    return num
  end
  
  function parse_value()
    skip_whitespace()
    local c = str:sub(i, i)
    
    if c == '"' then
      return parse_string()
    elseif c == '{' then
      return parse_object()
    elseif c == '[' then
      return parse_array()
    elseif c == 't' and str:sub(i, i + 3) == "true" then
      i = i + 4
      return true
    elseif c == 'f' and str:sub(i, i + 4) == "false" then
      i = i + 5
      return false
    elseif c == 'n' and str:sub(i, i + 3) == "null" then
      i = i + 4
      return nil
    elseif c:match('%d') or c == '-' then
      return parse_number()
    else
      error("Unexpected character: " .. c)
    end
  end
  
  return parse_value()
end

return Dkjson



