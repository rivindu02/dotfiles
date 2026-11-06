local M = {}

function M.directory(path)
    if path == nil and vim.bo.buftype ~= "" then return vim.b.dev_root or vim.fn.getcwd() end
    path = path or vim.api.nvim_buf_get_name(0)
    if path == "" then return vim.b.dev_root or vim.fn.getcwd() end
    path = vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
    local stat = vim.uv.fs_stat(path)
    return stat and stat.type == "directory" and path or vim.fs.dirname(path)
end

local function ancestors(path)
    local dirs = { M.directory(path) }
    for parent in vim.fs.parents(dirs[1]) do dirs[#dirs + 1] = parent end
    return dirs
end

function M.ros_root(path)
    local dirs = ancestors(path)
    local in_package = false
    for _, dir in ipairs(dirs) do
        in_package = in_package or vim.uv.fs_stat(dir .. "/package.xml") ~= nil
        if vim.uv.fs_stat(dir .. "/colcon.meta") or vim.uv.fs_stat(dir .. "/.colcon")
            or vim.uv.fs_stat(dir .. "/install/local_setup.sh") then
            return dir
        end
        -- Handles unbuilt workspaces and nested Git repositories under src/.
        if in_package and vim.fs.basename(dir) == "src" then return vim.fs.dirname(dir) end
    end
    -- Also works when the editor starts at an unbuilt workspace root.
    local dir = dirs[1]
    if vim.uv.fs_stat(dir .. "/src") and #vim.fs.find("package.xml", {
        path = dir .. "/src", type = "file", limit = 1,
    }) > 0 then
        return dir
    end
end

function M.root(path)
    return M.ros_root(path) or vim.fs.root(M.directory(path),
        { "pyproject.toml", "setup.py", "CMakePresets.json", "CMakeLists.txt", ".git" }) or M.directory(path)
end

function M.python(path)
    -- An explicitly activated environment takes precedence over local defaults.
    for _, env in ipairs({ "VIRTUAL_ENV", "CONDA_PREFIX" }) do
        local prefix = vim.env[env]
        if prefix and vim.fn.executable(prefix .. "/bin/python") == 1 then return prefix .. "/bin/python" end
    end
    for _, dir in ipairs(ancestors(path)) do
        for _, name in ipairs({ ".venv", "venv" }) do
            local python = dir .. "/" .. name .. "/bin/python"
            if vim.fn.executable(python) == 1 then return python end
        end
    end
    local python = vim.fn.exepath("python3")
    return python ~= "" and python or vim.fn.exepath("python")
end

return M
