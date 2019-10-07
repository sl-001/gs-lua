local screen = {
    x, y,
    left,
    right,
    bottom,
    top
}
local mouseX, mouseY = 0, 0
screen.x, screen.y = client.screen_size()
local epicky_checkbox = ui.new_checkbox("visuals", "other esp", "Bomb timer")
local epicky_colorpicker = ui.new_color_picker("visuals", "other esp", "bomb slider color", 127, 176, 0)
local epicky_combobox_vh = ui.new_combobox("visuals", "other esp", "Type", "Horizontal", "Vertical")
local epicky_slider_x_h = ui.new_slider("visuals", "other esp", "x", 0, 1920, 650, true, "px", 1, nil)
local epicky_slider_y_h = ui.new_slider("visuals", "other esp", "y", 0, 1080, 0, true, "px", 1, nil)
local epicky_slider_x_v = ui.new_slider("visuals", "other esp", "x", 0, 1920, 650, true, "px", 1, nil)
local epicky_slider_y_v = ui.new_slider("visuals", "other esp", "y", 0, 1080, 280, true, "px", 1, nil)
local epicky_checkbox_line = ui.new_checkbox("visuals", "other esp", "Draw line")
local epicky_colorpicker_line1 = ui.new_color_picker("visuals", "other esp", "gradient1", 5, 221, 255)
local epicky_colorpicker_line = ui.new_color_picker("visuals", "other esp", "line color", 127, 176, 0)
local epicky_combobox_line = ui.new_combobox("visuals", "other esp", "Line color", "Gradient", "Static", "2-Colored gradient", "3-Colored gradient")
local epicky_colorpicker_line2 = ui.new_color_picker("visuals", "other esp", "gradient2", 186, 12, 230)
local epicky_combobox_linepos = ui.new_combobox("visuals", "other esp", "Line position", "Left", "Right", "Top", "Bottom")
local epicky_colorpicker_line3 = ui.new_color_picker("visuals", "other esp", "gradient3", 219, 226, 60)
local epicky_checkbox_time = ui.new_checkbox("visuals", "other esp", "Draw time")
local epicky_combobox_time_h = ui.new_combobox("visuals", "other esp", "Time position", "Slider", "Under 'C4'", "Under slider")
local epicky_combobox_time_v = ui.new_combobox("visuals", "other esp", "Time position", "Slider", "Under 'C4'")
local epicky_slider_time_roundtofifth = ui.new_slider("visuals", "other esp", "Time roundToFifth", 0, 2, 1, true, "")
local get_prop = entity.get_prop
local get_class = entity.get_classname
local get_all = entity.get_all
local get_lp = entity.get_local_player
local get_ui = ui.get
local drawrect = renderer.rectangle
local drawline = renderer.line
local textd = renderer.text
local drawgradient = renderer.gradient
local shouldDrag = false
local defusing = false

-- ghetto but works GetProp(player, "m_bHasDefuser") didnt really gave me the result i wanted --
-- this only breaks when you reload the script after someone already got a defuser

local defusers = 0

client.set_event_callback("item_pickup", function(e)
    if e.item == "defuser" then
        defusers = defusers + 1
    end
end)

client.set_event_callback("item_remove", function(e)
    if e.item == "defuser" and defusers >= 1 then
        defusers = defusers - 1
    end
end)

local function lerp(a, b, percentage)
	return a + (b - a) * percentage
end

local function get_bomb_time(bomb)
   local bomb_time = get_prop(bomb, "m_flC4Blow") - globals.curtime()
    if bomb_time == nil then return 0 end
    if bomb_time > 0 then
        return bomb_time
    end
    return 0
end

local function can_not_defuse(player, bomb)
    local bomb_time = get_prop(bomb, "m_flC4Blow") - globals.curtime()
    if bomb_time == nil then return false end
    return (bomb_time < 5 and defusers >= 1) or (bomb_time < 10 and defusers == 0)
end

local function get_defuser(bomb)
    return get_prop(bomb, "m_hBombDefuser")
end
--credits to zeleney30(2468)
local function round(num, numDecimalPlaces)
	local mult = 10 ^ (numDecimalPlaces or 0)

	if num >= 0 then return math.floor(num * mult + 0.5) / mult
	else 
		return math.ceil(num * mult - 0.5) / mult
	end
end

local function roundToFifth(num)
    local time_roundtofifth = get_ui(epicky_slider_time_roundtofifth) 
	num = round(num, time_roundtofifth)
	return num
end

--local function dragFeature()
--    if get_ui(epicky_drag_hotkey) then
--        mouseX, mouseY = ui.mouse_position
--        if shouldDrag then
--            x = mouseX - dx;
--            y = mouseY - dy;
--        end
--        if mouseX >= x and mouseX <= x + w and mouseY >= y and mouseY <= y + 40 then
--            shouldDrag = true;
--            dx = mouseX - x;
--            dy = mouseY - y;
--        end
--    else
--        shouldDrag = false;
--    end
--end

client.set_event_callback("paint", function(ctx)
	if get_ui(epicky_checkbox) then
	  ui.set_visible(epicky_combobox_vh, true)
	  ui.set_visible(epicky_checkbox_time, true)
	  if get_ui(epicky_checkbox_line) then
		    ui.set_visible(epicky_combobox_line, true)
		else
		    ui.set_visible(epicky_combobox_line, false)
	  end
	  if get_ui(epicky_combobox_vh) == "Vertical" then
	    ui.set_visible(epicky_slider_x_v, true)
	    ui.set_visible(epicky_slider_y_v, true)
	    ui.set_visible(epicky_checkbox_line, true)
		ui.set_visible(epicky_colorpicker_line, true)
		ui.set_visible(epicky_combobox_linepos, true)
		ui.set_visible(epicky_combobox_line, false)
		ui.set_visible(epicky_colorpicker_line1, false)
		ui.set_visible(epicky_colorpicker_line2, false)
		ui.set_visible(epicky_colorpicker_line3, false)
	  else
	    ui.set_visible(epicky_slider_x_v, false)
	    ui.set_visible(epicky_slider_y_v, false)
	    ui.set_visible(epicky_checkbox_line, true)
		ui.set_visible(epicky_combobox_linepos, false)
	  
	  if get_ui(epicky_combobox_line) == "Static" then
		    ui.set_visible(epicky_colorpicker_line, true)
        else
		    ui.set_visible(epicky_colorpicker_line, false)
	  end
	  
	  if get_ui(epicky_combobox_line) == "2-Colored gradient" then
	        ui.set_visible(epicky_colorpicker_line1, true)
		    ui.set_visible(epicky_colorpicker_line2, true)
			ui.set_visible(epicky_colorpicker_line, false)
	  else
	        ui.set_visible(epicky_colorpicker_line1, false)
		    ui.set_visible(epicky_colorpicker_line2, false)
	  end
	  
	  
	  if get_ui(epicky_combobox_line) == "3-Colored gradient" then
	        ui.set_visible(epicky_colorpicker_line1, true)
		    ui.set_visible(epicky_colorpicker_line2, true)
			ui.set_visible(epicky_colorpicker_line3, true)
			ui.set_visible(epicky_colorpicker_line, false)
	  else
			ui.set_visible(epicky_colorpicker_line3, false)
	  end
	  
	  end
	  if get_ui(epicky_combobox_vh) == "Horizontal" then
		ui.set_visible(epicky_slider_x_h, true)
	    ui.set_visible(epicky_slider_y_h, true)
	  else 
		ui.set_visible(epicky_slider_x_h, false)
	    ui.set_visible(epicky_slider_y_h, false)
	  end
	  if get_ui(epicky_checkbox_time) then
	  ui.set_visible(epicky_slider_time_roundtofifth, true)
	    if get_ui(epicky_combobox_vh) == "Vertical" then
		   	ui.set_visible(epicky_combobox_time_v, true)
		else 
		    ui.set_visible(epicky_combobox_time_v, false)
		end
	    if get_ui(epicky_combobox_vh) == "Horizontal" then
		   	ui.set_visible(epicky_combobox_time_h, true)
		else 
		    ui.set_visible(epicky_combobox_time_h, false)
		end
	  else
	  ui.set_visible(epicky_combobox_time_h, false)
	  ui.set_visible(epicky_combobox_time_v, false)
	  ui.set_visible(epicky_slider_time_roundtofifth, false)
	  end
	else
	  ui.set_visible(epicky_combobox_vh, false)
	  ui.set_visible(epicky_checkbox_line, false)
	  ui.set_visible(epicky_colorpicker_line, false)
	  ui.set_visible(epicky_combobox_line, false)
	  ui.set_visible(epicky_combobox_linepos, false)
	  ui.set_visible(epicky_slider_x_v, false)
	  ui.set_visible(epicky_slider_y_v, false)
	  ui.set_visible(epicky_slider_x_h, false)
	  ui.set_visible(epicky_slider_y_h, false)
	  ui.set_visible(epicky_checkbox_time, false)
	  ui.set_visible(epicky_combobox_time_h, false)
	  ui.set_visible(epicky_combobox_time_v, false)
	  ui.set_visible(epicky_slider_time_roundtofifth, false)
	end
	
	-- credits to sapphyrus(561)
	local alpha = 255 
	
	local realtime = globals.realtime() * 1.2

	local a2 = alpha*(1-(100*1.2)/100)

	local val = realtime % 2
		if val > 1 then
			val = 2 - val
		end

	local a_new = alpha*0.15 + lerp(alpha, a2, val)
	a_new = math.min(alpha, math.max(0, a_new))
			
	local bomb = get_all("CPlantedC4")[1]
	local r2, g2, b2, a2 = get_ui(epicky_colorpicker) 
	if bomb == nil then return false end
	if get_prop(bomb, "m_bBombDefused") == 1 then return end
	--color changes
        if can_not_defuse(player, bomb) then
            r, g, b = 130, 0, 31
        else
            r, g, b = r2, g2, b2
        end  
	--
	local rl, gl, bl = get_ui(epicky_colorpicker_line)
	
    if get_ui(epicky_checkbox) then
	 if get_ui(epicky_combobox_vh) == "Horizontal" then
	screen.left = get_ui(epicky_slider_x_h)
    screen.right = screen.y
    screen.bottom = screen.x
    screen.top = get_ui(epicky_slider_y_h)
	  local bomb_time = get_bomb_time(bomb)
      local bomb_time_max = client.get_cvar("mp_c4timer")
	  local time_pos = get_ui(epicky_combobox_time_h)
	  local drawlinech = get_ui(epicky_checkbox_line)
	  local grr1, grg1, grb1 = get_ui(epicky_colorpicker_line1)
	  local grr2, grg2, grb2 = get_ui(epicky_colorpicker_line2)
	  local grr3, grg3, grb3 = get_ui(epicky_colorpicker_line3)

	  local width = ((math.abs(900 * bomb_time) / 120 ))
   
	   --boxes
	     drawrect(screen.left - 80, screen.top + 50,  440, 60, 25, 25, 25, 100)
	     drawrect(screen.left - 70, screen.top + 60, 420, 43, 25, 25, 25, 130)
	   
	   --outlines
	     drawline(screen.left - 80, screen.top + 50, screen.left + 360, screen.top + 50, 0, 0, 0, 200)
	     drawline(screen.left - 80, screen.top + 50, screen.left - 80, screen.top + 110, 0, 0, 0, 200)
	     drawline(screen.left - 80, screen.top + 110, screen.left + 360, screen.top + 110, 0, 0, 0, 200)
	     drawline(screen.left + 360, screen.top + 50, screen.left + 360, screen.top + 110, 0, 0, 0, 200)
	   
	   --outlines for the smaller box
	     drawline(screen.left - 70, screen.top + 60, screen.left + 350, screen.top + 60, 0, 0, 0, 200)
	     drawline(screen.left - 70, screen.top + 60, screen.left - 70, screen.top + 102, 0, 0, 0, 200)
	     drawline(screen.left - 70, screen.top + 102, screen.left + 350, screen.top + 102, 0, 0, 0, 200)
	     drawline(screen.left + 350, screen.top + 60, screen.left + 350, screen.top + 102, 0, 0, 0, 200)
	   
	   --rainbow line
	   if drawlinech then
	    if get_ui(epicky_combobox_line) == "Gradient" then
	     drawgradient(screen.left - 79, screen.top + 51, 230, 1, 5, 221, 255, 255, 186, 12, 230, 255, true)
         drawgradient(screen.left + 150, screen.top + 51, 210, 1, 186, 12, 230, 255, 219, 226, 60, 255,  true)
		end
		
		if get_ui(epicky_combobox_line) == "Static" then
		 drawline(screen.left - 79, screen.top + 51, screen.left + 360, screen.top + 51, rl, gl, bl, 200)
		end
		
		if get_ui(epicky_combobox_line) == "2-Colored gradient" then
		 drawgradient(screen.left - 79, screen.top + 51, 440, 1, grr1, grg1, grb1, 255, grr2, grg2, grb2, 255, true)
		end
		
		if get_ui(epicky_combobox_line) == "3-Colored gradient" then
		 drawgradient(screen.left - 79, screen.top + 51, 230, 1, grr1, grg1, grb1, 255, grr2, grg2, grb2, 255, true)
         drawgradient(screen.left + 150, screen.top + 51, 210, 1, grr2, grg2, grb2, 255, grr3, grg3, grb3, 255,  true)
		end
	   end
		 
	   --timer
         drawrect(screen.left - 16, screen.top + 77,  341, 14, 25, 25, 25, 160)
	     drawrect(screen.left - 15, screen.top + 78, width, 12, r, g, b, 255)
		 
	   --text 
	   if time_pos == "Slider" then
	   	 textd(screen.left - 40, screen.top + 82, 255, 255, 255, a_new, '+c', 0, "C4" )
		 if get_ui(epicky_checkbox_time) then
		 textd(screen.left - 17 + width, screen.top + 84, 255, 255, 255, 255, "c", 0, roundToFifth(get_bomb_time(bomb)))
		 end
	   end
	   if time_pos == "Under slider" then
	   	 textd(screen.left - 40, screen.top + 82, 255, 255, 255, a_new, '+c', 0, "C4" )
		 if get_ui(epicky_checkbox_time) then
		 textd(screen.left - 17 + width, screen.top + 92, 255, 255, 255, 255, "c", 0, roundToFifth(get_bomb_time(bomb)))
		 end
	   end
	   if time_pos == "Under 'C4'" then
	     textd(screen.left - 40, screen.top + 77, 255, 255, 255, a_new, '+c', 0, "C4" )
		 if get_ui(epicky_checkbox_time) then
		 textd(screen.left - 40, screen.top + 93, 255, 255, 255, 255, "c", 0, roundToFifth(get_bomb_time(bomb)))
		 end
	   end
     end
	 
	 if get_ui(epicky_combobox_vh) == "Vertical" then
	screen.left = get_ui(epicky_slider_x_v)
    screen.right = screen.y
    screen.bottom = screen.x
    screen.top = get_ui(epicky_slider_y_v)
	  local bomb_time = get_bomb_time(bomb)
      local bomb_time_max = client.get_cvar("mp_c4timer")
	  local time_pos = get_ui(epicky_combobox_time_v)
	  local drawlinechx = get_ui(epicky_checkbox_line)

	  local height = ((math.abs(900 * bomb_time) / 110 ))
   
	   --boxes
	     drawrect(screen.left - 430, screen.top + 20,  60, 440, 25, 25, 25, 100)
	     drawrect(screen.left - 420, screen.top + 30, 43, 420, 25, 25, 25, 130)
	   
	   --outlines for the smaller box
	     drawline(screen.left - 420, screen.top + 30, screen.left - 378, screen.top + 30, 0, 0, 0, 200)
	     drawline(screen.left - 420, screen.top + 30, screen.left - 420, screen.top + 450, 0, 0, 0, 200)
	     drawline(screen.left - 420, screen.top + 450, screen.left - 378, screen.top + 450, 0, 0, 0, 200)
	     drawline(screen.left - 378, screen.top + 30, screen.left - 378, screen.top + 450, 0, 0, 0, 200)
	   
	   --outlines
	     drawline(screen.left - 430, screen.top + 20, screen.left - 370, screen.top + 20, 0, 0, 0, 200)
	     drawline(screen.left - 430, screen.top + 20, screen.left - 430, screen.top + 460, 0, 0, 0, 200)
	     drawline(screen.left - 430, screen.top + 460, screen.left - 370, screen.top + 460, 0, 0, 0, 200)
	     drawline(screen.left - 370, screen.top + 20, screen.left - 370, screen.top + 460, 0, 0, 0, 200)
	   
	   --line
	   if drawlinechx then
	    if get_ui(epicky_combobox_linepos) == "Right" then
	     drawline(screen.left - 371, screen.top + 20, screen.left - 371, screen.top + 459, rl, gl, bl, 200)
		end
	    if get_ui(epicky_combobox_linepos) == "Left" then
	     drawline(screen.left - 429, screen.top + 20, screen.left - 429, screen.top + 459, rl, gl, bl, 200)
		end
	    if get_ui(epicky_combobox_linepos) == "Bottom" then
	     drawline(screen.left - 430, screen.top + 459, screen.left - 371, screen.top + 459, rl, gl, bl, 200)
		end
	    if get_ui(epicky_combobox_linepos) == "Top" then
	     drawline(screen.left - 430, screen.top + 21, screen.left - 370, screen.top + 21, rl, gl, bl, 200)
		end
	   end
		 
	   --timer
         drawrect(screen.left - 409, screen.top + 65, 20, 375, 25, 25, 25, 160)
	     drawrect(screen.left - 408, screen.top + 67, 17, height, r, g, b, 255)
		 
	   --text 
	   if time_pos == "Slider" then
	   	 textd(screen.left - 399, screen.top + 48, 255, 255, 255, a_new, '+c', 0, "C4" )
		 if get_ui(epicky_checkbox_time) then
		 textd(screen.left - 399, screen.top + 65 + height, 255, 255, 255, 255, "c", 0, roundToFifth(get_bomb_time(bomb)))
		 end
	   end
	   if time_pos == "Under 'C4'" then
	     textd(screen.left - 399, screen.top + 42, 255, 255, 255, a_new, '+c', 0, "C4" )
		 if get_ui(epicky_checkbox_time) then
		 textd(screen.left - 400, screen.top + 58, 255, 255, 255, 255, "c", 0, roundToFifth(get_bomb_time(bomb)))
		 end
	   end
	 end
    end
end )

-- credits to Aviarita(1363) for the original script
