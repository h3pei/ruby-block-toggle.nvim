local ts = require("ruby-block-toggle.treesitter")
local utils = require("ruby-block-toggle.utils")

local M = {}

--- Convert do~end to {}
---@param block_node TSNode Block node
local function convert_doend_to_brace(block_node)
  local bufnr = 0

  -- Get block keywords using Treesitter
  local keywords = ts.get_block_keywords(block_node)
  if not keywords or not keywords.opening_keyword or not keywords.closing_keyword then
    utils.notify_error("Failed to find block keywords")
    return
  end

  local do_node = keywords.opening_keyword
  local end_node = keywords.closing_keyword

  -- Get positions of "do" and "end"
  local do_start_row, do_start_col, do_end_row, do_end_col = do_node:range()
  local end_start_row, end_start_col, end_end_row, end_end_col = end_node:range()

  -- Replace "end" first (to avoid position shifts)
  vim.api.nvim_buf_set_text(bufnr, end_start_row, end_start_col, end_end_row, end_end_col, { "}" })

  -- Replace "do" with "{"
  vim.api.nvim_buf_set_text(bufnr, do_start_row, do_start_col, do_end_row, do_end_col, { "{" })
end

--- Convert {} to do~end
---@param block_node TSNode Block node
local function convert_brace_to_doend(block_node)
  local bufnr = 0

  -- Get block keywords using Treesitter
  local keywords = ts.get_block_keywords(block_node)
  if not keywords or not keywords.opening_keyword or not keywords.closing_keyword then
    utils.notify_error("Failed to find block keywords")
    return
  end

  local brace_open_node = keywords.opening_keyword
  local brace_close_node = keywords.closing_keyword

  -- Get positions of "{" and "}"
  local open_start_row, open_start_col, open_end_row, open_end_col = brace_open_node:range()
  local close_start_row, close_start_col, close_end_row, close_end_col = brace_close_node:range()

  -- Replace "}" first (to avoid position shifts)
  vim.api.nvim_buf_set_text(bufnr, close_start_row, close_start_col, close_end_row, close_end_col, { "end" })

  -- Replace "{" with "do"
  vim.api.nvim_buf_set_text(bufnr, open_start_row, open_start_col, open_end_row, open_end_col, { "do" })
end

--- Execute toggle
--- Detect Ruby block at cursor position and convert it
function M.execute()
  -- Detect nearest block node
  local block_node, block_type = ts.find_nearest_block()

  if not block_node then
    utils.notify_warn(block_type or "No Ruby block found near cursor")
    return
  end

  -- Convert based on block type
  if block_type == "do_block" then
    convert_doend_to_brace(block_node)
    utils.notify_info("Converted do~end to {}")
  elseif block_type == "block" then
    convert_brace_to_doend(block_node)
    utils.notify_info("Converted {} to do~end")
  else
    utils.notify_error(string.format("Unknown block type: %s", block_type))
  end
end

return M
