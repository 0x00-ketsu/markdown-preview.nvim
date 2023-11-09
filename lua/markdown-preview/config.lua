---@type mp.config
local defaults = {
  glow = {
    -- When find executable path of `glow` failed (from PATH), use this value instead
    exec_path = '',
    style = '' -- Path to glamour JSON style file
  },
  -- Markdown preview term
  term = {
    -- reload term when rendered markdown file changed
    reload = {
      enable = true,
      events = {'InsertLeave', 'TextChanged'},
    },
    direction = 'vertical', -- choices: vertical / horizontal
    keys = {
     close = {'q', '<Esc>'},
     refresh = 'r',
    }
  }
}

local M = {plugin_name = 'markdown-preview.nvim'}

---Get glow exec path
---
---@return string
M.get_glow_exec = function()
  local glow = M.opts.glow or {}
  local exec_path = ''
  if string.len(glow['exec_path']) > 0 then
    exec_path = glow['exec_path']
  else
    exec_path = 'glow'
  end
  return exec_path
end

---Get style
---
---@return string
M.get_style = function()
  local glow = M.opts.glow or {}
  if string.len(glow['style']) > 0 then
    return glow['style']
  else
    return vim.api.nvim_get_option('background') == 'light' and 'light' or 'dark'
  end
end

---Assign options
---
---@param opts mp.config?
M.setup = function(opts)
  M.opts = vim.tbl_deep_extend('force', {}, defaults, opts or {})
end

M.setup()

return M
