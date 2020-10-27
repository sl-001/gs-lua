local vector = require "vector"

local w, h = client.screen_size()
local off = {
    enabled = ui.new_checkbox("lua", "a", "Player indication"),
    clr = ui.new_color_picker("lua", "a", "arr:clr", 255, 255, 255, 255),
    size = ui.new_slider("lua", "a", "\n", 1, 35, 16, true, "px"),
    radius = ui.new_slider("lua", "a", "\n\n", -1, 100, -1, true, "%", 1, {[-1]="Distance"}),
    pulse = ui.new_slider("lua", "a", "Pulse", 0, 100, 18, true, "", 0.01, {[0]="Off"}),
    off_ = ui.new_checkbox("lua", "a", "Only off-screen"),
    lock = { ui.new_checkbox("lua", "a", "Lock on screen"), ui.new_slider("lua", "a", "\n\n\n", 0, 100, 80, true, "px") }
}

local function lerp(a, b, percentage)
	return a + (b - a) * percentage
end

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

local function on_paint()
    local size, radius, clr = ui.get(off.size), 1000*(ui.get(off.radius)/100), {ui.get(off.clr)}
    local fix_rad = radius+size
    local realtime = globals.realtime() * (ui.get(off.pulse)/10)
    local val = realtime % 2
	if val > 1 then
		val = 2 - val
	end
    local a_new = lerp(0, clr[4], val)
    local local_pos = vector(entity.get_origin(entity.get_local_player())); local_pos.z = 0
    if local_pos == nil then return end
    local view = {client.camera_angles()}
    if view == nil then return end
    
    for i=1, #entity.get_players(true) do
        enemy = entity.get_players(true)[i]
        
        local pos = vector(entity.get_origin(enemy)); pos.z = 0
        if pos == nil then return end
        local distance = math.min(800, local_pos:dist(pos))
        local w2s = {renderer.world_to_screen(pos.x, pos.y, pos.z)}
        local angle_x, angle_y = local_pos:to(pos):angles()
        if angle_y == nil then return end
        angle_y = 270-angle_y+view[2]
        local angle_rad = math.rad(angle_y)
        if ui.get(off.radius) < 0 then fix_rad = (1000*distance/800)+size end
        local point = { x=w/2+math.cos(angle_rad)*(fix_rad), y=h/2+math.sin(angle_rad)*(fix_rad) }
        if ui.get(off.lock[1]) then
            if point.x < ui.get(off.lock[2]) then point.x = ui.get(off.lock[2]) elseif point.x > w-ui.get(off.lock[2]) then point.x = w-ui.get(off.lock[2]) end
            if point.y < ui.get(off.lock[2]) then point.y = ui.get(off.lock[2]) elseif point.y > h-ui.get(off.lock[2]) then point.y = h-ui.get(off.lock[2]) end
        end
        local point_, point2 = { x=point.x-size/2, y=point.y-size }, { x=point.x+size/2, y=point.y-size }
        local get_rot = {rotate_around_c(math.rad(angle_y-90), point, point_, point2)}
        local new_point, new_point_ = {get_rot[1], get_rot[2]}, {get_rot[3], get_rot[4]}

        if ui.get(off.off_) then
            if not w2s[1] or w2s[1] > w or w2s[1] < 0 then
                renderer.triangle(point.x, point.y, new_point[1], new_point[2], new_point_[1], new_point_[2], clr[1], clr[2], clr[3], ui.get(off.pulse) > 0 and a_new or clr[4])
            end
        else
            renderer.triangle(point.x, point.y, new_point[1], new_point[2], new_point_[1], new_point_[2], clr[1], clr[2], clr[3], ui.get(off.pulse) > 0 and a_new or clr[4])
        end
    end
end

local function set_call()
    if ui.get(off.enabled) then
        client.set_event_callback("paint", on_paint)
    else
        client.unset_event_callback("paint", on_paint)
    end
    ui.set_visible(off.size, ui.get(off.enabled))
    ui.set_visible(off.radius, ui.get(off.enabled))
    ui.set_visible(off.pulse, ui.get(off.enabled))
    ui.set_visible(off.off_, ui.get(off.enabled))
    ui.set_visible(off.lock[1], ui.get(off.enabled))
    ui.set_visible(off.lock[2], ui.get(off.enabled) and ui.get(off.lock[1]))
end
ui.set_callback(off.enabled, set_call)
set_call()

local function menu_util()
    ui.set_visible(off.lock[2], ui.get(off.enabled) and ui.get(off.lock[1]))
end
ui.set_callback(off.lock[1], menu_util)
menu_util()
