local config = require('markdown-preview.config')
local notify = require('markdown-preview.utils.notify')
local validator = require('markdown-preview.utils.validator')

local M = {}

---@param opts? mp.config
M.setup = function(opts)
  config.setup(opts)

  local ok, msg = validator.inspect()
  if not ok then
    notify.error(msg)
    return
  end
end

return M
