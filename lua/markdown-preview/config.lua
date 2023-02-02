---@class ConfigOption
---@field glow table
---@field term table
local defaults = {
  glow = {
    -- When find executable path of `glow` failed (from PATH), use this value instead
    exec_path = ''
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

---Assign options
---
---@param opts table
M.setup = function(opts)
  M.opts = vim.tbl_deep_extend('force', {}, defaults, opts or {})
end

M.setup {}

return M
