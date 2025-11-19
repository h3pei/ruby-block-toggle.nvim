local M = {}

--- Check log level and display notification
---@param message string Notification message
---@param level number Log level
local function notify(message, level)
  -- Lazy load config to avoid circular dependency
  local config = require('ruby-block-toggle').config

  -- Don't notify if log_level is false
  if config.log_level == false then
    return
  end

  -- Only notify if level is greater than or equal to configured log_level
  if level >= config.log_level then
    vim.notify(message, level, { title = 'Ruby Block Toggle' })
  end
end

--- Display INFO level notification
---@param message string Notification message
function M.notify_info(message)
  notify(message, vim.log.levels.INFO)
end

--- Display WARN level notification
---@param message string Notification message
function M.notify_warn(message)
  notify(message, vim.log.levels.WARN)
end

--- Display ERROR level notification
---@param message string Notification message
function M.notify_error(message)
  notify(message, vim.log.levels.ERROR)
end

return M
