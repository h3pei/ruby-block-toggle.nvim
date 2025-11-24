.PHONY: test test-file lint format format-check check help

# Run all tests
test:
	@echo "Running all tests..."
	nvim --headless --noplugin -u tests/minimal_init.lua -c "lua require('plenary.test_harness').test_directory('tests/unit/', { minimal_init = 'tests/minimal_init.lua' })"

# Run a specific test file
# Usage: make test-file FILE=tests/unit/toggle_spec.lua
test-file:
	@echo "Running test file: $(FILE)"
	nvim --headless --noplugin -u tests/minimal_init.lua -c "lua require('plenary.busted').run('$(FILE)')"

# Run luacheck
lint:
	@echo "Running luacheck..."
	luacheck .

# Format code with stylua
format:
	@echo "Formatting code with stylua..."
	stylua .

# Show help
help:
	@echo "Available targets:"
	@echo "  test         - Run all tests"
	@echo "  test-file    - Run a specific test file (usage: make test-file FILE=tests/unit/toggle_spec.lua)"
	@echo "  lint         - Run luacheck"
	@echo "  format       - Format code with stylua"
	@echo "  help         - Show this help message"
