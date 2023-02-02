local config = require('markdown-preview.config')
local terminal = require('markdown-preview.term')
local notify = require('markdown-preview.utils.notify')
local validator = require('markdown-preview.utils.validator')

---@class Global 'Plugin declared global variables'
---@field vim.g.mp_parent_winnr number 'Parent window handler of Markdown preview terminal window'
---@field vim.g.mp_winnr number 'Markdown preview terminal window handler'
---@field vim.g.mp_bufnr number 'Markdown preview terminal buffer handler'

local M = {}

---@type Term?
local term

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
