---@class NodeRange
---@field start_row number Start row (0-indexed)
---@field start_col number Start column (0-indexed)
---@field end_row number End row (0-indexed)
---@field end_col number End column (0-indexed)

local M = {}

-- Ruby block node types
M.BLOCK_TYPES = {
  do_block = true,
  block = true,
}

--- Get node at cursor position
---@return TSNode|nil Node
---@return string|nil Error message
function M.get_node_at_cursor()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2] -- 0-indexed

  -- Get Ruby parser
  local ok, parser = pcall(vim.treesitter.get_parser, 0, 'ruby')
  if not ok or not parser then
    return nil, 'Failed to get Ruby parser'
  end

  -- Parse syntax tree
  local trees = parser:parse()
  if not trees or #trees == 0 then
    return nil, 'Failed to parse buffer'
  end

  local tree = trees[1]
  if not tree then
    return nil, 'Failed to get syntax tree'
  end

  local root = tree:root()

  -- Get node at cursor position
  return root:named_descendant_for_range(row, col, row, col)
end

--- Search for block node in parent direction
---@param start_node TSNode|nil Starting node
---@return TSNode|nil Block node
---@return string|nil Block type ('do_block' or 'block')
function M.find_block_node(start_node)
  if not start_node then
    return nil
  end

  ---@type TSNode|nil
  local node = start_node
  while node do
    local node_type = node:type()
    if M.BLOCK_TYPES[node_type] then
      return node, node_type
    end
    node = node:parent()
  end

  return nil, nil
end

--- Calculate distance from cursor position (in lines)
---@param cursor_row number Cursor row (0-indexed)
---@param cursor_col number Cursor column (0-indexed)
---@param node TSNode Target node
---@return number Distance
local function calculate_distance(cursor_row, cursor_col, node)
  local start_row, start_col, end_row, end_col = node:range()

  -- Distance is 0 if cursor is inside the node
  if cursor_row >= start_row and cursor_row <= end_row then
    if cursor_row == start_row and cursor_col < start_col then
      return math.abs(start_col - cursor_col)
    elseif cursor_row == end_row and cursor_col > end_col then
      return math.abs(cursor_col - end_col)
    else
      return 0
    end
  end

  -- Calculate distance before/after the node
  if cursor_row < start_row then
    return (start_row - cursor_row) * 1000 + math.abs(start_col - cursor_col)
  else
    return (cursor_row - end_row) * 1000 + math.abs(cursor_col - end_col)
  end
end

--- Detect nearest block node from entire buffer
---
--- This function uses a three-stage priority strategy to find the most appropriate block:
---
--- 1. **Cursor line priority**: First, search for blocks that start on the current cursor line.
---    - If multiple blocks start on the same line, select the smallest one (innermost block).
---    - This ensures that when the cursor is on a line like "array.each do |x|",
---      the block starting on that line is selected.
---
--- 2. **Parent traversal**: If no block starts on the cursor line, traverse upward from
---    the cursor position through parent nodes to find the nearest containing block.
---    - This is useful when the cursor is inside a block but not on its starting line.
---    - Example: cursor on "puts 'hello'" inside "some_process do ... end" will select
---      the some_process block.
---
--- 3. **Nearest block fallback**: If neither of the above finds a block, search the
---    entire buffer for the closest block based on distance calculation.
---    - This handles cases where the cursor is outside any block.
---
---@return TSNode|nil Block node (do_block or block type from Ruby Treesitter)
---@return string|nil Block type ('do_block' or 'block') or error message if not found
function M.find_nearest_block()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cursor_row, cursor_col = cursor[1] - 1, cursor[2]

  -- Get blocks from entire buffer
  local ok_parser, parser = pcall(vim.treesitter.get_parser, 0, 'ruby')
  if not ok_parser or not parser then
    return nil, 'Failed to get Ruby parser'
  end

  local trees = parser:parse()
  if not trees or #trees == 0 then
    return nil, 'Failed to parse buffer'
  end

  local tree = trees[1]
  if not tree then
    return nil, 'Failed to get syntax tree'
  end
  local root = tree:root()

  -- Use Treesitter query to search for blocks
  local query_str = [[
    (do_block) @block
    (block) @block
  ]]

  local ok, query = pcall(vim.treesitter.query.parse, 'ruby', query_str)
  if not ok then
    return nil, 'Failed to parse Treesitter query'
  end

  -- 1. Search for blocks starting on cursor line (priority)
  local blocks_on_cursor_line = {}
  for _, capture_node in query:iter_captures(root, 0) do
    local start_row = capture_node:range()
    if start_row == cursor_row then
      table.insert(blocks_on_cursor_line, capture_node)
    end
  end

  -- If multiple blocks start on cursor line, select the smallest one
  if #blocks_on_cursor_line > 0 then
    local smallest_block = blocks_on_cursor_line[1]
    local smallest_size = math.huge

    for _, block in ipairs(blocks_on_cursor_line) do
      local start_row, _, end_row, _ = block:range()
      local size = end_row - start_row
      if size < smallest_size then
        smallest_size = size
        smallest_block = block
      end
    end

    return smallest_block, smallest_block:type()
  end

  -- 2. Search in parent direction from cursor position
  local node, err = M.get_node_at_cursor()
  if not node then
    return nil, err
  end

  local block_node, block_type = M.find_block_node(node)
  if block_node then
    return block_node, block_type
  end

  -- 3. Search for nearest block from entire buffer
  local nearest_block = nil
  local min_distance = math.huge

  for _, capture_node in query:iter_captures(root, 0) do
    local distance = calculate_distance(cursor_row, cursor_col, capture_node)
    if distance < min_distance then
      min_distance = distance
      nearest_block = capture_node
    end
  end

  if nearest_block then
    return nearest_block, nearest_block:type()
  end

  return nil, 'No Ruby block found near cursor'
end

--- Get text range of node
---@param node TSNode Target node
---@return NodeRange Range information
function M.get_node_range(node)
  local start_row, start_col, end_row, end_col = node:range()
  return {
    start_row = start_row,
    start_col = start_col,
    end_row = end_row,
    end_col = end_col,
  }
end

return M
