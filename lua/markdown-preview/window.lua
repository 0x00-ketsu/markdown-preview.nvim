local api = vim.api

---Calculate window `anchor`.
---
---@param width integer
---@param height integer
---@return string
local function decide_anchor(width, height)
  local row = vim.fn.winline() > vim.fn.winheight(0) - height and 'S' or 'N'
  local col = vim.fn.wincol() > vim.fn.winwidth(0) - width and 'E' or 'W'
  return row .. col
end

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

---Create a new float window.
---
---@param is_enter_win? boolean default is `false`
---@param opts? table
---@return number 'Window handler'
M.open_float_win = function(is_enter_win, opts)
  opts = opts or {}
  is_enter_win = is_enter_win or false

  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

  local win_width = opts.width or 30
  local win_height = opts.height or 5
  local opts = {
    style = opts.style or 'minimal',
    relative = opts.style or 'cursor',
    anchor = decide_anchor(win_width, win_height),
    width = win_width,
    height = win_height,
    row = 1,
    col = 0,
    border = 'rounded'
  }
  return api.nvim_open_win(buf, is_enter_win, opts)
end

return M
