if exists("g:loaded_markdown_preview")
    finish
endif
let g:loaded_markdown_preview = 1

" Register commands
command! MPRefresh lua require('markdown-preview.action').refresh()
command! MPToggle lua require('markdown-preview.action').toggle()
command! MPOpen lua require('markdown-preview.action').open()
command! MPClose lua require('markdown-preview.action').close()
