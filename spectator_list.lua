local w, h = client.screen_size()
local draw = {
    box = renderer.rectangle,
    line = renderer.line,
    text = renderer.text,
    measure_text = renderer.measure_text,
    gradient = renderer.gradient
}
local styles = { "Default", "Gamesense" }
local gui = {
    enable_spec = ui.new_checkbox("lua", "a", "Spectators"),
    col_spec = ui.new_color_picker("lua", "a", "speccol", 255, 255, 255, 0),
    col_spec_gs = ui.new_color_picker("lua", "a", "speccolgs", 127, 176, 0, 255),
    col_spec_sp = ui.new_color_picker("lua", "a", "speccolgs", 127, 176, 0, 255),
    style_spec = ui.new_combobox("lua", "a", "\n", styles),
    x_spec = ui.new_slider("lua", "a", "X Offset", 0, w, 250, true, "px"),
    y_spec = ui.new_slider("lua", "a", "Y Offset", 0, h - 25, 25, true, "px"),
    w_spec = ui.new_slider("lua", "a", "Width", 150, 300, 150, true, "px"),
    header = ui.new_checkbox("lua", "a", "Header")
}
local players = {}
local lp = entity.get_local_player()
local h2o = 5
local visible = ui.set_visible

local function draw_dcontainer(x, y, w, h, title, header)
    local r, g, b, a = ui.get(gui.col_spec)
    draw.box(x, y, w, 25, 46, 43, 50, 200)
    draw.text(x + w/2, y + 12.5, r, g, b, 255, "c", 0, title)
    draw.box(x, y + 30, w, h, 46, 43, 50, 200)

    if header == true then
        draw.gradient(x + 2, y + 2, w/2, 1, 59, 175, 222, 255, 202, 70, 205, 255, true)
        draw.gradient(x + (w/2) - 1, y + 2, (w/2) - 2, 1, 202, 70, 205, 255, 201, 227, 58, 255, true)
    end
end

function draw_gscontainer(ctx, x, y, w, h, title, header) --gamesense container
    local c = {10, 60, 40, 40, 40, 60, 20}
    local r, g, b, a = ui.get(gui.col_spec_gs)
    for i = 0,6,1 do
        client.draw_rectangle(ctx, x+i, y+i, w-(i*2), 29-(i*2), c[i+1], c[i+1], c[i+1], a)
        draw.text(x + w/2, y + 14, r, g, b, 255, "c", 0, title)
        client.draw_rectangle(ctx, x+i, y+i+31, w-(i*2), h-(i*2), c[i+1], c[i+1], c[i+1], a)
    end

    if header == true then
        renderer.gradient(x + 7, y + 7, w/2, 1, 59, 175, 222, 255, 202, 70, 205, 255, true)
        renderer.gradient(x + w/2, y + 7, w/2 - 7, 1, 202, 70, 205, 255, 201, 227, 58, 255, true)
    end
end

client.set_event_callback("paint", function()
    if ui.get(gui.enable_spec) then

        if ui.get(gui.style_spec) == "Default" then
            visible(gui.col_spec, true)
        else
            visible(gui.col_spec, false)
        end

        if ui.get(gui.style_spec) == "Gamesense" then
            visible(gui.col_spec_gs, true)
        else
            visible(gui.col_spec_gs, false)
        end

        if ui.get(gui.style_spec) == "Special" then
            visible(gui.col_spec_sp, true)
        else
            visible(gui.col_spec_sp, false)
        end

        visible(gui.style_spec, true)
        visible(gui.x_spec, true)
        visible(gui.y_spec, true)
        visible(gui.w_spec, true)
        visible(gui.header, true)
    else
        visible(gui.col_spec, false)
        visible(gui.col_spec_gs, false)
        visible(gui.col_spec_sp, false)
        visible(gui.style_spec, false)
        visible(gui.x_spec, false)
        visible(gui.y_spec, false)
        visible(gui.w_spec, false)
        visible(gui.header, false)
    end
end)

client.set_event_callback("paint", function(ctx, entity_index)
    if not ui.get(gui.enable_spec) then return end
    local x, y, w = ui.get(gui.x_spec), ui.get(gui.y_spec), ui.get(gui.w_spec)
    local header_c = ui.get(gui.header)
    local spectators = {}
    local my_spectators = {}

    for player=1, globals.maxplayers() do
        if entity.get_classname(player) == "CCSPlayer" then
            local observer_target = entity.get_prop(player, "m_hObserverTarget")
            if observer_target ~= nil then
                if spectators[observer_target] == nil then
                    spectators[observer_target] = {}
                end
            table.insert(spectators[observer_target], player)
            end
        end
    end

    if spectators[lp] ~= nil then
        for i=1, #spectators[lp] do
            table.insert(my_spectators, entity.get_player_name(spectators[lp][i]))
        end
    end

    if ui.get(gui.style_spec) == "Default" then
        local r, g, b, a = ui.get(gui.col_spec)
        if ui.is_menu_open() then
            draw_dcontainer(x, y, w, 15, "Spectators", header_c)
            draw.line(x, y + 28, x + w - 1, y + 28, r, g, b, a)
            draw.text(x + 5, y + 30, 255, 255, 255, 255, "", 0, "Someone")
        end
        if spectators[lp] ~= nil then
            for i=1, #my_spectators do
                h2o = i * 15
            end
            if not ui.is_menu_open() then
                draw_dcontainer(x, y, w, h2o, "Spectators", header_c)

                for i=1, #my_spectators do
                    draw.line(x, y + 14 + (i * 15), x + w - 1, y + 14 + (i * 15), r, g, b, a)
                end

                for i=1, #my_spectators do
                    draw.text(x + 5, (y+15) + (i * 15), 255, 255, 255, 255, "", 0, my_spectators[i])
                end
            end
        end
    elseif ui.get(gui.style_spec) == "Gamesense" then
        local r, g, b, a = ui.get(gui.col_spec_gs)
        if ui.is_menu_open() then
            draw_gscontainer(ctx, x, y, w, 25, "Spectators", header_c)
            draw.text(x + 8, y + 37, 255, 255, 255, 255, "", 0, "Someone")
        end
        if spectators[lp] ~= nil then
            for i=1, #my_spectators do
                h2o = i * 15
            end
            if not ui.is_menu_open() then
                draw_gscontainer(ctx, x, y, w, h2o + 10, "Spectators", header_c)
                for i=1, #my_spectators do
                    draw.text(x + 8, (y+22) + (i * 15), 255, 255, 255, 255, "", 0, my_spectators[i])
                end
            end
        end
    end
end)

client.set_event_callback("round_start", function()
    client.exec("cl_fullupdate")
end)
