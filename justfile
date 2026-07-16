# Development tasks for dotfiles repository

# List available recipes
default:
  @just --list

# Lint shell scripts with shellcheck (no warnings allowed)
lint:
  shellcheck $(find scripts -name "*.sh" -type f)

# Run all tests
test:
  bats $(find scripts -name "*.bats" -type f)

# Run lint and test
verify: lint test
  @echo "✓ All checks passed"
