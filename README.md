# ruby-block-toggle.nvim

Toggle Ruby blocks between `do...end` and `{}` instantly.

```
do...end  ⇄  { }
```

```ruby
items.each do |item|        items.each { |item|
  puts item              ⇄    puts item
end                         }
```

## Features

- **One command** — No configuration required
- **Smart detection** — Finds the nearest block automatically
- **Treesitter-powered** — Accurate parsing, no regex hacks
- Preserves indentation and comments

## Requirements

- Neovim >= 0.7
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
- Ruby parser (`:TSInstall ruby`)

## Installation

```lua
-- lazy.nvim
{
  'h3pei/ruby-block-toggle.nvim',
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  ft = 'ruby',
  config = true,
}
```

<details>
<summary>Other package managers</summary>

```vim
" vim-plug
Plug 'nvim-treesitter/nvim-treesitter'
Plug 'h3pei/ruby-block-toggle.nvim'
```

```lua
-- packer.nvim
use {
  'h3pei/ruby-block-toggle.nvim',
  requires = { 'nvim-treesitter/nvim-treesitter' },
  ft = 'ruby',
  config = function() require('ruby-block-toggle').setup() end
}
```

</details>

## Usage

`:RubyBlockToggle` — that's it.

Recommended keymap:

```lua
vim.keymap.set('n', '<leader>b', '<cmd>RubyBlockToggle<cr>', { desc = 'Toggle Ruby block' })
```

## License

MIT
