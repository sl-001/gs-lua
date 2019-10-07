local draw = { line = renderer.line, rect = renderer.rectangle, text = renderer.text, gradient = renderer.gradient }
local get_all = entity.get_all
local local_player = entity.get_local_player
local get_prop = entity.get_prop
local set_prop = entity.set_prop
local w, h = client.screen_size()
local draw_rectangle = client.draw_rectangle
local epicky = 
{
    check = ui.new_checkbox("aa", "other", "Indicators"),
	color = ui.new_color_picker("aa", "other", "accent", 149, 184, 6, 255),
	colorg1 = ui.new_color_picker("aa", "other", "accentg1", 59, 175, 222, 255),
	selection = ui.new_multiselect("aa", "other", "\n", "Fakelag", "Body aim", "Fake duck"),
	colorg2 = ui.new_color_picker("aa", "other", "accentg2", 202, 70, 205, 255),
	box_pos = ui.new_combobox("aa", "other", "Box position", "Below text", "Next to text"),
	header = ui.new_checkbox("aa", "other", "Header"),
	gradient = ui.new_checkbox("aa", "other", "Gradient"),
	xx = ui.new_slider("aa", "other", "X position", 0, w, w - 220),
	yy = ui.new_slider("aa", "other", "Y position", 0, h, h/2)
}
local baim_ref = ui.reference("rage", "other", "Force body aim")
local fd_ref = ui.reference("rage", "other", "Duck peek assist")
local choked_ticks = 0
client.set_event_callback("setup_command", function(cmd)
    choked_ticksf = cmd.chokedcommands
    if cmd.chokedcommands > 3 then
    choked_ticks = cmd.chokedcommands
	else
	choked_ticks = 0
	end
end)

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
		local x_inner, y_inner = x+7, y+7
		local w_inner = w-14
		
        if ui.get(epicky.header) then
		    renderer.gradient(x_inner, y_inner, math.floor(w_inner/2), 1, 59, 175, 222, 255, 202, 70, 205, 255, true)
		    renderer.gradient(x_inner+math.floor(w_inner/2), y_inner, math.ceil(w_inner/2), 1, 202, 70, 205, 255, 201, 227, 58, 255, true)
		end
    end
end


local function w0w(ctx, e)

    local xx, yy = ui.get(epicky.xx), ui.get(epicky.yy)
	local val = ui.get(epicky.selection)
	local r, g, b, a = ui.get(epicky.color)
	local rg, gg, bg, ag = ui.get(epicky.colorg1)
	local rg2, gg2, bg2, ag2 = ui.get(epicky.colorg2)
	
    if ui.get(epicky.check) then
	    ui.set_visible(epicky.selection, true)
		if ui.get(epicky.gradient) then
		    if Contains(val, "Body aim") and not Contains(val, "Fakelag") and not Contains(val, "Fake duck") then
			    ui.set_visible(epicky.colorg1, false)
		        ui.set_visible(epicky.colorg2, false)
			    ui.set_visible(epicky.color, true)
			elseif not Contains(val, "Body aim") and Contains(val, "Fakelag") and Contains(val, "Fake duck") or not Contains(val, "Body aim") and Contains(val, "Fakelag") and not Contains(val, "Fake duck") or not Contains(val, "Body aim") and not Contains(val, "Fakelag") and Contains(val, "Fake duck") or Contains(val, "Body aim") and not Contains(val, "Fakelag") and Contains(val, "Fake duck") or Contains(val, "Body aim") and Contains(val, "Fakelag") and not Contains(val, "Fake duck") then
		        ui.set_visible(epicky.colorg1, true)
			    ui.set_visible(epicky.colorg2, true)
			    ui.set_visible(epicky.color, false)
			end
		else
		    ui.set_visible(epicky.colorg1, false)
		    ui.set_visible(epicky.colorg2, false)
			ui.set_visible(epicky.color, true)
		end
		ui.set_visible(epicky.box_pos, true)
		ui.set_visible(epicky.header, true)
		ui.set_visible(epicky.gradient, true)
		ui.set_visible(epicky.xx, true)
		ui.set_visible(epicky.yy, true)
    else
	    ui.set_visible(epicky.selection, false)
		ui.set_visible(epicky.colorg1, false)
		ui.set_visible(epicky.colorg2, false)
		ui.set_visible(epicky.box_pos, false)
		ui.set_visible(epicky.header, false)
		ui.set_visible(epicky.gradient, false)
		ui.set_visible(epicky.xx, false)
		ui.set_visible(epicky.yy, false)
	end
	

    if ui.get(epicky.check) and not Contains(val, "Fakelag") and not Contains(val, "Body aim") and not Contains(val, "Fake duck") then
	    draw_container(ctx, xx, yy, 200, 25)
		
	elseif ui.get(epicky.check) and Contains(val, "Fakelag") and not Contains(val, "Body aim") and not Contains(val, "Fake duck") then
	    if ui.get(epicky.box_pos) == "Below text" or ui.get(epicky.box_pos) == "Above text" then
	        draw_container(ctx, xx, yy, 200, 45)
		elseif ui.get(epicky.box_pos) == "Next to text" then
		    draw_container(ctx, xx, yy, 200, 35)
		end
		draw.text(xx + 13, yy + 12, 255, 255, 255, 255, "", 0, "Fakelag")
		if ui.get(epicky.box_pos) == "Below text" then
		    draw.rect(xx + 12, yy + 27, 170, 5, 10, 10, 10, 150)
			if ui.get(epicky.gradient) then
			    draw.text(xx + 58, yy + 12, rg, gg, bg, ag, "b", 0, choked_ticks)
		        renderer.gradient(xx + 12, yy + 27, 12*choked_ticks, 5, rg, gg, bg, ag, rg2, gg2, bg2, ag2, true)
			else
			    draw.text(xx + 58, yy + 12, r, g, b, a, "b", 0, choked_ticks)
			    draw.rect(xx + 12, yy + 27, 12*choked_ticks, 5, r, g, b, a)
			end
		elseif ui.get(epicky.box_pos) == "Next to text" then
		    draw.rect(xx + 72, yy + 16, 110, 5, 10, 10, 10, 150)
			if ui.get(epicky.gradient) then
			    draw.text(xx + 58, yy + 12, rg, gg, bg, ag, "b", 0, choked_ticks)
		        renderer.gradient(xx + 72, yy + 16, 7.8571428571428*choked_ticks, 5, rg, gg, bg, ag, rg2, gg2, bg2, ag2, true)
			else
			    draw.text(xx + 58, yy + 12, r, g, b, a, "b", 0, choked_ticks)
			    draw.rect(xx + 72, yy + 16, 7.8571428571428*choked_ticks, 5, r, g, b, a)
			end
		end
		
	elseif ui.get(epicky.check) and Contains(val, "Body aim") and not Contains(val, "Fakelag") and not Contains(val, "Fake duck") then
	    draw_container(ctx, xx, yy, 200, 35)
        if ui.get(baim_ref) then
            draw.text(xx + 13, yy + 12, r, g, b, a, "b", 0, "• Body aim")
		else
		    draw.text(xx + 13, yy + 12, 255, 255, 255, 255, "", 0, "Body aim")
		end
		
	elseif ui.get(epicky.check) and Contains(val, "Fake duck") and not Contains(val, "Fakelag") and not Contains(val, "Body aim") then
       	if ui.get(epicky.box_pos) == "Below text" or ui.get(epicky.box_pos) == "Above text" then
	        draw_container(ctx, xx, yy, 200, 45)
		elseif ui.get(epicky.box_pos) == "Next to text" then
		    draw_container(ctx, xx, yy, 200, 35)
		end
		if ui.get(epicky.box_pos) == "Below text" then
		    draw.rect(xx + 12, yy + 27, 170, 5, 10, 10, 10, 150)
		elseif ui.get(epicky.box_pos) == "Next to text" then
		    draw.rect(xx + 77, yy + 16, 110, 5, 10, 10, 10, 150)
		end
		if ui.get(fd_ref) then
		    if ui.get(epicky.box_pos) == "Below text" then
				if ui.get(epicky.gradient) then
				    renderer.gradient(xx + 12, yy + 27, 170/choked_ticksf, 5, rg, gg, bg, ag, rg2, gg2, bg2, ag2, true)
					draw.text(xx + 13, yy + 12, rg, gg, bg, ag, "b", 0, "• Fake duck")
				else
		            draw.rect(xx + 12, yy + 27, 170/choked_ticksf, 5, r, g, b, a)
					draw.text(xx + 13, yy + 12, r, g, b, a, "b", 0, "• Fake duck")
				end
		    elseif ui.get(epicky.box_pos) == "Next to text" then
			    if ui.get(epicky.gradient) then
				    renderer.gradient(xx + 77, yy + 16, 110/choked_ticksf, 5, rg, gg, bg, ag, rg2, gg2, bg2, ag2, true)
					draw.text(xx + 13, yy + 12, rg, gg, bg, ag, "b", 0, "• Fake duck")
				else
		            draw.rect(xx + 77, yy + 16, 110/choked_ticksf, 5, r, g, b, a)
					draw.text(xx + 13, yy + 12, r, g, b, a, "b", 0, "• Fake duck")
				end
		    end
		else
		    draw.text(xx + 13, yy + 12, 255, 255, 255, 255, "", 0, "Fake duck")
		end
		
	elseif ui.get(epicky.check) and Contains(val, "Fake duck") and Contains(val, "Fakelag") and Contains(val, "Body aim") then
	    if ui.get(epicky.box_pos) == "Below text" or ui.get(epicky.box_pos) == "Above text" then
	        draw_container(ctx, xx, yy, 200, 80)
		elseif ui.get(epicky.box_pos) == "Next to text" then
		    draw_container(ctx, xx, yy, 200, 70)
		end
		
		draw.text(xx + 13, yy + 12, 255, 255, 255, 255, "", 0, "Fakelag")
		if ui.get(epicky.box_pos) == "Below text" then
		    draw.rect(xx + 12, yy + 27, 170, 5, 10, 10, 10, 150)
		    if ui.get(epicky.gradient) then
			    draw.text(xx + 58, yy + 12, rg, gg, bg, ag, "b", 0, choked_ticks)
		        renderer.gradient(xx + 12, yy + 27, 12*choked_ticks, 5, rg, gg, bg, ag, rg2, gg2, bg2, ag2, true)
			else
			    draw.text(xx + 58, yy + 12, r, g, b, a, "b", 0, choked_ticks)
			    draw.rect(xx + 12, yy + 27, 12*choked_ticks, 5, r, g, b, a)
			end
			
			if ui.get(epicky.gradient) then
			    if ui.get(baim_ref) then
                    draw.text(xx + 13, yy + 36, rg, gg, bg, ag, "b", 0, "• Body aim")
		        else
		            draw.text(xx + 13, yy + 36, 255, 255, 255, 255, "", 0, "Body aim")
		        end
			else
			    if ui.get(baim_ref) then
                    draw.text(xx + 13, yy + 36, r, g, b, a, "b", 0, "• Body aim")
		        else
		            draw.text(xx + 13, yy + 36, 255, 255, 255, 255, "", 0, "Body aim")
		        end
			end
			
			if ui.get(epicky.gradient) then
			    if ui.get(fd_ref) then
                    draw.text(xx + 13, yy + 54, rg, gg, bg, ag, "b", 0, "• Fake duck")
		        else
		            draw.text(xx + 13, yy + 54, 255, 255, 255, 255, "", 0, "Fake duck")
		        end
			else
			    if ui.get(fd_ref) then
                    draw.text(xx + 13, yy + 54, r, g, b, a, "b", 0, "• Fake duck")
		        else
		            draw.text(xx + 13, yy + 54, 255, 255, 255, 255, "", 0, "Fake duck")
		        end
			end
			
		elseif ui.get(epicky.box_pos) == "Next to text" then
		    draw.rect(xx + 72, yy + 16, 110, 5, 10, 10, 10, 150)
		    if ui.get(epicky.gradient) then
			    draw.text(xx + 58, yy + 12, rg, gg, bg, ag, "b", 0, choked_ticks)
		        renderer.gradient(xx + 72, yy + 16, 7.8571428571428*choked_ticks, 5, rg, gg, bg, ag, rg2, gg2, bg2, ag2, true)
			else
			    draw.text(xx + 58, yy + 12, r, g, b, a, "b", 0, choked_ticks)
			    draw.rect(xx + 72, yy + 16, 7.8571428571428*choked_ticks, 5, r, g, b, a)
			end
			
			if ui.get(epicky.gradient) then
			    if ui.get(baim_ref) then
                    draw.text(xx + 13, yy + 29, rg, gg, bg, ag, "b", 0, "• Body aim")
		        else
		            draw.text(xx + 13, yy + 29, 255, 255, 255, 255, "", 0, "Body aim")
		        end
			else
			    if ui.get(baim_ref) then
                    draw.text(xx + 13, yy + 29, r, g, b, a, "b", 0, "• Body aim")
		        else
		            draw.text(xx + 13, yy + 29, 255, 255, 255, 255, "", 0, "Body aim")
		        end
			end
			
			if ui.get(epicky.gradient) then
			    if ui.get(fd_ref) then
                    draw.text(xx + 13, yy + 46, rg, gg, bg, ag, "b", 0, "• Fake duck")
		        else
		            draw.text(xx + 13, yy + 46, 255, 255, 255, 255, "", 0, "Fake duck")
		        end
			else
			    if ui.get(fd_ref) then
                    draw.text(xx + 13, yy + 46, r, g, b, a, "b", 0, "• Fake duck")
		        else
		            draw.text(xx + 13, yy + 46, 255, 255, 255, 255, "", 0, "Fake duck")
		        end
			end
			
		end
		
		
	elseif ui.get(epicky.check) and not Contains(val, "Fake duck") and Contains(val, "Fakelag") and Contains(val, "Body aim") then
	    if ui.get(epicky.box_pos) == "Below text" or ui.get(epicky.box_pos) == "Above text" then
	        draw_container(ctx, xx, yy, 200, 60)
		elseif ui.get(epicky.box_pos) == "Next to text" then
		    draw_container(ctx, xx, yy, 200, 52)
		end
		
		draw.text(xx + 13, yy + 12, 255, 255, 255, 255, "", 0, "Fakelag")
		if ui.get(epicky.box_pos) == "Below text" then
		    draw.rect(xx + 12, yy + 27, 170, 5, 10, 10, 10, 150)
		    if ui.get(epicky.gradient) then
			    draw.text(xx + 58, yy + 12, rg, gg, bg, ag, "b", 0, choked_ticks)
		        renderer.gradient(xx + 12, yy + 27, 12*choked_ticks, 5, rg, gg, bg, ag, rg2, gg2, bg2, ag2, true)
			else
			    draw.text(xx + 58, yy + 12, r, g, b, a, "b", 0, choked_ticks)
			    draw.rect(xx + 12, yy + 27, 12*choked_ticks, 5, r, g, b, a)
			end
			
			if ui.get(epicky.gradient) then
			    if ui.get(baim_ref) then
                    draw.text(xx + 13, yy + 36, rg, gg, bg, ag, "b", 0, "• Body aim")
		        else
		            draw.text(xx + 13, yy + 36, 255, 255, 255, 255, "", 0, "Body aim")
		        end
			else
			    if ui.get(baim_ref) then
                    draw.text(xx + 13, yy + 36, r, g, b, a, "b", 0, "• Body aim")
		        else
		            draw.text(xx + 13, yy + 36, 255, 255, 255, 255, "", 0, "Body aim")
		        end
			end
			
		elseif ui.get(epicky.box_pos) == "Next to text" then
		    draw.rect(xx + 72, yy + 16, 110, 5, 10, 10, 10, 150)
		    if ui.get(epicky.gradient) then
			    draw.text(xx + 58, yy + 12, rg, gg, bg, ag, "b", 0, choked_ticks)
		        renderer.gradient(xx + 72, yy + 16, 7.8571428571428*choked_ticks, 5, rg, gg, bg, ag, rg2, gg2, bg2, ag2, true)
			else
			    draw.text(xx + 58, yy + 12, r, g, b, a, "b", 0, choked_ticks)
			    draw.rect(xx + 72, yy + 16, 7.8571428571428*choked_ticks, 5, r, g, b, a)
			end
			
			if ui.get(epicky.gradient) then
			    if ui.get(baim_ref) then
                    draw.text(xx + 13, yy + 29, rg, gg, bg, ag, "b", 0, "• Body aim")
		        else
		            draw.text(xx + 13, yy + 29, 255, 255, 255, 255, "", 0, "Body aim")
		        end
			else
			    if ui.get(baim_ref) then
                    draw.text(xx + 13, yy + 29, r, g, b, a, "b", 0, "• Body aim")
		        else
		            draw.text(xx + 13, yy + 29, 255, 255, 255, 255, "", 0, "Body aim")
		        end
			end
			
		end

		
    elseif ui.get(epicky.check) and Contains(val, "Fake duck") and Contains(val, "Fakelag") and not Contains(val, "Body aim") then
	    if ui.get(epicky.box_pos) == "Below text" or ui.get(epicky.box_pos) == "Above text" then
	        draw_container(ctx, xx, yy, 200, 60)
		elseif ui.get(epicky.box_pos) == "Next to text" then
		    draw_container(ctx, xx, yy, 200, 52)
		end
		draw.text(xx + 13, yy + 12, 255, 255, 255, 255, "", 0, "Fakelag")
		if ui.get(epicky.box_pos) == "Below text" then
		    draw.rect(xx + 12, yy + 27, 170, 5, 10, 10, 10, 150)
		    if ui.get(epicky.gradient) then
			    draw.text(xx + 58, yy + 12, rg, gg, bg, ag, "b", 0, choked_ticks)
		        renderer.gradient(xx + 12, yy + 27, 12*choked_ticks, 5, rg, gg, bg, ag, rg2, gg2, bg2, ag2, true)
			else
			    draw.text(xx + 58, yy + 12, r, g, b, a, "b", 0, choked_ticks)
			    draw.rect(xx + 12, yy + 27, 12*choked_ticks, 5, r, g, b, a)
			end
			
			if ui.get(epicky.gradient) then
			    if ui.get(fd_ref) then
                    draw.text(xx + 13, yy + 35, rg, gg, bg, ag, "b", 0, "• Fake duck")
		        else
		            draw.text(xx + 13, yy + 35, 255, 255, 255, 255, "", 0, "Fake duck")
		        end
			else
			    if ui.get(fd_ref) then
                    draw.text(xx + 13, yy + 35, r, g, b, a, "b", 0, "• Fake duck")
		        else
		            draw.text(xx + 13, yy + 35, 255, 255, 255, 255, "", 0, "Fake duck")
		        end
			end

		elseif ui.get(epicky.box_pos) == "Next to text" then
		    draw.rect(xx + 72, yy + 16, 110, 5, 10, 10, 10, 150)
		    if ui.get(epicky.gradient) then
			    draw.text(xx + 58, yy + 12, rg, gg, bg, ag, "b", 0, choked_ticks)
		        renderer.gradient(xx + 72, yy + 16, 7.8571428571428*choked_ticks, 5, rg, gg, bg, ag, rg2, gg2, bg2, ag2, true)
			else
			    draw.text(xx + 58, yy + 12, r, g, b, a, "b", 0, choked_ticks)
			    draw.rect(xx + 72, yy + 16, 7.8571428571428*choked_ticks, 5, r, g, b, a)
			end
			
			if ui.get(epicky.gradient) then
			    if ui.get(fd_ref) then
                    draw.text(xx + 13, yy + 29, rg, gg, bg, ag, "b", 0, "• Fake duck")
		        else
		            draw.text(xx + 13, yy + 29, 255, 255, 255, 255, "", 0, "Fake duck")
		        end
			else
			    if ui.get(fd_ref) then
                    draw.text(xx + 13, yy + 29, r, g, b, a, "b", 0, "• Fake duck")
		        else
		            draw.text(xx + 13, yy + 29, 255, 255, 255, 255, "", 0, "Fake duck")
		        end
			end
			
		end
		
		
	elseif ui.get(epicky.check) and Contains(val, "Fake duck") and not Contains(val, "Fakelag") and Contains(val, "Body aim") then
	    if ui.get(epicky.box_pos) == "Below text" or ui.get(epicky.box_pos) == "Above text" then
	        draw_container(ctx, xx, yy, 200, 60)
		elseif ui.get(epicky.box_pos) == "Next to text" then
		    draw_container(ctx, xx, yy, 200, 52)
		end
		if ui.get(epicky.box_pos) == "Below text" then
		    draw.rect(xx + 12, yy + 27, 170, 5, 10, 10, 10, 150)
		elseif ui.get(epicky.box_pos) == "Next to text" then
		    draw.rect(xx + 77, yy + 16, 110, 5, 10, 10, 10, 150)
		end
		if ui.get(fd_ref) then
		    if ui.get(epicky.box_pos) == "Below text" then
		        if ui.get(epicky.gradient) then
				    renderer.gradient(xx + 12, yy + 27, 170/choked_ticksf, 5, rg, gg, bg, ag, rg2, gg2, bg2, ag2, true)
					draw.text(xx + 13, yy + 12, rg, gg, bg, ag, "b", 0, "• Fake duck")
				else
		            draw.rect(xx + 12, yy + 27, 170/choked_ticksf, 5, r, g, b, a)
					draw.text(xx + 13, yy + 12, r, g, b, a, "b", 0, "• Fake duck")
				end
		    elseif ui.get(epicky.box_pos) == "Next to text" then
		        if ui.get(epicky.gradient) then
				    renderer.gradient(xx + 77, yy + 16, 110/choked_ticksf, 5, rg, gg, bg, ag, rg2, gg2, bg2, ag2, true)
					draw.text(xx + 13, yy + 12, rg, gg, bg, ag, "b", 0, "• Fake duck")
				else
		            draw.rect(xx + 77, yy + 16, 110/choked_ticksf, 5, r, g, b, a)
					draw.text(xx + 13, yy + 12, r, g, b, a, "b", 0, "• Fake duck")
				end
		    end
		else
		    draw.text(xx + 13, yy + 12, 255, 255, 255, 255, "", 0, "Fake duck")
		end
		
		if ui.get(epicky.box_pos) == "Below text" then
		    if ui.get(epicky.gradient) then
			    if ui.get(baim_ref) then
                    draw.text(xx + 13, yy + 36, rg, gg, bg, ag, "b", 0, "• Body aim")
		        else
		            draw.text(xx + 13, yy + 36, 255, 255, 255, 255, "", 0, "Body aim")
		        end
			else
			    if ui.get(baim_ref) then
                    draw.text(xx + 13, yy + 36, r, g, b, a, "b", 0, "• Body aim")
		        else
		            draw.text(xx + 13, yy + 36, 255, 255, 255, 255, "", 0, "Body aim")
		        end
			end
		elseif ui.get(epicky.box_pos) == "Next to text" then
		    if ui.get(epicky.gradient) then
			    if ui.get(baim_ref) then
                    draw.text(xx + 13, yy + 29, rg, gg, bg, ag, "b", 0, "• Body aim")
		        else
		            draw.text(xx + 13, yy + 29, 255, 255, 255, 255, "", 0, "Body aim")
		        end
			else
			    if ui.get(baim_ref) then
                    draw.text(xx + 13, yy + 29, r, g, b, a, "b", 0, "• Body aim")
		        else
		            draw.text(xx + 13, yy + 29, 255, 255, 255, 255, "", 0, "Body aim")
		        end
			end
		end
	end
end


client.set_event_callback("paint", w0w)
client.set_event_callback("setup_command", setup_command)