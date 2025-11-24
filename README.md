# ruby-block-toggle.nvim

Toggle Ruby blocks between `do...end` and `{}` instantly.

**`do...end`  ⇄  `{}`**

![ruby-block-toggle-demo](https://github.com/user-attachments/assets/cc204486-d4fa-4e24-84da-742b86718301)

**Multi-line block**

```ruby
items.each { |item|
  puts item
}
```
↕
```ruby
items.each do |item|
  puts item
end
```

**Single-line block**
```ruby
items.map do |x| x * 2 end
```
↕
```ruby
items.map { |x| x * 2 }
```

**Nested blocks** ([smart detection](#block-detection))
```ruby
items.each { |item|
  item.process do
    puts item
  end
}
```
↕
```ruby
items.each do |item|
  item.process do
    puts item
  end
end
```

## Features

- **One command**: No configuration required
- **Smart detection**: Intuitively finds the right block
- **Treesitter-powered**: Accurate parsing, no regex hacks

## Requirements

- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) with Ruby parser (Run `:TSInstall ruby`)

## Installation

```lua
-- lazy.nvim
{
  'h3pei/ruby-block-toggle.nvim',
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  ft = 'ruby',
  opts = {},
}
```

<details>
<summary>Other package managers</summary>

```vim
" vim-plug
Plug 'nvim-treesitter/nvim-treesitter'
Plug 'h3pei/ruby-block-toggle.nvim'
```

</details>

## Usage

`:RubyBlockToggle` — that's it!

Example keymap:

```lua
vim.keymap.set('n', '<leader>rb', '<cmd>RubyBlockToggle<cr>', { desc = 'Toggle Ruby block' })
```

## Block Detection

The plugin uses an intelligent strategy to find the right block:

1. **Cursor line priority** — If a block starts on the cursor line, that block is selected
   - For nested blocks on the same line, the innermost block is chosen
2. **Parent traversal** — If no block starts on the cursor line, traverse upward to find the nearest parent block
3. **Nearest fallback** — If neither finds a block, select the closest block by distance

```ruby
items.each do |item|         # ← cursor here: toggles `each`
                             # ← cursor here: toggles `each` (parent)
  item.process do            # ← cursor here: toggles `process`
    puts item                # ← cursor here: toggles `process` (parent)
  end
end
```
