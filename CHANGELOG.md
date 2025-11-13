# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- 🔄 Removed engine support from frontend generator only
- 🔄 Scaffold generator retains full engine support with `--engine` and `--engine_structure` options
- 📝 Updated documentation to clarify engine support differences

## [0.0.12] - 2025-11-07

### Added
- ✨ Engine support for frontend generator with `--engine` option
- ✨ Engine support for scaffold generator with `--engine` option
- ✨ `--engine_structure` option to load structure files from different engines
- ✨ Auto-detect engine paths (engines/, components/, gems/)
- ✨ Multiple engine support for modular Rails applications
- 📝 ENGINE_SUPPORT.md comprehensive documentation
- 📝 Updated USAGE with engine examples

### Changed
- 🔄 Frontend generator now supports path_app helper for engine routing
- 🔄 Scaffold generator now supports engine-specific paths
- 🔄 Structure file path resolution supports engines
- 📝 Updated README with engine usage examples

### Fixed
- 🐛 All path references now use helpers for engine compatibility

## [0.0.11] - 2025-11-07

### Changed
- 🔄 Migrated from Yarn/NPM to Bun for faster package management
- 🔄 Updated all `yarn` commands to `bun` commands
- 📦 All frontend dependencies now installed via Bun

### Added
- ✨ RSpec structure matching rider-kick (co-located specs)
- ✨ generator_spec gem for better generator testing
- ✨ Support directory for test helpers
- 📝 MIGRATION_TO_BUN.md documentation

### Fixed
- ✅ All 37 RSpec tests now passing
- 🧹 Cleaned up root-level development artifacts

## [0.0.1] - 2024-01-01

### Added
- 🎉 Initial release
- ⚡ Vite + Tailwind v4 + Hotwire (Turbo + Stimulus) integration
- 🎨 Frontend generator with modern stack
- 📝 Scaffold generator for Clean Architecture
- 🏗️ View scaffolds aligned with domain

