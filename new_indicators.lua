local js, img = panorama.open(), require "gamesense/images"

--> menu elements
local e = {
    enabled = ui.new_checkbox("visuals", "other esp", "Indicators"),
    opt = ui.new_multiselect("visuals", "other esp", "\n", "User info", "Force baim", "Double tap", "Desync", "Desync safety", "Fake lag", "Fake duck", "On shot", "Fake peek", "Min damage"),
}

--> local variables
local steamid64 = js.MyPersonaAPI.GetXuid()
local avatar = img.get_steam_avatar(steamid64, 65)
local w, h = client.screen_size()
local a_time = globals.tickcount()
local body_yaw = {0, 0}
local fade_out = false
local wnd = {
    x = database.read("indicators__x") or w,
    y = database.read("indicators__y") or h/2,
    dragging = false
}
local off = {
    ["User info"] = 20,
    ["Force baim"] = 20,
    ["Double tap"] = 20,
    ["Desync"] = 30,
    ["Desync safety"] = 30,
    ["Fake lag"] = 30,
    ["Fake duck"] = 20,
    ["On shot"] = 20,
    ["Fake peek"] = 20,
    ["Min damage"] = 30
}
local ref = {
    ui.reference("rage", "other", "force body aim"),
    {ui.reference("rage", "other", "double tap")},
    ui.reference("rage", "other", "duck peek assist"),
    {ui.reference("aa", "other", "on shot anti-aim")},
    {ui.reference("aa", "other", "fake peek")},
    ui.reference("rage", "aimbot", "minimum damage")
}

--> local function
local function contains(tbl, val)
    for i=1, #tbl do
        if tbl[i] == val then return true end
    end
    return false
end

local function intersect(x, y, w, h) 
    local cx, cy = ui.mouse_position()
    return cx >= x and cx <= x + w and cy >= y and cy <= y + h
end

local function draw_con(x, y, w, h, a, dragged, name, clr)
    local c = { 10, 60, 25 }
    local t = {renderer.measure_text("b", name)}
    for i = 0, 3, 1 do
        renderer.rectangle(x+i, y+i, w-(i*2), h-(i*2), c[i+1], c[i+1], c[i+1], a)
    end
    renderer.rectangle(x+5, y, t[1]+7, 2, 25, 25, 25, a)
    renderer.text(x+8, y-7, dragged and clr[1] or 220, dragged and clr[2] or 220, dragged and clr[3] or 220, a, "b", 0, name)
end

local function draw_check(x, y, name, state, clr, clr2)
    renderer.rectangle(x, y, 8, 8, 0, 0, 0, clr[4])
    renderer.gradient(x+1, y+1, 6, 6, 60, 60, 60, clr[4], 40, 40, 40, clr[4], false)
    if state then renderer.gradient(x+1, y+1, 6, 6, clr[1], clr[2], clr[3], clr[4], clr2[1], clr2[2], clr2[3], clr2[4], false) end
    renderer.text(x+16, y-3, 220, 220, 220, clr[4], "", 0, name)
end

local function draw_slider(x, y, w, name, perc, te, t_add, neg, show, clr, clr2)
    local off_ = name ~= "" and name ~= " " and name ~= nil and 15 or 0
    local ba = clr[4]-90
    ba = ba >= 0 and ba or 0
    if name ~= "" and name ~= " " and name ~= nil then
        renderer.text(x, y, 220, 220, 220, clr[4], "", 0, name)
    end
    renderer.rectangle(x, y+15, w, 7, 0, 0, 0, clr[4])
    renderer.gradient(x+1, y+16, w-2, 5, 70, 70, 70, 255, 50, 50, 50, clr[4], false)
    if neg then
        renderer.gradient(x+1+(w/2), y+16, (w/2)*(perc), 5, clr[1], clr[2], clr[3], clr[4], clr2[1], clr2[2], clr2[3], clr2[4], false)
        if show then
            renderer.text(x+w/2+(w/2)*(perc), y+20, 0, 0, 0, ba, "cb", 0, te .. t_add)
            renderer.text(x+2+w/2+(w/2)*(perc), y+20, 0, 0, 0, ba, "cb", 0, te .. t_add)
            renderer.text(x+1+w/2+(w/2)*(perc), y+21, 220, 220, 220, clr[4], "cb", 0, te .. t_add)
        end
    else
        renderer.gradient(x+1, y+16, w*(perc), 5, clr[1], clr[2], clr[3], clr[4], clr2[1], clr2[2], clr2[3], clr2[4], false)
        if show then
            renderer.text(x+w*(perc), y+20, 0, 0, 0, ba, "cb", 0, te .. t_add)
            renderer.text(x+2+w*(perc), y+20, 0, 0, 0, ba, "cb", 0, te .. t_add)
            renderer.text(x+1+w*(perc), y+21, 220, 220, 220, clr[4], "cb", 0, te .. t_add)
        end
    end
end

--> callbacks
local function on_paint()
    local get_local = entity.get_local_player()
    if get_local == nil or entity.is_alive(get_local) == false then return end
    if steamid64 == nil then steamid64 = js.MyPersonaAPI.getXuid(); avatar = img.get_steam_avatar(steamid64, 65) end
    local opts = ui.get(e.opt)
    local cx, cy = ui.mouse_position()
    local left_click = client.key_state(0x01)
    local a_ = math.min(10, -(a_time-globals.tickcount()))/10
    if fade_out then a_ = math.max(0, -(globals.tickcount()-a_time))/10 end
    local a = 255*a_
    local mclr = {ui.get(ui.reference("misc", "settings", "menu color"))};mclr[4] = a
    local mclr_ = {math.max(0, mclr[1]-50), math.max(0, mclr[2]-50), math.max(0, mclr[3]-50), a}
    local c_ = { x=wnd.x, y=wnd.y, w=200, h=20 }
    c_.x=c_.x-c_.w-5
    local ind = { x=c_.x+12, y=c_.y }
    local p = { name=entity.get_player_name(get_local):upper():sub(0, 10), hp=entity.get_prop(get_local, "m_iHealth") }

    for i, opt in pairs(opts) do 
        if opts[i] ~= nil then
            if opt == "Desync" then
                c_.h = c_.h + 30
            elseif opt == "Fake lag" then
                c_.h = c_.h + 30
            elseif opt == "Desync safety" then
                c_.h = contains(opts, "Desync") and c_.h + 15 or c_.h + 30
                if contains(opts, "Desync") then off["Desync safety"] = 15 else off["Desync safety"] = 30 end
            elseif opt == "Min damage" then
                c_.h = c_.h + 30
            else
                c_.h = c_.h + 20
            end
        end
    end

    if ui.is_menu_open() then
        if wnd.dragging and not left_click then
            wnd.dragging = false
        end
    
        if wnd.dragging and left_click then
            wnd.x = cx - wnd.drag_x
            wnd.y = cy - wnd.drag_y
        end
    
        if intersect(wnd.x-205, wnd.y, 200, c_.h) then
            wnd.dragging = true
            wnd.drag_x = cx - wnd.x
            wnd.drag_y = cy - wnd.y
        end
    end

    draw_con(c_.x, c_.y, c_.w, c_.h, a, intersect(wnd.x-205, wnd.y, 200, c_.h) and ui.is_menu_open() and wnd.dragging and left_click, "Indicators", mclr)
    --> container elements
    for i, opt in pairs(opts) do
        if off[opt] ~= nil then
            ind.y = ind.y + off[opt]
        end
        if opt == "User info" then
            avatar:draw(c_.x+10, ind.y-10, 20, 20, 255, 255, 255, a, true)
            renderer.text(c_.x+35, ind.y-5, 255, 255, 255, a, "-", 0, p.name)
            if entity.get_prop(get_local, "m_iHealth") > 0 then draw_slider(ind.x+80, ind.y-18, c_.w-114, "", math.min(1, p.hp/100), p.hp, "hp", false, true, mclr, mclr_) end
        elseif opt == "Force baim" then
            draw_check(ind.x, ind.y, "Body-aim", ui.get(ref[1]), mclr, mclr_)
        elseif opt == "Double tap" then
            draw_check(ind.x, ind.y, "Double tap", ui.get(ref[2][1]) and ui.get(ref[2][2]), mclr, mclr_)
            local cur, use = globals.curtime(), 0
            local act = entity.get_player_weapon(get_local)
            if act == nil then act = "" end
            local dt = {entity.get_prop(get_local, "m_flNextAttack"), entity.get_prop(act, "m_flNextPrimaryAttack"), entity.get_prop(act, "m_flNextSecondaryAttack")}
            if dt[1] ~= nil and dt[2] ~= nil and dt[3] ~= nil then
                dt[1] = dt[1]+0.5; dt[2] = dt[2]+0.5; dt[3] = dt[3]+0.5
                use = math.max(dt[1], dt[3]) < dt[2] and dt[3] - cur or math.max(dt[2], dt[3]) - cur
                if ui.get(ref[2][2]) and entity.get_classname(act) ~= "CKnife" then
                    if math.max(dt[1], dt[3]) < dt[2] and use > 0 or use > 0 then
                        draw_slider(ind.x+80, ind.y-14, c_.w-114, "", 1+math.max(-1, -use), math.max(0, math.floor((1-use)*100)), "%", false, true, mclr, mclr_)
                    end
                end
            end
        elseif opt == "Desync" then
            draw_slider(ind.x+16, ind.y-14, c_.w-50, "Desync", body_yaw[1]/60, body_yaw[1], "°", true, true, mclr, mclr_)
        elseif opt == "Desync safety" then
            draw_slider(ind.x+16, ind.y-14, c_.w-50, contains(opts, "Desync") and "" or "Desync safety", body_yaw[2]/60, math.floor(100*(body_yaw[2]/60)), "%", false, true, mclr, mclr_)
        elseif opt == "Fake lag" then
            draw_slider(ind.x+16, ind.y-14, c_.w-50, "Fake lag", globals.chokedcommands()/ui.get(ui.reference("aa", "fake lag", "limit")), globals.chokedcommands(), "", false, true, mclr, mclr_)
        elseif opt == "Fake duck" then
            draw_check(ind.x, ind.y, "Fake duck", ui.get(ref[3]), mclr, mclr_)
        elseif opt == "On shot" then
            draw_check(ind.x, ind.y, "On shot aa", ui.get(ref[4][1]) and ui.get(ref[4][2]), mclr, mclr_)
        elseif opt == "Fake peek" then
            draw_check(ind.x, ind.y, "Fake peek", ui.get(ref[5][1]) and ui.get(ref[5][2]), mclr, mclr_)
        elseif opt == "Min damage" then
            draw_slider(ind.x+16, ind.y-14, c_.w-50, "Minimum damage", ui.get(ref[6])/126, ui.get(ref[6]) == 0 and "Auto" or ui.get(ref[6]) >= 101 and "HP+" .. ui.get(ref[6])-100 or ui.get(ref[6]), "", false, true, mclr, mclr_)
        end
    end
end

local function setupcmd(e)
    if e.chokedcommands == 0 then
        body_yaw[1] = math.max(-60, math.min(60, math.floor((entity.get_prop(entity.get_local_player(), "m_flPoseParameter", 11) or 0)*120-60+0.5)))
        body_yaw[2] = math.min(60, math.abs(entity.get_prop(entity.get_local_player(), "m_flPoseParameter", 11)*120-60))
    end
end

--> menu and callback handling
local function enable() 
    if ui.get(e.enabled) then
        a_time = globals.tickcount()
        unset = math.huge
        fade_out = false
        client.set_event_callback("paint", on_paint)
        client.set_event_callback("setup_command", function(e) 
            setupcmd(e)
            if globals.tickcount() > unset then
                client.unset_event_callback("paint", on_paint)
                client.unset_event_callback("setup_command", setupcmd)
            end
        end)
    else
        unset = globals.tickcount()+10
        fade_out = true
        a_time = globals.tickcount()+10
    end
    ui.set_visible(e.opt, ui.get(e.enabled))
end
ui.set_callback(e.enabled, enable)
enable()
client.set_event_callback("player_connect_full", function(ev)
    if client.userid_to_entindex(ev.userid) == entity.get_local_player() then
        if ui.get(e.enabled) then
            unset = math.huge
            a_time = globals.tickcount()
        end
    end
end)
client.set_event_callback("shutdown", function() database.write("indicators__x", wnd.x); database.write("indicators__y", wnd.y) end)
