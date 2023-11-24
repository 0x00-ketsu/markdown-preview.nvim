local fn = vim.fn

local config = require('markdown-preview.config')

local M = {}

---Pre validation.
---
---@return boolean
---@return string
M.inspect = function()
  local ok, msg = M.validate_os()
  if not ok then
    return false, msg
  end

  local ok, msg = M.validate_glow()
  if not ok then
    return false, msg
  end

  return true, ''
end

---Check current OS type is suit for run this plugin.
---
---@return boolean
---@return string
M.validate_os = function()
  -- validate file format
  local fileformat = vim.bo.fileformat
  local accept_fileformats = { 'unix', 'mac' }
  ---@diagnostic disable-next-line: param-type-mismatch
  if not vim.tbl_contains(accept_fileformats, fileformat) then
    return false, 'Plugin is only work under Linux or Mac.'
  end

  return true, ''
end

---Check if command of `glow` is installed.
---
---@return boolean
---@return string
M.validate_glow = function()
  local exec_path = config.get_glow_exec()
  if fn.executable(exec_path) ~= 1 then
    return false, 'Command `' .. exec_path .. '` is not installed, install `glow` first'
  else
    return true, ''
  end
end

return M
