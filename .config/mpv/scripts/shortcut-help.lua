-- Read the maintained shortcut guide instead of showing disabled defaults.
local mp = require('mp')
local utils = require('mp.utils')
local menu_type = 'shortcut-help'

local function plain(text)
    return (text:gsub('`', ''):match('^%s*(.-)%s*$'))
end

local function toggle()
    if mp.get_property_native('user-data/uosc/menu/type') == menu_type then
        mp.commandv('script-message-to', 'uosc', 'close-menu', menu_type)
        return
    end

    local path = mp.command_native({'expand-path', '~~/README.md'})
    local file = io.open(path, 'r')
    if not file then
        mp.osd_message('Shortcut guide missing: ' .. path)
        return
    end

    local sections, section = {}, nil
    for line in file:lines() do
        local heading = line:match('^## (.+)')
        if heading then
            if heading == 'Disabled advanced defaults' then break end
            section = {title = heading, items = {}}
            sections[#sections + 1] = section
        else
            local keys, action = line:match('^|%s*(.-)%s*|%s*(.-)%s*|%s*$')
            if section and keys and keys ~= 'Key' and not keys:match('^%-') then
                section.items[#section.items + 1] = {
                    title = plain(keys) .. '  —  ' .. plain(action),
                    value = 'ignore',
                    keep_open = true,
                }
            end
        end
    end
    file:close()

    mp.commandv('script-message-to', 'uosc', 'open-menu', utils.format_json({
        type = menu_type,
        title = 'Your mpv shortcuts',
        search_submenus = true,
        footnote = '/ to search · Arrows to navigate · Esc or ? to close',
        items = sections,
    }))
end

mp.add_key_binding(nil, 'toggle', toggle)
