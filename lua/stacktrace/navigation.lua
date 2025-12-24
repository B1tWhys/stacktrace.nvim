---@class Navigation
local M = {}

---Jump to a specific stack frame location
---@param frame table
---@param source_win number|nil
M.jump_to_location = function(frame, source_win)
  if not frame.resolved_path then
    if frame.file_path then
      vim.notify(
        string.format("Could not resolve file: %s", frame.file_path),
        vim.log.levels.WARN,
        { title = "Stacktrace" }
      )
    else
      vim.notify("No file path in this line", vim.log.levels.INFO, { title = "Stacktrace" })
    end
    return
  end

  -- Close the stacktrace window (will be handled by ui.lua)
  -- Switch to source window or create new one
  if source_win and vim.api.nvim_win_is_valid(source_win) then
    vim.api.nvim_set_current_win(source_win)
  end

  -- Open the file
  vim.cmd("edit " .. vim.fn.fnameescape(frame.resolved_path))

  -- Jump to line and column
  if frame.line then
    local col = frame.column or 1
    vim.api.nvim_win_set_cursor(0, { frame.line, col - 1 })

    -- Center the cursor
    vim.cmd("normal! zz")

    vim.notify(
      string.format("Jumped to %s:%d", vim.fn.fnamemodify(frame.resolved_path, ":."), frame.line),
      vim.log.levels.INFO,
      { title = "Stacktrace" }
    )
  end
end

---Jump from a specific line number in the stacktrace buffer
---@param line_num number
---@param frames table
---@param source_win number|nil
M.jump_from_line = function(line_num, frames, source_win)
  -- Find frame matching this line number
  local frame = nil
  for _, f in ipairs(frames) do
    if f.line_number == line_num then
      frame = f
      break
    end
  end

  if not frame then
    vim.notify("No stack frame on this line", vim.log.levels.INFO, { title = "Stacktrace" })
    return
  end

  M.jump_to_location(frame, source_win)
end

---Find next frame with a resolved path
---@param frames table
---@param current_idx number
---@return number|nil
local function find_next_resolved_frame(frames, current_idx)
  for i = current_idx + 1, #frames do
    if frames[i].resolved_path then
      return i
    end
  end

  -- Wrap around
  for i = 1, current_idx - 1 do
    if frames[i].resolved_path then
      return i
    end
  end

  return nil
end

---Find previous frame with a resolved path
---@param frames table
---@param current_idx number
---@return number|nil
local function find_prev_resolved_frame(frames, current_idx)
  for i = current_idx - 1, 1, -1 do
    if frames[i].resolved_path then
      return i
    end
  end

  -- Wrap around
  for i = #frames, current_idx + 1, -1 do
    if frames[i].resolved_path then
      return i
    end
  end

  return nil
end

---Navigate to next frame
---@param frames table
M.next_frame = function(frames)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local current_line = cursor[1]

  -- Find current frame index
  local current_idx = nil
  for i, frame in ipairs(frames) do
    if frame.line_number == current_line then
      current_idx = i
      break
    end
  end

  if not current_idx then
    current_idx = 0
  end

  local next_idx = find_next_resolved_frame(frames, current_idx)

  if next_idx then
    -- Move cursor to next frame line
    vim.api.nvim_win_set_cursor(0, { frames[next_idx].line_number, 0 })
  else
    vim.notify("No more resolved frames", vim.log.levels.INFO, { title = "Stacktrace" })
  end
end

---Navigate to previous frame
---@param frames table
M.prev_frame = function(frames)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local current_line = cursor[1]

  -- Find current frame index
  local current_idx = nil
  for i, frame in ipairs(frames) do
    if frame.line_number == current_line then
      current_idx = i
      break
    end
  end

  if not current_idx then
    current_idx = #frames + 1
  end

  local prev_idx = find_prev_resolved_frame(frames, current_idx)

  if prev_idx then
    -- Move cursor to previous frame line
    vim.api.nvim_win_set_cursor(0, { frames[prev_idx].line_number, 0 })
  else
    vim.notify("No more resolved frames", vim.log.levels.INFO, { title = "Stacktrace" })
  end
end

return M
