local api = vim.api
local fn = vim.fn
local vl = vim.loop

local config = require('markdown-preview.config')
local window = require('markdown-preview.window')
local file = require('markdown-preview.utils.file')
local notify = require('markdown-preview.utils.notify')

---Create tmp file and write buffer lines to it.
---
---@return string
local function tmp_file()
  local bufnr = api.nvim_win_get_buf(vim.g.mp_parent_winnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, vim.api.nvim_buf_line_count(bufnr), false)
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

---@class Term
---@field job_id number 'job id'
---@field tf string 'template filename'
local Term = {}

---Create an instance of Term class.
---
---@param opts? ConfigOption
---@return Term
Term.create = function(opts)
  opts = opts or {}

  vim.g.mp_parent_winnr = api.nvim_get_current_win()

  local term = Term:new()
  return term
end

---Declare Term class.
---
---@return Term
function Term:new()
  local this = {}
  setmetatable(this, self)
  self.__index = self
  return this
end

---Setup.
---
function Term:setup()
  local term_opts = config.opts.term

  -- options
  local win_opts = {number = false, relativenumber = false, foldenable = false, wrap = false}
  local buf_opts = {bufhidden = 'wipe', filetype = 'markdownpreview'}
  local winnr, bufnr = window.open_normal_win(term_opts['direction'], win_opts, buf_opts)
  vim.g.mp_winnr = winnr
  vim.g.mp_bufnr = bufnr

  -- keymaps
  local key_bindings = term_opts.keys
  for action, keys in pairs(key_bindings) do
    if type(keys) == 'string' then
      keys = {keys}
    end

    if vim.g.mp_bufnr ~= nil then
      for _, key in pairs(keys) do
        vim.api.nvim_buf_set_keymap(
            vim.g.mp_bufnr, 'n', key,
                [[<cmd>lua require('markdown-preview').do_action(']] .. action .. [[')<cr>]],
                {silent = true, noremap = true, nowait = true}
        )
      end
    end
  end

  -- events
  local term_reload_opts = term_opts.reload
  if term_reload_opts['enable'] then
    local reload_events = table.concat(term_reload_opts['events'] or {}, ',')
    local md_exts = {
      'md', 'markdown', 'mkd', 'mkdn', 'mdwn', 'mdown', 'mdtxt', 'mdtext', 'rmd', 'wiki'
    }
    local aupats = ''
    for idx, ext in ipairs(md_exts) do
      if idx == #md_exts then
        aupats = aupats .. string.format('*.%s', ext)
      else
        aupats = aupats .. string.format('*.%s', ext) .. ','
      end
    end
    api.nvim_exec(
        [[
      aug MP
        au ]] .. reload_events .. [[ ]] .. aupats ..
            [[ execute "lua require('markdown-preview').refresh()"
      aug END
    ]], false
    )
  else
    api.nvim_exec(
        [[
      aug MP
        au!
      aug END
    ]], false
    )
  end
end

---Open a terminal window and display glow generated contents.
---
function Term:open()
  if not file.is_markdown_filetype(vim.bo.filetype) then
    notify.error('Preview only works on markdown files.')
    return
  end

  if self:is_open() then
    notify.error('Markdown preview window is already exist.')
    return
  end

  self:setup()
  self:render()
end

function Term:refresh()
  if not self:is_open() then
    notify.error('No markdown preview is not exist.')
    return
  end

  self:_remove_tmpfile()
  self:render()
end

---Display glow generated contents.
---
function Term:render()
  local tf = tmp_file()
  if #tf < 1 then
    notify.error('Create temporary file failed.')
    return
  end
  self.tf = tf

  local glow_exec = config.get_glow_exec()
  local style = config.get_style()
  local cmd_args = {glow_exec, '-s', style, self.tf}

  self:unlock()
  local chan = api.nvim_open_term(vim.g.mp_bufnr, {})
  -- callbacks for handling output from process
  local schedule = {
    on_stdout = function(err, data)
      if err then
        notify.error('Failed render with error: ' .. vim.inspect(err))
      end
      if data then
        local lines = vim.split(data, "\n", {})
        for _, d in ipairs(lines) do
          api.nvim_chan_send(chan, d .. "\r\n")
        end
      end
    end,
    on_exit = function()
      stop_job()
    end
  }

  -- setup pipes
  job = {stdout = vl.new_pipe(false), stderr = vl.new_pipe(false)}

  local cmd = table.remove(cmd_args, 1)
  -- LuaFormatter off
  job.handle = vl.spawn(
      cmd, {
        args = cmd_args,
        stdio = {nil, job.stdout, job.stderr}
      },
      vim.schedule_wrap(schedule.on_exit)
  )
  -- LuaFormatter on
  vl.read_start(job.stdout, vim.schedule_wrap(schedule.on_stdout))
  vl.read_start(job.stderr, vim.schedule_wrap(schedule.on_stdout))

  -- self.job_id = fn.jobstart(
  --     cmd, {
  --       on_stdout = function(_, data, _)
  --         for _, d in ipairs(data) do
  --           api.nvim_chan_send(chan, d .. '\r\n')
  --         end
  --       end
  --     }
  -- )
  self:lock()

  -- back to markdown file buffer
  api.nvim_set_current_win(vim.g.mp_parent_winnr)
end

---Lock Term buffer
---
function Term:lock()
  api.nvim_buf_set_option(vim.g.mp_bufnr, 'readonly', true)
  api.nvim_buf_set_option(vim.g.mp_bufnr, 'modifiable', false)
end

---Unlock Term buffer
---
function Term:unlock()
  api.nvim_buf_set_option(vim.g.mp_bufnr, 'modifiable', true)
  api.nvim_buf_set_option(vim.g.mp_bufnr, 'readonly', false)
end

---Close opened terminal window.
---
function Term:close()
  if self:is_open() and api.nvim_win_is_valid(vim.g.mp_winnr) then
    api.nvim_win_close(vim.g.mp_winnr, true)
  end

  self:_remove_tmpfile()
end

---Check term window is opened.
---
---@return boolean
function Term:is_open()
  if not vim.g.mp_winnr then
    return false
  end

  local win_type = fn.win_gettype(vim.g.mp_winnr)
  local win_open = win_type == '' or win_type == 'popup'
  return win_open and api.nvim_win_get_buf(vim.g.mp_winnr) == vim.g.mp_bufnr
end

---@package
function Term:_remove_tmpfile()
  if self.tf ~= nil then
    os.remove(self.tf)
  end
end

---@package
function Term:_stop_job()
  if self.job_id == nil then
    return
  end

  fn.jobstop(self.job_id)
  self.job_id = nil
end

return Term
