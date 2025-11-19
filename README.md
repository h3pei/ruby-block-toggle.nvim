# ruby-block-toggle.nvim

A Neovim plugin to toggle Ruby block notation between `do ~ end` and `{}`.

## Features

- Toggle between `do ~ end` and `{}` block syntax
- Works with multi-line blocks
- Preserves indentation and comments
- Finds the nearest block automatically
- Maintains proper Ruby formatting
- Supports Ruby files

## Requirements

- Neovim >= 0.7
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
- Treesitter Ruby parser (`:TSInstall ruby`)

## Installation

### lazy.nvim

```lua
{
  'h3pei/ruby-block-toggle.nvim',
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  ft = 'ruby',
  config = function()
    require('ruby-block-toggle').setup()
  end,
}
```

### vim-plug

```vim
Plug 'nvim-treesitter/nvim-treesitter'
Plug 'h3pei/ruby-block-toggle.nvim'
```

## Usage

### Basic Usage

1. Open a Ruby file
2. Place cursor in or near a block
3. Execute `:RubyBlockToggle` command

### Keymapping

```lua
-- Lua
vim.keymap.set('n', '<Leader>tb', ':RubyBlockToggle<CR>', { desc = 'Toggle Ruby block' })
```

```vim
" VimScript
nnoremap <Leader>tb :RubyBlockToggle<CR>
```

### Examples

#### Converting `do~end` to `{}`

Before:
```ruby
array.each do |item|
  # comment
  puts item
end
```

After:
```ruby
array.each { |item|
  # comment
  puts item
}
```

#### Converting `{}` to `do~end`

Before:
```ruby
array.map { |x|
  x * 2
}
```

After:
```ruby
array.map do |x|
  x * 2
end
```

## Configuration

You can customize the behavior with the following options:

```lua
require('ruby-block-toggle').setup({
  -- Notification log level
  -- vim.log.levels.INFO: Show all notifications
  -- vim.log.levels.WARN: Show warnings and errors (default)
  -- vim.log.levels.ERROR: Show only errors
  -- false: Disable all notifications
  log_level = vim.log.levels.WARN,
})
```

## How It Works

### Block Detection Strategy

The plugin uses an intelligent strategy to select which block to toggle:

1. **Cursor line priority**: If a block starts on the current cursor line, that block is selected
   - For nested blocks on the same line, the innermost (smallest range) block is chosen
2. **Parent traversal**: If no block starts on the cursor line, traverse upward from the cursor position to find the nearest parent block
3. **Nearest block fallback**: If neither approach finds a block, select the closest block by distance

**Example with nested blocks:**
```ruby
members.each do |member|              # Line 1
  some_process(member) do             # Line 2
    puts 'inner block'                # Line 3
                                      # Line 4 (empty)
    other_process(member) do          # Line 5
      puts 'innermost block'          # Line 6
    end
  end
end
```

- Line 1: Toggles `each` block (starts on cursor line)
- Line 2: Toggles `some_process` block (starts on cursor line)
- Line 3: Toggles `some_process` block (parent traversal)
- Line 4: Toggles `some_process` block (parent traversal)
- Line 5: Toggles `other_process` block (starts on cursor line)
- Line 6: Toggles `other_process` block (parent traversal)

### Other Features

- Uses Treesitter to accurately detect and parse Ruby blocks
- Preserves indentation based on your Neovim settings (`expandtab`, `shiftwidth`)
- Maintains spacing around block parameters (e.g., `do |x|` ↔ `{ |x|`)
- Shows notifications for operations and errors (configurable)
- Only operates on Ruby files

## License

MIT

## Contributing

Issues and Pull Requests are welcome!
