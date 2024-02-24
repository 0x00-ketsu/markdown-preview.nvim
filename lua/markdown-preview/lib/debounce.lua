local M = {}

---@param fn function 'Callback to call once timeout expires'
---@param timeout integer 'Timeout in ms'
M.debounce = function(fn, timeout)
  local queued = false

  local function inner_debounce()
    if not queued then
      vim.defer_fn(function()
        queued = false
        fn()
      end, timeout)
      queued = true
    end
  end

  return inner_debounce
end

return M
