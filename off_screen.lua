--» init gs libraries
local vector, images = require "vector", require "gamesense/images"

local gs = {ent = entity, render = renderer, client = client}

--» variables
local w, h = client.screen_size()
local pa = {
    enabled = ui.new_checkbox("visuals", "player esp", "Arrow indicators"),
    clr = ui.new_color_picker("visuals", "player esp", "player_arrows:clr", 255, 255, 255, 255),
    clr2 = ui.new_color_picker("visuals", "player esp", "player_arrows:clr2", 255, 0, 0, 255),
    options = ui.new_multiselect("visuals", "player esp", "\noptions", "Dormant players", "Include weapons", "Include name", "Grenade warning", "Distance based size", "Distance based radius"),
    size = ui.new_slider("visuals", "player esp", "\nsize", 1, 35, 15, true, "px"),
    radius = ui.new_slider("visuals", "player esp", "\nradius", 0, 100, 100, true, "%"),
    pulse = ui.new_slider("visuals", "player esp", "Pulse", 0, 100, 18, true, "", 0.01, {[0]="Off"}),
    off_screen = ui.new_checkbox("visuals", "player esp", "Only off-screen"),
    limit = ui.new_checkbox("visuals", "player esp", "Limit edges"),
    limit_off = ui.new_slider("visuals", "player esp", "\nlimit_offset", 0, 100, 80, true, "px")
}

--» functions
local function contains(tbl, val)
	for i = 1, #tbl do
		if tbl[i] == val then return true end
	end
	return false
end

local function lerp(a, b, percentage)
	return a + (b - a) * percentage
end
--[[local alpha = globals.tickcount() % 510
alpha = math.max(0, math.min(255, alpha))]]

local function rotate_around_c(angle, center, point, point_)
    local s = math.sin(angle)
    local c = math.cos(angle)

    point.x = point.x-center.x
    point.y = point.y-center.y
    point_.x = point_.x-center.x
    point_.y = point_.y-center.y

    local xn, yn = point.x * c - point.y * s, point.x * s + point.y * c
    local x_n, y_n = point_.x * c - point_.y * s, point_.x * s + point_.y * c 

    return xn+center.x, yn+center.y, x_n+center.x, y_n+center.y
end

--» callbacks
local function on_paint()
    local player = gs.ent["get_local_player"]()
    if not player and gs.ent["is_alive"](player) then return end
    local r, g, b, a = ui.get(pa.clr)
    local size, get_radius, opts = ui.get(pa.size), 10*ui.get(pa.radius), ui.get(pa.options)
    local alpha = 1
    if ui.get(pa.pulse) > 0 then
        local realtime = globals.realtime() * (ui.get(pa.pulse)/10)
        local val = realtime % 2
	    if val > 1 then
	    	val = 2 - val
	    end
        alpha = lerp(0, a, val)/255
    end
    local radius = get_radius+size
    local view = vector(0, 0, 0)
    view.x, view.y = client.camera_angles()
    if view.x == nil then return end
    local pos = vector(gs.ent["get_origin"](player))
    local player_resource = gs.ent["get_player_resource"]()
    if not pos then return end

    for ent=1, globals.maxplayers() do
        if gs.ent["get_prop"](player_resource, "m_bConnected", ent) ~= 1 then
			goto skip
		end

        if not gs.ent["is_alive"](ent) then
            goto skip
        end

        if not gs.ent["is_enemy"](ent) then
            goto skip
        end

        local bb = {gs.ent["get_bounding_box"](ent)}
        local position = vector(gs.ent["get_origin"](ent))
        if not position then goto skip end
        local dist = math.min(800, pos:dist(position))/800
        local weapon = gs.ent["get_player_weapon"](ent)
        local weapon_idx = gs.ent["get_prop"](weapon, "m_iItemDefinitionIndex")
        if contains(opts, "Distance based size") then
            size = size*(1-dist)
        end
        if contains(opts, "Distance based radius") then
            radius = radius*(1-dist)
        end
        local w2s, w2s2 = gs.render["world_to_screen"](position.x, position.y, position.z)
        local _, angle = pos:to(position):angles()
        if not angle then goto skip end
        angle = 270-angle+view.y
        local angle_rad = math.rad(angle)
        local point = vector(w/2+math.cos(angle_rad)*(radius), h/2+math.sin(angle_rad)*(radius), 0)

        if ui.get(pa.limit) then
            point.x = math.min(w-ui.get(pa.limit_off), math.max(ui.get(pa.limit_off), point.x))
            point.y = math.min(h-ui.get(pa.limit_off), math.max(ui.get(pa.limit_off), point.y))
        end

        local point1, point2 = vector(point.x-size/2, point.y-size, 0), vector(point.x+size/2, point.y-size, 0)
        local converted = {rotate_around_c(math.rad(angle-90), point, point1, point2)}

        if gs.ent["is_dormant"](ent) then
            if contains(opts, "Dormant players") then
                r, g, b, a = 180, 180, 180, 255*bb[5]
            else
                goto skip
            end
        end

        if ui.get(pa.off_screen) then
            if w2s and w2s2 and w2s2 > 0 and w2s2 < h then a = 0 end
        end

        if contains(opts, "Grenade warning") then
            local class = gs.ent["get_classname"](ent)
            if class:find("Grenade") then
                r, g, b = ui.get(pa.clr2)
                if not contains(opts, "Include weapons") then
                    local get_icon = images.get_weapon_icon(weapon_idx)
                    if get_icon then
                        local def_size = get_icon:measure()
                        local size = {get_icon:measure(def_size*0.5)}
                        get_icon:draw(point.x-size[1]/2, point.y+5, size[1], size[2])
                    end
                end
            end
        end

        gs.render["triangle"](point.x, point.y, converted[1], converted[2], converted[3], converted[4], r, g, b, a*alpha)
        if contains(opts, "Include name") then
            gs.render["text"](point.x, point.y, 220, 220, 220, a, "-c", 0, gs.ent["get_player_name"](ent):upper())
        end
        if contains(opts, "Include weapons") then
            local get_icon = images.get_weapon_icon(weapon_idx)
            if get_icon then
                local def_size = get_icon:measure()
                local size = {get_icon:measure(def_size*0.5)}
                get_icon:draw(point.x-size[1]/2, point.y+5, size[1], size[2], 220, 220, 220, a)
            end
        end

        ::skip::
    end
end

local function ui_call(self)
    local main = ui.get(pa.enabled)
    local set_callback = gs.client[main and "set_event_callback" or "unset_event_callback"]

    for name, i in pairs(pa) do
        if name ~= "enabled" and name ~= "limit_off" and name ~= "pulse" then
            ui.set_visible(i, main)
        else
            if name == "limit_off" then
                ui.set_visible(i, main and ui.get(pa.limit))
            elseif name == "pulse" then
                ui.set_visible(i, main and not contains(ui.get(pa.options), "Distance based pulse"))
            end
            if self == pa.enabled then
                set_callback("paint", on_paint)
            end
        end
    end
end

ui.set_callback(pa.enabled, ui_call); ui.set_callback(pa.limit, ui_call); ui.set_callback(pa.options, ui_call)
ui_call()
