-- Empty the trash bin behind yazi's own confirm dialog.
-- Same steps as "Empty trash bin" in the built-in trash plugin, without
-- depending on that plugin's ya pub handler being registered.
return {
	entry = function()
		local confirmed = ya.confirm {
			pos = { "center", w = 60, h = 10 },
			title = ui.Line("Empty trash?"):style(th.confirm.title),
			body = ui.Text("All items in the trash will be permanently deleted."),
		}
		if not confirmed then
			return
		end

		local ok, err = fs.trash.empty()
		if ok then
			ya.emit("refresh", {})
			ya.notify { title = "Trash", content = "Trash emptied", timeout = 3 }
		else
			ya.notify { title = "Trash", content = tostring(err), timeout = 5, level = "error" }
		end
	end,
}
