---@class Parser
local M = {}

local parsers = {}

---@class StackFrame
---@field file_path string|nil
---@field line number|nil
---@field column number|nil
---@field raw_line string
---@field line_number number

---Register a custom parser
---@param name string
---@param parser_fn function
M.register_parser = function(name, parser_fn)
  parsers[name] = parser_fn
end

---Common patterns for file paths with line/column numbers
local patterns = {
  -- Python: File "/path/to/file.py", line 123, in function
  {
    pattern = 'File "([^"]+)", line (%d+)',
    file = 1,
    line = 2,
  },
  -- Node.js/JavaScript: at Object.<anonymous> (/path/to/file.js:123:45)
  {
    pattern = "%(([^:)]+):(%d+):(%d+)%)",
    file = 1,
    line = 2,
    column = 3,
  },
  -- Node.js/JavaScript (simpler): at /path/to/file.js:123:45
  {
    pattern = "at ([^:%(]+):(%d+):(%d+)",
    file = 1,
    line = 2,
    column = 3,
  },
  -- Java: at package.Class.method(File.java:123)
  {
    pattern = "at [^%(]+%(([^:)]+):(%d+)%)",
    file = 1,
    line = 2,
  },
  -- Rust: --> /path/to/file.rs:123:45
  {
    pattern = "%-%-?%> ([^:]+):(%d+):(%d+)",
    file = 1,
    line = 2,
    column = 3,
  },
  -- Go: /path/to/file.go:123 +0x45
  {
    pattern = "([^:]+%.go):(%d+) ",
    file = 1,
    line = 2,
  },
  -- Generic: /path/to/file:123:45
  {
    pattern = "([%w_/%.%-]+%.[%w]+):(%d+):(%d+)",
    file = 1,
    line = 2,
    column = 3,
  },
  -- Generic: /path/to/file:123
  {
    pattern = "([%w_/%.%-]+%.[%w]+):(%d+)",
    file = 1,
    line = 2,
  },
  -- Generic: file.ext line 123
  {
    pattern = "([%w_/%.%-]+%.[%w]+) line (%d+)",
    file = 1,
    line = 2,
  },
  -- Windows paths: C:\path\to\file.ext:123:45
  {
    pattern = "([A-Z]:[\\%w_%.%-]+):(%d+):(%d+)",
    file = 1,
    line = 2,
    column = 3,
  },
  -- Windows paths: C:\path\to\file.ext:123
  {
    pattern = "([A-Z]:[\\%w_%.%-]+):(%d+)",
    file = 1,
    line = 2,
  },
}

---Try to extract file path and line/column from a line using patterns
---@param line string
---@return string|nil file_path
---@return number|nil line_num
---@return number|nil column_num
local function extract_location(line)
  for _, pattern_spec in ipairs(patterns) do
    local matches = { line:match(pattern_spec.pattern) }

    if #matches > 0 then
      local file_path = matches[pattern_spec.file]
      local line_num = pattern_spec.line and tonumber(matches[pattern_spec.line]) or nil
      local column_num = pattern_spec.column and tonumber(matches[pattern_spec.column]) or nil

      return file_path, line_num, column_num
    end
  end

  return nil, nil, nil
end

---Default generic parser that works for most stack traces
---@param text string
---@return table
local function default_parser(text)
  local frames = {}
  local lines = vim.split(text, "\n")

  for line_num, line in ipairs(lines) do
    local file_path, line_number, column = extract_location(line)

    -- Only create a frame if we found file path information
    if file_path then
      ---@type StackFrame
      local frame = {
        file_path = file_path,
        line = line_number,
        column = column,
        raw_line = line,
        line_number = line_num,
      }

      table.insert(frames, frame)
    end
  end

  return frames
end

---Parse stack trace text into structured frames
---@param text string
---@param parser_name string|nil
---@return table
M.parse = function(text, parser_name)
  local parser_fn = parsers[parser_name] or default_parser

  return parser_fn(text)
end

---Add a new pattern to the default parser
---@param pattern_spec table
M.add_pattern = function(pattern_spec)
  table.insert(patterns, 1, pattern_spec)
end

return M
