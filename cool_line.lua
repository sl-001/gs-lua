local x, y = client.screen_size()
local gui =
{
    checkbox = ui.new_checkbox("visuals", "effects", "Cool line"),
	color = ui.new_color_picker("visuals", "effects", "Rainbow line", 255, 255, 255, 255),
		types = ui.new_combobox("visuals", "effects", "\n", "Gradient", "Static", "Overflow"),
	thickness = ui.new_slider("visuals", "effects", "\n", 1, 5, 1, true, "px", 1)
}

local function hsv_to_rgb(h, s, v, a)
    local r, g, b

    local i = math.floor(h * 6);
    local f = h * 6 - i;
    local p = v * (1 - s);
    local q = v * (1 - f * s);
    local t = v * (1 - (1 - f) * s);

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

local function func_rgb_rainbowize(frequency, rgb_split_ratio)
    local r, g, b, a = hsv_to_rgb(globals.realtime() * frequency, 1, 1, 1)

    r = r * rgb_split_ratio
    g = g * rgb_split_ratio
    b = b * rgb_split_ratio

    return r, g, b
end

client.set_event_callback("paint", function(ctx)
local r, g, b = func_rgb_rainbowize(0.1, 1)
local rs, gs, bs, as = ui.get(gui.color)

    if ui.get(gui.checkbox) then
        ui.set_visible(gui.thickness, true)
		ui.set_visible(gui.types, true)
		if ui.get(gui.types) == "Static" then
		    ui.set_visible(gui.color, true)
	    else
		    ui.set_visible(gui.color, false)
		end
    else
        ui.set_visible(gui.thickness, false)
		ui.set_visible(gui.types, false)
		ui.set_visible(gui.color, false)
    end

    if ui.get(gui.checkbox) then
	    if ui.get(gui.types) == "Gradient" then
		
	        renderer.gradient(0, 0, x/2, ui.get(gui.thickness), 5, 221, 255, 255, 186, 12, 230, 255, true)
            renderer.gradient(x/2, 0, x, ui.get(gui.thickness), 186, 12, 230, 255, 219, 226, 60, 255, true)
			
		elseif ui.get(gui.types) == "Static" then
		
		    renderer.rectangle(0, 0, x/2, ui.get(gui.thickness), rs, gs, bs, 255)
			renderer.rectangle(x/2, 0, x, ui.get(gui.thickness), rs, gs, bs, 255)
			
	    elseif ui.get(gui.types) == "Overflow" then
		
		    local a = 255
			
		    renderer.gradient(0, 0, x/2, ui.get(gui.thickness), g, b, r, a, r, g, b, a, true)
		    renderer.gradient(x/2, 0, x, ui.get(gui.thickness), r, g, b, a, b, r, g, a, true)

		    local a_lower = a*0.5
		
		    renderer.gradient(0, 0, x/2, ui.get(gui.thickness), g, b, r, a_lower, r, g, b, a_lower, true)
		    renderer.gradient(x, 0, x, ui.get(gui.thickness), r, g, b, a_lower, b, r, g, a_lower, true)
			
		end
	end
end)
