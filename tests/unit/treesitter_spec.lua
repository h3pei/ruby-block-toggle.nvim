-- Tests for Treesitter functionality
local helpers = require("tests.helpers")

describe("treesitter module", function()
  local ts

  before_each(function()
    -- Check dependencies
    if not helpers.check_dependencies() then
      pending("nvim-treesitter or Ruby parser not available")
      return
    end

    ts = require("ruby-block-toggle.treesitter")
  end)

  after_each(function()
    helpers.cleanup_buffer()
  end)

  describe("find_nearest_block", function()
    it("should find do_block on cursor line", function()
      local content = [[
items.each do |item|
  puts item
end]]

      helpers.setup_ruby_buffer(content, { 1, 11 }) -- Cursor on "do"

      local block_node, block_type = ts.find_nearest_block()

      assert.is_not_nil(block_node)
      assert.are.equal("do_block", block_type)
    end)

    it("should find block ({}) on cursor line", function()
      local content = [[
items.map { |item|
  item * 2
}]]

      helpers.setup_ruby_buffer(content, { 1, 11 }) -- Cursor on "{"

      local block_node, block_type = ts.find_nearest_block()

      assert.is_not_nil(block_node)
      assert.are.equal("block", block_type)
    end)

    it("should find parent block when cursor is inside", function()
      local content = [[
items.each do |item|
  puts item
end]]

      helpers.setup_ruby_buffer(content, { 2, 5 }) -- Cursor inside block

      local block_node, block_type = ts.find_nearest_block()

      assert.is_not_nil(block_node)
      assert.are.equal("do_block", block_type)
    end)

    it("should find innermost block when multiple blocks on same line", function()
      local content = "items.each do |item| item.map do |x| x * 2 end end"

      helpers.setup_ruby_buffer(content, { 1, 35 }) -- Cursor on inner "do"

      local block_node, block_type = ts.find_nearest_block()

      assert.is_not_nil(block_node)
      assert.are.equal("do_block", block_type)

      -- Check that it's the innermost block (smaller range)
      local start_row, _, end_row, _ = block_node:range()
      local range_size = end_row - start_row
      assert.are.equal(0, range_size) -- Single line, so innermost
    end)

    it("should return nil when no block found", function()
      local content = "def foo; end" -- Not a block

      helpers.setup_ruby_buffer(content, { 1, 5 })

      local block_node, message = ts.find_nearest_block()

      assert.is_nil(block_node)
      assert.is_not_nil(message)
    end)
  end)

  describe("get_block_keywords", function()
    it("should extract do and end keywords from do_block", function()
      local content = [[
items.each do |item|
  puts item
end]]

      helpers.setup_ruby_buffer(content, { 1, 11 })

      local block_node, _ = ts.find_nearest_block()
      assert.is_not_nil(block_node)

      local keywords = ts.get_block_keywords(block_node)

      assert.is_not_nil(keywords)
      assert.is_not_nil(keywords.opening_keyword)
      assert.is_not_nil(keywords.closing_keyword)
      assert.are.equal("do", keywords.opening_keyword:type())
      assert.are.equal("end", keywords.closing_keyword:type())
    end)

    it("should extract { and } keywords from block", function()
      local content = [[
items.map { |item|
  item * 2
}]]

      helpers.setup_ruby_buffer(content, { 1, 11 })

      local block_node, _ = ts.find_nearest_block()
      assert.is_not_nil(block_node)

      local keywords = ts.get_block_keywords(block_node)

      assert.is_not_nil(keywords)
      assert.is_not_nil(keywords.opening_keyword)
      assert.is_not_nil(keywords.closing_keyword)
      assert.are.equal("{", keywords.opening_keyword:type())
      assert.are.equal("}", keywords.closing_keyword:type())
    end)

    it("should extract block_parameters when present", function()
      local content = [[
items.map do |x|
  x * 2
end]]

      helpers.setup_ruby_buffer(content, { 1, 11 })

      local block_node, _ = ts.find_nearest_block()
      assert.is_not_nil(block_node)

      local keywords = ts.get_block_keywords(block_node)

      assert.is_not_nil(keywords)
      assert.is_not_nil(keywords.block_parameters)
      assert.are.equal("block_parameters", keywords.block_parameters:type())
    end)

    it("should handle blocks without parameters", function()
      local content = [[
5.times do
  puts 'hello'
end]]

      helpers.setup_ruby_buffer(content, { 1, 8 })

      local block_node, _ = ts.find_nearest_block()
      assert.is_not_nil(block_node)

      local keywords = ts.get_block_keywords(block_node)

      assert.is_not_nil(keywords)
      assert.is_not_nil(keywords.opening_keyword)
      assert.is_not_nil(keywords.closing_keyword)
      assert.is_nil(keywords.block_parameters)
    end)

    it("should return nil for invalid input", function()
      local keywords = ts.get_block_keywords(nil)
      assert.is_nil(keywords)
    end)
  end)

  describe("get_node_range", function()
    it("should return correct range information", function()
      local content = [[
items.each do |item|
  puts item
end]]

      helpers.setup_ruby_buffer(content, { 1, 11 })

      local block_node, _ = ts.find_nearest_block()
      assert.is_not_nil(block_node)

      local range = ts.get_node_range(block_node)

      assert.is_not_nil(range)
      assert.is_not_nil(range.start_row)
      assert.is_not_nil(range.start_col)
      assert.is_not_nil(range.end_row)
      assert.is_not_nil(range.end_col)
      assert.is_true(range.end_row >= range.start_row)
    end)
  end)

  describe("block detection strategy", function()
    describe("priority 1: cursor line blocks", function()
      it("should prefer blocks starting on cursor line", function()
        local content = [[
items.each do |item|
  process(item) do
    puts 'inner'
  end
end]]

        helpers.setup_ruby_buffer(content, { 2, 17 }) -- Cursor on inner "do"

        local block_node, block_type = ts.find_nearest_block()

        assert.is_not_nil(block_node)
        assert.are.equal("do_block", block_type)

        -- Verify it's the inner block by checking start row
        local start_row, _, _, _ = block_node:range()
        assert.are.equal(1, start_row) -- 0-indexed, so line 2 is index 1
      end)
    end)

    describe("priority 2: parent traversal", function()
      it("should find parent block when cursor is inside", function()
        local content = [[
items.each do |item|
  puts item
end]]

        helpers.setup_ruby_buffer(content, { 2, 7 }) -- Cursor on "puts"

        local block_node, block_type = ts.find_nearest_block()

        assert.is_not_nil(block_node)
        assert.are.equal("do_block", block_type)
      end)
    end)

    describe("priority 3: nearest block fallback", function()
      it("should find nearest block when not inside any block", function()
        local content = [[
def foo; end

items.each do |item|
  puts item
end]]

        helpers.setup_ruby_buffer(content, { 2, 0 }) -- Empty line between def and block

        local block_node, block_type = ts.find_nearest_block()

        assert.is_not_nil(block_node)
        assert.are.equal("do_block", block_type)
      end)
    end)
  end)
end)
