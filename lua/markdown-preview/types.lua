---@meta

---
---NOTE: Types for Global
---

---@class mp.global
---@field vim.g.mp_parent_winnr number 'Parent window handler of Markdown preview terminal window'
---@field vim.g.mp_winnr number 'Markdown preview terminal window handler'
---@field vim.g.mp_bufnr number 'Markdown preview terminal buffer handler'

---
---NOTE: Types for Configuration
---

---@class mp.config
---@field glow mp.config.glow
---@field term mp.config.term

---@class mp.config.glow
---@field exec_path string
---@field style string

---@class mp.config.term
---@field direction string
---@field keys mp.config.term.keys
---@field reload mp.config.term.reload

---@class mp.config.term.keys
---@field close table
---@field refresh string

---@class mp.config.term.reload
---@field enable boolean
---@field events table

---
---NOTE: Types for Term
---

---@class mp.term
---@field job_id number 'job id'
---@field tf string 'template filename'
---@field public new function
---@field public setup function
---@field public open function
---@field public close function
---@field public toggle function
---@field public refresh function
---@field public is_open function
---@field public render function
---@field public lock function
---@field public unlock function
