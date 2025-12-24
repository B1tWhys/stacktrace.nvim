---@class Highlight
local M = {}

local namespace = vim.api.nvim_create_namespace("stacktrace")

---Initialize highlight groups
M.setup = function()
  -- File paths (resolved - can be navigated to)
  vim.api.nvim_set_hl(0, "StacktraceFileResolved", {
    fg = "#61AFEF",
    underline = true,
    default = true,
  })

  -- File paths (unresolved - cannot be found)
  vim.api.nvim_set_hl(0, "StacktraceFileUnresolved", {
    fg = "#5C6370",
    default = true,
  })
end

---Apply highlighting to a frame in the buffer
---@param bufnr number
---@param frame table
M.highlight_frame = function(bufnr, frame)
  local line_num = frame.line_number

  if not line_num then
    return
  end

  -- Only highlight file paths
  if frame.file_path then
    local hl_group = frame.resolved_path and "StacktraceFileResolved" or "StacktraceFileUnresolved"

    -- Find the file path in the line
    local s, e = frame.raw_line:find(vim.pesc(frame.file_path), 1, true)
    if s then
      vim.api.nvim_buf_set_extmark(bufnr, namespace, line_num - 1, s - 1, {
        end_col = e,
        hl_group = hl_group,
      })
    end
  end
end

---Apply highlighting to all frames in the buffer
---@param bufnr number
---@param frames table
M.highlight_buffer = function(bufnr, frames)
  -- Clear existing highlights
  vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)

  -- Apply highlighting to each frame
  for _, frame in ipairs(frames) do
    M.highlight_frame(bufnr, frame)
  end
end

---Clear highlighting from buffer
---@param bufnr number
M.clear_buffer = function(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
end

return M
