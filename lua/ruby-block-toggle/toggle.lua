local ts = require('ruby-block-toggle.treesitter')
local utils = require('ruby-block-toggle.utils')

local M = {}

--- Get current indent settings
---@return string Indent string (spaces or tab)
local function get_indent()
  if vim.bo.expandtab then
    return string.rep(' ', vim.bo.shiftwidth)
  else
    return '\t'
  end
end

--- Get indent level of a line
---@param line string Target line
---@return number Indent level
local function get_indent_level(line)
  local indent = line:match('^%s*')
  if vim.bo.expandtab then
    return #indent / vim.bo.shiftwidth
  else
    return #indent:gsub(' ', '')
  end
end

--- Generate indent of specified level
---@param level number Indent level
---@return string Indent string
local function make_indent(level)
  local indent = get_indent()
  return string.rep(indent, level)
end

--- Convert do~end to {}
---@param block_node TSNode Block node
local function convert_doend_to_brace(block_node)
  local bufnr = 0
  local range = ts.get_node_range(block_node)

  -- Get all lines of the block
  local lines = vim.api.nvim_buf_get_lines(bufnr, range.start_row, range.end_row + 1, false)

  if #lines == 0 then
    return
  end

  -- Get indent level from first line
  local base_indent_level = get_indent_level(lines[1])
  local base_indent = make_indent(base_indent_level)

  -- Parse and convert each line
  local new_lines = {}
  local first_line = lines[1]

  -- First line: Replace "do" with "{"
  -- "do |x|" -> "{ |x|" (preserve trailing space)
  -- "do" -> "{" (no trailing space)
  local converted_first = first_line:gsub('%s*do(%s*)', ' {%1', 1)
  table.insert(new_lines, converted_first)

  -- Middle lines: Keep as is (preserve comments and indentation)
  for i = 2, #lines - 1 do
    table.insert(new_lines, lines[i])
  end

  -- Last line: Replace "end" with "}"
  if #lines > 1 then
    local last_line = lines[#lines]
    local converted_last = last_line:gsub('%s*end%s*$', base_indent .. '}', 1)
    table.insert(new_lines, converted_last)
  end

  -- Write to buffer
  vim.api.nvim_buf_set_lines(bufnr, range.start_row, range.end_row + 1, false, new_lines)
end

--- Convert {} to do~end
---@param block_node TSNode Block node
local function convert_brace_to_doend(block_node)
  local bufnr = 0
  local range = ts.get_node_range(block_node)

  -- Get all lines of the block
  local lines = vim.api.nvim_buf_get_lines(bufnr, range.start_row, range.end_row + 1, false)

  if #lines == 0 then
    return
  end

  -- Get indent level from first line
  local base_indent_level = get_indent_level(lines[1])
  local base_indent = make_indent(base_indent_level)

  -- Parse and convert each line
  local new_lines = {}
  local first_line = lines[1]

  -- First line: Replace "{" with "do"
  -- "{ |x|" -> "do |x|" (preserve trailing space)
  -- "{" -> "do" (no trailing space)
  local converted_first = first_line:gsub('%s*{(%s*)', ' do%1', 1)
  table.insert(new_lines, converted_first)

  -- Middle lines: Keep as is (preserve comments)
  for i = 2, #lines - 1 do
    table.insert(new_lines, lines[i])
  end

  -- Last line: Replace "}" with "end"
  if #lines > 1 then
    local last_line = lines[#lines]
    local converted_last = last_line:gsub('%s*}%s*$', base_indent .. 'end', 1)
    table.insert(new_lines, converted_last)
  end

  -- Write to buffer
  vim.api.nvim_buf_set_lines(bufnr, range.start_row, range.end_row + 1, false, new_lines)
end

--- Execute toggle
--- Detect Ruby block at cursor position and convert it
function M.execute()
  -- Detect nearest block node
  local block_node, block_type = ts.find_nearest_block()

  if not block_node then
    utils.notify_warn(block_type or 'No Ruby block found near cursor')
    return
  end

  -- Convert based on block type
  if block_type == 'do_block' then
    convert_doend_to_brace(block_node)
    utils.notify_info('Converted do~end to {}')
  elseif block_type == 'block' then
    convert_brace_to_doend(block_node)
    utils.notify_info('Converted {} to do~end')
  else
    utils.notify_error(string.format('Unknown block type: %s', block_type))
  end
end

return M
