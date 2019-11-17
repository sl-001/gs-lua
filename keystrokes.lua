local client_set_event_callback = client.set_event_callback
local client_draw_rectangle = client.draw_rectangle
local client_draw_text = client.draw_text

local ui_new_hotkey = ui.new_hotkey
local ui_get = ui.get

local hw = ui_new_hotkey("LUA", "A", "W")
local ha = ui_new_hotkey("LUA", "A", "A")
local hs = ui_new_hotkey("LUA", "A", "S")
local hd = ui_new_hotkey("LUA", "A", "D")
local hspace = ui_new_hotkey("LUA", "A", "SPACE")
local hcrouch = ui_new_hotkey("LUA", "A", "CROUCH")
local hfakecrouch = ui.reference("RAGE", "Other", "Duck peek assist")

local function eventhandler_paint(ctx)
	
	if ui_get(hw) then
		client_draw_text(ctx, 960, 750, 124, 195, 13, 255, "c+", 0, "w")
	else
		client_draw_text(ctx, 960, 750, 255, 13, 13, 50, "c+", 0, "w")
	end
	
	
	if ui_get(ha) then
		client_draw_text(ctx, 930, 780, 124, 195, 13, 255, "c+", 0, "a")
	else
		client_draw_text(ctx, 930, 780, 255, 13, 13, 50, "c+", 0, "a")
	end
	
	
	if ui_get(hd) then
		client_draw_text(ctx, 990, 780, 124, 195, 13, 255, "c+", 0, "d")
	else
		client_draw_text(ctx, 990, 780, 255, 13, 13, 50, "c+", 0, "d")
	end
	
	
	if ui_get(hs) then
		client_draw_text(ctx, 960, 780, 124, 195, 13, 255, "c+", 0, "s")
	else
		client_draw_text(ctx, 960, 780, 255, 13, 13, 50, "c+", 0, "s")
	end
	
	
	if ui_get(hspace) then
		client_draw_text(ctx, 960, 810, 124, 195, 13, 255, "c+", 0, "space")
	else
		client_draw_text(ctx, 960, 810, 255, 13, 13, 50, "c+", 0, "space")
	end
	
	if ui_get(hcrouch) or ui_get(hfakecrouch) then
		client_draw_text(ctx, 908, 810, 124, 195, 13, 255, "c+", 0, "⮟")
	else
		client_draw_text(ctx, 908, 810, 255, 13, 13, 50, "c+", 0, "⮟")
	end

end

client_set_event_callback("paint", eventhandler_paint)