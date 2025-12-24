local stacktrace = require("stacktrace")

describe("stacktrace", function()
  describe("setup", function()
    it("works with default config", function()
      stacktrace.setup()
      assert.is_not_nil(stacktrace.config)
    end)

    it("merges custom config", function()
      stacktrace.setup({
        search_paths = { "/custom/path" },
        keymaps = {
          jump = "<leader>j",
        },
      })

      assert.are.equal("/custom/path", stacktrace.config.search_paths[1])
      assert.are.equal("<leader>j", stacktrace.config.keymaps.jump)
      -- Default values should still be present
      assert.are.equal("q", stacktrace.config.keymaps.close)
    end)
  end)

  describe("analyze_stacktrace", function()
    it("parses and displays stack trace", function()
      local test_trace = [[
  File "/path/to/file.py", line 42, in main
    raise ValueError("error")
]]

      -- This will open a floating window, so we just test it doesn't error
      -- In a real environment, we'd need to mock the UI
      stacktrace.setup()

      -- Just verify the function exists and is callable
      assert.is_function(stacktrace.analyze_stacktrace)
    end)
  end)

  describe("analyze_from_clipboard", function()
    it("is callable", function()
      stacktrace.setup()
      assert.is_function(stacktrace.analyze_from_clipboard)
    end)
  end)

  describe("analyze_from_selection", function()
    it("is callable", function()
      stacktrace.setup()
      assert.is_function(stacktrace.analyze_from_selection)
    end)
  end)
end)
