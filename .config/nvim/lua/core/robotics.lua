local M = {}
local project = require("core.project")

-- Build argument arrays rather than shell strings: paths and arguments stay literal.
function M.command(name, args, path)
    args = args or {}
    local root, argv
    if name:match("^Ros") then
        root = project.ros_root(path)
        if not root then return nil, "No colcon workspace found (open a ROS package or workspace)." end
        local commands = {
            RosBuild = { "colcon", "build", "--symlink-install", "--cmake-args", "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON" },
            RosTest = { "colcon", "test" },
            RosTestResults = { "colcon", "test-result", "--verbose" },
            RosLaunch = { "ros2", "launch" },
        }
        argv = commands[name]
        if name == "RosLaunch" and #args < 2 then return nil, "Usage: :RosLaunch package launch_file [name:=value ...]" end
    else
        root = vim.fs.root(project.directory(path), { "CMakePresets.json", "CMakeLists.txt" })
        if not root then return nil, "No CMake project found." end
        local commands = {
            CMakeConfigure = { "cmake", "-S", root, "-B", root .. "/build", "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON" },
            CMakeBuild = { "cmake", "--build", root .. "/build" },
            CMakeTest = { "ctest", "--test-dir", root .. "/build", "--output-on-failure" },
        }
        argv = commands[name]
    end
    if not argv then return nil, "Unknown build command: " .. name end
    vim.list_extend(argv, args)
    return { argv = argv, cwd = root }
end

local function run(name, args)
    local task, err = M.command(name, args)
    if not task then return vim.notify(err, vim.log.levels.WARN) end
    if vim.fn.executable(task.argv[1]) ~= 1 then
        return vim.notify(task.argv[1] .. " is unavailable. Source ROS or install the build tool first.", vim.log.levels.ERROR)
    end
    -- Use the already sourced editor environment; do not source shell configs again.
    vim.cmd("botright 14new")
    vim.bo.bufhidden = "hide"
    vim.b.dev_root = task.cwd
    local job = vim.fn.jobstart(task.argv, {
        term = true,
        cwd = task.cwd,
        on_exit = function(_, code)
            vim.schedule(function()
                vim.notify(name .. " finished (exit " .. code .. ")", code == 0 and vim.log.levels.INFO or vim.log.levels.WARN)
            end)
        end,
    })
    if job <= 0 then return vim.notify("Could not start " .. name, vim.log.levels.ERROR) end
    vim.cmd.startinsert()
end

function M.info()
    local root = project.root()
    local clients = vim.tbl_map(function(client) return client.name end, vim.lsp.get_clients({ bufnr = 0 }))
    local lines = {
        "Filetype: " .. vim.bo.filetype,
        "Vim syntax: " .. vim.bo.syntax,
        "Tree-sitter: " .. (vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] and "active" or "inactive"),
        "Attached LSP: " .. (#clients > 0 and table.concat(clients, ", ") or "none"),
        "Project: " .. root,
        "ROS workspace: " .. (project.ros_root() or "none"),
        "ROS distro: " .. (vim.env.ROS_DISTRO or "not sourced"),
        "Python: " .. project.python(),
        "Compilation database: " .. (vim.uv.fs_stat(root .. "/build/compile_commands.json")
            and root .. "/build/compile_commands.json" or vim.uv.fs_stat(root .. "/compile_commands.json")
            and root .. "/compile_commands.json" or "not found; build with compile commands enabled"),
    }
    for _, tool in ipairs({ "colcon", "ros2", "clangd", "clang-format", "pyright-langserver", "ruff",
        "neocmakelsp", "yaml-language-server", "cmake-format", "black", "debugpy-adapter", "codelldb" }) do
        local executable = vim.fn.exepath(tool)
        lines[#lines + 1] = tool .. ": " .. (executable ~= "" and executable or "missing")
    end
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "Development environment" })
end

function M.setup()
    vim.filetype.add({ extension = { urdf = "xml", xacro = "xml", sdf = "xml" } })
    local commands = {
        RosBuild = "Build colcon workspace (extra colcon build arguments)",
        RosTest = "Test colcon workspace (extra colcon test arguments)",
        RosTestResults = "Show colcon test results",
        RosLaunch = "Launch ROS 2 package and launch file",
        CMakeConfigure = "Configure nearest CMake project into build/",
        CMakeBuild = "Build nearest CMake project",
        CMakeTest = "Run CTest for nearest CMake project",
    }
    for name, desc in pairs(commands) do
        vim.api.nvim_create_user_command(name, function(opts) run(name, opts.fargs) end, { nargs = "*", desc = desc })
    end
    vim.api.nvim_create_user_command("DevInfo", M.info, { desc = "Show project, interpreter and development tools" })
    for lhs, command in pairs({
        ["<leader>rb"] = "RosBuild", ["<leader>rt"] = "RosTest", ["<leader>rr"] = "RosTestResults",
        ["<leader>rc"] = "CMakeConfigure", ["<leader>rm"] = "CMakeBuild", ["<leader>ri"] = "DevInfo",
    }) do
        vim.keymap.set("n", lhs, "<cmd>" .. command .. "<CR>", { desc = commands[command] or "Development environment" })
    end
    vim.keymap.set("n", "<leader>rl", ":RosLaunch ", { desc = "ROS 2 launch (enter package and file)" })
end

return M
