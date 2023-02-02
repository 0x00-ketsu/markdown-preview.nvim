local api = vim.api

local M = {}

---Create a normal (non-floating) window.
---
---@param direction string `vertical` / `horizontal`
---@param win_opts? table window options: `{name: value}`
---@param buf_opts? table buffer options: `{name: value}`
---@return number 'Window handler'
---@return number 'Buffer handle'
M.open_normal_win = function(direction, win_opts, buf_opts)
  if direction == 'vertical' then
    vim.cmd('vsplit')
  elseif direction == 'horizontal' then
    vim.cmd('split')
  end

  bufnr = api.nvim_create_buf(false, true)
  vim.cmd(string.format("buffer %d", bufnr))

  local winnr = api.nvim_get_current_win()
  if win_opts ~= nil then
    for name, value in pairs(win_opts) do
      api.nvim_win_set_option(winnr, name, value)
    end
  end

  if buf_opts ~= nil then
    for name, value in pairs(buf_opts) do
      api.nvim_buf_set_option(bufnr, name, value)
    end
  end

  return winnr, bufnr
end

return M
