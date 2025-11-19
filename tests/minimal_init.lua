-- Minimal init.lua for testing
-- This file sets up the minimum required environment for running tests

-- Add plugin directory to runtime path
vim.opt.runtimepath:append('.')

-- Add plenary.nvim to runtime path (adjust path as needed)
-- If plenary is installed via a plugin manager, it should be in stdpath('data')
local plenary_path = vim.fn.stdpath('data') .. '/lazy/plenary.nvim'
if vim.fn.isdirectory(plenary_path) == 1 then
  vim.opt.runtimepath:append(plenary_path)
else
  -- Try other common locations
  local alt_paths = {
    vim.fn.stdpath('data') .. '/site/pack/packer/start/plenary.nvim',
    vim.fn.stdpath('data') .. '/site/pack/*/start/plenary.nvim',
  }
  for _, path in ipairs(alt_paths) do
    if vim.fn.isdirectory(path) == 1 then
      vim.opt.runtimepath:append(path)
      break
    end
  end
end

-- Add nvim-treesitter to runtime path
local treesitter_path = vim.fn.stdpath('data') .. '/lazy/nvim-treesitter'
if vim.fn.isdirectory(treesitter_path) == 1 then
  vim.opt.runtimepath:append(treesitter_path)
else
  -- Try other common locations
  local alt_paths = {
    vim.fn.stdpath('data') .. '/site/pack/packer/start/nvim-treesitter',
    vim.fn.stdpath('data') .. '/site/pack/*/start/nvim-treesitter',
  }
  for _, path in ipairs(alt_paths) do
    if vim.fn.isdirectory(path) == 1 then
      vim.opt.runtimepath:append(path)
      break
    end
  end
end

-- Ensure Ruby parser is available
local has_parser = pcall(vim.treesitter.language.add, 'ruby')
if not has_parser then
  print('Warning: Ruby parser not found. Some tests may be skipped.')
  print('Run :TSInstall ruby in Neovim to install the Ruby parser.')
end

-- Set up test environment
vim.o.swapfile = false
vim.o.hidden = true

-- Load the plugin
vim.cmd('runtime! plugin/ruby-block-toggle.lua')
