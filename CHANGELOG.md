# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2025-06-08

### 🚀 Major Release - 100% Local AI Revolution

This is a complete architectural overhaul that transforms MitchAI from a cloud-dependent tool to a fully local, privacy-first AI code review platform.

### Added

#### 🏠 100% Local AI Processing
- **Ollama Integration**: Complete local AI model support via Ollama
- **Zero Cloud APIs**: No OpenAI or external API dependencies
- **Complete Privacy**: Code never leaves your machine
- **Zero API Costs**: Free AI-powered code reviews forever

#### 🎯 Tiered Model System
- **Fast Tier** (1.6-2.2GB): `codegemma:2b`, `phi3:mini` - ~2 minute setup
- **Balanced Tier** (3.8-4.1GB): `deepseek-coder:6.7b`, `qwen2.5-coder:7b` - ~5-10 minute setup  
- **Premium Tier** (7-19GB): `codellama:13b`, `deepseek-coder:33b` - ~10-15 minute setup
- **Quality Scoring**: 1-10 quality ratings for informed model selection
- **Smart Defaults**: Fast tier for immediate functionality, upgrade prompts for better quality

#### 🛠️ Enhanced Command System
- **Modular CLI Architecture**: Separated commands into focused, maintainable classes
- **Server Management**: `mitch-ai server start/stop/status/restart`
- **Model Management**: `mitch-ai models list/tiers/upgrade/install/remove`
- **Interactive Setup**: Tier selection with download time estimates
- **Upgrade Suggestions**: Context-aware model upgrade recommendations

#### 🔧 Model Context Protocol (MCP) Server
- **Advanced Project Analysis**: Deep understanding of project structure and languages
- **Multi-Language File Discovery**: Intelligent source file detection
- **Language-Specific Analysis**: Tailored code review rules per programming language
- **Graceful Fallbacks**: Direct file system analysis when MCP server unavailable

#### 🎨 Enhanced User Experience
- **Interactive Setup Flow**: Choose performance tier during installation
- **Progress Indicators**: Clear feedback during model downloads
- **Intelligent Prompts**: Alternative model suggestions for large downloads
- **Upgrade Notifications**: Quality improvement suggestions after reviews
- **Verbose Mode**: Detailed logging for debugging and transparency

### Changed

#### 💫 Breaking Changes
- **Removed OpenAI Dependency**: No longer requires OpenAI API keys
- **New Setup Process**: `mitch-ai setup` now installs local models instead of configuring API keys
- **Enhanced CLI Interface**: New command structure with `server` and `models` subcommands

#### 🏗️ Architecture Improvements
- **Modular Command System**: CLI split into focused command classes
- **Smart Model Selection**: Language-aware model recommendations
- **Fallback Mechanisms**: Robust operation without external dependencies
- **Performance Optimization**: Fast tier models for immediate usability

#### 📊 Enhanced Analysis
- **Multi-Language Support**: Expanded language detection and analysis
- **Context-Aware Reviews**: Language-specific best practices and patterns
- **Quality Metrics**: Structured scoring and improvement suggestions
- **Project-Wide Analysis**: Comprehensive codebase understanding

### Fixed

#### 🐛 Critical Issues Resolved
- **Timeout Problems**: Large model downloads no longer cause review failures
- **Directory Review Failures**: Robust project analysis with MCP server integration
- **Memory Management**: Efficient handling of large codebases
- **Error Handling**: Graceful degradation and helpful error messages

#### 🔧 Technical Improvements
- **RuboCop Compliance**: Refactored code to meet style guidelines
- **Method Length Reduction**: Broke down complex methods for maintainability
- **Input Validation**: Safe handling of user input and edge cases
- **Resource Management**: Proper cleanup and resource handling

### Migration Guide

#### From v0.x to v1.0
1. **Remove OpenAI Configuration**: No longer needed
2. **Run New Setup**: `mitch-ai setup` to install local models
3. **Update Workflows**: Replace API key configuration with model installation
4. **Explore New Features**: Try `mitch-ai models tiers` and `mitch-ai server status`

#### Key Benefits of Migration
- ✅ **No More API Costs**: Completely free operation
- ✅ **Enhanced Privacy**: Code never leaves your machine  
- ✅ **Faster Setup**: Start reviewing in under 2 minutes
- ✅ **Better Quality**: Choose models optimized for your languages
- ✅ **Offline Operation**: Works without internet connection

### Technical Details

#### Dependencies Added
- **Ollama**: Local AI model runtime
- **Sinatra**: MCP server framework
- **TTY::Spinner**: Enhanced progress indicators
- **Colorize**: Terminal output formatting

#### Dependencies Removed
- **OpenAI API**: No longer required
- **Thor**: Replaced with custom CLI system

#### Performance Improvements
- **Startup Time**: 10x faster with local models
- **Analysis Speed**: Optimized model selection for each language
- **Resource Usage**: Efficient memory management for large projects

## [0.4.0] - 2025-05-23

### Fixed

- Fixed bundler setup issue that prevented gem from running outside development directory
- Fixed spinner execution in standalone executable mode
- Corrected load path configuration for proper gem installation

### Changed

- Improved executable reliability across different Ruby environments
- Added support for more languages

## [0.3.0] - 2025-04-15

### Added

- TTY spinner for better user experience during code analysis
- Visual feedback with loading indicators and completion status

## [0.2.0] - 2025-03-27

### Changed

- Updated versioning scheme for better release management

## [0.1.0] - 2025-03-27

### Added

- Initial release with basic AI-powered code review functionality
- Support for multiple programming languages
- CLI interface with Thor
- OpenAI integration for code analysis
- JSON and terminal output formats
