local resolver = require("stacktrace.resolver")

describe("resolver", function()
  before_each(function()
    resolver.clear_cache()
  end)

  describe("setup", function()
    it("accepts custom search paths", function()
      resolver.setup({ search_paths = { "/custom/path" } })
      -- Setup should not error
      assert.is_true(true)
    end)
  end)

  describe("resolve_file", function()
    it("returns nil for empty path", function()
      local result = resolver.resolve_file("")
      assert.is_nil(result)
    end)

    it("returns nil for nil path", function()
      local result = resolver.resolve_file(nil)
      assert.is_nil(result)
    end)

    it("caches resolution results", function()
      -- Note: This test assumes the Makefile exists in the test environment
      local path = "Makefile"

      local result1 = resolver.resolve_file(path)
      local result2 = resolver.resolve_file(path)

      -- Should return the same result (from cache)
      assert.are.equal(result1, result2)
    end)
  end)

  describe("resolve_frames", function()
    it("resolves frames with file paths", function()
      local frames = {
        { file_path = "Makefile", line = 1, raw_line = "test", line_number = 1 },
        { file_path = "nonexistent.txt", line = 1, raw_line = "test", line_number = 2 },
      }

      local resolved = resolver.resolve_frames(frames)

      assert.are.equal(2, #resolved)
      -- First frame should be resolved (Makefile exists)
      assert.is_not_nil(resolved[1].resolved_path)
      -- Second frame should not be resolved
      assert.is_nil(resolved[2].resolved_path)
    end)

    it("preserves original frame data", function()
      local frames = {
        { file_path = "test.txt", line = 42, column = 10, raw_line = "test line", line_number = 1 },
      }

      local resolved = resolver.resolve_frames(frames)

      assert.are.equal("test.txt", resolved[1].file_path)
      assert.are.equal(42, resolved[1].line)
      assert.are.equal(10, resolved[1].column)
      assert.are.equal("test line", resolved[1].raw_line)
      assert.are.equal(1, resolved[1].line_number)
    end)
  end)

  describe("clear_cache", function()
    it("clears the resolution cache", function()
      resolver.resolve_file("Makefile")
      resolver.clear_cache()
      -- Should not error
      assert.is_true(true)
    end)
  end)
end)
