-- Keep the built-in fzf navigation/selection logic, with previews and home search.
-- run_with follows Yazi's built-in fzf.lua (https://yazi-rs.github.io/docs/plugins/builtins/).
local fzf = require("fzf")

function fzf.run_with(cwd, selected)
	-- Search the whole home directory when nothing is selected. fd returns
	-- absolute paths so Yazi can reveal matches outside the current directory.
	-- With an existing selection, retain the built-in selection-only picker.
	local root = #selected == 0 and (os.getenv("HOME") or tostring(cwd)) or tostring(cwd)
	local find = "fd --hidden --no-ignore --absolute-path --type f --type d"
		.. " --exclude .git --exclude .cache --exclude node_modules"
	local preview = os.getenv("FZF_CTRL_T_OPTS")
	if not preview or preview == "" then
		-- Also work when Yazi is launched outside an interactive zsh session.
		preview = [[--preview 'if [ -d {} ]; then
    if command -v eza >/dev/null; then
        eza --tree --color=always -- {} | head -200
    else
        ls -R -- {} | head -200
    fi
elif command -v bat >/dev/null; then
    bat -n --color=always --paging=never --line-range :500 -- {}
elif command -v batcat >/dev/null; then
    batcat -n --color=always --paging=never --line-range :500 -- {}
else
    head -500 -- {}
fi']]
	end
	-- Scope these options to this picker; leave the shell and other fzf uses alone.
	local opts = (os.getenv("FZF_DEFAULT_OPTS") or "") .. " " .. preview .. " --bind=ctrl-/:toggle-preview"
	local child, err = Command("fzf")
		:arg("-m")
		:env("FZF_DEFAULT_OPTS", opts)
		:env("FZF_DEFAULT_COMMAND", find)
		:cwd(root)
		:stdin(#selected > 0 and Command.PIPED or Command.INHERIT)
		:stdout(Command.PIPED)
		:spawn()
	if not child then
		return nil, Err("Failed to start `fzf`, error: %s", err)
	end

	for _, url in ipairs(selected) do
		child:write_all(string.format("%s\n", url))
	end
	if #selected > 0 then
		child:flush()
	end

	local output, output_err = child:wait_with_output()
	if not output then
		return nil, Err("Cannot read `fzf` output, error: %s", output_err)
	elseif not output.status.success and output.status.code ~= 130 then
		return nil, Err("`fzf` exited with error code %s", output.status.code)
	end
	return output.stdout, nil
end

return fzf
