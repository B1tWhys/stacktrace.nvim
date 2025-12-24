local parser = require("stacktrace.parser")
local resolver = require("stacktrace.resolver")
local ui = require("stacktrace.ui")

---@class StacktraceConfig
---@field parsers table Additional parser registrations
---@field search_paths table Custom search paths
---@field ui table UI configuration
---@field keymaps table Keymap configuration
local config = {
  parsers = {},
  search_paths = {},
  ui = {
    open_fn = nil,
    window_type = "split", -- "split", "vsplit", or "float"
    split_opts = {
      position = "below", -- "below", "above", "left", "right"
      size = 15, -- height for horizontal, width for vertical splits
    },
    float_opts = {
      border = "rounded",
      max_width = 120,
      max_height = 40,
    },
  },
  keymaps = {
    jump = "<CR>",
    close = "q",
    next_frame = "]s",
    prev_frame = "[s",
  },
}

---@class Stacktrace
local M = {}

---@type StacktraceConfig
M.config = config

---@param args StacktraceConfig?
M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})

  -- Register custom parsers if provided
  for name, parser_fn in pairs(M.config.parsers) do
    parser.register_parser(name, parser_fn)
  end

  -- Configure resolver with custom search paths
  resolver.setup({ search_paths = M.config.search_paths })
end

---@param text string The stack trace text to analyze
M.analyze_stacktrace = function(text)
  local frames = parser.parse(text)
  local resolved_frames = resolver.resolve_frames(frames)

  if M.config.ui.open_fn then
    M.config.ui.open_fn(text, resolved_frames)
  else
    ui.open_stacktrace(text, resolved_frames, M.config)
  end
end

M.analyze_from_clipboard = function()
  local clipboard = vim.fn.getreg("+")
  if clipboard == "" then
    vim.notify("Clipboard is empty", vim.log.levels.WARN)
    return
  end
  M.analyze_stacktrace(clipboard)
end

M.analyze_from_selection = function()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local lines = vim.fn.getline(start_pos[2], end_pos[2])

  if #lines == 0 then
    vim.notify("No selection", vim.log.levels.WARN)
    return
  end

  local text = table.concat(lines, "\n")
  M.analyze_stacktrace(text)
end

return M
