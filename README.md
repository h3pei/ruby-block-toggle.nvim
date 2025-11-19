# ruby-block-toggle.nvim

A Neovim plugin to toggle Ruby block notation between `do ~ end` and `{}` quickly.

## Features

- Toggle between `do ~ end` and `{}` block syntax
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

### Examples

#### Converting `do~end` to `{}`

Before:
```ruby
items.each do |item|
  puts item
end
```

After:
```ruby
items.each { |item|
  puts item
}
```

#### Converting `{}` to `do~end`

Before:
```ruby
items.map { |item|
  item * 2
}
```

After:
```ruby
items.map do |x|
  item * 2
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

## How It Works (Block Detection Strategy)

The plugin uses an intelligent strategy to select which block to toggle:

1. **Cursor line priority**: If a block starts on the current cursor line, that block is selected
   - For nested blocks on the same line, the innermost (smallest range) block is chosen
2. **Parent traversal**: If no block starts on the cursor line, traverse upward from the cursor position to find the nearest parent block
3. **Nearest block fallback**: If neither approach finds a block, select the closest block by distance

**Example with nested blocks:**
```ruby
items.each do |item|         # Line 1
  process1(item) do          # Line 2
    puts 'inner block'       # Line 3
                             # Line 4 (empty)
    process2(item) do        # Line 5
      puts 'innermost block' # Line 6
    end
  end
end
```

- Line 1: Toggles `each` block (starts on cursor line)
- Line 2: Toggles `process1` block (starts on cursor line)
- Line 3: Toggles `process1` block (parent traversal)
- Line 4: Toggles `process1` block (parent traversal)
- Line 5: Toggles `process2` block (starts on cursor line)
- Line 6: Toggles `process2` block (parent traversal)

## License

MIT

## Contributing

Issues and Pull Requests are welcome!
