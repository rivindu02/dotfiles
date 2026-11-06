-- Run from the repo root: nvim --headless -u NONE -i NONE -l .config/nvim/tests/robotics.lua
local config = vim.fs.dirname(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)))
vim.opt.rtp:prepend(config)
local project = require("core.project")
local robotics = require("core.robotics")
local temporary = vim.fn.tempname() .. " robotics checks"
local saved_env = { VIRTUAL_ENV = vim.env.VIRTUAL_ENV, CONDA_PREFIX = vim.env.CONDA_PREFIX }
local checks = 0

local function equal(actual, expected)
    assert(vim.deep_equal(actual, expected), "Expected " .. vim.inspect(expected) .. ", got " .. vim.inspect(actual))
    checks = checks + 1
end

local function file(path, lines, executable)
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    vim.fn.writefile(lines or {}, path)
    if executable then vim.fn.setfperm(path, "rwx------") end
end

local ok, err = xpcall(function()
    vim.env.VIRTUAL_ENV, vim.env.CONDA_PREFIX = nil, nil
    local workspace = temporary .. "/ros workspace"
    local package = workspace .. "/src/nested repo/my_robot"
    local source = package .. "/src/controller.cpp"
    file(package .. "/package.xml", { "<package/>" })
    file(package .. "/CMakeLists.txt", { "project(my_robot)" })
    file(source, { "int main() {}" })
    vim.fn.mkdir(workspace .. "/src/nested repo/.git", "p")
    equal(project.ros_root(source), workspace)
    equal(project.ros_root(workspace), workspace)
    equal(project.root(source), workspace)
    equal(project.ros_root(package .. "/src/new.cpp"), workspace)

    local build = assert(robotics.command("RosBuild", { "--packages-select", "my_robot" }, source))
    equal(build.cwd, workspace)
    equal(build.argv, { "colcon", "build", "--symlink-install", "--cmake-args",
        "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON", "--packages-select", "my_robot" })
    local launch = assert(robotics.command("RosLaunch", { "my_robot", "bringup.launch.py", "label:=two words", "$(literal)" }, source))
    equal(launch.argv, { "ros2", "launch", "my_robot", "bringup.launch.py", "label:=two words", "$(literal)" })
    equal(robotics.command("RosLaunch", { "my_robot" }, source), nil)
    equal(robotics.command("RosTest", { "--packages-select", "my_robot" }, source).argv,
        { "colcon", "test", "--packages-select", "my_robot" })
    equal(robotics.command("RosTestResults", {}, source).argv, { "colcon", "test-result", "--verbose" })

    local native = temporary .. "/native project"
    file(native .. "/CMakeLists.txt", { "project(native)" })
    file(native .. "/src/main.cpp", { "int main() {}" })
    equal(project.ros_root(native .. "/src/main.cpp"), nil)
    equal(robotics.command("RosBuild", {}, native .. "/src/main.cpp"), nil)
    local cmake = assert(robotics.command("CMakeConfigure", { "-DCMAKE_BUILD_TYPE=Debug" }, native .. "/src/main.cpp"))
    equal(cmake.cwd, native)
    equal(cmake.argv, { "cmake", "-S", native, "-B", native .. "/build",
        "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON", "-DCMAKE_BUILD_TYPE=Debug" })
    equal(robotics.command("CMakeBuild", { "--target", "native" }, native).argv,
        { "cmake", "--build", native .. "/build", "--target", "native" })
    equal(robotics.command("CMakeTest", {}, native).argv,
        { "ctest", "--test-dir", native .. "/build", "--output-on-failure" })

    -- Non-src layouts work with a workspace marker.
    local custom = temporary .. "/custom layout"
    file(custom .. "/colcon.meta", { "{}" })
    file(custom .. "/packages/pkg/package.xml", { "<package/>" })
    equal(project.ros_root(custom .. "/packages/pkg/package.xml"), custom)
    equal(robotics.command("CMakeConfigure", {}, custom), nil)

    file(workspace .. "/.venv/bin/python", { "#!/bin/sh", "exit 0" }, true)
    equal(project.python(source), workspace .. "/.venv/bin/python")
    file(package .. "/venv/bin/python", { "#!/bin/sh", "exit 0" }, true)
    equal(project.python(source), package .. "/venv/bin/python")
    file(temporary .. "/active/bin/python", { "#!/bin/sh", "exit 0" }, true)
    vim.env.CONDA_PREFIX = temporary .. "/active"
    equal(project.python(source), temporary .. "/active/bin/python")
    file(temporary .. "/virtual/bin/python", { "#!/bin/sh", "exit 0" }, true)
    vim.env.VIRTUAL_ENV = temporary .. "/virtual"
    equal(project.python(source), temporary .. "/virtual/bin/python")
    vim.env.VIRTUAL_ENV = temporary .. "/missing"
    equal(project.python(source), temporary .. "/active/bin/python")
    vim.env.VIRTUAL_ENV, vim.env.CONDA_PREFIX = nil, nil
    equal(project.python(native), vim.fn.exepath("python3"))

    robotics.setup()
    equal(vim.filetype.match({ filename = "robot.urdf" }), "xml")
    equal(vim.filetype.match({ filename = "robot.xacro" }), "xml")
    equal(vim.filetype.match({ filename = "world.sdf" }), "xml")
    -- Exercise a registered command, capturing the process request instead of building.
    vim.cmd.edit(vim.fn.fnameescape(source))
    local original_jobstart, original_executable = vim.fn.jobstart, vim.fn.executable
    local captured
    vim.fn.executable = function() return 1 end
    vim.fn.jobstart = function(argv, opts)
        captured = { argv = argv, cwd = opts.cwd, term = opts.term }
        return 1
    end
    local command_ok, command_err = pcall(vim.cmd, "RosBuild --packages-select my_robot")
    vim.fn.jobstart, vim.fn.executable = original_jobstart, original_executable
    assert(command_ok, command_err)
    equal(captured, { argv = build.argv, cwd = workspace, term = true })
    -- Follow-up commands from a task terminal keep the task's workspace.
    vim.bo.buftype = "nofile"
    equal(project.directory(), workspace)
    equal(project.ros_root(), workspace)

    -- Syntax-check every Lua config file, including plugin specs, without running plugins.
    for _, path in ipairs(vim.fn.glob(config .. "/**/*.lua", false, true)) do
        assert(loadfile(path))
    end
end, debug.traceback)

vim.env.VIRTUAL_ENV, vim.env.CONDA_PREFIX = saved_env.VIRTUAL_ENV, saved_env.CONDA_PREFIX
vim.fn.delete(temporary, "rf")
if not ok then
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
end
print("Passed " .. checks .. " robotics configuration checks")
vim.cmd("qa!")
