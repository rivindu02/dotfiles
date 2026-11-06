-- Run as the regular devbox user: nvim --headless '+luafile /path/to/this/file'
assert(vim.uv.getuid() ~= 0, "Initialize editor data as the regular container user, not root")
assert(vim.fn.stdpath("data"):match("/distrobox%-editor/devbox/nvim$"), "Use the container's /usr/local/bin/nvim wrapper")
local packages = {
    "pyright", "ruff", "clangd", "neocmakelsp", "yaml-language-server",
    "bash-language-server", "lua-language-server", "typescript-language-server",
    "black", "clang-format", "cmakelang", "debugpy", "codelldb", "stylua", "prettier", "eslint_d",
}
local registry = require("mason-registry")
local remaining, failures = #packages, {}
registry.refresh(function()
    for _, name in ipairs(packages) do
        local ok, package = pcall(registry.get_package, name)
        if not ok then
            failures[#failures + 1] = name .. ": missing from registry"
            remaining = remaining - 1
        elseif package:is_installed() then
            remaining = remaining - 1
        else
            print("Installing " .. name)
            -- These projects publish static musl binaries alongside builds for newer glibc.
            local opts = (name == "neocmakelsp" or name == "stylua") and { target = "linux_x64" } or {}
            package:install(opts, vim.schedule_wrap(function(success, result)
                print(name .. (success and ": installed" or ": FAILED"))
                if not success then failures[#failures + 1] = name .. ": " .. vim.inspect(result) end
                remaining = remaining - 1
            end))
        end
    end
end)
if not vim.wait(360000, function() return remaining == 0 end, 100) then
    failures[#failures + 1] = "Tool installation timed out"
end
local ok, err = pcall(function()
    local languages = { "python", "c", "cpp", "cmake", "bash", "lua", "vim", "vimdoc", "query",
        "json", "yaml", "xml", "markdown", "markdown_inline" }
    require("nvim-treesitter").install(languages):wait(180000)
    local base = vim.fn.stdpath("data") .. "/treesitter"
    assert(vim.wait(180000, function()
        for _, language in ipairs(languages) do
            if vim.fn.filereadable(base .. "/parser/" .. language .. ".so") ~= 1 then return false end
        end
        return true
    end, 100), "Parser installation did not finish")
end)
if not ok then failures[#failures + 1] = tostring(err) end
for _, tool in ipairs({ "node", "tree-sitter", "pyright-langserver", "ruff", "clangd", "clang-format", "black", "debugpy-adapter" }) do
    if vim.fn.executable(tool) ~= 1 then failures[#failures + 1] = "Executable missing: " .. tool end
end
for _, tool in ipairs({ "node", "tree-sitter", "ruff", "clangd", "clang-format", "black", "neocmakelsp", "stylua" }) do
    local result = vim.system({ tool, "--version" }, { text = true }):wait(15000)
    if result.code ~= 0 then failures[#failures + 1] = tool .. " cannot run: " .. (result.stderr or "") end
end
if #failures > 0 then
    io.stderr:write(table.concat(failures, "\n") .. "\n")
    vim.cmd("cquit 1")
end
print("Container editor plugins, parsers, and tools are ready")
vim.cmd("qa!")
