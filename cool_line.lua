local w, h = client.screen_size( )
local int = {
    checkbox = ui.new_checkbox( "visuals", "effects", "Cool line" ),
	color = ui.new_color_picker( "visuals", "effects", "Rainbow line", 255, 255, 255, 255 ),
	types = ui.new_combobox( "visuals", "effects", "\n", "Gradient", "Static", "Overflow" ),
	thickness = ui.new_slider( "visuals", "effects", "\n", 1, 5, 1, true, "px", 1 )
}

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
    local r, g, b, a = hsv_to_rgb( globals.realtime( ) * frequency, 1, 1, 1 )

    r = r * rgb_split_ratio
    g = g * rgb_split_ratio
    b = b * rgb_split_ratio

    return r, g, b
end

local function menu( )
    ui.set_visible( int.thickness, ui.get( int.checkbox ) )
    ui.set_visible( int.types, ui.get( int.checkbox ) )
    ui.set_visible( int.color, ui.get( int.checkbox ) and ui.get( int.types ) == "Static" )
end

ui.set_callback( int.checkbox, menu )
ui.set_callback( int.types, menu )
menu( )

client.set_event_callback( "paint", function( )
local r, g, b, a = ui.get( int.color )
local ro, go, bo = func_rgb_rainbowize( 0.1, 1 )

    if ui.get( int.checkbox ) then
	    if ui.get( int.types ) == "Gradient" then
	        renderer.gradient( 0, 0, w/2, ui.get( int.thickness ), 5, 221, 255, 255, 186, 12, 230, 255, true )
            renderer.gradient( w/2, 0, w, ui.get( int.thickness ), 186, 12, 230, 255, 219, 226, 60, 255, true )
		elseif ui.get( int.types ) == "Static" then
		    renderer.rectangle( 0, 0, w, ui.get( int.thickness ), r, g, b, 255 )
	    elseif ui.get( int.types ) == "Overflow" then
		    local a = 255
		    renderer.gradient( 0, 0, w/2, ui.get( int.thickness ), go, bo, ro, a, ro, go, bo, a, true )
		    renderer.gradient( w/2, 0, w/2, ui.get( int.thickness ), ro, go, bo, a, bo, ro, go, a, true )
		    local a_lower = a*0.5
		    renderer.gradient( 0, 0, w/2, ui.get( int.thickness ), go, bo, ro, a_lower, ro, go, bo, a_lower, true )
		    renderer.gradient( w/2, 0, w/2, ui.get( int.thickness ), ro, go, bo, a_lower, bo, ro, go, a_lower, true )
		end
	end
end )
