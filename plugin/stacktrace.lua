vim.api.nvim_create_user_command("StacktraceAnalyze", function()
  vim.ui.input({ prompt = "Enter stack trace (or paste): " }, function(input)
    if input and input ~= "" then
      require("stacktrace").analyze_stacktrace(input)
    end
  end)
end, {})

vim.api.nvim_create_user_command("StacktraceFromClipboard", function()
  require("stacktrace").analyze_from_clipboard()
end, {})

vim.api.nvim_create_user_command("StacktraceFromSelection", function()
  require("stacktrace").analyze_from_selection()
end, { range = true })
