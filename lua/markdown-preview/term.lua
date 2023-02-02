local api = vim.api
local fn = vim.fn

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
        au ]] .. reload_events .. [[ ]] .. aupats .. [[ execute "lua require('markdown-preview').refresh()"
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
  self:_stop_job()

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
    return
  end
  self.tf = tf

  local glow_exec = config.get_glow_exec()
  local background = api.nvim_get_option('background') == 'light' and 'light' or 'dark'
  local cmd = string.format('%s -s %s %s', glow_exec, background, self.tf)

  self:unlock()
  local chan = api.nvim_open_term(vim.g.mp_bufnr, {})
  self.job_id = fn.jobstart(
      cmd, {
        on_stdout = function(_, data, _)
          for _, d in ipairs(data) do
            api.nvim_chan_send(chan, d .. '\r\n')
          end
        end
      }
  )
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
  self:_stop_job()

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
