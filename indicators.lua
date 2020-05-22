-- cache common functions
local renderer = renderer
local line, rectangle, text = renderer.line, renderer.rectangle, renderer.text
local get_screen_size = client.screen_size
local get_local_player, get_prop = entity.get_local_player, entity.get_prop
local min, max, abs, sqrt, floor = math.min, math.max, math.abs, math.sqrt, math.floor
local get, get_mousepos = ui.get, ui.mouse_position
local band = bit.band
local event_callback = client.set_event_callback

local wdei, hdei = get_screen_size( )
local scr = { w = wdei, h = hdei }
local menu_color = ui.reference( "misc", "settings", "menu color" )
local rm, gm, bm, am = ui.get( menu_color )
local choked_ticks = 0
local old_origin = { x=180, y=180, z=170 }
local old_simulation_time = 0
local fdk = ui.reference( "rage", "other", "duck peek assist" )
local dtap, dtk = ui.reference( "rage", "other", "double tap" )
local fl_am = ui.reference( "aa", "fake lag", "limit" )
local max_choked_ticks = ui.reference( "MISC", "Settings", "sv_maxusrcmdprocessticks" )
local angle = 0

local int = {
    enabled = ui.new_checkbox( "visuals", "other esp", "Indicators" ),
    color = ui.new_color_picker( "visuals", "other esp", "otindc_color", rm, gm, bm, am ),
    options = ui.new_multiselect( "visuals", "other esp", "\n", "Fakelag", "Lag compensation", "Double tap", "Fake duck", "Fake"),
    statuss = ui.new_combobox( "visuals", "other esp", "Indication type", "Color", "Checkmark" ),
    max_bar = ui.new_checkbox( "visuals", "other esp", "Maximum bar mode" )
}
local wnd = {
    x = database.read( "otindc_x" ) or 15,
    y = database.read( "otindc_y" ) or scr.h/2,
    dragging = false
}
local heights = {
    ["Fakelag"] = 18,
    ["Lag compensation"] = 18,
    ["Fake duck"] = 18,
    ["Double tap"] = 18,
    ["Fake"] = 25
}

local function tointeger( n )
    return floor( n + 0.5 )
end

local function vec_3( _x, _y, _z ) 
	return { x = _x or 0, y = _y or 0, z = _z or 0 } 
end

local function copy_table( original ) -- http://lua-users.org/wiki/CopyTable
    local original_type = type( original )
    local copy
    if original_type == 'table' then
        copy = { }
        for original_key, original_value in next, original, nil do
            copy[ copy_table( original_key ) ] = copy_table( original_value )
        end
        setmetatable( copy, copy_table( getmetatable( original ) ) ) 
    else
        copy = original
    end
    return copy
end

local function on_ground( ent )
    if band( get_prop( get_local_player( ), "m_fFlags" ), 1 ) == 1 then return true end
    return false
end

local function contains( tbl, val )
    for i = 1, #tbl do
        if tbl[i] == val then return true end
    end
    return false
end

local function intersect( x, y, w, h ) 
    local cx, cy = get_mousepos( )
    return cx >= x and cx <= x + w and cy >= y and cy <= y + h
end
local function conta( x, y, w, h )
    local r, g, b, a = ui.get( int.color )
    rectangle( x, y, w, h, 30, 30, 30, 200 )
    rectangle( x+1, y+1, w-2, 1, r, g, b, 255 )
end
local function rendind( x, y, max, value, size, r, g, b, a, name )
    if value > 1 then value = value + 1 end
    for i=1, max do
        rectangle( x+( size+2 )*i-( size+2 ), y+6, size, 5, 15, 15, 15, 150 )
    end
    for i=1, value do
        if i < value then i = i+1 end
        rectangle( x+( size+2 )*i-( size+2 )*2, y+6, size, 5, r, g, b, 180)
    end
    if name ~= "" and name ~= " " and name ~= nil then
        text( x, name == string.upper( name ) and y-8 or y-10, 255, 255, 255, 255, name == string.upper( name ) and "-" or "", 0, name )
    end
end
local function renstatus( x, y, size, state, type )
    local r, g, b, a = ui.get( int.color )
    line( state and x-size/2 or x-size/2, state and y-size/2 or y-size, state and x or x+size/2, y, state and r or 255, state and g or 20, state and b or 0, 255 )
    line( state and x or x-size/2, y, state and x+size or x+size/2, y-size, state and r or 255, state and g or 20, state and b or 0, 255 )
end
local render = { container = conta, indication = rendind, status = renstatus }

local function menu( )
    ui.set_visible( int.options, ui.get( int.enabled ) )
    ui.set_visible( int.statuss, ui.get( int.enabled ) )
    ui.set_visible( int.max_bar, ui.get( int.enabled ) )
end

ui.set_callback( int.enabled, menu )
menu( )

event_callback( "setup_command", function( cmd ) 
    choked_ticks = cmd.chokedcommands/2 > 2 and cmd.chokedcommands or 0 
    local origin = vec_3( get_prop( get_local_player( ), "m_vecOrigin" ) )
    local simulation_time = get_prop( get_local_player( ), "m_flSimulationTime" )
    if ( simulation_time ~= old_simulation_time ) then
        origin_delta = vec_3( origin.x - old_origin.x, origin.y - old_origin.y, origin.z - old_origin.z )
        old_origin = copy_table( origin )
	    old_simulation_time = simulation_time
    end
    if cmd.chokedcommands == 0 then
		if cmd.in_use == 1 then
			angle = 0
		else
			angle = min( 57, abs( get_prop( get_local_player( ), "m_flPoseParameter", 11 )*120-60 ) )
		end
	end
end )

local function on_paint( )
    if ui.get( int.enabled ) ~= true then return end
    for i = 1, 50 do
        renderer.indicator( 255, 255, 255, 0, i)
    end
    if entity.is_alive( get_local_player( ) ) ~= true then choked_ticks = 0 end

    local r, g, b, a = ui.get( int.color )
    local left_click = client.key_state( 0x01 )
    local cx, cy = get_mousepos( )
    local options = ui.get( int.options )
    local width, height = 116, 10

    local origin = vec_3( get_prop( get_local_player( ), "m_vecOrigin" ) )
    local velocity_prop = vec_3( entity.get_prop( get_local_player( ), "m_vecVelocity" ) )
    local velocity = sqrt( velocity_prop.x * velocity_prop.x + velocity_prop.y * velocity_prop.y )
    local trace_fraction, trace_entity = client.trace_line( 1, origin.x, origin.y, origin.z, origin.x, origin.y, origin.z - 24.97 )
    local bar_max, bar_fake = 9, tointeger( angle )/6.666666666666667
    local bar_ticks = tointeger( choked_ticks/1.5 )
    local lc = { r = 255, g = 0, b = 0, state = false }
    local dt = { r = 255, g = 0, b = 0, state = false }
    local fk = { r = 255, g = 0, b = 0 }
    if trace_fraction < 1 and not on_ground( get_local_player( ) ) or velocity > 270 and origin_delta ~= nil then
        if sqrt( origin_delta.x * origin_delta.x + origin_delta.y * origin_delta.y ) > 64 then
            lc.r = r
            lc.g = g
            lc.b = b
            lc.state = true
        end
    end
    if ui.get( dtap ) and ui.get( dtk ) then
        if max_choked_ticks == ui.get( fl_am ) or ui.get( fdk ) and choked_ticks >= 0 then
            dt.r = dt.r
            dt.g = dt.g
            dt.b = dt.b
        elseif choked_ticks <= 3 then
            dt.r = r
            dt.g = g
            dt.b = b
            dt.state = true
        else
            dt.r = 255
            dt.g = 150
            dt.b = 0
            dt.state = false
        end
    end
    if angle > 38 then
        fk.r = r
        fk.g = g
        fk.b = b
    elseif angle < 39 and angle > 15 then
        fk.r = 255
        fk.g = 150
        fk.b = 0
    end

    if ui.is_menu_open( ) then 
        if wnd.dragging and not left_click then
            wnd.dragging = false
        end
    
        if wnd.dragging and left_click then
            wnd.x = cx - wnd.drag_x
            wnd.y = cy - wnd.drag_y
        end
    
        if intersect( wnd.x, wnd.y, width, 25 ) and left_click then 
            wnd.dragging = true
            wnd.drag_x = cx - wnd.x
            wnd.drag_y = cy - wnd.y
        end
    end

    for i=1, #options do 
        option = options[ i ]
        if heights[ option ] ~= nil then
            height = height + heights[ option ]
        end
    end

    if ui.get( int.max_bar ) then 
        bar_ticks = choked_ticks
        bar_fake = angle/4.285714285714286
        width = 176
        bar_max = 14
    end

    local indic = { x = wnd.x + 5, y = wnd.y + 15 }
    render.container( wnd.x, wnd.y, width, height )
    for i=1, #options do
        option = options[ i ]
        if option == "Fakelag" then
            render.indication( indic.x, indic.y, bar_max, bar_ticks, 10, r, g, b, 255, string.format( "CHOKED  -  %s", choked_ticks ) )
        elseif option == "Lag compensation" then
            if ui.get( int.statuss ) == "Color" then
                text( indic.x, indic.y, lc.r, lc.g, lc.b, 255, "-", 0, "LAG COMPENSATION" )
            else
                text( indic.x, indic.y, 255, 255, 255, 255, "-", 0, "LAG COMPENSATION" )
                render.status( indic.x+width-15, indic.y+8, 5, lc.state )
            end
        elseif option == "Fake duck" then
            if ui.get( int.statuss ) == "Color" then
                text( indic.x, indic.y, ui.get( fdk ) and on_ground( get_local_player( ) ) and r or 255, ui.get( fdk ) and on_ground( get_local_player( ) ) and g or 0, ui.get( fdk ) and on_ground( get_local_player( ) ) and b or 0, 255, "-", 0, "FAKE DUCK" )
            else
                text( indic.x, indic.y, 255, 255, 255, 255, "-", 0, "FAKE DUCK" )
                render.status( indic.x+width-15, indic.y+8, 5, ui.get( fdk ) and on_ground( get_local_player( ) ) )
            end
        elseif option == "Double tap" then
            if ui.get( int.statuss ) == "Color" then
                text( indic.x, indic.y, dt.r, dt.g, dt.b, 255, "-", 0, "DOUBLE TAP" )
            else
                text( indic.x, indic.y, 255, 255, 255, 255, "-", 0, "DOUBLE TAP" )
                render.status( indic.x+width-15, indic.y+8, 5, dt.state )
            end
        elseif option == "Fake" then
            render.indication( indic.x, indic.y + 6, bar_max, bar_fake, 10, fk.r, fk.g, fk.b, 255, string.format( "FAKE  -  %s", tointeger( angle ) ) )
        end
        if heights[option] ~= nil then
            indic.y = indic.y + ( heights[ option ]-1 )
        end
    end
end

event_callback( "paint", on_paint )
