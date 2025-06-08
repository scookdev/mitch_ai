# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Testing and Quality Assurance
```bash
# Run all tests
bundle exec rspec

# Run linting  
bundle exec rubocop

# Run both tests and linting (default rake task)
rake

# Run integration tests (requires Ollama)
rake mitch_ai:integration

# Setup development environment
rake mitch_ai:setup
```

### MCP Server Management
```bash
# Start MCP server for enhanced directory review
mitch-ai server start

# Check server status
mitch-ai server status

# Stop server
mitch-ai server stop

# Restart server
mitch-ai server restart
```

### Model Management (Tiered System)
```bash
# Show available model tiers
mitch-ai models tiers

# List all models with status
mitch-ai models list

# Upgrade to better models for current project
mitch-ai models upgrade

# Install specific model
mitch-ai models install codegemma:2b

# Remove model to free space
mitch-ai models remove deepseek-coder:6.7b
```

### Local Development
```bash
# Install dependencies
bundle install

# Build and install gem locally
rake mitch_ai:install_local

# Start test environment (starts Ollama if needed)
rake mitch_ai:test_env

# Clean build artifacts
rake mitch_ai:clean
```

### Testing Individual Components
```bash
# Test specific files
bundle exec rspec spec/cli_spec.rb
bundle exec rspec spec/ollama_client_spec.rb
bundle exec rspec spec/mcp_client_spec.rb
```

## Architecture Overview

Mitch-AI is a local AI-powered code review tool built with Ruby that combines multiple components:

### Core Components
- **CLI (`lib/mitch_ai/cli.rb`)**: Main command dispatcher that routes commands to specialized command classes
- **Commands (`lib/mitch_ai/commands/`)**: Modular command classes organized by functionality:
  - `BaseCommand`: Shared functionality for all commands
  - `ReviewCommand`: Code review operations
  - `SetupCommand`: Installation and configuration
  - `InfoCommands`: Languages, models, version, and help commands
- **Reviewer (`lib/mitch_ai/reviewer.rb`)**: Orchestrates the code review process using MCP and Ollama
- **OllamaManager (`lib/mitch_ai/ollama_manager.rb`)**: Manages Ollama installation, model downloads, and service lifecycle
- **SmartModelManager**: Recommends optimal models based on detected programming languages
- **MCPClient**: Interfaces with Model Context Protocol server for code analysis
- **OllamaClient**: Communicates with local Ollama API for AI inference
- **LanguageDetector**: Detects programming languages in projects and files

### Key Design Patterns

**Local-First Architecture**: All AI processing happens locally via Ollama - no cloud APIs required. Code never leaves the user's machine.

**Modular Review Process**: 
1. Project structure analysis via MCP server (with fallback to direct analysis)
2. Language detection and model selection
3. File grouping by language
4. Batch review processing
5. Comprehensive result presentation

**Tiered Model System**: 
- **Fast Tier** (1.6-2.2GB): `codegemma:2b`, `phi3:mini` - Quick setup, good quality
- **Balanced Tier** (3.8-4.1GB): `deepseek-coder:6.7b`, `qwen2.5-coder:7b` - Better quality, moderate setup  
- **Premium Tier** (7-19GB): `codellama:13b`, `deepseek-coder:33b` - Best quality, longer setup
- Defaults to Fast tier for immediate functionality, with upgrade prompts

**Backward Compatibility**: Maintains legacy reviewer interface to ensure existing integrations continue working.

### External Dependencies
- **Ollama**: Local AI model runtime (auto-installed via OllamaManager)
- **MCP (Model Context Protocol)**: For structured code analysis
- **Colorize**: Terminal output formatting
- **TTY::Spinner**: Progress indicators during setup

### File Structure
- `exe/mitch-ai`: Executable entry point
- `lib/mitch_ai.rb`: Main module with convenience methods
- `lib/mitch_ai/`: Individual component classes
- `spec/`: RSpec test files with VCR for HTTP mocking

## Model Configuration

The gem downloads and manages AI models automatically. Default model is `deepseek-coder:6.7b`. The SmartModelManager selects optimal models based on detected languages in the codebase.