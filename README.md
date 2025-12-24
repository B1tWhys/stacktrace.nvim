# stacktrace.nvim

![Lint and Test](https://github.com/B1tWhys/stacktrace.nvim/actions/workflows/lint-test.yml/badge.svg)
![Docs](https://github.com/B1tWhys/stacktrace.nvim/actions/workflows/docs.yml/badge.svg)

A Neovim plugin for analyzing stack traces with intelligent file path resolution and quick navigation. Similar to IntelliJ's "Analyze Stack Trace" feature.

## Features

- **Smart Path Resolution**: Automatically resolves file paths using git root, cwd, and custom search paths
- **Fuzzy Matching**: Finds files even with partial paths in stack traces
- **Multi-Language Support**: Works with Python, JavaScript/TypeScript, Java, Rust, Go, and more
- **Pluggable Parser System**: Register custom parsers for specific languages or formats
- **Customizable UI**: Default split window with options for floating window or custom display function
- **Quick Navigation**: Click or press Enter to jump to files, navigate between frames
- **Syntax Highlighting**: Highlighted file paths (resolved vs unresolved), line numbers, and errors
- **Zero Dependencies**: Uses only Neovim built-in APIs

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "B1tWhys/stacktrace.nvim",
  config = function()
    require("stacktrace").setup()
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "B1tWhys/stacktrace.nvim",
  config = function()
    require("stacktrace").setup()
  end
}
```

## Usage

### Commands

- `:StacktraceAnalyze` - Opens a prompt to paste or enter a stack trace
- `:StacktraceFromClipboard` - Analyzes stack trace from system clipboard
- `:StacktraceFromSelection` - Analyzes visually selected text as a stack trace

### Keymaps (in stacktrace window)

- `<CR>` (Enter) - Jump to file location under cursor
- `<LeftMouse>` - Click to jump to file location
- `]s` - Navigate to next stack frame
- `[s` - Navigate to previous stack frame
- `q` or `<Esc>` - Close stacktrace window

### Basic Example

1. Copy a stack trace to your clipboard
2. Run `:StacktraceFromClipboard`
3. Navigate with `]s`/`[s]` or click/press Enter on lines with file paths
4. Files will open at the correct line and column

### Programmatic Usage

```lua
local stacktrace = require("stacktrace")

-- Analyze a stack trace string
stacktrace.analyze_stacktrace([[
  File "/path/to/file.py", line 42, in main
    raise ValueError("error")
]])

-- From clipboard
stacktrace.analyze_from_clipboard()

-- From visual selection
stacktrace.analyze_from_selection()
```

## Configuration

```lua
require("stacktrace").setup({
  -- Custom parsers (optional)
  parsers = {
    -- Register a custom parser
    custom_format = function(text)
      -- Return array of frames: { file_path, line, column, raw_line, line_number }
      return {}
    end,
  },

  -- Additional search paths for file resolution
  search_paths = {
    "~/projects",
    "/usr/local/src",
  },

  -- UI configuration
  ui = {
    -- Custom UI function (optional)
    -- If provided, this will be called instead of the default window
    open_fn = nil,

    -- Window type: "split" (default), "vsplit", or "float"
    window_type = "split",

    -- Split window options (used when window_type is "split" or "vsplit")
    split_opts = {
      position = "below", -- "below", "above", "left", "right"
      size = 15,          -- height for horizontal splits, width for vertical splits
    },

    -- Floating window options (used when window_type is "float")
    float_opts = {
      border = "rounded", -- "none", "single", "double", "rounded", "solid", "shadow"
      max_width = 120,
      max_height = 40,
    },
  },

  -- Keymap configuration
  keymaps = {
    jump = "<CR>",
    close = "q",
    next_frame = "]s",
    prev_frame = "[s",
  },
})
```

## Supported Stack Trace Formats

The plugin includes a generic parser that recognizes common patterns across many languages:

- **Python**: `File "/path/to/file.py", line 42, in function`
- **JavaScript/Node.js**: `at Object.<anonymous> (/path/to/file.js:15:10)`
- **Java**: `at package.Class.method(File.java:123)`
- **Rust**: `--> src/main.rs:42:5`
- **Go**: `/path/to/file.go:123 +0x45`
- **Generic**: `/path/to/file.ext:line:column`

### Custom Parsers

You can register language-specific parsers for better accuracy:

```lua
local parser = require("stacktrace.parser")

parser.register_parser("my_language", function(text)
  local frames = {}
  -- Parse text and extract frames
  return frames
end)

-- Use the custom parser
stacktrace.analyze_stacktrace(trace_text, "my_language")
```

### Adding Custom Patterns

For simple cases, you can add patterns to the default parser:

```lua
local parser = require("stacktrace.parser")

parser.add_pattern({
  pattern = "your_pattern_here",
  file = 1,    -- capture group index for file path
  line = 2,    -- capture group index for line number
  column = 3,  -- capture group index for column (optional)
})
```

## Custom UI

The default is a split window at the bottom of your screen. You can change to a floating window:

```lua
require("stacktrace").setup({
  ui = {
    window_type = "float",
  },
})
```

Or provide your own UI function for complete control:

```lua
require("stacktrace").setup({
  ui = {
    open_fn = function(text, resolved_frames)
      -- text: original stack trace text
      -- resolved_frames: array of parsed and resolved frames

      -- Create your custom UI here
      -- ... set up buffer and highlighting
    end,
  },
})
```

## How It Works

1. **Parsing**: The parser scans each line for file path patterns and extracts file, line, and column information
2. **Resolution**: Each file path is resolved using:
   - Git repository root (detected via `.git` directory)
   - Current working directory
   - Custom search paths from configuration
   - Fuzzy matching for partial paths
3. **Display**: Stack trace is shown in a floating window with syntax highlighting
4. **Navigation**: Clicking or pressing Enter on a line jumps to the resolved file location

## Development

### Running Tests

```bash
make test
```

### Formatting

```bash
stylua lua/
```

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
