# Neovim for ROS 2 and Python

Custom lazy.nvim setup; requires Neovim 0.12 or newer and tree-sitter-cli 0.26.1+.
Java and Solidity LSP
support are no longer enabled. Shell, Lua, and existing web tooling remain available.

## Tools

LSP: Pyright for Python types/navigation, Ruff for linting/import actions, clangd
for C/C++, neocmakelsp for CMake, and YAML language server for ROS parameters.
Mason installs these language servers on an interactive startup if missing.

Install the formatters and debugger adapters through `:Mason`:

```vim
:MasonInstall black clang-format cmakelang debugpy codelldb stylua prettier eslint_d
```

`clang-format` can also come from the system's `clang` package. `cmakelang`
provides `cmake-format`. Formatting stays manual: `<Space>fm` uses Black for
Python, clang-format for C/C++, and cmake-format for CMake, respecting project
configuration files. Ruff provides lint fixes and organize-import actions under
`<Space>ca`; it does not compete with Black for formatting.

Tree-sitter installs parsers and queries for Python, C/C++, CMake, shell, Lua,
Vim, JSON, YAML, XML, and Markdown into `~/.local/share/nvim/treesitter`.
Highlighting starts on `FileType`; standard Vim syntax is available as a fallback.
This avoids the old broken query symlinks under `site/queries` from vim-plug.
Update parsers with `:TSUpdate`. Python LSP works for standalone `.py` scripts
as well as projects containing `pyproject.toml` or Git metadata.

`<Space>ri` / `:DevInfo` shows the buffer's filetype, highlighting and attached
LSP clients, plus the detected project, Python interpreter, ROS distro,
compilation database, and executable locations.

## ROS 2 / colcon

Start Neovim from a terminal with the ROS environment sourced. For a Jazzy installation:

```zsh
source /opt/ros/jazzy/setup.zsh
cd ~/your_ros_workspace
# After the first build, in a fresh terminal with the ROS underlay sourced:
source install/setup.zsh
nvim .
```

If ROS lives in a container or on another machine, run Neovim in that development
environment too, so its language servers can see the same Python packages and
C++ headers. This configuration does not install ROS or route commands into a container.

This machine's ROS installation is Humble in the Ubuntu 22.04 `devbox` container.
Its distro package is named `neovim`, but the default repository version (0.6.1)
is too old for this config. The container runtime installer is
[`system/distrobox/install-neovim.py`](../../system/distrobox/install-neovim.py):

```sh
# From the host, with devbox running:
podman exec --user root devbox python3 /home/rivindu02/dotfiles/system/distrobox/install-neovim.py
# Initialize as the regular user (no sudo):
podman exec --user rivindu02 devbox /usr/local/bin/nvim --headless '+luafile /home/rivindu02/dotfiles/system/distrobox/bootstrap-neovim.lua'
distrobox enter devbox
source /opt/ros/humble/setup.zsh
nvim your_node.py
```

The container's `/usr/local/bin/nvim` wrapper uses the same configuration with
separate data, cache, and state under `distrobox-editor/devbox` in each XDG
directory. Its Neovim/Node/Tree-sitter executables live under `/opt/devbox-editor`.
The bootstrap command installs plugins, parsers, and Mason tools as the regular user.
The installer builds Tree-sitter CLI locally if its official prebuilt binary needs
a newer glibc than Ubuntu 22.04 provides; the temporary Rust compiler is removed
after the build. With the ROS underlay sourced, the container check is:

```sh
nvim --headless '+luafile /home/rivindu02/dotfiles/system/distrobox/check-neovim.lua'
```

Build from a terminal that has the underlay sourced but has not sourced the same
workspace's overlay. Use an editor launched with the overlay sourced for running,
debugging, and resolving installed/generated Python modules. The commands below
inherit Neovim's environment; they do not source or reset it automatically.
After adding packages or generating new interfaces, build, then restart the editor
from a terminal with the refreshed overlay sourced.

| Keys | Command | Purpose |
|---|---|---|
| `<Space>rb` | `:RosBuild` | `colcon build --symlink-install --cmake-args -DCMAKE_EXPORT_COMPILE_COMMANDS=ON` |
| `<Space>rt` | `:RosTest` | Run `colcon test` |
| `<Space>rr` | `:RosTestResults` | Run `colcon test-result --verbose` |
| `<Space>rl` | `:RosLaunch package launch_file` | Enter a ROS launch command |

Commands find the enclosing workspace even when editing a package in a nested
Git repository. Standard `workspace/src/.../package.xml` layouts work before
the first build; `colcon.meta`, `.colcon`, or `install/local_setup.sh` also mark
a workspace. An unconventional unbuilt layout can use an empty `colcon.meta`
JSON object (`{}`) at the workspace root.

Extra arguments pass directly to the tool:

```vim
:RosBuild --packages-up-to my_robot
:RosTest --packages-select my_robot
:RosLaunch my_robot bringup.launch.py use_sim_time:=true
```

If supplying your own `--cmake-args`, include
`-DCMAKE_EXPORT_COMPILE_COMMANDS=ON` again, since argparse replaces the earlier
argument group. Add `-DCMAKE_BUILD_TYPE=RelWithDebInfo` for native debugging:

```vim
:RosBuild --packages-select my_robot --cmake-args -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo
```

colcon-cmake aggregates package compilation databases into
`build/compile_commands.json`. clangd discovers this standard location, giving it
the include paths and definitions for ROS headers and generated interfaces.
Custom build directories need a project `.clangd` `CompilationDatabase` setting
or a `compile_commands.json` symlink at the workspace root.

URDF, Xacro, and SDF files use XML syntax. Build/install/log directories, virtual
environments, and Python caches are hidden from ordinary Telescope searches and
the file tree; use a terminal when inspecting generated build artifacts.

## Python / machine learning

Interpreter selection for Pyright and Python debug launches:

1. Activated `VIRTUAL_ENV`, then `CONDA_PREFIX`.
2. The nearest `.venv/bin/python` or `venv/bin/python`, searching parent folders.
3. `python3`, then `python`, from the inherited PATH.

Activate the intended environment **before** opening Neovim. ROS Python projects
must use a Python version and environment compatible with the installed ROS
distribution; an unrelated ML environment may hide ROS packages. The old global
reference to `~/Documents/Machine-Learning/.venv` has been removed. Neovim's own
Python provider is separate from the interpreter used by Pyright and debugpy.

Existing `<Space>tn` / `tf` / `ts` test mappings still run through vim-test/Vimux
inside tmux. Install pytest in each project environment when using pytest.

## CMake and debugging

| Keys | Command | Purpose |
|---|---|---|
| `<Space>rc` | `:CMakeConfigure` | Configure the nearest CMake project into `build/`, exporting compile commands |
| `<Space>rm` | `:CMakeBuild` | Build that project's `build/` directory |
| | `:CMakeTest` | Run CTest with failure output |

For ROS packages, use `:RosBuild` so colcon handles package dependencies and
installation. Use the CMake commands for standalone projects. These convenience
commands use `build/`; projects with presets or other build directories can use
their existing terminal commands.

`F5` starts/continues debugging, `F10` steps over, `F11` steps into, and `F12`
steps out. `<Space>db` / `dt` toggles breakpoints, `dB` sets a conditional
breakpoint, `du` toggles the UI, and `de` evaluates an expression or selection.

Python supports file, module, and attach configurations. A ROS Python node can
be debugged by module name when its module is executable with `python -m`.
For native ROS nodes, select the executable under
`install/<package>/lib/<package>/<node>` or attach to a running process. Build
with debug symbols first. Normal process-attach permissions still apply.
Project `.vscode/launch.json` files can supply arguments and custom launch setups.

## Occasional STM32 projects

Keep board/toolchain settings in the project. For an ARM GCC project, a `.clangd`
can select its compilation database:

```yaml
CompileFlags:
  CompilationDatabase: build
```

If clangd cannot find ARM standard headers, allow it to query your **specific**
compiler with `--query-driver=/absolute/path/to/arm-none-eabi-gcc,/absolute/path/to/arm-none-eabi-g++`
in a project-specific clangd configuration. This is a clangd command-line option,
not a `.clangd` YAML key. No ARM compiler paths are enabled globally.

Flashing and hardware debugging remain with your existing STM32CubeIDE or the
project's OpenOCD/ST-Link setup. They need the actual board, probe, ELF path, and
GDB server settings; the desktop codelldb configurations are for native programs.

References: [colcon compile commands](https://colcon.readthedocs.io/en/released/user/how-to.html#generate-a-compilation-database),
[Pyright environments](https://github.com/microsoft/pyright/blob/main/docs/import-resolution.md),
[clangd compiler headers](https://clangd.llvm.org/troubleshooting#cant-find-standard-library-headers-map-stdioh-etc).

## Configuration checks

Run the temporary-workspace checks without loading plugins or touching real ROS projects:

```sh
nvim --headless -u NONE -i NONE -l .config/nvim/tests/robotics.lua
```

After installing plugins/parsers/tools, check normal startup for project,
standalone, and newly created Python files, including actual highlight captures,
LSP hover, lint diagnostics, and completion:

```sh
python3 .config/nvim/tests/python_startup.py
```

These startup checks use temporary files under `/var/tmp` and isolated editor
state. They disable the unrelated Supermaven service and registry refreshes.
