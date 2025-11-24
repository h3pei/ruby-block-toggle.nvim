---@class RubyBlockToggle.Config
---@field log_level number|false Minimum log level for notifications (vim.log.levels.* or false to disable)

---@class RubyBlockToggle
---@field config RubyBlockToggle.Config Plugin configuration
local M = {}

local utils = require("ruby-block-toggle.utils")

-- Default configuration
M.config = {
  log_level = vim.log.levels.WARN, -- Show WARN and above (INFO, WARN, ERROR)
}

--- Customize plugin configuration (optional)
---@param opts RubyBlockToggle.Config|nil User configuration
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

--- Check if current filetype is Ruby
---@return boolean true if filetype is ruby
local function is_valid_filetype()
  return vim.bo.filetype == "ruby"
end

--- Check if nvim-treesitter and Ruby parser are available
---@return boolean true if dependencies are satisfied
local function check_dependencies()
  -- nvim-treesitter
  local has_ts, _ = pcall(require, "nvim-treesitter")
  if not has_ts then
    utils.notify_error("nvim-treesitter is required. Please install it.")
    return false
  end

  -- Ruby parser
  local has_parser = pcall(vim.treesitter.get_parser, 0, "ruby")
  if not has_parser then
    utils.notify_error("Ruby parser not found. Run :TSInstall ruby")
    return false
  end

  return true
end

--- Main function
--- Toggle Ruby block notation between do~end and {}
function M.toggle()
  -- Check filetype
  if not is_valid_filetype() then
    utils.notify_warn(string.format("RubyBlockToggle only works in Ruby files (current: %s)", vim.bo.filetype))
    return
  end

  -- Check dependencies
  if not check_dependencies() then
    return
  end

  -- Execute toggle with error handling
  local ok, err = pcall(function()
    local toggle = require("ruby-block-toggle.toggle")
    toggle.execute()
  end)

  if not ok then
    utils.notify_error(string.format("Toggle failed: %s", err))
  end
end

return M
