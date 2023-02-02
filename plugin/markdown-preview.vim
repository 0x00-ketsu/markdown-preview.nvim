if exists("g:loaded_markdown_preview")
    finish
endif
let g:loaded_markdown_preview = 1

" Register commands
command! MPToggle lua require('markdown-preview').toggle()
command! MPOpen lua require('markdown-preview').open()
command! MPClose lua require('markdown-preview').close()
command! MPRefresh lua require('markdown-preview').refresh()
