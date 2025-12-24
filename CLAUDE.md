# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

stacktrace.nvim is a Neovim plugin for analyzing stack traces with intelligent file path resolution and quick navigation. Written in 100% Lua with zero external dependencies (except plenary.nvim for testing).

**Key Features**:
- Multi-language stack trace parsing (Python, JavaScript, Java, Rust, Go, etc.)
- Smart file path resolution with git root detection and fuzzy matching
- Split window UI (default) with optional floating window mode
- Syntax highlighting with extmarks
- Pluggable architecture for custom parsers and UI

## Commands

### Testing
```bash
# Run all tests
make test

# Tests run using plenary.nvim's busted framework
```

### Formatting
```bash
# Check formatting
stylua --check lua

# Auto-format code
stylua lua
```

## Architecture

### Module Structure

```
lua/stacktrace/
├── parser.lua      - Parser registry + default generic parser
├── resolver.lua    - File path resolution (git root, cwd, fuzzy matching)
├── ui.lua          - Split/floating window, buffer setup, keymaps
├── navigation.lua  - Jump to file:line:column, frame navigation
└── highlight.lua   - Syntax highlighting with extmarks
```

### Core Components

**`lua/stacktrace.lua`** - Main module
- Public API: `analyze_stacktrace()`, `analyze_from_clipboard()`, `analyze_from_selection()`
- Configuration management with `setup()`
- Orchestrates parser → resolver → UI flow

**`lua/stacktrace/parser.lua`** - Stack trace parsing
- Pluggable parser registry: `register_parser(name, fn)`
- Default generic parser with patterns for Python, JS, Java, Rust, Go, etc.
- Returns structured frames: `{ file_path, line, column, raw_line, line_number }`
- Custom patterns can be added via `add_pattern()`

**`lua/stacktrace/resolver.lua`** - File path resolution
- Resolution strategy (in order): git root → cwd → custom search paths
- Git root detection by searching for `.git` directory upward
- Fuzzy matching for partial paths (e.g., `src/file.js` matches `*/src/file.js`)
- Path scoring algorithm to pick best match
- Results cached for performance

**`lua/stacktrace/ui.lua`** - UI management
- Default split window (bottom, configurable size and position)
- Alternative floating window mode (centered, bordered, auto-sized)
- Buffer setup with `stacktrace` filetype
- Stores frame metadata for navigation
- Keymaps: `<CR>` to jump, `]s`/`[s]` for next/prev frame, `q` to close
- Mouse click support

**`lua/stacktrace/navigation.lua`** - Navigation
- Jump to resolved file at specific line:column
- Window management (close stacktrace, switch to source window)
- Next/prev frame navigation with wrap-around
- Graceful handling of unresolved files with user notifications

**`lua/stacktrace/highlight.lua`** - Syntax highlighting
- Highlight groups: resolved files (blue, underlined), unresolved files (red), line/column numbers (orange), errors/warnings
- Extmarks-based highlighting (no treesitter dependency)
- Pattern-based keyword highlighting (Error, Warning, function names)

**`plugin/stacktrace.lua`** - User commands
- `:StacktraceAnalyze` - Prompt for input
- `:StacktraceFromClipboard` - Read from `+` register
- `:StacktraceFromSelection` - Read from visual selection

### Data Flow

1. **Input** → `analyze_stacktrace(text)`
2. **Parse** → `parser.parse(text)` returns frames array
3. **Resolve** → `resolver.resolve_frames(frames)` adds `resolved_path` to frames
4. **Display** → `ui.open_stacktrace(text, frames, config)` shows split/floating window
5. **Navigate** → User presses `<CR>` → `navigation.jump_to_location(frame)`

### Configuration Pattern

The `setup()` function uses `vim.tbl_deep_extend("force", defaults, user_config)` for config merging. Custom parsers and search paths are registered during setup.

### Testing

Tests are organized by module:
- `tests/stacktrace/parser_spec.lua` - Tests for all supported formats
- `tests/stacktrace/resolver_spec.lua` - Path resolution and caching tests
- `tests/stacktrace/stacktrace_spec.lua` - Integration tests

## Code Style

- **Indentation**: 2 spaces (enforced by StyLua)
- **Line width**: 120 characters
- **Quote style**: Auto-prefer double quotes
- **Annotations**: Use LSP annotations (`---@class`, `---@param`, `---@return`) for type information
- **Dependencies**: Zero runtime dependencies (uses only Neovim built-in APIs)

## Key Design Decisions

**Pluggable Parsers**: Users can register custom parsers while the default handles 80% of cases

**Fuzzy Matching**: Essential for stack traces with partial/relative paths

**Extmarks over Treesitter**: Keeps dependencies minimal while providing good highlighting

**Customizable UI**: The `ui.open_fn` callback allows complete UI customization
