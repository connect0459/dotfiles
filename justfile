# List available recipes
default:
  @just --list

# Lint shell scripts - Usage: just lint [path]
lint path="scripts":
  shellcheck $(find {{path}} -name "*.sh" -type f)

# Run tests - Usage: just test [path]
test path="scripts":
  bats $(find {{path}} -name "*.bats" -type f)

# Run lint and test
verify: (lint "scripts") (test "scripts")
  @echo "✓ All checks passed"
