local highlight = require("stacktrace.highlight")
local navigation = require("stacktrace.navigation")

---@class UI
local M = {}

local state = {
  bufnr = nil,
  winid = nil,
  frames = {},
  source_win = nil,
}

---Calculate window size and position for floating window
---@param max_width number
---@param max_height number
---@param lines table
---@return table
local function calculate_window_size(max_width, max_height, lines)
  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, #line)
  end

  width = math.min(width + 2, max_width)
  local height = math.min(#lines, max_height)

  local ui = vim.api.nvim_list_uis()[1]
  local row = math.floor((ui.height - height) / 2)
  local col = math.floor((ui.width - width) / 2)

  return {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
  }
end

---Setup keymaps for the stacktrace buffer
---@param bufnr number
---@param config table
local function setup_keymaps(bufnr, config)
  local keymaps = config.keymaps or {}

  -- Jump to location
  if keymaps.jump then
    vim.keymap.set("n", keymaps.jump, function()
      local cursor = vim.api.nvim_win_get_cursor(0)
      local line_num = cursor[1]
      navigation.jump_from_line(line_num, state.frames, state.source_win)
    end, { buffer = bufnr, silent = true, desc = "Jump to stack frame location" })
  end

  -- Close window
  if keymaps.close then
    vim.keymap.set("n", keymaps.close, function()
      M.close_stacktrace()
    end, { buffer = bufnr, silent = true, desc = "Close stacktrace window" })
  end

  -- Next frame
  if keymaps.next_frame then
    vim.keymap.set("n", keymaps.next_frame, function()
      navigation.next_frame(state.frames)
    end, { buffer = bufnr, silent = true, desc = "Jump to next stack frame" })
  end

  -- Previous frame
  if keymaps.prev_frame then
    vim.keymap.set("n", keymaps.prev_frame, function()
      navigation.prev_frame(state.frames)
    end, { buffer = bufnr, silent = true, desc = "Jump to previous stack frame" })
  end

  -- Mouse click support
  vim.keymap.set("n", "<LeftMouse>", function()
    -- Move cursor to mouse click position
    local mouse_pos = vim.fn.getmousepos()
    if mouse_pos.winid == vim.api.nvim_get_current_win() then
      vim.api.nvim_win_set_cursor(0, { mouse_pos.line, mouse_pos.column - 1 })
      -- Jump to location
      navigation.jump_from_line(mouse_pos.line, state.frames, state.source_win)
    end
  end, { buffer = bufnr, silent = true, desc = "Click to jump to stack frame" })

  -- ESC also closes
  vim.keymap.set("n", "<Esc>", function()
    M.close_stacktrace()
  end, { buffer = bufnr, silent = true, desc = "Close stacktrace window" })
end

---Create and configure the stacktrace buffer
---@param text string
---@param frames table
---@return number bufnr
local function create_buffer(text, frames)
  local bufnr = vim.api.nvim_create_buf(false, true)

  -- Set buffer options
  vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
  vim.api.nvim_buf_set_option(bufnr, "swapfile", false)
  vim.api.nvim_buf_set_option(bufnr, "filetype", "stacktrace")
  vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")

  -- Set buffer content
  local lines = vim.split(text, "\n")
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  -- Make buffer read-only
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

  -- Apply highlighting
  highlight.highlight_buffer(bufnr, frames)

  return bufnr
end

---Open the stacktrace window (split or float based on config)
---@param text string
---@param frames table
---@param config table
M.open_stacktrace = function(text, frames, config)
  -- Initialize highlight groups
  highlight.setup()

  -- Store source window
  state.source_win = vim.api.nvim_get_current_win()

  -- Close existing window if open
  if state.winid and vim.api.nvim_win_is_valid(state.winid) then
    M.close_stacktrace()
  end

  -- Create buffer
  state.bufnr = create_buffer(text, frames)
  state.frames = frames

  local window_type = config.ui.window_type or "split"

  if window_type == "float" then
    -- Create floating window
    local lines = vim.split(text, "\n")
    local float_opts = config.ui.float_opts or {}
    local max_width = float_opts.max_width or 120
    local max_height = float_opts.max_height or 40
    local border = float_opts.border or "rounded"

    local win_opts = calculate_window_size(max_width, max_height, lines)
    win_opts.border = border
    win_opts.style = "minimal"

    state.winid = vim.api.nvim_open_win(state.bufnr, true, win_opts)
  else
    -- Create split window
    local split_opts = config.ui.split_opts or {}
    local position = split_opts.position or "below"
    local size = split_opts.size or 15

    -- Determine split command
    local split_cmd
    if position == "above" then
      split_cmd = "topleft split"
    elseif position == "below" then
      split_cmd = "botright split"
    elseif position == "left" then
      split_cmd = "topleft vsplit"
    elseif position == "right" then
      split_cmd = "botright vsplit"
    else
      split_cmd = "botright split"
    end

    -- Execute split and set buffer
    vim.cmd(split_cmd)
    state.winid = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(state.winid, state.bufnr)

    -- Set window size
    if position == "left" or position == "right" then
      vim.api.nvim_win_set_width(state.winid, size)
    else
      vim.api.nvim_win_set_height(state.winid, size)
    end
  end

  -- Set window options
  vim.api.nvim_win_set_option(state.winid, "wrap", false)
  vim.api.nvim_win_set_option(state.winid, "cursorline", true)

  -- Setup keymaps
  setup_keymaps(state.bufnr, config)

  -- Set buffer name
  vim.api.nvim_buf_set_name(state.bufnr, "stacktrace://analysis")
end

---Close the stacktrace window
M.close_stacktrace = function()
  if state.winid and vim.api.nvim_win_is_valid(state.winid) then
    vim.api.nvim_win_close(state.winid, true)
  end

  state.winid = nil
  state.bufnr = nil
  state.frames = {}
end

---Get current state (for testing)
M.get_state = function()
  return state
end

return M
