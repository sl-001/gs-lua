local drawgradient = renderer.gradient
local drawline = renderer.line
local drawrect = renderer.rectangle
local drawtext = renderer.text
local get_all = entity.get_all
local get_lp = entity.get_local_player
local get_prop = entity.get_prop
local get_ui = ui.get
local set_prop = entity.set_prop
local w, h = client.screen_size()
local draw_rectangle = client.draw_rectangle
local epicky = 
{
   master = ui.new_checkbox("misc", "miscellaneous", "HUD"),
   originalhud = ui.new_checkbox("misc", "miscellaneous", "Disable original hud"),
   color1 = ui.new_color_picker("misc", "miscellaneous", "solo's color", 127, 176, 0),
   color3 = ui.new_color_picker("misc", "miscellaneous", "gamesense color", 127, 176, 0),
   look = ui.new_combobox("misc", "miscellaneous", "Type", "Solo's", "Custom", "Gamesense"),
   color1m = ui.new_color_picker("misc", "miscellaneous", "solo's colorm", 255, 134, 3),
   color1l = ui.new_color_picker("misc", "miscellaneous", "solo's colorl", 255, 51, 51),
   things1 = ui.new_multiselect("misc", "miscellaneous", "Options for solo's type", "Change x/y", "Show ammo", "Show armor", "Custom hp color", "Custom armor color", "Show fps", "Show ping"),
   color1a = ui.new_color_picker("misc", "miscellaneous", "solo's colora", 7, 169, 232),
   types1 = ui.new_combobox("misc", "miscellaneous", "Indicator for solo's type", "-", "Circle outline", "Line"),
   things2 = ui.new_multiselect("misc", "miscellaneous", "Options for custom type", "Show header", "Show ammo", "Show fps", "Show ping"),
   indicatec = ui.new_checkbox("misc", "miscellaneous", "Indicator"),
   things3 = ui.new_multiselect("misc", "miscellaneous", "Options for gamesense type", "Change x/y", "Change accent", "Show gradient header", "Show ammo", "Show armor","Show fps", "Show ping"),
   types3 = ui.new_combobox("misc", "miscellaneous", "Indicator for gamesense type", "-", "Circle outline", "Line"),
   xlol1 = ui.new_slider("misc", "miscellaneous", "x for solo's type", "0", w, 25, true),
   ylol1 = ui.new_slider("misc", "miscellaneous", "y for solo's type", "0", h, 1040, true),
   xfp = ui.new_slider("misc", "miscellaneous", "fps/ping x for solo's type", "0", w, 25, true),
   yfp = ui.new_slider("misc", "miscellaneous", "fps/ping y for solo's type", "0", h, h/2, true),
   xa = ui.new_slider("misc", "miscellaneous", "ammo x for solo's type", "0", w, 1800, true),
   ya = ui.new_slider("misc", "miscellaneous", "ammo y for solo's type", "0", h, 700, true),
   xlol3 = ui.new_slider("misc", "miscellaneous", "x for gamesense type", "0", w, 5, true),
   ylol3 = ui.new_slider("misc", "miscellaneous", "y for gamesense type", "0", h, 1015, true),
   xfp3 = ui.new_slider("misc", "miscellaneous", "fps/ping x for gamesense type", "0", w, 10, true),
   yfp3 = ui.new_slider("misc", "miscellaneous", "fps/ping y for gamesense type", "0", h, 25, true),
   xa3 = ui.new_slider("misc", "miscellaneous", "ammo x for gamesense type", "0", w, 1735, true),
   ya3 = ui.new_slider("misc", "miscellaneous", "ammo y for gamesense type", "0", h, 645, true),
}

local function Contains(table, val) --thanks sapphyrus
    for i = 1, #table do
        if table[i] == val then
            return true
        end
    end
    return false
end

function draw_container(ctx, x, y, w, h) --gamesense container
    local c = {10, 60, 40, 40, 40, 60, 20}
    for i = 0,6,1 do
        draw_rectangle(ctx, x+i, y+i, w-(i*2), h-(i*2), c[i+1], c[i+1], c[i+1], 255)
    end
end

local function draw_indicator_circle(ctx, x, y, r, g, b, a, percentage, outline) --stolen from oxisDOG
    local outline = outline == nil and true or outline
    local radius = 9
    local start_degrees = 0
    if outline then
        client.draw_circle_outline(ctx, x, y, 0, 0, 0, 200, radius, start_degrees, 1.0, 5)
    end
    client.draw_circle_outline(ctx, x, y, r, g, b, a, radius - 1, start_degrees, percentage, 3)
end

local frametimes = {}
local fps_prev = 0
local value_prev = {}
local last_update_time = 0


local function accumulate_fps()
	local rt, ft = globals.realtime(), globals.absoluteframetime()

	if ft > 0 then
		table.insert(frametimes, 1, ft)
	end

	local count = #frametimes
	if count == 0 then
		return 0
	end

	local accum = 0
	local i = 0
	while accum < 0.5 do
		i = i + 1
		accum = accum + frametimes[i]
		if i >= count then
			break
		end
	end

	accum = accum / i

	while i < count do
		i = i + 1
		table.remove(frametimes)
	end

	local fps = 1 / accum
	local time_since_update = rt - last_update_time
	if math.abs(fps - fps_prev) > 4 or time_since_update > 1 then
		fps_prev = fps
		last_update_time = rt
	else
		fps = fps_prev
	end

	return math.floor(fps + 0.5)
end

local function wishbestmod(ctx, e)

    --needed things
	local lp = entity.get_local_player()
	local ammo = get_prop(entity.get_player_weapon(entity.get_local_player()), "m_iClip1")
	local ammores = get_prop(entity.get_player_weapon(entity.get_local_player()), "m_iPrimaryReserveAmmoCount")
	local armor = get_prop(lp, "m_ArmorValue")
	local buyz = get_prop(lp, "m_bInBuyZone")
	local hp = get_prop(lp, "m_iHealth")
	local money = get_prop(lp, "m_iAccount")
	local hasc4 = get_prop(pResource, "m_iPlayerC4")
	local cwep = get_prop(lp, "m_hActiveWeapon")
	local pResource = get_all("CCSPlayerResource")[1]
	local x1, y1 = ui.get(epicky.xlol1), ui.get(epicky.ylol1)
	local x3, y3 = ui.get(epicky.xlol3), ui.get(epicky.ylol3)
	local xfp, yfp = ui.get(epicky.xfp), ui.get(epicky.yfp)
	local xfp3, yfp3 = ui.get(epicky.xfp3), ui.get(epicky.yfp3)
	local xa, ya = ui.get(epicky.xa), ui.get(epicky.ya)
	local xa3, ya3 = ui.get(epicky.xa3), ui.get(epicky.ya3)
	local r1, g1, b1, a1 = ui.get(epicky.color1)
	local r1m, g1m, b1m, a1m = ui.get(epicky.color1m)
	local r1l, g1l, b1l, a1l = ui.get(epicky.color1l)
	local r3, g3, b3, a3 = ui.get(epicky.color3)
	local r1a, g1a, b1a, a1a = ui.get(epicky.color1a)
	local things1ref = ui.get(epicky.things1)
	local things2ref = ui.get(epicky.things2)
	local things3ref = ui.get(epicky.things3)
	local fps = accumulate_fps()
	local ping = math.floor(math.min(1000, client.latency() * 1000) + 0.5)
	
	if not entity.is_alive(lp) then return end
	--end
	
	--menu stuff
    if ui.get(epicky.master) then

	   ui.set_visible(epicky.look, true)
	   ui.set_visible(epicky.originalhud, true)
	   if ui.get(epicky.look) == "Solo's" then
	        ui.set_visible(epicky.things1, true)
			ui.set_visible(epicky.types1, true)
			
			if Contains(things1ref, "Show fps") and Contains(things1ref, "Change x/y") then
			    ui.set_visible(epicky.xfp, true)
			    ui.set_visible(epicky.yfp, true)
			else
                ui.set_visible(epicky.xfp, false)
			    ui.set_visible(epicky.yfp, false)
			end
			
            if Contains(things1ref, "Show ammo") and Contains(things1ref, "Change x/y") then
			    ui.set_visible(epicky.xa, true)
			    ui.set_visible(epicky.ya, true)
			else
                ui.set_visible(epicky.xa, false)
			    ui.set_visible(epicky.ya, false)
			end
			
			if Contains(things1ref, "Change x/y") then
	            ui.set_visible(epicky.xlol1, true)
			    ui.set_visible(epicky.ylol1, true)
			else
	            ui.set_visible(epicky.xlol1, false)
			    ui.set_visible(epicky.ylol1, false)
			end
			
			if Contains(things1ref, "Custom hp color") then
			    ui.set_visible(epicky.color1, true)
			    ui.set_visible(epicky.color1m, true)
			    ui.set_visible(epicky.color1l, true)
			else
			    ui.set_visible(epicky.color1, false)
			    ui.set_visible(epicky.color1m, false)
			    ui.set_visible(epicky.color1l, false)
			end
			
			if Contains(things1ref, "Custom armor color") then
			    ui.set_visible(epicky.color1a, true)
			else
			    ui.set_visible(epicky.color1a, false)
		    end

	   else
	        ui.set_visible(epicky.things1, false)
			ui.set_visible(epicky.types1, false)
	        ui.set_visible(epicky.xlol1, false)
			ui.set_visible(epicky.ylol1, false)
			ui.set_visible(epicky.xfp, false)
			ui.set_visible(epicky.yfp, false)
			ui.set_visible(epicky.xa, false)
			ui.set_visible(epicky.ya, false)
			ui.set_visible(epicky.color1, false)
			ui.set_visible(epicky.color1m, false)
			ui.set_visible(epicky.color1l, false)
			ui.set_visible(epicky.color1a, false)
	   end
	   
	   if ui.get(epicky.look) == "Custom" then
	   
	        ui.set_visible(epicky.things2, true)
			ui.set_visible(epicky.indicatec, true)
	   else
	        ui.set_visible(epicky.things2, false)
			ui.set_visible(epicky.indicatec, false)
	   end
	   
	   if ui.get(epicky.look) == "Gamesense" then
	        ui.set_visible(epicky.things3, true)
			ui.set_visible(epicky.types3, true)
			
			if Contains(things3ref, "Show fps") and Contains(things3ref, "Change x/y") then
			    ui.set_visible(epicky.xfp3, true)
			    ui.set_visible(epicky.yfp3, true)
			else
                ui.set_visible(epicky.xfp3, false)
			    ui.set_visible(epicky.yfp3, false)
			end
			
			if Contains(things3ref, "Show ammo") and Contains(things3ref, "Change x/y") then
			    ui.set_visible(epicky.xa3, true)
			    ui.set_visible(epicky.ya3, true)
			else
                ui.set_visible(epicky.xa3, false)
			    ui.set_visible(epicky.ya3, false)
			end
			
	        if Contains(ui.get(epicky.things3), "Change x/y") then
	            ui.set_visible(epicky.xlol3, true)
			    ui.set_visible(epicky.ylol3, true)
			else
	            ui.set_visible(epicky.xlol3, false)
			    ui.set_visible(epicky.ylol3, false)
			end
			
			if Contains(ui.get(epicky.things3), "Change accent") then
			    ui.set_visible(epicky.color3, true)
		    else
			    ui.set_visible(epicky.color3, false)
			end
	   else
	        ui.set_visible(epicky.things3, false)
			ui.set_visible(epicky.types3, false)
	        ui.set_visible(epicky.xlol3, false)
			ui.set_visible(epicky.ylol3, false)
			ui.set_visible(epicky.color3, false)
			ui.set_visible(epicky.xfp3, false)
			ui.set_visible(epicky.yfp3, false)
			ui.set_visible(epicky.xa3, false)
			ui.set_visible(epicky.ya3, false)
	   end
	else
	   ui.set_visible(epicky.originalhud, false)
	   ui.set_visible(epicky.things1, false)
	   ui.set_visible(epicky.things2, false)
	   ui.set_visible(epicky.things3, false)
	   ui.set_visible(epicky.types1, false)
	   ui.set_visible(epicky.indicatec, false)
	   ui.set_visible(epicky.types3, false)
	   ui.set_visible(epicky.look, false)
	   ui.set_visible(epicky.xlol1, false)
	   ui.set_visible(epicky.ylol1, false)
	   ui.set_visible(epicky.xlol3, false)
	   ui.set_visible(epicky.ylol3, false)
	   ui.set_visible(epicky.color1, false)
	   ui.set_visible(epicky.color1m, false)
	   ui.set_visible(epicky.color1l, false)
	   ui.set_visible(epicky.color1a, false)
	   ui.set_visible(epicky.color3, false)
	   ui.set_visible(epicky.xfp, false)
	   ui.set_visible(epicky.yfp, false)
	   ui.set_visible(epicky.xfp3, false)
	   ui.set_visible(epicky.yfp3, false)
	   ui.set_visible(epicky.xa, false)
	   ui.set_visible(epicky.ya, false)
	   ui.set_visible(epicky.xa3, false)
	   ui.set_visible(epicky.ya3, false)
	end

    if ui.get(epicky.master) then
	
	    if ui.get(epicky.originalhud) then
		set_prop(lp, "m_iHideHud", 8200)
		end
		
	    if ui.get(epicky.look) == "Solo's" then
		
		    ui.set_visible(epicky.originalhud, false)
		    set_prop(lp, "m_iHideHud", 8200)
			
		    if buyz == 1 then
		        drawtext(10, 315, 255, 255, 255, a1, "+", 0, "$", money)
			end
			
		    if hp == 100 then 
			    drawtext(x1, y1, r1, g1, b1, a1, "+", 0, hp)
				drawtext(x1 + 55, y1, 255, 255, 255, a1, "+", 0, "HP")
				if ui.get(epicky.types1) == "Circle outline" then
				    draw_indicator_circle(ctx, x1 + 103, y1 + 15, r1, g1, b1, a1, hp / 100)
				elseif ui.get(epicky.types1) == "Line" then
				    drawrect(x1 - 1, y1 + 27, 92, 5, 0, 0, 0, 200)
					drawrect(x1, y1 + 28, hp / 1.111111111, 3, r1, g1, b1, a1)
				end
			elseif hp > 100 and hp < 1000 then
			    drawtext(x1, y1, 255, 156, 0, a1, "+", 0, hp)
				drawtext(x1 + 55, y1, 255, 255, 255, a1, "+", 0, "HP")
				if ui.get(epicky.types1) == "Circle outline" then
				    draw_indicator_circle(ctx, x1 + 103, y1 + 15, 255, 156, 0, a1, 1)
				elseif ui.get(epicky.types1) == "Line" then
				    drawrect(x1 - 1, y1 + 27, 92, 5, 0, 0, 0, 200)
					drawrect(x1, y1 + 28, 90, 3, 255, 156, 0, a1)
				end
			elseif hp == 1000 or hp > 1000 and hp < 10000 then
			    drawtext(x1, y1, 255, 156, 0, a1, "+", 0, hp)
				drawtext(x1 + 70, y1, 255, 255, 255, a1, "+", 0, "HP")
				if ui.get(epicky.types1) == "Circle outline" then
				    draw_indicator_circle(ctx, x1 + 118, y1 + 15, 255, 156, 0, a1, 1)
				elseif ui.get(epicky.types1) == "Line" then
				    drawrect(x1 - 1, y1 + 27, 102, 5, 0, 0, 0, 200)
					drawrect(x1, y1 + 28, 100, 3, 255, 156, 0, a1)
				end
		    elseif hp == 32767 or hp > 10000 or hp == 10000 then
			    drawtext(x1 - 15, y1, 255, 255, 255, a1, "+", 0, "serverside)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))")
			elseif hp < 100 and hp > 50 then
			    drawtext(x1, y1, r1, g1, b1, a1, "+", 0, hp)
				drawtext(x1 + 40, y1, 255, 255, 255, a1, "+", 0, "HP")
				if ui.get(epicky.types1) == "Circle outline" then
				    draw_indicator_circle(ctx, x1 + 88, y1 + 15, r1, g1, b1, a1, hp / 100)
				elseif ui.get(epicky.types1) == "Line" then
				    drawrect(x1 - 1, y1 + 27, 77, 5, 0, 0, 0, 200)
					drawrect(x1, y1 + 28, hp / 1.333333, 3, r1, g1, b1, a1)
				end
			elseif hp == 50 or hp < 50 and hp > 10 then
			    drawtext(x1, y1, r1m, g1m, b1m, a1m, "+", 0, hp)
				drawtext(x1 + 40, y1, 255, 255, 255, a1, "+", 0, "HP")
				if ui.get(epicky.types1) == "Circle outline" then
				    draw_indicator_circle(ctx, x1 + 88, y1 + 15, r1m, g1m, b1m, a1m, hp / 100)
				elseif ui.get(epicky.types1) == "Line" then
				    drawrect(x1 - 1, y1 + 27, 77, 5, 0, 0, 0, 200)
					drawrect(x1, y1 + 28, hp / 1.333333, 3, r1m, g1m, b1m, a1m)
				end
			elseif hp == 10 then
			    drawtext(x1, y1, r1l, g1l, b1l, a1l, "+", 0, hp)
				drawtext(x1 + 40, y1, 255, 255, 255, a1, "+", 0, "HP")
				if ui.get(epicky.types1) == "Circle outline" then
				    draw_indicator_circle(ctx, x1 + 88, y1 + 15, r1l, g1l, b1l, a1l, hp / 100)
				elseif ui.get(epicky.types1) == "Line" then
				    drawrect(x1 - 1, y1 + 27, 77, 5, 0, 0, 0, 200)
					drawrect(x1, y1 + 28, hp / 1.333333, 3, r1l, g1l, b1l, a1l)
				end
			elseif hp < 10 and hp > 0 then
			    drawtext(x1, y1, r1l, g1l, b1l, a1l, "+", 0, hp)
				drawtext(x1 + 25, y1, 255, 255, 255, a1, "+", 0, "HP")
				if ui.get(epicky.types1) == "Circle outline" then
				    draw_indicator_circle(ctx, x1 + 73, y1 + 15, r1l, g1l, b1l, a1l, hp / 100)
				elseif ui.get(epicky.types1) == "Line" then
				    drawrect(x1 - 1, y1 + 27, 62, 5, 0, 0, 0, 200)
					drawrect(x1, y1 + 28, hp / 1.6666666, 3, r1l, g1l, b1l, a1l)
				end
            elseif hp == 0 or hp < 0 then
			    drawtext(x1, y1, 255, 255, 255, a1l, "+", 0, "wtf")
			end
		    
			if Contains(things1ref, "Show armor")then
			    if armor == 100 or armor > 0 or armor < 100 then
			        drawtext(x1 + 130, y1, r1a, g1a, b1a, a1a, "+", 0, armor)
			        drawtext(x1 + 185, y1, 255, 255, 255, a1a, "+", 0, "ARMOR")
			    elseif armor == 0 then end
				if ui.get(epicky.types1) == "Circle outline" then
				    draw_indicator_circle(ctx, x1 + 293, y1 + 15, r1a, g1a, b1a, a1a, armor / 100)
				elseif ui.get(epicky.types1) == "Line" then
				    drawrect(x1 + 129, y1 + 27, 152, 6, 0, 0, 0, 200)
					drawrect(x1 + 130, y1 + 28, armor / 0.6666666666666, 3, r1a, g1a, b1a, a1a) 
				end
			end
			
			if Contains(things1ref, "Show fps") then 
			    drawtext(xfp, yfp - 30, 255, 255, 255, a1, "c", 0, fps, " fps")
				if Contains(things1ref, "Show ping") then
				drawtext(xfp + 40, yfp - 30, 255, 255, 255, a1, "c", 0, ping, " ms")
				end
			end
			
		    if Contains(things1ref, "Show ammo") then if ammo < 0 then return end
			    drawtext(xa, ya, 255, 255, 255, a1, "+", 0, ammo, "/", ammores)
				if ui.get(epicky.types1) == "Circle outline" or ui.get(epicky.types1) == "Line" then
				    draw_indicator_circle(ctx, xa + 100, ya + 15, r1a, g1a, b1a, a1a, ammo / 50)
				end
			end
		end
		
		if ui.get(epicky.look) == "Custom" then
		
		ui.set_visible(epicky.originalhud, false)
		set_prop(lp, "m_iHideHud", 8200)
		
		drawrect(0, h - 33, 300, 33, 0, 0, 0, 200)
		if Contains(things2ref, "Show header") then
		    renderer.gradient(0, h - 33, 150, 1, 59, 175, 222, 255, 202, 70, 205, 255, true)
		    renderer.gradient(150, h - 33, 150, 1, 202, 70, 205, 255, 201, 227, 58, 255, true)
		end 
		
			if hp == 100 then 
			    drawtext(w / 3 - 630, h - 30, 127, 176, 0, 255, "+", 0, hp)
				drawtext(w / 3 - 577, h - 20, 255, 255, 255, a1, "", 0, "HP")
				if ui.get(epicky.indicatec) then
				    drawrect(w / 3 - 630, h - 1, hp / 1.25, 1, 127, 176, 0, 255)
				end
			elseif hp > 100 and hp < 1000 then
			    drawtext(w / 3 - 630, h - 30, 255, 156, 0, 255, "+", 0, hp)
				drawtext(w / 3 - 577, h - 20, 255, 255, 255, a1, "", 0, "HP")
				if ui.get(epicky.indicatec) then
				    drawrect(w / 3 - 630, h - 1, 80, 1, 255, 156, 0, 255)
				end
			elseif hp == 1000 or hp > 1000 and hp < 10000 then
			    drawtext(w / 3 - 630, h - 30, 255, 156, 0, 255, "+", 0, hp)
				drawtext(w / 3 - 562, h - 20, 255, 255, 255, 255, "", 0, "HP")
				if ui.get(epicky.indicatec) then
				    drawrect(w / 3 - 630, h - 1, 80, 1, 255, 156, 0, 255)
				end
		    elseif hp == 32767 or hp > 10000 or hp == 10000 then
			    drawtext(w / 3 - 630, h - 30, 255, 255, 255, 255, "+", 0, "serverside)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))")
			elseif hp < 100 and hp > 50 then
			    drawtext(w / 3 - 630, h - 30, 127, 176, 0, 255, "+", 0, hp)
				drawtext(w / 3 - 592, h - 20, 255, 255, 255, 255, "", 0, "HP")
				if ui.get(epicky.indicatec) then
				    drawrect(w / 3 - 630, h - 1, hp / 1.25, 1, 127, 176, 0, 255)
				end
			elseif hp == 50 or hp < 50 and hp > 10 then
			    drawtext(w / 3 - 630, h - 30, 255, 134, 3, 255, "+", 0, hp)
				drawtext(w / 3 - 592, h - 20, 255, 255, 255, 255, "", 0, "HP")
				if ui.get(epicky.indicatec) then
				    drawrect(w / 3 - 630, h - 1, hp, 1, 255, 134, 3, 255)
				end
			elseif hp == 10 then
			    drawtext(w / 3 - 630, h - 30, 255, 51, 51, 255, "+", 0, hp)
				drawtext(w / 3 - 592, h - 20, 255, 255, 255, 255, "", 0, "HP")
				if ui.get(epicky.indicatec) then
				    drawrect(w / 3 - 630, h - 1, hp, 1, 255, 51, 51, 255)
				end
			elseif hp < 10 and hp > 0 then
			    drawtext(w / 3 - 630, h - 30, 255, 51, 51, 255, "+", 0, hp)
				drawtext(w / 3 - 612, h - 20, 255, 255, 255, 255, "", 0, "HP")
				if ui.get(epicky.indicatec) then
				    drawrect(w / 3 - 630, h - 1, hp, 1, 255, 51, 51, 255)
				end
            elseif hp == 0 or hp < 0 then
			    drawtext(w / 3 - 630, h - 30, 255, 255, 255, a1l, "+", 0, "wtf")
			end 
			
			if armor == 100 or armor > 0 or armor < 100 then
			    drawtext(w / 3 - 530, h - 30, r1a, g1a, b1a, a1a, "+", 0, armor)
			    drawtext(w / 3 - 476, h - 20, 255, 255, 255, a1a, "", 0, "ARMOR")
				if ui.get(epicky.indicatec) then
				    drawrect(w / 3 - 530, h - 1, armor, 1, 7, 169, 232, 255)
				end
			elseif armor == 0 then end
			
			if Contains(things2ref, "Show fps") then
			    drawrect(w - 105, 5, 100, 20, 0, 0, 0, 200)
				drawtext(w - 95, 8, 255, 255, 255, a1, "", 0, fps, " fps")
				if Contains(things2ref, "Show ping") then
				    drawtext(w - 40, 8, 255, 255, 255, a1, "", 0, ping, " ms")
				end
				if Contains(things2ref, "Show header") then
				    renderer.gradient(w - 105, 5, 52.5, 1, 59, 175, 222, 255, 202, 70, 205, 255, true)
		            renderer.gradient(w - 52.5, 5, 48, 1, 202, 70, 205, 255, 201, 227, 58, 255, true)
				end 
			end
			
			if Contains(things2ref, "Show ammo") then if ammo < 0 then return end
			    drawrect(w - 160, h - 450, 150, 33, 0, 0, 0, 200)
			    drawtext(w - 137, h - 448, 255, 255, 255, a1, "+", 0, ammo, "/", ammores)
				if Contains(things2ref, "Show header") then
				    renderer.gradient(w - 160, h - 450, 75, 1, 59, 175, 222, 255, 202, 70, 205, 255, true)
		            renderer.gradient(w - 85, h - 450, 75, 1, 202, 70, 205, 255, 201, 227, 58, 255, true)
				end 
			end
		end
		
		if ui.get(epicky.look) == "Gamesense" then
		draw_container(ctx, x3, y3, 350, 60)
			
			if Contains(things3ref, "Show gradient header") then
			drawgradient(x3 + 7, y3 + 7, 171, 1, 5, 221, 255, 255, 186, 12, 230, 255, true)
		    drawgradient(x3 + 177, y3 + 7, 166, 1, 186, 12, 230, 255, 219, 226, 60, 255, true)
			end
			
			if hp >= 1000 then
				drawtext(x3 + 45, y3 + 30, 248, 218, 0, 255, "c+", 0, hp )
	            drawtext(x3 + 95, y3 + 30, 255, 255, 255, a1, "c+", 0, "HP")
				if ui.get(epicky.types3) == "Circle outline" then
				    draw_indicator_circle(ctx, x3 + 125, y3 + 32, 248, 218, 0, 255, 100)
				elseif ui.get(epicky.types3) == "Line" then
				    drawrect(x3 + 15, y3 + 45, 85, 3, 0, 0, 0, 200)
					drawrect(x3 + 15, y3 + 45, 100, 3, 248, 218, 0, a1)  
				end
			end
			
		    if hp > 100 and hp < 1000 then
				drawtext(x3 + 40, y3 + 30, 248, 218, 0, 255, "c+", 0, hp )
	            drawtext(x3 + 85, y3 + 30, 255, 255, 255, a3, "c+", 0, "HP")
				if ui.get(epicky.types3) == "Circle outline" then
				    draw_indicator_circle(ctx, x3 + 115, y3 + 32, 248, 218, 0, 255, 100)
				elseif ui.get(epicky.types3) == "Line" then
				    drawrect(x3 + 15, y3 + 45, 50, 3, 0, 0, 0, 200)
					drawrect(x3 + 15, y3 + 45, 50, 3, 248, 218, 0, a3)  
				end
			end
			
		    if hp == 100 then
		        drawtext(x3 + 40, y3 + 30, r3, g3, b3, a3, "c+", 0, hp )
	            drawtext(x3 + 85, y3 + 30, 255, 255, 255, a3, "c+", 0, "HP")
				if ui.get(epicky.types3) == "Circle outline" then
				    draw_indicator_circle(ctx, x3 + 115, y3 + 32, r3, g3, b3, a3, hp)
				elseif ui.get(epicky.types3) == "Line" then
				    drawrect(x3 + 15, y3 + 45, 50, 3, 0, 0, 0, 200)
					drawrect(x3 + 15, y3 + 45, hp / 2, 3, r3, g3, b3, a3)  
				end
			elseif hp < 100 and hp > 50 then
		        drawtext(x3 + 30, y3 + 30, r3, g3, b3, a3, "c+", 0, hp )
	            drawtext(x3 + 65, y3 + 30, 255, 255, 255, a3, "c+", 0, "HP")	
				if ui.get(epicky.types3) == "Circle outline" then
				    draw_indicator_circle(ctx, x3 + 95, y3 + 32, r3, g3, b3, a3, hp / 100)
				elseif ui.get(epicky.types3) == "Line" then
				    drawrect(x3 + 15, y3 + 45, 50, 3, 0, 0, 0, 200)
					drawrect(x3 + 15, y3 + 45, hp / 2, 3, r3, g3, b3, a3)  
				end
			elseif hp <= 50 and hp > 20 then
		        drawtext(x3 + 30, y3 + 30, 255, 134, 3, a3, "c+", 0, hp )
	            drawtext(x3 + 65, y3 + 30, 255, 255, 255, a3, "c+", 0, "HP")
				if ui.get(epicky.types3) == "Circle outline" then
				    draw_indicator_circle(ctx, x3 + 95, y3 + 32, 255, 134, 3, a3, hp / 100)
				elseif ui.get(epicky.types3) == "Line" then
				    drawrect(x3 + 15, y3 + 45, 50, 3, 0, 0, 0, 200)
					drawrect(x3 + 15, y3 + 45, hp / 2, 3, 255, 134, 3, a3)  
				end				
			elseif hp <= 20 and hp >= 10 then
		        drawtext(x3 + 30, y3 + 30, 255, 51, 51, a3, "c+", 0, hp )
	            drawtext(x3 + 65, y3 + 30, 255, 255, 255, a3, "c+", 0, "HP")
				if ui.get(epicky.types3) == "Circle outline" then
				    draw_indicator_circle(ctx, x3 + 95, y3 + 32, 255, 51, 51, a3, hp / 100)
				elseif ui.get(epicky.types3) == "Line" then
				    drawrect(x3 + 15, y3 + 45, 50, 3, 0, 0, 0, 200)
					drawrect(x3 + 15, y3 + 45, hp / 2, 3, 255, 51, 51, a3)  
				end
			elseif hp < 10 then
		        drawtext(x3 + 25, y3 + 30, 255, 51, 51, a3, "c+", 0, hp )
	            drawtext(x3 + 55, y3 + 30, 255, 255, 255, a3, "c+", 0, "HP")
				if ui.get(epicky.types3) == "Circle outline" then
				    draw_indicator_circle(ctx, x3 + 85, y3 + 32, 255, 51, 51, a3, hp / 100)
				elseif ui.get(epicky.types3) == "Line" then
				    drawrect(x3 + 15, y3 + 45, 50, 3, 0, 0, 0, 200)
					drawrect(x3 + 15, y3 + 45, hp / 2, 3, 255, 51, 51, a3)    
				end
			end
			
			if Contains(things3ref, "Show armor") then
			   if armor == 100 and hp >= 1000 then
		        drawtext(x3 + 170, y3 + 30, r3, g3, b3, a3, "c+", 0, armor )
	            drawtext(x3 + 245, y3 + 30, 255, 255, 255, a3, "c+", 0, "ARMOR")
				if ui.get(epicky.types3) == "Circle outline" then
				    draw_indicator_circle(ctx, x3 + 310, y3 + 32, r3, g3, b3, a3, armor / 100)
				elseif ui.get(epicky.types3) == "Line" then
				    drawrect(x3 + 150, y3 + 45, 50, 3, 0, 0, 0, 200)
					drawrect(x3 + 150, y3 + 45, armor / 2, 3, r3, g3, b3, a3)  
				end
				elseif armor == 100 then
		        drawtext(x3 + 160, y3 + 30, r3, g3, b3, a3, "c+", 0, armor )
	            drawtext(x3 + 235, y3 + 30, 255, 255, 255, a3, "c+", 0, "ARMOR")
				if ui.get(epicky.types3) == "Circle outline" then
				    draw_indicator_circle(ctx, x3 + 295, y3 + 32, r3, g3, b3, a3, armor / 100)
				elseif ui.get(epicky.types3) == "Line" then
				    drawrect(x3 + 135, y3 + 45, 50, 3, 0, 0, 0, 200)
					drawrect(x3 + 135, y3 + 45, armor / 2, 3, r3, g3, b3, a3)  
				end
				elseif armor < 100 and armor >= 10 then
		        drawtext(x3 + 160, y3 + 30, r3, g3, b3, a3, "c+", 0, armor )
	            drawtext(x3 + 225, y3 + 30, 255, 255, 255, a3, "c+", 0, "ARMOR")
				if ui.get(epicky.types3) == "Circle outline" then
				    draw_indicator_circle(ctx, x3 + 290, y3 + 32, r3, g3, b3, a3, armor / 100)
				elseif ui.get(epicky.types3) == "Line" then
				    drawrect(x3 + 145, y3 + 45, 50, 3, 0, 0, 0, 200)
					drawrect(x3 + 145, y3 + 45, armor / 2, 3, r3, g3, b3, a3)  
				end
				elseif armor < 10 then
		        drawtext(x3 + 160, y3 + 30, r3, g3, b3, a3, "c+", 0, armor )
	            drawtext(x3 + 215, y3 + 30, 255, 255, 255, a3, "c+", 0, "ARMOR")
				if ui.get(epicky.types3) == "Circle outline" then
				    draw_indicator_circle(ctx, x3 + 275, y3 + 32, r3, g3, b3, a3, armor / 100)
				elseif ui.get(epicky.types3) == "Line" then
				    drawrect(x3 + 135, y3 + 45, 50, 3, 0, 0, 0, 200)
					drawrect(x3 + 135, y3 + 45, armor / 2, 3, r3, g3, b3, a3)  
				end
			   end
			end
			if Contains(things3ref, "Show fps") then
			    drawtext(xfp3 + 20, yfp3 - 10, 255, 255, 255, a3, "c", 0, fps, " fps")
			end
			if Contains(things3ref, "Show ping") then
			    drawtext(xfp3 + 60, yfp3 - 10, 255, 255, 255, a3, "c", 0, ping, "ms" )
			end
			if Contains(things3ref, "Show ammo") then
                draw_container(ctx, xa3 + 30, ya3 + 15, 130, 45)
			    if Contains(things3ref, "Show gradient header") then
			        drawgradient(xa3 + 37, ya3 + 22, 60, 1, 5, 221, 255, 255, 186, 12, 230, 255, true)
		            drawgradient(xa3 + 97, ya3 + 22, 56, 1, 186, 12, 230, 255, 219, 226, 60, 255, true)
			    end
				drawtext(xa3 + 80, ya3 + 38, 7, 169, 232, a3, "c+", 0, ammo, "/", ammores)
				
				if ui.get(epicky.types3) == "Circle outline" or ui.get(epicky.types3) == "Line" then
				    draw_indicator_circle(ctx, xa3 + 135, ya3 + 39, 7, 169, 232, a3, ammo / 100) 
				end
			end
		end
	end
end


client.set_event_callback("paint", wishbestmod)