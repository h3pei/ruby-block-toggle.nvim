-- Tests for block toggle functionality
local helpers = require("tests.helpers")

describe("ruby-block-toggle", function()
  local toggle

  before_each(function()
    -- Check dependencies
    if not helpers.check_dependencies() then
      pending("nvim-treesitter or Ruby parser not available")
      return
    end

    -- Load the plugin
    toggle = require("ruby-block-toggle")
    toggle.setup({
      log_level = false, -- Disable notifications during tests
    })
  end)

  after_each(function()
    helpers.cleanup_buffer()
  end)

  describe("do~end to {} conversion", function()
    it("should convert simple do~end block to braces", function()
      local content = [[
items.each do |item|
  puts item
end]]

      helpers.setup_ruby_buffer(content, { 1, 11 }) -- Cursor on "do"

      toggle.toggle()

      local result = helpers.get_buffer_content()
      assert.is_true(result:match("items%.each { |item|") ~= nil)
      assert.is_true(result:match("}") ~= nil)
      assert.is_true(result:match("do") == nil)
      assert.is_true(result:match("end") == nil)
    end)

    it("should convert single-line do~end block (BUG FIX)", function()
      local content = "foo do 1 end"

      helpers.setup_ruby_buffer(content, { 1, 5 }) -- Cursor on "do"

      toggle.toggle()

      local result = helpers.get_buffer_content()
      assert.are.equal("foo { 1 }", result)
    end)

    it("should preserve block parameters", function()
      local content = [[
items.map do |x|
  x * 2
end]]

      helpers.setup_ruby_buffer(content, { 1, 11 })

      toggle.toggle()

      local result = helpers.get_buffer_content()
      assert.is_true(result:match("items%.map { |x|") ~= nil)
      assert.is_true(result:match("x %* 2") ~= nil)
    end)

    it("should preserve comments inside block", function()
      local content = [[
items.map do |item|
  # This is a comment
  item * 2
end]]

      helpers.setup_ruby_buffer(content, { 1, 11 })

      toggle.toggle()

      local result = helpers.get_buffer_content()
      assert.is_true(result:match("# This is a comment") ~= nil)
      assert.is_true(result:match("items%.map {") ~= nil)
    end)

    it("should preserve indentation", function()
      local content = [[
items.each do |item|
  puts item
end]]

      helpers.setup_ruby_buffer(content, { 1, 11 })

      toggle.toggle()

      local result = helpers.get_buffer_content()
      -- Check that indentation is preserved
      local lines = vim.split(result, "\n")
      assert.is_true(lines[2]:match("^%s+puts") ~= nil)
    end)
  end)

  describe("{} to do~end conversion", function()
    it("should convert simple brace block to do~end", function()
      local content = [[
items.map { |item|
  item * 2
}]]

      helpers.setup_ruby_buffer(content, { 1, 11 }) -- Cursor on "{"

      toggle.toggle()

      local result = helpers.get_buffer_content()
      assert.is_true(result:match("items%.map do |item|") ~= nil)
      assert.is_true(result:match("end") ~= nil)
      assert.is_true(result:match("{") == nil)
      assert.is_true(result:match("}") == nil)
    end)

    it("should convert single-line brace block", function()
      local content = "bar { |x| x * 2 }"

      helpers.setup_ruby_buffer(content, { 1, 5 }) -- Cursor on "{"

      toggle.toggle()

      local result = helpers.get_buffer_content()
      assert.is_true(result:match("bar do |x|") ~= nil)
      assert.is_true(result:match("end") ~= nil)
    end)

    it("should preserve block parameters", function()
      local content = [[
items.reject { |item|
  item.nil?
}]]

      helpers.setup_ruby_buffer(content, { 1, 15 })

      toggle.toggle()

      local result = helpers.get_buffer_content()
      assert.is_true(result:match("items%.reject do |item|") ~= nil)
      assert.is_true(result:match("item%.nil%?") ~= nil)
    end)
  end)

  describe("nested blocks", function()
    it("should toggle innermost block on cursor line", function()
      local content = [[
members.each do |member|
  some_process(member) do
    puts 'inner block'
  end
end]]

      helpers.setup_ruby_buffer(content, { 2, 23 }) -- Cursor on inner "do"

      toggle.toggle()

      local result = helpers.get_buffer_content()
      -- Outer block should remain do~end
      assert.is_true(result:match("members%.each do") ~= nil)
      -- Inner block should be converted to braces
      assert.is_true(result:match("some_process%(member%) {") ~= nil)
    end)

    it("should toggle outer block when cursor is on outer block line", function()
      local content = [[
members.each do |member|
  some_process(member) do
    puts 'inner block'
  end
end]]

      helpers.setup_ruby_buffer(content, { 1, 14 }) -- Cursor on outer "do"

      toggle.toggle()

      local result = helpers.get_buffer_content()
      -- Outer block should be converted to braces
      assert.is_true(result:match("members%.each {") ~= nil)
      -- Inner block should remain do~end
      assert.is_true(result:match("some_process%(member%) do") ~= nil)
    end)
  end)

  describe("edge cases", function()
    it("should handle empty blocks", function()
      local content = [[
array.each do |x|
end]]

      helpers.setup_ruby_buffer(content, { 1, 12 })

      toggle.toggle()

      local result = helpers.get_buffer_content()
      assert.is_true(result:match("array%.each { |x|") ~= nil)
      assert.is_true(result:match("}") ~= nil)
    end)

    it("should handle blocks without parameters", function()
      local content = [[
5.times do
  puts 'hello'
end]]

      helpers.setup_ruby_buffer(content, { 1, 8 })

      toggle.toggle()

      local result = helpers.get_buffer_content()
      assert.is_true(result:match("5%.times {") ~= nil)
    end)

    it("should not toggle if not in a Ruby file", function()
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_current_buf(bufnr)
      vim.bo[bufnr].filetype = "lua" -- Not Ruby

      -- This should not error, just show a warning
      toggle.toggle()

      -- Buffer should remain unchanged (empty buffer has 1 empty line by default)
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      assert.are.equal(1, #lines)
      assert.are.equal("", lines[1])

      helpers.cleanup_buffer(bufnr)
    end)
  end)
end)
