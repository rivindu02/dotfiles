-- Run through devbox's nvim wrapper with /opt/ros/humble/setup.sh sourced.
local fixture = vim.fn.tempname() .. ".py"
local ok, err = xpcall(function()
    assert(vim.fn.stdpath("data"):match("/distrobox%-editor/devbox/nvim$"), "Container editor data is not isolated")
    local runtime = vim.system({ "python3", "-c", "import sys, rclpy; print(sys.executable); print(rclpy.__file__)" },
        { text = true }):wait(15000)
    assert(runtime.code == 0, "ROS Python runtime import failed: " .. (runtime.stderr or ""))
    print("ROS Python runtime: " .. runtime.stdout:gsub("\n", " "))
    vim.fn.writefile({ "import rclpy", "from std_msgs.msg import String" }, fixture)
    vim.cmd.edit(vim.fn.fnameescape(fixture))
    local bufnr = vim.api.nvim_get_current_buf()
    local pyright
    assert(vim.wait(30000, function()
        pyright = vim.lsp.get_clients({ name = "pyright", bufnr = bufnr })[1]
        local ruff = vim.lsp.get_clients({ name = "ruff", bufnr = bufnr })[1]
        return pyright and pyright.initialized and ruff and ruff.initialized
    end, 100), "Python language servers did not attach inside devbox")
    assert(vim.treesitter.highlighter.active[bufnr], "Python Tree-sitter highlighting is inactive")
    vim.treesitter.get_parser(bufnr):parse()
    assert(#vim.treesitter.get_captures_at_pos(bufnr, 0, 0) > 0, "Python syntax captures are missing")
    local definition = pyright:request_sync("textDocument/definition", {
        textDocument = { uri = vim.uri_from_bufnr(bufnr) }, position = { line = 0, character = 9 },
    }, 30000, bufnr)
    assert(definition and definition.result and vim.inspect(definition.result):find("/opt/ros/humble/", 1, true),
        "Pyright did not resolve rclpy inside the ROS installation: " .. vim.inspect(definition))
    print("PASS: container Python highlighting, Pyright/Ruff attachment, and ROS import resolution")
end, debug.traceback)
for _, client in ipairs(vim.lsp.get_clients()) do client:stop(true) end
vim.fn.delete(fixture)
if not ok then io.stderr:write(err .. "\n"); vim.cmd("cquit 1") end
vim.cmd("qa!")
