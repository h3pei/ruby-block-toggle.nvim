# Test fixtures for ruby-block-toggle.nvim

# Simple do~end block
items.each do |item|
  puts item
end

# Simple brace block
items.map { |item|
  item * 2
}

# Single-line do~end block (important edge case)
foo do 1 end

# Single-line brace block
bar { |x| x * 2 }

# Nested blocks
members.each do |member|
  some_process(member) do
    puts 'inner block'

    other_process(member) do
      puts 'innermost block'
    end
  end
end

# Block with parameters
items.select do |item|
  item.valid?
end

# Brace block with parameters on same line
items.reject { |item| item.nil? }

# Block without parameters
5.times do
  puts 'hello'
end

# Empty block
array.each do |x|
end

# Block with comments
items.map do |item|
  # This is a comment
  item * 2
end
