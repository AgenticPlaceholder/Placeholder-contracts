.PHONY: all anvil deploy help build test clean

help:
	@echo "Available targets:"
	@echo "  anvil         - Run Anvil local network"
	@echo "  build         - Build the project"
	@echo "  test          - Run tests"
	@echo "  deploy        - Deploy to local Anvil network"
	@echo "  clean         - Remove build artifacts"

# Start Anvil
anvil:
	anvil

# Build the project
build:
	forge build

# Run tests
test:
	forge test -vv

# Clean build artifacts
clean:
	forge clean

# Deploy to Anvil
deploy:
	forge script script/DeployPlaceholderAds.s.sol:DeployPlaceholderAds --rpc-url  https://sepolia.base.org --broadcast --verify

# Default target
all: clean build test