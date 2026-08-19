local WidgetContainer = require("ui/widget/container/widgetcontainer")
local Menu = require("ui/widget/menu")
local InputDialog = require("ui/widget/inputdialog")
local ButtonDialog = require("ui/widget/buttondialog")
local CenterContainer = require("ui/widget/container/centercontainer")
local ConfirmBox = require("ui/widget/confirmbox")
local UIManager = require("ui/uimanager")
local DataStorage = require("datastorage")
local Device = require("device")
local lfs = require("libs/libkoreader-lfs")
local _ = require("gettext")

local Scratchpad = WidgetContainer:extend{
    name = "later_thoughts",
    is_doc_only = false,
}

local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function safeFilename(name)
    if not name then return nil end
    name = trim(name)
    name = name:gsub("[/%\\:%*%?\"<>|]", "_")
    name = name:gsub("%s+$", "")
    if name == "" then return nil end
    local max_bytes = 60
    if #name > max_bytes then
        local cut = max_bytes
        while cut > 1 do
            local b = name:byte(cut)
            if not b or b < 128 or b >= 192 then break end
            cut = cut - 1
        end
        name = trim(name:sub(1, cut))
    end
    return name
end

local function readFile(path)
    local f = io.open(path, "r")
    if not f then return "" end
    local text = f:read("*a") or ""
    f:close()
    return text
end

local function writeFile(path, text)
    local f, err = io.open(path, "w")
    if not f then return false, err end
    f:write(text or "")
    f:close()
    return true
end

local function getNotes(dir)
    local notes = {}
    for name in lfs.dir(dir) do
        if name ~= "." and name ~= ".." and name:sub(-4):lower() == ".txt" then
            local path = dir .. "/" .. name
            local attr = lfs.attributes(path)
            notes[#notes + 1] = {
                name = name,
                path = path,
                mtime = (attr and attr.modification) or 0,
            }
        end
    end
    table.sort(notes, function(a, b)
        if a.mtime == b.mtime then
            return a.name:lower() < b.name:lower()
        end
        return a.mtime > b.mtime
    end)
    return notes
end

function Scratchpad:init()
    self.storage_dir = DataStorage:getDataDir() .. "/scratchpad"
    if lfs.attributes(self.storage_dir, "mode") ~= "directory" then
        lfs.mkdir(self.storage_dir)
    end
    self.ui.menu:registerToMainMenu(self)
end

function Scratchpad:addToMainMenu(menu_items)
    menu_items.scratchpad = {
        text = _("Later Thoughts"),
        icon = "edit",
        sorting_hint = "more_tools",
        callback = function() self:open() end,
    }
end

function Scratchpad:open()
    self:showPicker()
end

function Scratchpad:showPicker()
    local items = {
        {
            text = _("+ Quick Entry"),
            callback = function()
                UIManager:close(self.picker_container)
                self.picker_container = nil
                self.picker = nil
                self:openQuickEntry()
            end,
        },
        {
            text = _("+ New Note"),
            callback = function()
                UIManager:close(self.picker_container)
                self.picker_container = nil
                self.picker = nil
                self:openEditor(nil, "", false, _("New Note"))
            end,
        },
        {
            text = _("⚙ Manage Notes"),
            callback = function()
                UIManager:close(self.picker_container)
                self.picker_container = nil
                self.picker = nil
                self:showManageNotes()
            end,
        },
        {
            text = "────────────────",
            enabled = false,
        },
        {
            text = _("Close"),
            callback = function()
                if self.picker_container then
                    UIManager:close(self.picker_container)
                end
                self.picker_container = nil
                self.picker = nil
            end,
        },
    }

    local current_notes = getNotes(self.storage_dir)
    if #current_notes == 0 then
        table.insert(items, {
            text = _("No notes yet"),
            enabled = false,
        })
    end

    for _, note in ipairs(current_notes) do
        local display = note.name:gsub("%.txt$", "")
        table.insert(items, {
            text = display,
            callback = function()
                UIManager:close(self.picker_container)
                self.picker_container = nil
                self.picker = nil
                self:openEditor(note.path, readFile(note.path), false, display)
            end,
        })
    end

    local container = CenterContainer:new{
        covers_header = true,
        dimen = Device.screen:getSize(),
    }

    local menu = Menu:new{
        title = _("Later Thoughts"),
        item_table = items,
        width = math.floor(Device.screen:getWidth() * 0.82),
        height = math.floor(Device.screen:getHeight() * 0.72),
        is_borderless = false,
        is_popout = true,
        with_bottom_line = true,
        show_parent = container,
        close_callback = function()
            local parent = self.picker_container
            self.picker_container = nil
            self.picker = nil
            if parent then
                UIManager:close(parent)
            end
        end,
    }

    container[1] = menu
    self.picker_container = container
    self.picker = menu
    UIManager:show(container)
end

function Scratchpad:showManageNotes()
    local items = {
        {
            text = _("‹ Back to Later Thoughts"),
            callback = function()
                if self.manage_container then
                    UIManager:close(self.manage_container)
                    self.manage_container = nil
                end
                self:showPicker()
            end,
        },
        {
            text = "────────────────",
            enabled = false,
        },
    }
    local manage_menu
    local manage_container

    for _, note in ipairs(getNotes(self.storage_dir)) do
        local display = note.name:gsub("%.txt$", "")
        table.insert(items, {
            text = display,
            callback = function()
                self:showNoteActions(note.path, display, manage_container)
            end,
        })
    end

    if #getNotes(self.storage_dir) == 0 then
        table.insert(items, {
            text = _("No notes yet"),
            enabled = false,
        })
    end

    manage_container = CenterContainer:new{
        covers_header = true,
        dimen = Device.screen:getSize(),
    }

    manage_menu = Menu:new{
        title = _("⚙ Manage Notes"),
        subtitle = _("Open, rename, or delete notes"),
        item_table = items,
        width = math.floor(Device.screen:getWidth() * 0.82),
        height = math.floor(Device.screen:getHeight() * 0.72),
        is_borderless = false,
        is_popout = true,
        with_bottom_line = true,
        title_bar_fm_style = true,
        show_parent = manage_container,
        close_callback = function()
            local parent = self.manage_container
            self.manage_container = nil
            if parent then
                UIManager:close(parent)
            end
        end,
    }

    manage_container[1] = manage_menu
    self.manage_container = manage_container
    UIManager:show(manage_container)
end

function Scratchpad:showNoteActions(path, display, manage_container)
    local dialog
    dialog = ButtonDialog:new{
        title = display,
        buttons = {
            {{ text = _("Open"), callback = function()
                UIManager:close(dialog)
                if manage_container then UIManager:close(manage_container) end
                self:openEditor(path, readFile(path), false, display)
            end }},
            {{ text = _("Rename"), callback = function()
                UIManager:close(dialog)
                if manage_container then UIManager:close(manage_container) end
                self:renameNote(path, display)
            end }},
            {{ text = _("Delete"), callback = function()
                UIManager:close(dialog)
                UIManager:show(ConfirmBox:new{
                    text = _("Delete this note?"),
                    ok_text = _("Delete"),
                    cancel_text = _("Cancel"),
                    ok_callback = function()
                        os.remove(path)
                        if manage_container then UIManager:close(manage_container) end
                        self:showPicker()
                    end,
                })
            end }},
            {{ text = _("Cancel"), callback = function() UIManager:close(dialog) end }},
        },
    }
    UIManager:show(dialog)
end

function Scratchpad:getCurrentBookContext()
    local ReaderUI = package.loaded["apps/reader/readerui"]
    local reader = ReaderUI and ReaderUI.instance
    if not reader or not reader.document then return nil end

    local title
    if reader.doc_props and reader.doc_props.display_title then
        title = reader.doc_props.display_title
    elseif reader.document.info and reader.document.info.title then
        title = reader.document.info.title
    end

    local page
    if reader.view and reader.view.current_page then
        page = reader.view.current_page
    elseif reader.document.getCurrentPage then
        page = reader.document:getCurrentPage()
    end

    if not title and not page then return nil end
    return { title = title or _("Current book"), page = page }
end

function Scratchpad:contextLine()
    local ctx = self:getCurrentBookContext()
    local stamp = os.date("%Y-%m-%d %H:%M")
    if ctx then
        if ctx.page then
            return string.format("[%s] %s — p.%s", stamp, ctx.title, tostring(ctx.page))
        end
        return string.format("[%s] %s", stamp, ctx.title)
    end
    return "[" .. stamp .. "]"
end

function Scratchpad:bookPageText()
    local ctx = self:getCurrentBookContext()
    if not ctx then return "" end
    if ctx.page then
        return string.format("%s — p.%s", ctx.title, tostring(ctx.page))
    end
    return ctx.title
end

function Scratchpad:firstNonEmptyLine(text)
    for line in (text .. "\n"):gmatch("(.-)\r?\n") do
        line = trim(line)
        if line ~= "" then return line end
    end
    return nil
end

function Scratchpad:openQuickEntry()
    local path = self.storage_dir .. "/Quick Notes.txt"
    local existing = readFile(path)
    local text = existing
    if text ~= "" and text:sub(-1) ~= "\n" then text = text .. "\n" end
    if text ~= "" then text = text .. "\n" end
    text = text .. self:contextLine() .. "\n\n"
    self:openEditor(path, text, true, _("Quick Entry"))
end

function Scratchpad:openEditor(path, initial_text, quick_entry, title)
    local editor
    editor = InputDialog:new{
        title = title,
        input = initial_text or "",
        fullscreen = true,
        condensed = true,
        allow_newline = true,
        add_nav_bar = true,
        save_button_text = _("Save"),
        close_button_text = _("Close"),
        close_unsaved_confirm_text = _("Discard unsaved changes?"),
        close_discard_button_text = _("Discard"),
        close_save_button_text = _("Save"),

        buttons = {
            {
                {
                    text = _("Insert"),
                    callback = function()
                        self:showInsertMenu(editor)
                    end,
                },
            },
        },

        save_callback = function(content)
            if quick_entry then
                local ok, err = writeFile(path, content)
                if not ok then
                    return false, _("Could not save note: ") .. tostring(err)
                end
                return true
            end

            if trim(content or "") == "" then return true end

            local target = path
            if not target then
                local first_line = self:firstNonEmptyLine(content)
                local title_name = safeFilename(first_line)
                if not title_name then return true end

                target = self.storage_dir .. "/" .. title_name .. ".txt"
                if lfs.attributes(target, "mode") then
                    local n = 2
                    while lfs.attributes(self.storage_dir .. "/" .. title_name .. " (" .. n .. ").txt", "mode") do
                        n = n + 1
                    end
                    target = self.storage_dir .. "/" .. title_name .. " (" .. n .. ").txt"
                end
                path = target
            end

            local ok, err = writeFile(target, content)
            if not ok then
                return false, _("Could not save note: ") .. tostring(err)
            end
            return true
        end,

        close_callback = function() self.editor = nil end,
    }

    self.editor = editor
    UIManager:show(editor)
    editor:onShowKeyboard()
end

function Scratchpad:showInsertMenu(editor)
    local ctx = self:getCurrentBookContext()
    local dialog

    local function restoreKeyboard()
        UIManager:scheduleIn(0.05, function()
            if editor and editor.onShowKeyboard then
                editor:onShowKeyboard()
            end
        end)
    end

    local function closeAndInsert(text)
        UIManager:close(dialog)
        editor:addTextToInput(text)
        restoreKeyboard()
    end

    if editor.onCloseKeyboard then
        editor:onCloseKeyboard()
    end

    local items = {
        {
            text = _("Timestamp"),
            callback = function()
                closeAndInsert(os.date("[%Y-%m-%d %H:%M] "))
            end,
        },
        {
            text = _("Date"),
            callback = function()
                closeAndInsert(os.date("%Y-%m-%d "))
            end,
        },
    }

    if ctx then
        table.insert(items, {
            text = _("Book + page"),
            callback = function()
                closeAndInsert(self:bookPageText() .. " ")
            end,
        })
        table.insert(items, {
            text = _("Timestamp + book + page"),
            callback = function()
                closeAndInsert(self:contextLine() .. "\n")
            end,
        })
    end

    table.insert(items, {
        text = _("Divider"),
        callback = function()
            closeAndInsert("\n────────────────\n")
        end,
    })

    table.insert(items, {
        text = _("Bullet"),
        callback = function()
            closeAndInsert("• ")
        end,
    })

    table.insert(items, {
        text = _("Close"),
        callback = function()
            UIManager:close(dialog)
            restoreKeyboard()
        end,
    })

    dialog = Menu:new{
        title = _("Insert"),
        item_table = items,
        width = math.floor(Device.screen:getWidth() * 0.68),
        height = math.floor(Device.screen:getHeight() * 0.60),
        is_borderless = false,
        is_popout = true,
        with_bottom_line = true,
        close_callback = function()
            restoreKeyboard()
        end,
    }

    UIManager:show(dialog)
end

function Scratchpad:renameNote(path, old_title)
    local dialog
    dialog = InputDialog:new{
        title = _("Rename note"),
        input = old_title,
        buttons = {{
            { text = _("Cancel"), callback = function() UIManager:close(dialog) end },
            { text = _("Rename"), is_enter_default = true, callback = function()
                local new_title = safeFilename(dialog:getInputText())
                if not new_title then
                    UIManager:show(ConfirmBox:new{
                        text = _("Please enter a note name."),
                        ok_text = _("OK"),
                    })
                    return
                end

                local new_path = self.storage_dir .. "/" .. new_title .. ".txt"
                if new_path ~= path and lfs.attributes(new_path, "mode") then
                    UIManager:show(ConfirmBox:new{
                        text = _("A note with that name already exists."),
                        ok_text = _("OK"),
                    })
                    return
                end

                local ok, err = os.rename(path, new_path)
                if not ok then
                    UIManager:show(ConfirmBox:new{
                        text = _("Could not rename note: ") .. tostring(err),
                        ok_text = _("OK"),
                    })
                    return
                end

                UIManager:close(dialog)
                self:showPicker()
            end },
        }},
    }
    UIManager:show(dialog)
    dialog:onShowKeyboard()
end

return Scratchpad
