<div align="center">
  <img src="mitch-ai-logo.svg" alt="MitchAI" width="500">
</div>

# MitchAI

## AI-Powered Code Review Assistant

<!-- [![Gem Version](https://badge.fury.io/rb/mitch_ai.svg)](https://badge.fury.io/rb/mitch_ai) -->
<!-- [![Ruby CI](https://github.com/scookdev/mitch_ai/actions/workflows/ruby.yml/badge.svg)](https://github.com/scookdev/mitch_ai/actions) -->
<!-- [![Code Coverage](https://codecov.io/gh/scookdev/mitch_ai/branch/main/graph/badge.svg)](https://codecov.io/gh/scookdev/mitch_ai) -->
<!-- [![Ruby Style Guide](https://img.shields.io/badge/code_style-rubocop-brightgreen.svg)](https://github.com/rubocop/rubocop) -->

## 🚀 Overview

MitchAI is an intelligent CLI tool that leverages **100% local AI models** to provide comprehensive code reviews. No cloud APIs, no data sharing - your code never leaves your machine while getting professional-grade AI analysis.

## ✨ Features

- 🏠 **100% Local AI** - No cloud APIs, complete privacy
- 🚀 **Tiered Model System** - Fast setup to premium quality
- 🔍 **Smart Project Analysis** - Understands your codebase structure
- 🤖 **Multi-language Support** - Ruby, Python, TypeScript, JavaScript, Go, Rust, Java, C++, CSS, HTML
- 🛡️ **Security & Bug Detection** - Catches vulnerabilities and potential issues
- ⚡ **Lightning Fast Setup** - Get started in under 2 minutes
- 📈 **Quality Upgrade Path** - Improve analysis quality on demand
- 🎯 **Context-Aware Reviews** - Language-specific best practices and patterns

## 🛠️ Installation

```bash
gem install mitch-ai
```

## 🚀 Quick Start

```bash
# 1. Install
gem install mitch-ai

# 2. Setup (choose your performance tier)
mitch-ai setup

# 3. Review your code
mitch-ai review
```

> **💡 First-time setup**: MitchAI will guide you through selecting a model tier. The Fast tier gets you started in under 2 minutes!

## 💡 Usage

### Basic Commands
```bash
# Review current directory
mitch-ai review

# Review specific file
mitch-ai review ./app/models/user.rb

# Review entire project with verbose output
mitch-ai review ./my-project -v
```

### Model Management
```bash
# See available model tiers
mitch-ai models tiers

# List installed models
mitch-ai models list

# Upgrade to better models for current project
mitch-ai models upgrade

# Install specific model
mitch-ai models install codegemma:2b
```

### Server Management
```bash
# Start MCP server for enhanced analysis
mitch-ai server start

# Check server status
mitch-ai server status

# Stop server
mitch-ai server stop
```

## 🎯 Model Tiers

Choose the right balance of speed vs. quality for your needs:

### 🚀 Fast Tier (1.6-2.2GB)
- **Setup time**: ~2 minutes
- **Models**: `codegemma:2b`, `phi3:mini`
- **Best for**: Quick reviews, immediate feedback
- **Quality**: ★★★★★★★☆☆☆ (7/10)

### ⚖️ Balanced Tier (3.8-4.1GB)
- **Setup time**: ~5-10 minutes  
- **Models**: `deepseek-coder:6.7b`, `qwen2.5-coder:7b`
- **Best for**: Professional development, CI/CD
- **Quality**: ★★★★★★★★★☆ (9/10)

### 🎯 Premium Tier (7-19GB)
- **Setup time**: ~10-15 minutes
- **Models**: `codellama:13b`, `deepseek-coder:33b`
- **Best for**: Enterprise codebases, critical reviews
- **Quality**: ★★★★★★★★★★ (10/10)

## 🤝 Contributing

Contributions are welcome! Please check out [Contributing Guidelines](CONTRIBUTING.md).

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📋 Requirements

- Ruby 3.0+
- [Ollama](https://ollama.ai/) (auto-installed during setup)

## 🧪 Development

```bash
# Clone the repository
git clone https://github.com/scookdev/mitch_ai.git

# Install dependencies
bundle install

# Setup development environment (installs Ollama, downloads test models)
rake mitch_ai:setup

# Run tests
bundle exec rspec

# Run linter
bundle exec rubocop

# Start MCP server for testing
mitch-ai server start

# Test with different model tiers
mitch-ai models tiers
mitch-ai models list
```

## 🏗️ Architecture

MitchAI uses a modular architecture combining:

- **Local AI Models** via [Ollama](https://ollama.ai/) for zero-cost, private analysis
- **Model Context Protocol (MCP)** for advanced project structure analysis
- **Tiered Model System** for flexible performance/quality trade-offs
- **Graceful Fallbacks** ensuring reliability without external dependencies

## 🆚 Why Choose MitchAI v1.0?

| Feature | MitchAI v1.0 | Traditional Tools |
|---------|--------------|-------------------|
| **Privacy** | 🔒 100% Local | ☁️ Cloud-dependent |
| **Cost** | 🆓 Completely Free | 💳 Pay-per-use APIs |
| **Setup Time** | ⚡ 2 minutes (Fast tier) | 🐌 Complex configuration |
| **Offline Work** | ✅ Full functionality | ❌ Internet required |
| **Data Security** | 🛡️ Never leaves machine | 📡 Sent to external servers |
| **Quality Scaling** | 📈 Tier-based upgrades | 🔧 One-size-fits-all |

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE.txt)
file for details.

## 🙌 Acknowledgments

- Powered by local AI models via [Ollama](https://ollama.ai/)
- Model Context Protocol (MCP) for advanced code analysis
- Inspired by the need for private, intelligent code reviews

## 💬 Support

If you encounter any problems or have suggestions, please [open an issue](https://github.com/scookdev/mitch_ai/issues).
