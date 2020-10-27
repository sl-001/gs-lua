--> init gamesense libraries
local vector, ffi = require "vector", require "ffi"
local ffi_cast = ffi.cast

ffi.cdef [[
typedef int(__thiscall* get_clipboard_text_count)(void*);
typedef void(__thiscall* set_clipboard_text)(void*, const char*, int);
typedef void(__thiscall* get_clipboard_text)(void*, int, const char*, int);
]]

local VGUI_System010 =  client.create_interface("vgui2.dll", "VGUI_System010") or print( "Error finding VGUI_System010")
local VGUI_System = ffi_cast( ffi.typeof( "void***" ), VGUI_System010 )
local get_clipboard_text_count = ffi_cast( "get_clipboard_text_count", VGUI_System[ 0 ][ 7 ] ) or print( "get_clipboard_text_count Invalid")
local set_clipboard_text = ffi_cast( "set_clipboard_text", VGUI_System[ 0 ][ 9 ] ) or print( "set_clipboard_text Invalid")
local get_clipboard_text = ffi_cast( "get_clipboard_text", VGUI_System[ 0 ][ 11 ] ) or print( "get_clipboard_text Invalid")

--> local variables
local mouse = {}
local logs = database.read("console/prev_logs") or {}
local w, h = client.screen_size()
local width, height = database.read("console/width") or 600, database.read("console/height") or 500
local fade, fade_, clear_f, scroll_f = 1, 1, 1, 1
local scroll = false
local longest = "gamesense console                                  "
local clear_ = { false, false }
local settings = {
    enabled = ui.new_checkbox("lua", "a", "Console settings"),
    always_open = ui.new_checkbox("lua", "a", "» Always on-screen"),
    _ = ui.new_label("lua", "a", "» Prefix"),
    prfx = ui.new_textbox("lua", "a", "pre_fix"),
    __ = ui.new_label("lua", "a", "» Prefix colored"),
    prfxc = ui.new_textbox("lua", "a", "pre_fix_clrd"),
    override_clr = ui.new_checkbox("lua", "a", "» Override color"),
    ovr_clr = ui.new_color_picker("lua", "a", "ovr_clr___", 147, 195, 50, 255),
    copy = ui.new_checkbox("lua", "a", "» Don't copy prefixes"),
    center = ui.new_multiselect("lua", "a", "» Center", "X position", "Y position")
}
ui.set(settings.enabled, database.read("console/save/enabled") or false); ui.set(settings.always_open, database.read("console/save/always") or false); ui.set(settings.prfx, database.read("console/save/prefix") or "game"); ui.set(settings.prfxc, database.read("console/save/prefix_c") or "sense"); ui.set(settings.copy, database.read("console/save/dont_copy") or false); ui.set(settings.override_clr, database.read("console/save/clr_C") or false)
if database.read("console/save/clr_r") ~= nil then ui.set(settings.ovr_clr, database.read("console/save/clr_r"), database.read("console/save/clr_g"), database.read("console/save/clr_b"), database.read("console/save/clr_a")) end

local pos = {
    x = database.read("console/pos/x") or w/2-width/2,
    y = database.read("console/pos/y") or h/2-height/2,
    drag = false,
    resize = false,
    rx = 0, ry = 0,
    ty = 0
}
local scrll = {
    y = pos.y-12,
    drag = false,
    fix = 0
}

--> local functions
local function draw_container(x, y, w, h, a)
    local c = {10, 60, 40, 40, 40, 60, 20}
    for i = 0,6,1 do
        renderer.rectangle(x+i, y+i, w-(i*2), h-(i*2), c[i+1], c[i+1], c[i+1], a)
    end
end

local function intersect(cx, cy, x_, y_, width, height) 
    return cx >= x_ and cx <= x_ + width and cy >= y_ and cy <= y_ + height
end

local function clamp(b, c, d)
    local e=b; e=e<c and c or e;e=e>d and d or e
    return e
end

local function contains( tbl, val )
    for i = 1, #tbl do
        if tbl[ i ] == val then return true end
    end
    return false
end

--> callbacks
local function on_paint()
    local r, g, b, a = ui.get(ui.reference("misc", "settings", "menu color"))
    if ui.get(settings.override_clr) then r, g, b, a = ui.get(settings.ovr_clr) end
    local speed, speed_ = globals.frametime() * 8, globals.frametime() * 12
    mouse.left, mouse.pos = client.key_state(0x01), {ui.mouse_position()}
    if not mouse.left then mouse.fixed_pos = {ui.mouse_position()} end

    if ui.is_menu_open() then
        if pos.drag and not mouse.left then pos.drag = false end

        if pos.drag and mouse.left then
            pos.x = mouse.pos[1] - pos.drag_x
            pos.y = mouse.pos[2] - pos.drag_y
            database.write("console/pos/x", pos.x)
            database.write("console/pos/y", pos.y)
        end

        if intersect(mouse.fixed_pos[1], mouse.fixed_pos[2], pos.x, pos.y, width-10, height-10) and mouse.left then
            pos.drag = true
            pos.drag_x = mouse.pos[1] - pos.x
            pos.drag_y = mouse.pos[2] - pos.y
        end

        if mouse.left and not ui.get(ui.reference("misc", "settings", "lock menu layout")) then
            if pos.resize then
                width = mouse.pos[1] - pos.rx
                height = mouse.pos[2] - pos.ry
                pos.drag = false
                database.write("console/width", width)
                database.write("console/height", height)
            end

            if intersect(mouse.pos[1], mouse.pos[2], pos.x+width-10, pos.y+height-10, 10, 10) then
                pos.resize = true
                pos.rx = mouse.pos[1] - width
                pos.ry = mouse.pos[2] - height
            end
        else
            pos.resize = false
        end
    end

    if fade ~= 0 then
        if width < 42+renderer.measure_text("", longest) then width = 42+renderer.measure_text("", longest) end
        if height < 200 then height = 200 end
        if contains(ui.get(settings.center), "X position") then
            pos.x = w/2-width/2
        end
        if contains(ui.get(settings.center), "Y position") then
            pos.y = h/2-height/2
        end
        draw_container(pos.x, pos.y, width, height, fade*255)
        renderer.rectangle(pos.x+12, pos.y+25, width-24, height-37, 30, 30, 30, fade_*255)

        local scroll_h = height-(15*#logs)
        local temp_h = scroll_h < 15 and 15 or scroll_h > height-40 and height-40 or scroll_h
        local temp_y = pos.y+scrll.fix+height-12-temp_h

        for i=1, #logs do
            log = logs[i]
            local ya = scrll.y
            
            pos.ty = pos.y+(height-160)-15*(#logs-i)-ya
            if pos.ty >= pos.y+24 and pos.ty < pos.y+height-22 then
                log[3] = intersect(mouse.pos[1], mouse.pos[2], pos.x+16, pos.ty, width-34, 14) and not scrll.drag
                log[4] = mouse.left and log[3]
                local msg = ""
                if log[3] then renderer.rectangle(pos.x+17, pos.ty, width-34, 14, log[3] and 60 or 50, log[3] and 60 or 50, log[3] and 60 or 50, 255) end
                if log[2] == "log" then
                    renderer.text(pos.x+18, pos.ty, r, g, b, fade*a, "", 0, "[" .. ui.get(settings.prfx) .. ui.get(settings.prfxc) .. "]")
                    renderer.text(pos.x+18+renderer.measure_text("", "[" .. ui.get(settings.prfx) .. ui.get(settings.prfxc) .. "]"), pos.ty, 255, 255, 255, fade*255, "", 0, " " .. log[1])
                    msg = "[" .. ui.get(settings.prfx) .. ui.get(settings.prfxc) .. "] " .. log[1]
                    if ui.get(settings.copy) then msg = log[1] end
                    if renderer.measure_text("", "[" .. ui.get(settings.prfx) .. ui.get(settings.prfxc) .. "] " .. log[1]) > renderer.measure_text("", longest) then longest = "[" .. ui.get(settings.prfx) .. ui.get(settings.prfxc) .. "] " .. log[1] end
                elseif log[2] == "err" then
                    renderer.text(pos.x+18, pos.ty, r, g, b, fade*a, "", 0, "[" .. ui.get(settings.prfx) .. ui.get(settings.prfxc) .. "]")
                    renderer.text(pos.x+18+renderer.measure_text("", "[" .. ui.get(settings.prfx) .. ui.get(settings.prfxc) .. "]"), pos.ty, 255, 0, 50, fade*255, "", 0, " " .. log[1])
                    msg = "[" .. ui.get(settings.prfx) .. ui.get(settings.prfxc) .. "] " .. log[1]
                    if ui.get(settings.copy) then msg = log[1] end
                    if renderer.measure_text("", "[" .. ui.get(settings.prfx) .. ui.get(settings.prfxc) .. "] " .. log[1]) > renderer.measure_text("", longest) then longest = "[" .. ui.get(settings.prfx) .. ui.get(settings.prfxc) .. "] " .. log[1] end
                elseif log[2] == "msg" then
                    renderer.text(pos.x+18, pos.ty, 255, 255, 255, fade*255, "", 0, log[1])
                    msg = log[1]
                    if renderer.measure_text("", log[1]) > renderer.measure_text("", longest) then longest = log[1] end
                elseif log[2] == "player_msg" then
                    log[5]= log[5]:sub(0, 22)
                    renderer.text(pos.x+18, pos.ty, r, g, b, fade*a, "", 0, log[5])
                    renderer.text(pos.x+18+renderer.measure_text("", log[5]), pos.ty, 255, 255, 255, fade*255, "", 0, " »")
                    renderer.text(pos.x+18+renderer.measure_text("", log[5] .. " » "), pos.ty, 255, 255, 255, fade*255, "", 0, log[1])
                    msg = log[5] .. " : " .. log[1]
                    if ui.get(settings.copy) then msg = log[1] end
                    if renderer.measure_text("", log[5] .. " : " .. log[1]) > renderer.measure_text("", longest) then longest = log[5] .. " : " .. log[1] end
                end
                if log[4] then set_clipboard_text(VGUI_System, msg, msg:len()) end
            else
                scroll = true
            end
            last_y = pos.ty
        end
        renderer.gradient(pos.x+12, pos.y+26, width-24, 15, 30, 30, 30, fade_*255, 30, 30, 30, 0, false)
        renderer.gradient(pos.x+12, pos.y+height-26, width-24, 15, 30, 30, 30, 0, 30, 30, 30, fade_*255, false)
        renderer.text(pos.x+12, pos.y+8, 220, 220, 220, fade*255, "", 0, ui.get(settings.prfx))
        renderer.text(pos.x+12+renderer.measure_text("", ui.get(settings.prfx)), pos.y+8, r, g, b, fade*a, "", 0, ui.get(settings.prfxc))
        renderer.text(pos.x+12+renderer.measure_text("", ui.get(settings.prfx) .. ui.get(settings.prfxc)), pos.y+8, 220, 220, 220, fade*255, "", 0, " console")
        clear_[1] = intersect(mouse.pos[1], mouse.pos[2], pos.x+width-72, pos.y+8, 60, 16)
        clear_[2] = clear_[1] and mouse.left
        if entity.is_alive(entity.get_local_player()) == false or entity.get_local_player() == nil then
            clear_f = 0
        end
        if clear_f ~= 0 then
            renderer.rectangle(pos.x+width-72, pos.y+8, 60, 16, clear_[2] and 60 or clear_[1] and 50 or 40, clear_[2] and 60 or clear_[1] and 50 or 40, clear_[2] and 60 or clear_[1] and 50 or 40, clear_f*255)
            renderer.text(pos.x+width-42, pos.y+15, 255, 255, 255, clear_f*255, "c", 0, "Clear")
        end
        

        if scroll then
            if ui.is_menu_open() then
                if scrll.drag and not mouse.left then scrll.drag = false end
        
                if scrll.drag and mouse.left then
                    scrll.fix = mouse.pos[2] - scrll.drag_y
                    
                    pos.drag = false
                    pos.resize = false
                end
                

                scrll.y = scrll.fix-120
                if temp_y+temp_h > pos.y+height-12 then temp_y = pos.y+height-12-temp_h end
                if temp_y < pos.y+28 then temp_y = pos.y+28 end
        
                if intersect(mouse.pos[1], mouse.pos[2], pos.x+width-17, temp_y, 10, temp_h) and mouse.left then
                    scrll.drag = true
                    scrll.drag_y = mouse.pos[2] - scrll.fix
                end
            end
            

            if scroll_f ~= 0 then
                renderer.rectangle(pos.x+width-18, pos.y+26, 6, height-38, 35, 35, 35, scroll_f*255)
                renderer.rectangle(pos.x+width-17, temp_y, 4, temp_h, 45, 45, 45, scroll_f*255)
            end
        end
    end
    
    if ui.get(settings.always_open) then
        fade = 1; fade_ = 1
    else
        fade = clamp(fade + (ui.is_menu_open() and speed/2 or -speed), 0, 1)
        fade_ = clamp(fade_ + (ui.is_menu_open() and speed_/2 or -speed_), 0, 1)
    end
    clear_f = clamp(clear_f + (ui.is_menu_open() and speed/2 or -speed), 0, 1)
    scroll_f = clamp(scroll_f + (ui.is_menu_open() and speed/2 or -speed), 0, 1)
end

local o_client_log = _G["client"]["log"]
_G["client"]["log"] = function(...)
	local args = {...}
	local str = ""
	for k, v in pairs(args) do
		str = str .. tostring(v) .. " "
	end
    table.insert(logs, {str, "log", false, false})
    database.write("console/prev_logs", logs)
    local ret = { o_client_log(unpack(args)) }
	return unpack(ret)
end
local o_error_log = _G["client"]["error_log"]
_G["error"] = function(...)
	local args = {...}
	local str = ""
	for k, v in pairs(args) do
		str = str .. tostring(v) .. " "
	end
    table.insert(logs, {str, "err", false, false})
    database.write("console/prev_logs", logs)
    local ret = { o_error_log(unpack(args)) }
	return unpack(ret)
end
local o_print = _G["print"]
_G["print"] = function(...)
	local args = {...}
	local str = ""
	for k, v in pairs(args) do
		str = str .. tostring(v) .. " "
	end
    table.insert(logs, {str, "log", false, false})
    database.write("console/prev_logs", logs)
    local ret = { o_print(unpack(args)) }
	return unpack(ret)
end
local o_error = _G["error"]
_G["error"] = function(...)
	local args = {...}
	local str = ""
	for k, v in pairs(args) do
		str = str .. tostring(v) .. " "
	end
    table.insert(logs, {str, "err", false, false})
    database.write("console/prev_logs", logs)
    local ret = { o_error(unpack(args)) }
	return unpack(ret)
end

function cast(log, name, msg)
    if log == nil or type(log) ~= "string" or log ~= "log" and log ~= "msg" and log ~= "player_msg" then return error("Invalid arg[1] for 'cast'") end
    if msg == nil then return end
    if log == "player_msg" and name == nil then
        name = entity.get_player_name(entity.get_local_player) ~= "unknown" and entity.get_player_name(entity.get_local_player) or "retard"
    end

    table.insert(logs, {msg, log, false, false, name})
    database.write("console/prev_logs", logs)
    local index = #logs
    return index
end

function clear(idx)
    if idx == nil or type(idx) ~= "number" then return error("Incorrect index") end
    table.remove(logs, idx)
    database.write("console/prev_logs", nil)
end

function edit(idx, msg)
    if idx == nil or type(idx) ~= "number" then return error("Incorrect index") end
    logs[idx][1] = msg
end

function get_table()
    local tbl = {}
    for i=1, #logs do
        table.insert(tbl, {logs[i][1], false})
    end
    return tbl
end

local is_pressed = false
client.set_event_callback("setup_command", function()
    if client.key_state(0x01) then
        is_pressed = true
    else
        if clear_[1] and ui.is_menu_open() and is_pressed then
            for j in pairs(logs) do
                logs[j] = nil
            end
            longest = "gamesense console                                  "
            scroll = false
        end
        is_pressed = false
    end
end) 
client.set_event_callback("paint_ui", on_paint)
client.set_event_callback("console_input", function(out)
    if out:sub(0, 5):lower() == "clear" or out:sub(0, 10) == "clear_cast" then
        for j in pairs(logs) do
            logs[j] = nil
        end
        longest = "gamesense console                                  "
        scroll = false
        return false
    end
end)
client.set_event_callback("player_hurt", function(e)
    if not ui.get(ui.reference("misc", "miscellaneous", "log damage dealt")) then return end
    local hitgroup_names = {"generic", "head", "chest", "stomach", "left arm", "right arm", "left leg", "right leg", "neck", "?", "gear"}
    local group = hitgroup_names[e.hitgroup + 1] or "?"
    if client.userid_to_entindex(e.attacker) == entity.get_local_player() then
        cast("log", nil, "Hit " .. entity.get_player_name(client.userid_to_entindex(e.userid)) .. " in the " .. group .. " for " .. e.dmg_health .. " damage (" .. e.health .. " health remaining)")
    end
end)
client.set_event_callback("aim_miss", function(e)
    if e.reason == "spread" and ui.get(ui.reference("rage", "aimbot", "log misses due to spread")) then
        cast("log", nil, "Missed shot due to spread")
    end
end)

client.set_event_callback("shutdown", function()
    local r, g, b, a = ui.get(settings.ovr_clr)
    database.write("console/save/enabled", ui.get(settings.enabled))
    database.write("console/save/always", ui.get(settings.always_open))
    database.write("console/save/prefix", ui.get(settings.prfx))
    database.write("console/save/prefix_c", ui.get(settings.prfxc))
    database.write("console/save/clr_C", ui.get(settings.override_clr))
    database.write("console/save/clr_r", r)
    database.write("console/save/clr_g", g)
    database.write("console/save/clr_b", b)
    database.write("console/save/clr_a", a)
    database.write("console/save/dont_copy", ui.get(settings.copy))
end)

local function menu_init()
    local e = ui.get(settings.enabled)
    ui.set_visible(settings.always_open, e)
    ui.set_visible(settings._, e)
    ui.set_visible(settings.prfx, e)
    ui.set_visible(settings.__, e)
    ui.set_visible(settings.prfxc, e)
    ui.set_visible(settings.override_clr, e)
    ui.set_visible(settings.ovr_clr, e)
    ui.set_visible(settings.copy, e)
    ui.set_visible(settings.center, e)
end

ui.set_callback(settings.enabled, menu_init)
menu_init()

local functions = {
    print = cast,
    edit = edit,
    clear = clear,
    get_table = get_table
}
return functions
