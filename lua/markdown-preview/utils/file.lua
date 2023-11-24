local M = {}

---Check filetype if is `markdown`.
---
---@param ft string
---@return boolean
M.is_markdown_filetype = function(ft)
  local allowed_fts = {
    'markdown',
    'markdown.pandoc',
    'markdown.gfm',
    'wiki',
    'vimwiki',
    'telekasten',
  }
  ---@diagnostic disable-next-line: param-type-mismatch
  if not vim.tbl_contains(allowed_fts, ft) then
    return false
  end

  return true
end

return M
