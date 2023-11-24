local config = require('markdown-preview.config')
local notify = require('markdown-preview.utils.notify')
local terminal = require('markdown-preview.term')
local validator = require('markdown-preview.utils.validator')

local M = {}

---@type mp.term
local term

---@param opts mp.config
M.setup = function(opts)
  config.setup(opts)

  local ok, msg = validator.inspect()
  if not ok then
    notify.error(msg)
    return
  end
end

M.open = function()
  term = terminal.create()
  term:open()
end

M.close = function()
  if M._valid_term() then
    ---@diagnostic disable-next-line:need-check-nil
    term:close()
  end
end

M.toggle = function()
  if term == nil or not term:is_open() then
    M.open()
  else
    M.close()
  end
end

M.refresh = function()
  if term ~= nil and term:is_open() then
    term:refresh()
  end
end

M.do_action = function(action)
  if not M._valid_term() then
    return
  end

  if action == 'close' then
    M.close()
  elseif action == 'refresh' then
    M.refresh()
  end
end

---@package
---@return boolean
M._valid_term = function()
  if term == nil or not term:is_open() then
    notify.error('No active terminal.')
    return false
  end

  return true
end

return M
