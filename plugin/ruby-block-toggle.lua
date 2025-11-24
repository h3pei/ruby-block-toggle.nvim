-- Requires Neovim 0.7 or later
if vim.fn.has("nvim-0.7") == 0 then
  vim.notify("ruby-block-toggle requires Neovim >= 0.7", vim.log.levels.ERROR)
  return
end

-- Prevent double loading
if vim.g.loaded_ruby_block_toggle then
  return
end
vim.g.loaded_ruby_block_toggle = 1

-- Define :RubyBlockToggle command
vim.api.nvim_create_user_command("RubyBlockToggle", function()
  require("ruby-block-toggle").toggle()
end, {
  desc = "Toggle Ruby block notation between do~end and {}",
})
