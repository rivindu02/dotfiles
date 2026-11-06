-- Used by python_startup.py after opening a Python file through normal startup.
local bufnr = vim.api.nvim_get_current_buf()
local function check(condition, message)
    assert(condition, message)
end
local function attached(name)
    local client
    check(vim.wait(20000, function()
        client = vim.lsp.get_clients({ name = name, bufnr = bufnr })[1]
        return client and client.initialized
    end, 50), name .. " did not attach")
    return client
end
local ok, err = xpcall(function()
    if vim.env.PYTHON_STARTUP_NEW == "1" then
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
            "import os", "", "def add(a: int, b: int) -> int:", "    return a + b", "", "answer = add(1, 2)",
        })
    end
    check(vim.bo[bufnr].filetype == "python", "Python filetype was not detected")
    check(vim.g.syntax_on == 1, "Vim syntax fallback is disabled")
    check(vim.wait(10000, function()
        return vim.treesitter.highlighter.active[bufnr] ~= nil
    end, 50), "Python Tree-sitter highlighting did not start")
    vim.treesitter.get_parser(bufnr):parse()
    local captures = vim.treesitter.get_captures_at_pos(bufnr, 0, 0)
    check(#captures > 0, "Python import keyword has no syntax captures")
    local pyright = attached("pyright")
    attached("ruff")
    check(pyright.config.root_dir == vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr)),
        "Python workspace does not match this standalone/project file's directory: " .. tostring(pyright.config.root_dir)
            .. " versus " .. vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr)))
    local result = pyright:request_sync("textDocument/hover", {
        textDocument = { uri = vim.uri_from_bufnr(bufnr) }, position = { line = 2, character = 5 },
    }, 15000, bufnr)
    check(result and result.result and vim.inspect(result.result):find("add", 1, true),
        "Pyright did not return hover information for the function")
    check(vim.wait(10000, function()
        for _, diagnostic in ipairs(vim.diagnostic.get(bufnr)) do
            if diagnostic.code == "F401" then return true end
        end
        return false
    end, 50), "Ruff did not report the unused import")
    check(require("cmp").get_config().enabled(), "Completion is disabled in this Python buffer")
    print("PASS: Python filetype, syntax captures, Pyright hover, Ruff diagnostics, and completion")
end, debug.traceback)
for _, client in ipairs(vim.lsp.get_clients()) do client:stop(true) end
if not ok then
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
end
vim.cmd("qa!")
