local config = require('markdown-preview.config')

local M = {}

---Display a notification to the user.
---
---@param message string
---@param level number | nil
M.notify = function(message, level)
  if type(message) ~= 'string' then
    return
  end

  local ok, notify = pcall(require, 'notify')
  if ok then
    notify(message, level, { title = config.plugin_name })
  else
    vim.notify(message, level)
  end
end

---Send success message to the user.
---
---@param message string
M.success = function(message)
  M.notify(message, vim.log.levels.INFO)
end

---Send failed message to the user.
---
---@param message string
M.error = function(message)
  M.notify(message, vim.log.levels.ERROR)
end

return M
