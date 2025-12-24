local parser = require("stacktrace.parser")

describe("parser", function()
  describe("parse", function()
    it("parses Python 3.13 stack traces", function()
      local stacktrace = [[
Traceback (most recent call last):
  File "/tmp/test.py", line 5, in <module>
    foo()
    ~~~^^
  File "/tmp/test.py", line 3, in foo
    print(list[0])
          ~~~~^^^
IndexError: list index out of range
]]

      local frames = parser.parse(stacktrace)

      -- Should have 2 frames (only lines with file paths)
      assert.are.equal(2, #frames)

      -- Check first stack frame
      assert.are.equal("/tmp/test.py", frames[1].file_path)
      assert.are.equal(5, frames[1].line)
      assert.is_nil(frames[1].column) -- python doesn't include column numbers

      -- Check second stack frame
      assert.are.equal("/tmp/test.py", frames[2].file_path)
      assert.are.equal(3, frames[2].line)
      assert.is_nil(frames[2].column) -- python doesn't include column numbers
    end)

    it("parses JavaScript/Node.js stack traces", function()
      local stacktrace = [[
/tmp/test.js:3
      throw new Error("Something went wrong");
      ^

Error: Something went wrong
    at processData (/tmp/test.js:3:13)
    at run (/tmp/test.js:7:7)
    at Object.<anonymous> (/tmp/test.js:10:3)
    at Module._compile (node:internal/modules/cjs/loader:1706:14)
    at Object..js (node:internal/modules/cjs/loader:1839:10)
    at Module.load (node:internal/modules/cjs/loader:1441:32)
    at Function._load (node:internal/modules/cjs/loader:1263:12)
    at TracingChannel.traceSync (node:diagnostics_channel:328:14)
    at wrapModuleLoad (node:internal/modules/cjs/loader:237:24)
    at Function.executeUserEntryPoint [as runMain] (node:internal/modules/run_main:171:5)

Node.js v22.21.1
]]

      local frames = parser.parse(stacktrace)

      -- Should have 4 frames (the /tmp/test.js references, node:internal won't match)
      assert.are.equal(4, #frames)

      -- First frame: /tmp/test.js:3 (simple format)
      assert.are.equal("/tmp/test.js", frames[1].file_path)
      assert.are.equal(3, frames[1].line)

      -- Second frame: at processData (/tmp/test.js:3:13)
      assert.are.equal("/tmp/test.js", frames[2].file_path)
      assert.are.equal(3, frames[2].line)
      assert.are.equal(13, frames[2].column)

      -- Third frame: at run (/tmp/test.js:7:7)
      assert.are.equal("/tmp/test.js", frames[3].file_path)
      assert.are.equal(7, frames[3].line)
      assert.are.equal(7, frames[3].column)

      -- Fourth frame: at Object.<anonymous> (/tmp/test.js:10:3)
      assert.are.equal("/tmp/test.js", frames[4].file_path)
      assert.are.equal(10, frames[4].line)
      assert.are.equal(3, frames[4].column)
    end)

    it("parses Java stack traces", function()
      local stacktrace = [[
Exception in thread "main" java.lang.NullPointerException: Test error
	at Main.doSomething(Main.java:4)
	at Main.main(Main.java:8)
]]

      local frames = parser.parse(stacktrace)

      -- Should have 2 frames
      assert.are.equal(2, #frames)

      assert.are.equal("Main.java", frames[1].file_path)
      assert.are.equal(4, frames[1].line)

      assert.are.equal("Main.java", frames[2].file_path)
      assert.are.equal(8, frames[2].line)
    end)

    it("parses Rust stack traces", function()
      local stacktrace = [[
thread 'main' panicked at 'assertion failed'
  --> src/main.rs:42:5
   |
42 |     assert_eq!(a, b);
   |     ^^^^^^^^^^^^^^^^
]]

      local frames = parser.parse(stacktrace)

      -- Should have 1 frame (only the --> line has file path)
      assert.are.equal(1, #frames)

      assert.are.equal("src/main.rs", frames[1].file_path)
      assert.are.equal(42, frames[1].line)
      assert.are.equal(5, frames[1].column)
    end)

    it("parses generic file:line:column format", function()
      local stacktrace = [[
Error in src/utils/helper.ts:123:45
Processing file.js:10:1
At main.py:42
]]

      local frames = parser.parse(stacktrace)

      assert.are.equal("src/utils/helper.ts", frames[1].file_path)
      assert.are.equal(123, frames[1].line)
      assert.are.equal(45, frames[1].column)

      assert.are.equal("file.js", frames[2].file_path)
      assert.are.equal(10, frames[2].line)
      assert.are.equal(1, frames[2].column)

      assert.are.equal("main.py", frames[3].file_path)
      assert.are.equal(42, frames[3].line)
    end)

    it("handles lines without file paths", function()
      local stacktrace = [[
This is just text
Error: Something went wrong
  at /path/to/file.js:10:5
More text without paths
]]

      local frames = parser.parse(stacktrace)

      -- Only one frame (the line with file path)
      assert.are.equal(1, #frames)
      assert.are.equal("/path/to/file.js", frames[1].file_path)
      assert.are.equal(10, frames[1].line)
      assert.are.equal(5, frames[1].column)
    end)
  end)

  describe("register_parser", function()
    it("allows registering custom parsers", function()
      local custom_called = false

      parser.register_parser("custom", function(text)
        custom_called = true
        return { { file_path = "custom.txt", line = 1, column = 1, raw_line = text, line_number = 1 } }
      end)

      local frames = parser.parse("test", "custom")

      assert.is_true(custom_called)
      assert.are.equal(1, #frames)
      assert.are.equal("custom.txt", frames[1].file_path)
    end)
  end)
end)
