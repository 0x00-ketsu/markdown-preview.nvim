# markdown-preview

A Neovim plugin renders markdown file in terminal buffer.

>
> This plugin relys on [Glow](https://github.com/charmbracelet/glow), only work under Linux or Mac.

[video](https://user-images.githubusercontent.com/16932133/216219726-f79645fb-555a-4684-8962-c69e87a7d605.mp4)

## Features

- Open terminal buffer in different direction: `vertical`, `horizontal`.
- Support auto refresh when file content changed.

## Requirements

- Install [Glow](https://github.com/charmbracelet/glow#installation)

## Installation

[Packer](https://github.com/wbthomason/packer.nvim)

```lua
-- Lua
use {
  '0x00-ketsu/markdown-preview.nvim',
  ft = {'md', 'markdown', 'mkd', 'mkdn', 'mdwn', 'mdown', 'mdtxt', 'mdtext', 'rmd', 'wiki'},
  config = function()
    require('markdown-preview').setup {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the setup section below
    },
  end
}
```

## Setup

Following defaults:

```lua
local mp = require('markdown-preview')
mp.setup(
    {
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
)
```

## Commands

- `:MPToggle`: toggle markdown preview open or close.
- `:MPOpen`: open markdown preview window.
- `:MPClose`: close markdown preview window.
- `:MPRefresh`: refresh markdown preview window.

## Thanks

[glow.nvim](https://github.com/ellisonleao/glow.nvim)

## License

MIT
