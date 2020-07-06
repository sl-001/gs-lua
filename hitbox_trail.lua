local tp = { ui.reference("visuals", "effects", "force third person (alive)") }
local int = {
    enabled = ui.new_checkbox("lua", "a", "Hitbox trail"),
    color = ui.new_color_picker("lua", "a", "trail_clr", 255, 255, 255, 125),
    hitbox = ui.new_multiselect("lua", "a", "\n\n", "Head", "Neck", "Shoulders", "Upper chest", "Chest", "Stomach", "Pelvis", "Left arm", "Left forearm", "Left hand", "Left thigh", "Left leg", "Left foot", "Right arm", "Right forearm", "Right hand", "Right thigh", "Right leg", "Right foot"),
    length = ui.new_slider("lua", "a", "\n", 1, 100, 10, true, "", 0.1),
    limit = ui.new_slider("lua", "a", "Velocity needed", 0, 250, 80),
    random = ui.new_checkbox("lua", "a", "Randomize hitboxes"),
    rainbow = ui.new_checkbox("lua", "a", "Rainbow"),
    tp_check = ui.new_checkbox("lua", "a", "Thirdperson check")
}
local hitboxes = { 
    ["Head"] = 0,
    ["Neck"] = 1,
    ["Pelvis"] = 2,
    ["Stomach"] = 3,
    ["Chest"] = 4,
    ["Upper chest"] = 5,
    ["Shoulders"] = 6,
    ["Right thigh"] = 7,
    ["Left thigh"] = 8,
    ["Right leg"] = 9,
    ["Left leg"] = 10,
    ["Right foot"] = 11,
    ["Left foot"] = 12,
    ["Right hand"] = 13,
    ["Left hand"] = 14,
    ["Right arm"] = 15,
    ["Right forearm"] = 16,
    ["Left arm"] = 17,
    ["Left forearm"] = 18
}
ui.set( int.hitbox, { "Left foot", "Right foot" } )
ui.set( int.tp_check, true )

local function hsv_to_rgb( h, s, v, a )
    local r, g, b

    local i = math.floor( h * 6 );
    local f = h * 6 - i;
    local p = v * ( 1 - s );
    local q = v * ( 1 - f * s );
    local t = v * ( 1 - ( 1 - f ) * s );

    i = i % 6

    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end

    return r * 255, g * 255, b * 255, a * 255
end

local function func_rgb_rainbowize( frequency, rgb_split_ratio )
    local r, g, b, a = hsv_to_rgb( globals.realtime() * frequency, 1, 1, 1 )
    return r * rgb_split_ratio, g * rgb_split_ratio, b * rgb_split_ratio
end

local function menu_handling()
    ui.set_visible( int.hitbox, ui.get( int.enabled ) )
    ui.set_visible( int.length, ui.get( int.enabled ) )
    ui.set_visible( int.limit, ui.get( int.enabled ) )
    ui.set_visible( int.random, ui.get( int.enabled ) )
    ui.set_visible( int.rainbow, ui.get( int.enabled ) )
    ui.set_visible( int.tp_check, ui.get( int.enabled ) )
end

local function on_paint()
    if ui.get( int.tp_check ) and ui.get( tp[1] ) and not ui.get( tp[2] ) or ui.get( int.tp_check ) and not ui.get( tp[1] ) or entity.is_alive( entity.get_local_player() ) ~= true then return end
    local vx, vy = entity.get_prop( entity.get_local_player(), 'm_vecVelocity' )
    local speed = vx ~= nil and math.floor( math.sqrt( vx*vx + vy*vy + 0.5 ) ) or 0
    local r, g, b, a = ui.get( int.color )
    local lhitboxes = ui.get( int.hitbox )
    if ui.get( int.rainbow ) then r, g, b = func_rgb_rainbowize( 0.2, 1 ) end
    
    if speed >= ui.get( int.limit ) and ui.get( int.enabled ) then
        if ui.get( int.random ) then
            client.draw_hitboxes( entity.get_local_player(), ui.get( int.length )/100, math.random( 0, 19 ), r, g, b, a )
        else
            for i=1, #lhitboxes do
                local hitbox = lhitboxes[i]
                client.draw_hitboxes( entity.get_local_player(), ui.get( int.length )/100, hitboxes[hitbox], r, g, b, a )
            end
        end
    end
end
client.set_event_callback("paint", on_paint)
ui.set_callback(int.enabled, menu_handling)
menu_handling()
