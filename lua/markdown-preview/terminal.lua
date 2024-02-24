local api = vim.api
local fn = vim.fn
local vl = vim.loop

local config = require('markdown-preview.config')
local debounce = require('markdown-preview.lib.debounce')
local file = require('markdown-preview.utils.file')
local notify = require('markdown-preview.utils.notify')
local window = require('markdown-preview.lib.window')

---Create tmp file and write buffer lines to it.
---
---@return string
local function tmp_file()
  local bufnr = api.nvim_win_get_buf(vim.g.mp_parent_winnr)
  local lines = api.nvim_buf_get_lines(bufnr, 0, api.nvim_buf_line_count(bufnr), false)
  if vim.tbl_isempty(lines) then
    notify.error('Current buffer is empty')
    return ''
  end
  local tmp = vim.fn.tempname() .. '.md'
  vim.fn.writefile(lines, tmp)
  return tmp
end

local function safe_close(h)
  if not h:is_closing() then
    h:close()
  end
end

---Stop job for term
---
local function stop_job()
  if job == nil then
    return
  end

  if not job.stdout == nil then
    job.stdout:read_stop()
    safe_close(job.stdout)
  end

  if not job.stderr == nil then
    job.stderr:read_stop()
    safe_close(job.stderr)
  end

  if not job.handle == nil then
    safe_close(job.handle)
  end

  job = nil
end

local M = {}

---@package
M._do_refresh = function()
  M.debounced_refresh()
end

M.load_autocmds = function()
  ---@type mp.config.term.reload
  local term_reload_opts = config.opts.term.reload
  if not term_reload_opts.enable then
    return
  end

  local delay = term_reload_opts.delay
  if delay == 0 then
    M.debounced_refresh = M.refresh_actually
  else
    M.debounced_refresh = debounce.debounce(M.refresh_actually, delay)
  end

  local events = term_reload_opts.events
  local reload_events = table.concat(events, ',')
  local md_exts = {
    'md',
    'markdown',
    'mkd',
    'mkdn',
    'mdwn',
    'mdown',
    'mdtxt',
    'mdtext',
    'rmd',
    'wiki',
  }
  local fts = ''
  for idx, ext in ipairs(md_exts) do
    if idx == #md_exts then
      fts = fts .. string.format('*.%s', ext)
    else
      fts = fts .. string.format('*.%s', ext) .. ','
    end
  end
  api.nvim_command('augroup MP')
  api.nvim_command(
    [[ au ]]
      .. reload_events
      .. [[ ]]
      .. fts
      .. [[ execute "lua require('markdown-preview.action').refresh()" ]]
  )
  api.nvim_command(
    [[ au QuitPre ]]
      .. [[ ]]
      .. fts
      .. [[ execute "lua require('markdown-preview.action').close()" ]]
  )
  api.nvim_command('augroup END')
end

M.unload_autocmds = function()
  api.nvim_command('augroup MP')
  api.nvim_command('au!')
  api.nvim_command('augroup END')
end

---Create an instance of Term class.
---
---@return mp.term
M.create = function()
  vim.g.mp_parent_winnr = api.nvim_get_current_win()

  local term = M:new()
  return term
end

---Declare Term class.
---
---@return mp.term
function M:new()
  local this = {}
  setmetatable(this, self)
  self.__index = self
  return this
end

---Setup.
---
function M:setup()
  ---@type mp.config.term
  local term_opts = config.opts.term

  -- options
  local win_opts = { number = false, relativenumber = false, foldenable = false, wrap = false }
  local buf_opts = { bufhidden = 'wipe', filetype = 'mp' }
  local winnr, bufnr = window.open_normal_win(term_opts['direction'], win_opts, buf_opts)
  api.nvim_buf_set_name(bufnr, 'markdown-preview')

  vim.g.mp_winnr = winnr
  vim.g.mp_bufnr = bufnr

  -- keymaps
  local key_bindings = term_opts.keys
  for action, keys in pairs(key_bindings) do
    if type(keys) == 'string' then
      keys = { keys }
    end

    if vim.g.mp_bufnr ~= nil then
      for _, key in pairs(keys) do
        api.nvim_buf_set_keymap(
          vim.g.mp_bufnr,
          'n',
          key,
          [[<cmd>lua require('markdown-preview.action').do_action(']] .. action .. [[')<cr>]],
          { silent = true, noremap = true, nowait = true }
        )
      end
    end
  end
end

---Refresh a terminal window.
---
function M:refresh()
  M._do_refresh()
end

---Open a terminal window and display glow generated contents.
---
function M:open()
  if not file.is_markdown_filetype(vim.bo.filetype) then
    notify.error('Preview only works on markdown files.')
    return
  end

  if self:is_open() then
    notify.error('Markdown preview window is already exist.')
    return
  end

  M.load_autocmds()

  self:setup()
  self:render()
end

function M.refresh_actually()
  if not M:is_open() then
    notify.error('No markdown preview is not exist.')
    return
  end

  M:_remove_tmpfile()
  M:render()
end

---Display glow generated contents.
---
function M:render()
  local tf = tmp_file()
  if #tf < 1 then
    notify.error('Create temporary file failed.')
    return
  end
  self.tf = tf

  local glow_exec = config.get_glow_exec()
  local style = config.get_style()
  local cmd_args = { glow_exec, '-s', style, self.tf }

  self:unlock()
  local chan = api.nvim_open_term(vim.g.mp_bufnr, {})
  -- callbacks for handling output from process
  local schedule = {
    on_stdout = function(err, data)
      if err then
        notify.error('Failed render with error: ' .. vim.inspect(err))
      end
      if data then
        local lines = vim.split(data, '\n', {})
        for _, d in ipairs(lines) do
          api.nvim_chan_send(chan, d .. '\r\n')
        end
      end
    end,
    on_exit = function()
      stop_job()
    end,
  }

  -- setup pipes
  job = { stdout = vl.new_pipe(false), stderr = vl.new_pipe(false) }

  local cmd = table.remove(cmd_args, 1)
  job.handle = vl.spawn(cmd, {
    args = cmd_args,
    stdio = { nil, job.stdout, job.stderr },
  }, vim.schedule_wrap(schedule.on_exit))
  vl.read_start(job.stdout, vim.schedule_wrap(schedule.on_stdout))
  vl.read_start(job.stderr, vim.schedule_wrap(schedule.on_stdout))

  self:lock()

  -- back to markdown file buffer
  api.nvim_set_current_win(vim.g.mp_parent_winnr)
end

---
---Lock Term buffer
---
function M:lock()
  api.nvim_buf_set_option(vim.g.mp_bufnr, 'readonly', true)
  api.nvim_buf_set_option(vim.g.mp_bufnr, 'modifiable', false)
end

---Unlock Term buffer
---
function M:unlock()
  api.nvim_buf_set_option(vim.g.mp_bufnr, 'modifiable', true)
  api.nvim_buf_set_option(vim.g.mp_bufnr, 'readonly', false)
end

---Close opened terminal window.
---
function M:close()
  if self:is_open() and api.nvim_win_is_valid(vim.g.mp_winnr) then
    api.nvim_win_close(vim.g.mp_winnr, true)
    M.unload_autocmds()
  end

  self:_remove_tmpfile()
end

---Check term window is opened.
---
---@return boolean
function M:is_open()
  if not vim.g.mp_winnr then
    return false
  end

  local win_type = fn.win_gettype(vim.g.mp_winnr)
  local win_open = win_type == '' or win_type == 'popup'
  return win_open and api.nvim_win_get_buf(vim.g.mp_winnr) == vim.g.mp_bufnr
end

---@package
function M:_remove_tmpfile()
  if self.tf ~= nil then
    os.remove(self.tf)
  end
end

---@package
function M:_stop_job()
  if self.job_id == nil then
    return
  end

  fn.jobstop(self.job_id)
  self.job_id = nil
end

return M
