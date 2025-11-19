-- Test helper functions for ruby-block-toggle.nvim
local M = {}

--- Setup a Ruby buffer with given content
---@param content string Ruby code content
---@param cursor_pos table|nil Cursor position {row, col} (1-indexed row, 0-indexed col)
---@return number bufnr Buffer number
function M.setup_ruby_buffer(content, cursor_pos)
  -- Create new scratch buffer
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(bufnr)

  -- Set content
  local lines = vim.split(content, '\n', { plain = true })
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  -- Set filetype to Ruby
  vim.bo[bufnr].filetype = 'ruby'

  -- Set cursor position if provided
  if cursor_pos then
    vim.api.nvim_win_set_cursor(0, cursor_pos)
  end

  return bufnr
end

--- Get buffer content as a single string
---@param bufnr number|nil Buffer number (default: current buffer)
---@return string Content of the buffer
function M.get_buffer_content(bufnr)
  bufnr = bufnr or 0
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  return table.concat(lines, '\n')
end

--- Check if nvim-treesitter and Ruby parser are available
---@return boolean available True if dependencies are satisfied
function M.check_dependencies()
  -- Check nvim-treesitter
  local has_ts = pcall(require, 'nvim-treesitter')
  if not has_ts then
    return false
  end

  -- Check Ruby parser
  local has_parser = pcall(vim.treesitter.get_parser, 0, 'ruby')
  if not has_parser then
    return false
  end

  return true
end

--- Cleanup buffer after test
---@param bufnr number|nil Buffer number (default: current buffer)
function M.cleanup_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end
end

return M
