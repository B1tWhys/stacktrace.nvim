---@class Resolver
local M = {}

local config = {
  search_paths = {},
}

local cache = {}

---@param opts table?
M.setup = function(opts)
  opts = opts or {}
  config.search_paths = opts.search_paths or {}
  cache = {}
end

---Find git root directory by searching for .git directory
---@param start_path string?
---@return string|nil
local function find_git_root(start_path)
  start_path = start_path or vim.fn.getcwd()

  local current = start_path
  while current ~= "/" do
    local git_dir = current .. "/.git"
    if vim.fn.isdirectory(git_dir) == 1 then
      return current
    end
    current = vim.fn.fnamemodify(current, ":h")
  end

  return nil
end

---Get search directories in priority order
---@return table
local function get_search_dirs()
  local dirs = {}

  -- 1. Git root (highest priority)
  local git_root = find_git_root()
  if git_root then
    table.insert(dirs, git_root)
  end

  -- 2. Current working directory
  table.insert(dirs, vim.fn.getcwd())

  -- 3. User-configured search paths
  for _, path in ipairs(config.search_paths) do
    table.insert(dirs, vim.fn.expand(path))
  end

  return dirs
end

---Check if file exists
---@param path string
---@return boolean
local function file_exists(path)
  return vim.fn.filereadable(path) == 1
end

---Try to resolve path by checking it directly and in search directories
---@param path_fragment string
---@param search_dirs table
---@return string|nil
local function try_direct_match(path_fragment, search_dirs)
  -- Try absolute path first
  if path_fragment:sub(1, 1) == "/" and file_exists(path_fragment) then
    return path_fragment
  end

  -- Try relative to each search directory
  for _, dir in ipairs(search_dirs) do
    local full_path = dir .. "/" .. path_fragment
    if file_exists(full_path) then
      return vim.fn.fnamemodify(full_path, ":p")
    end
  end

  return nil
end

---Find files matching a pattern in a directory (recursive)
---@param dir string
---@param pattern string
---@param max_depth number
---@return table
local function find_files_matching(dir, pattern, max_depth)
  max_depth = max_depth or 5
  local matches = {}

  -- Escape special characters in pattern for vim glob
  local glob_pattern = dir .. "/**/" .. pattern

  -- Use vim's globpath for efficient search
  local found = vim.fn.globpath(dir, "**/" .. pattern, 0, 1)

  for _, path in ipairs(found) do
    if file_exists(path) then
      table.insert(matches, vim.fn.fnamemodify(path, ":p"))
    end
  end

  return matches
end

---Score a path match based on how well it matches the fragment
---@param full_path string
---@param fragment string
---@return number
local function score_match(full_path, fragment)
  local score = 0

  -- Exact match gets highest score
  if full_path:match(fragment .. "$") then
    score = score + 100
  end

  -- Count matching path segments
  local fragment_parts = vim.split(fragment, "/")
  local path_parts = vim.split(full_path, "/")

  local matching_segments = 0
  for i = #fragment_parts, 1, -1 do
    local frag_part = fragment_parts[i]
    local path_idx = #path_parts - (#fragment_parts - i)

    if path_idx > 0 and path_parts[path_idx] == frag_part then
      matching_segments = matching_segments + 1
    else
      break
    end
  end

  score = score + (matching_segments * 10)

  -- Prefer shorter paths (less nested)
  score = score - (#path_parts * 0.1)

  return score
end

---Fuzzy match file path fragment
---@param path_fragment string
---@param search_dirs table
---@return string|nil
local function fuzzy_match(path_fragment, search_dirs)
  local filename = vim.fn.fnamemodify(path_fragment, ":t")
  local all_matches = {}

  for _, dir in ipairs(search_dirs) do
    local matches = find_files_matching(dir, filename)
    for _, match in ipairs(matches) do
      table.insert(all_matches, match)
    end
  end

  if #all_matches == 0 then
    return nil
  end

  -- Score all matches and pick the best one
  local best_match = nil
  local best_score = -1

  for _, match in ipairs(all_matches) do
    local score = score_match(match, path_fragment)
    if score > best_score then
      best_score = score
      best_match = match
    end
  end

  return best_match
end

---Resolve a file path fragment to an absolute path
---@param path_fragment string
---@return string|nil
M.resolve_file = function(path_fragment)
  if not path_fragment or path_fragment == "" then
    return nil
  end

  -- Check cache first
  if cache[path_fragment] then
    return cache[path_fragment]
  end

  local search_dirs = get_search_dirs()

  -- Try direct match first (faster)
  local resolved = try_direct_match(path_fragment, search_dirs)

  -- Fall back to fuzzy matching if direct match fails
  if not resolved then
    resolved = fuzzy_match(path_fragment, search_dirs)
  end

  -- Cache the result
  if resolved then
    cache[path_fragment] = resolved
  end

  return resolved
end

---Resolve multiple frames
---@param frames table
---@return table
M.resolve_frames = function(frames)
  local resolved = {}

  for _, frame in ipairs(frames) do
    local resolved_frame = vim.deepcopy(frame)

    if frame.file_path then
      resolved_frame.resolved_path = M.resolve_file(frame.file_path)
    end

    table.insert(resolved, resolved_frame)
  end

  return resolved
end

---Clear the resolution cache
M.clear_cache = function()
  cache = {}
end

return M
