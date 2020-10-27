--> init gs libraries
local vector, chat, ffi, images, js = require "vector", require "print_chat", require "ffi", require "gamesense/images", panorama.open()

--> local variables
local steamid64 = js.MyPersonaAPI.GetXuid()
local current = {map=globals.mapname(), local_pos}
local shop_items = {
    {"Anti-aim correction", "res", "Will try to find head of the enemy.", 50, "cheat_feature", {"rage", "other", "anti-aim correction"}, "rpg/shop/res", database.read("rpg/shop/res")},
    {"Double tap", "dt", "Will shoot 2x when held and charged.", 500, "cheat_feature", {"rage", "other", "double tap"}, "rpg/shop/dt", database.read("rpg/shop/dt")},
    {"On-shot AA", "os", "Helps you to not get onshotted.", 150, "cheat_feature", {"aa", "other", "on shot anti-aim"}, "rpg/shop/os", database.read("rpg/shop/os")}
}
local npcs = {}
local data = {
    username = database.read("rpg/nickname"),
    avatar = database.read("rpg/avatar") or images.get_steam_avatar(steamid64, 65) or nil,
    lvl = database.read("rpg/level") or 1,
    xp = {
        database.read("rpg/xp/current") or 0,
        database.read("rpg/xp/needed") or 100,
        database.read("rpg/xp/reached") or 0,
        database.read("rpg/xp/prev_reached") or 0,
        globals.curtime(),
        0,
        globals.tickcount()
    },
    balance = database.read("rpg/balance") or 0,
    b_add = { globals.curtime(), 0, globals.tickcount() },
    npc_quests = {
        database.read("rpg/npc_quests/current") or {}
    }
}
local w, h = client.screen_size()
local cross = {x=w/2, y=h/2}
local auto_save = globals.tickcount()+12000
local hud_type, hud_fade, hud_m_fade = database.read("rpg/hud_type") or "default", globals.tickcount(), globals.tickcount()

--> setup
if data.username == nil then
    chat.print_("Please select your username \x10[.nick]")
end
--[[if data.avatar == nil then
    chat.print_("Please select your avatar \x10[.avatar (url/steam)]")
end]]

--> local functions
local function draw_circle_3d(x, y, z, radius, degrees, start_at, r, g, b, a, filled, fill_r, fill_g, fill_b, fill_a)
    local old = { x, y }
    local center = {}; center.x, center.y = renderer.world_to_screen(x, y, z)
	for rot=start_at, degrees+start_at, math.min(25, radius/5) do
		local rot_t = math.rad(rot)
		local point = vector(radius * math.cos(rot_t) + x, radius * math.sin(rot_t) + y, z)
        local current = {}; current.x, current.y = renderer.world_to_screen(point.x, point.y, point.z)
        if current.x ~= nil and old.x ~= nil then
            if filled then renderer.triangle(center.x, center.y, old.x, old.y, current.x, current.y, fill_r, fill_g, fill_b, fill_a) end
            renderer.line(current.x, current.y, old.x, old.y, r, g, b, a)
        end
		old.x, old.y = current.x, current.y
    end
end

local function render_dialogue(func_table)
    renderer.gradient(w/2-185, h/2-20, 35, 80, 10, 10, 10, 0, 10, 10, 10, 60, true)
    renderer.rectangle(w/2-150, h/2-20, 300, 80, 10, 10, 10, 60)
    renderer.gradient(w/2+150, h/2-20, 35, 80, 10, 10, 10, 60, 10, 10, 10, 0, true)
    renderer.text(w/2, h/2-5, 0, 150, 255, 255, "bc", 0, "-" .. func_table[1] .. "-")
    renderer.text(w/2, h/2+10, 255, 255, 255, 255, "c", 0, "Hey there, " .. data.username .. ". Can you help me?")
    if func_table[2] == "treasure" then
        renderer.text(w/2, h/2+25, 255, 255, 255, 255, "c", 0, "I've found this treasure map, but i can't locate the treasure.")
        renderer.text(w/2, h/2+40, 255, 255, 255, 255, "c", 0, "If you find it, ill give you $" .. func_table[3][1] .. ". What do you say?")
    elseif func_table[2] == "hunt_quest" then
        renderer.text(w/2, h/2+25, 255, 255, 255, 255, "c", 0, "There's this high k/d player that you need to kill")
        renderer.text(w/2, h/2+40, 255, 255, 255, 255, "c", 0, "If you kill him, ill give you $" .. func_table[3][1] .. ". What do you say?")
    end
end

local function get_dormant_players(enemy_only, alive_only)
	local enemy_only = enemy_only ~= nil and enemy_only or false
	local alive_only = alive_only ~= nil and alive_only or true
	local result = {}

	local player_resource = entity.get_all("CCSPlayerResource")[1]

	for player=1, globals.maxplayers() do
		if entity.get_prop(player_resource, "m_bConnected", player) == 1 then
			local local_player_team
			if enemy_only then
				local_player_team = entity.get_prop(entity.get_local_player(), "m_iTeamNum")
			end

			local is_enemy = true
			if enemy_only and entity.get_prop(player, "m_iTeamNum") == local_player_team then
				is_enemy = false
			end

			if is_enemy then
				local is_alive = true
				if alive_only and entity.get_prop(player_resource, "m_bAlive", player) ~= 1 then
					is_alive = false
				end

				if is_alive then
					table.insert(result, player)
				end
			end
		end
	end

	return result
end

local function add_npc(x, y, z, height, func_table) --[[func_table: {name, objective, {money, xp}_reward}]]
    if type(func_table) ~= "table" then return error("Eh.. no, arg[5] must be a table") end
    table.insert(npcs, {x, y, z, height, func_table, false, 0, false, false})
end

local function save(auto)
    database.write("rpg/level", data.lvl)
    database.write("rpg/xp/current", data.xp[1])
    database.write("rpg/xp/needed", data.xp[2])
    database.write("rpg/xp/reached", data.xp[3])
    database.write("rpg/xp/prev_reached", data.xp[4])
    database.write("rpg/balance", data.balance)
    database.write("rpg/has_save", true)

    chat.print_(auto and "Automatically saved progress." or "Successfully saved progress.")
end

local function load()
    if database.read("rpg/has_save") == nil or database.read("rpg/has_save") == false or database.read("rpg/level") == nil then
        chat.print_(" \x02Couldn't find any save, sorry!")
        return
    end
    data.lvl = database.read("rpg/level")
    data.xp[1] = database.read("rpg/xp/current")
    data.xp[2] = database.read("rpg/xp/needed")
    data.xp[3] = database.read("rpg/xp/reached")
    data.xp[4] = database.read("rpg/xp/prev_reached")
    data.balance = database.read("rpg/balance")

    chat.print_("Loaded latest save.")
end

local function reset(save)
    if save then
        if database.read("rpg/has_save") then
            database.write("rpg/level", nil)
            database.write("rpg/xp/current", nil)
            database.write("rpg/xp/needed", nil)
            database.write("rpg/xp/reached", nil)
            database.write("rpg/xp/prev_reached", nil)
            database.write("rpg/balance", nil)
            database.write("rpg/has_save", false)
            chat.print_("Successfully reset your save")
        else
            chat.print_(" \x02Couldn't find any save to reset.")
        end
    else
        data.lvl = 1; data.xp[1] = 0; data.xp[2] = 100; data.xp[3] = 0; data.xp[4] = 0; data.balance = 0
        chat.print_("Successfully reset your progress.")
    end
end

--> callbacks & system
local function handle_login(e)
    local cap = ""
    if e.text:sub(0, 5) == ".nick" and client.userid_to_entindex(e.userid) == entity.get_local_player() then
        data.username = e.text:sub(7, 25)
        database.write("rpg/nickname", e.text:sub(7, 25))
        if e.text:sub(7, -1):len() > 20 then cap = " (capped, limit is 20)" end
        chat.print_("Changed nickname to \x02" .. data.username .. "\x01." .. cap)
    --elseif e.text:sub(0, 7) == ".avatar" then
        --if e.text:sub(9, 14) == "steam" then
            --steamid64 = js.MyPersonaAPI.GetXuid()
            --data.avatar = images.get_steam_avatar(steamid64)
        --end
    end
end

local function commands(e)
    local msg = e.text
    if client.userid_to_entindex(e.userid) ~= entity.get_local_player() then return end
    if msg:sub(0, 1) == "." then
        if msg:sub(2, 5):lower() == "help" then
            chat.print_("Hey, \x02" .. data.username .. "\x01. Here's a list of all the current commands.")
            chat.print_(" \x10.nick [nickname] \x01- change your nickname.")
            --chat.print_(" \x10.avatar [url/steam] \x01- change your avatar.")
            chat.print_(" \x10.stats \x01- display your current statistics. (level, xp, balance)")
            chat.print_(" \x10.buy [item] \x01- show shop/buy an item.")
            chat.print_(" \x10.save \x01- save your current progress.")
            chat.print_(" \x10.load \x01- load the latest save available.")
            chat.print_(" \x10.reset [1] \x01- reset your progress [save].")
            chat.print_(" \x10.quests \x01- show all your current quests.")
            chat.print_(" \x10.hud [type] \x01- change HUD type.")
        elseif msg:sub(2, 6):lower() == "stats" then
            chat.print_("[\x10RPG\x01] Level: " .. data.lvl .. " (\x0B" .. data.xp[1] .. "xp\x01), balance: \x04$" .. data.balance)
        elseif msg:sub(2, 4):lower() == "buy" then
            if msg:len() > 5 then
                for i=1, #shop_items do
                    item = shop_items[i]
                    if msg:sub(6, 11) == "refund" then
                        if item[2] == msg:sub(13, -1):lower() then
                            if not item[8] then
                                chat.print_(" \x02This item has not been purchased.")
                            else
                                data.balance = data.balance + item[4]
                                chat.print_(" \x0BItem successfully refunded.")
                                database.write(item[7], false)
                                item[8] = false
                                data.b_add[1] = globals.curtime()+5
                            end
                        end
                    else
                        if item[2] == msg:sub(6, -1):lower() then
                            if item[8] then
                                chat.print_(" \x02This item has already been purchased.")
                            else
                                if item[4] <= data.balance then
                                    data.balance = data.balance - item[4]
                                    chat.print_(" \x0BItem successfully purchased.")
                                    database.write(item[7], true)
                                    item[8] = true
                                    data.b_add[1] = globals.curtime()+5
                                else
                                    chat.print_(" \x02You don't have enough money.")
                                end
                            end
                        end
                    end
                end                
            else
                chat.print_("Shop items;")
                for i=1, #shop_items do
                    item = shop_items[i]
                    local clr = item[8] and " \x0B" or " \x10"
                    chat.print_(clr .. item[1] .. " \x01[" .. item[2] .. "] - " .. item[3] .. " \x10$" .. item[4])
                end
            end
        elseif msg:sub(2, 5):lower() == "save" then
            save(false)
        elseif msg:sub(2, 5):lower() == "load" then
            load()
            data.xp[5] = globals.curtime()
            data.b_add[1] = globals.curtime()
        elseif msg:sub(2, 6) == "reset" then
            reset(msg:sub(8, 8) == "1")
            data.xp[5] = globals.curtime()
            data.b_add[1] = globals.curtime()
        elseif msg:sub(2, 7):lower() == "quests" then
            if msg:len() > 8 then
                --
            else
                if data.npc_quests[1][1] ~= nil then
                    for i=1, #data.npc_quests[1] do
                        quest = data.npc_quests[1][i]
                        local quest_name = quest[1] == "treasure" and "Finding treasure" or quest[1] == "hunt_quest" and "Hunting high k/d target" or ""
                        local clr = i == #data.npc_quests[1] and " \x0A" or " \x01"
                        chat.print_(clr .. quest_name .. "\x01 - \x10$" .. quest[2][1] .. "\x01 and \x0B" .. quest[2][2] .. "xp\x01")
                    end
                else
                    chat.print_("No quests available")
                end
            end
        elseif msg:sub(2, 4):lower() == "hud" then
            if msg:len() > 5 then
                if msg:sub(6, 9):lower() == "csgo" then
                    if hud_type ~= "csgo" then
                        hud_fade = globals.tickcount()
                        chat.print_("Changed HUD to \x10CSGO")
                    else
                        chat.print_("The HUD is already set to \x10CSGO")
                    end
                    hud_type = "csgo"
                    database.write("rpg/hud_type", "csgo")
                elseif msg:sub(6, 13):lower() == "default" then
                    if hud_type ~= "default" then
                        hud_fade = globals.tickcount()
                        chat.print_("Changed HUD to \x10Default")
                    else
                        chat.print_("The HUD is already set to \x10Default")
                    end
                    hud_type = "default"
                    database.write("rpg/hud_type", "default")
                end
            else
                chat.print_("All HUD types; \x10Default\x01, \x10CSGO")
            end
        end
    end
end

local username_delay = globals.tickcount()+300
local function game_sys()
    if data.xp[1] >= data.xp[2] then
        data.xp[4] = data.xp[3]; data.xp[3] = data.xp[2]; data.lvl = data.lvl+1
        data.xp[2] = data.lvl <= 10 and data.xp[2]*3 or data.xp[2]*4
        chat.print_("[\x10RPG\x01] Reached a new level! \x10" .. data.lvl .. " \x01, required xp for next level: \x0B" .. data.xp[2])
        save(true)
    end
    if data.username == nil and globals.tickcount() > username_delay then
        chat.print_("Please select your username \x10[.nick]")
        
        username_delay = globals.tickcount()+300
    end
    if data.avatar == nil and globals.tickcount() > username_delay then
        chat.print_("Please select your avatar \x10[.avatar (url/steam)]")
        
        username_delay = globals.tickcount()+300
    end
    if globals.tickcount() > auto_save then
        save(true)
        auto_save = globals.tickcount()+12000
    end
    if data.xp[5]+0.1 < globals.curtime() then data.xp[6] = data.xp[1] end
    if data.b_add[1]+0.1 < globals.curtime() then data.b_add[2] = data.balance end
    if globals.curtime() < data.xp[5]-0.2 then data.xp[7] = globals.tickcount() end
    if globals.curtime() < data.b_add[1]-0.2 then data.b_add[3] = globals.tickcount() end

    for i=1, #shop_items do
        item = shop_items[i]
        if not item[8] then
            if type(item[6][1]) == "table" then
                ui.set(ui.reference(item[6][1][1], item[6][1][2], item[6][1][3]), false)
            else
                ui.set(ui.reference(item[6][1], item[6][2], item[6][3]), false)
            end
        end
        if item[5] == "cheat_feature" then
            if type(item[6][1]) == "table" then
                for i=1, #item[6] do
                    ui.set_visible(ui.reference(item[6][i][1], item[6][i][2], item[6][i][3]), item[8])
                end
            else
                ui.set_visible(ui.reference(item[6][1], item[6][2], item[6][3]), item[8])
            end
        end
    end
end

local held = {false, false, false}
local function input_sys()
    if client.key_state(0x45) then
        if not held[1] then
            for i=1, #npcs do
                npc = npcs[i]
                if npc[8] then
                    npc[6] = not npc[6]
                end
            end
        end
        held[1] = true
    else held[1] = false end
    if client.key_state(0x59) then
        if not held[2] then
            for i=1, #npcs do
                npc = npcs[i]
                if npc[6] and not npc[9] then
                    npc[9] = true
                    chat.print_("[\x0B" .. npc[5][1] .. "\x01] Thank you! Good luck.")
                    table.insert(data.npc_quests[1], {npc[5][2], npc[5][3]})
                end
            end
        end
        held[2] = true
    else held[2] = false end
    if client.key_state(0x4E) then
        if not held[3] then
            for i=1, #npcs do
                npc = npcs[i]
                if npc[6] and not npc[9] then
                    npc[6] = false
                    chat.print_("[\x0B" .. npc[5][1] .. "\x01] Well okay, come back later then!")
                end
            end
        end
        held[3] = true
    else held[3] = false end
end

local function on_say(e) commands(e);handle_login(e) end
local function on_setup_cmd(e) game_sys();input_sys() end
client.set_event_callback("paint", function()
    local get_local = entity.get_local_player()
    if get_local == nil then return end
    current.local_pos = vector(entity.get_origin(get_local))
    local balance_len = {renderer.measure_text("+", "$" .. data.balance)}
    local current_quest = data.npc_quests[1][#data.npc_quests[1]] ~= nil and data.npc_quests[1][#data.npc_quests[1]] or 0
    local all_enemies = get_dormant_players(true, false)
    if data.avatar == nil then data.avatar = images.get_steam_avatar(steamid64, 65) end
    local fade_hud = math.min(18, globals.tickcount()-hud_fade)/18
    local xp__ = data.xp[1]-data.xp[6]
    local balance__ = data.balance-data.b_add[2]
    if data.balance <= 0 then data.balance = 0 end
    if entity.is_alive(entity.get_local_player()) == false then
        fade_hud = 1;
    end
    
--[[> dbg
    renderer.text(5, 500, 255, 255, 255, 255, "", 0, math.floor(current.local_pos.x), " ", math.floor(current.local_pos.y), " ", math.floor(current.local_pos.z))
    renderer.text(5, 515, 255, 255, 255, 255, "", 0, #data.npc_quests)
--]]

--> hud elements
    --> user information
    if hud_type == "default" then
        renderer.gradient(w/2-155, h-150, 35, 50, 10, 10, 10, 0, 10, 10, 10, 60*fade_hud, true)
        renderer.rectangle(w/2-120, h-150, 270, 50, 10, 10, 10, 60*fade_hud)
        renderer.gradient(w/2+150, h-150, 35, 50, 10, 10, 10, 60*fade_hud, 10, 10, 10, 0, true)
        data.avatar:draw(w/2-120, h-143, 35, 35, 255, 255, 255, 255*fade_hud, false)
        renderer.text(w/2-80, h-142, 255, 255, 255, 255*fade_hud, "", 0, data.username .. " • level " .. data.lvl .. " (+" .. data.xp[2] - data.xp[1] .. " xp)")
        renderer.rectangle(w/2-80, h-125, 230, 15, 60, 60, 60, 120*fade_hud)
        renderer.rectangle(w/2-79, h-124, 228*math.min(1, data.xp[1]/data.xp[2]), 13, 220, 220, 220, 255*fade_hud)
        if globals.curtime() < data.xp[5] then
            local xp_alpha = math.min(18, data.xp[7]-globals.tickcount())/18
            if entity.is_alive(entity.get_local_player()) == false then
                xp_alpha = 1;
            end
            if xp__ > 0 then
                renderer.text(w/2, h-170, 255, 210, 0, 255*xp_alpha, "c+", 0, "+" .. xp__ .. "xp")
            else
                renderer.text(w/2, h-170, 255, 0, 0, 255*xp_alpha, "c+", 0, xp__ .. "xp")
            end
        end
    elseif hud_type == "csgo" then
        renderer.gradient(w/2-285, h-45, 35, 45, 10, 10, 10, 0, 10, 10, 10, 60*fade_hud, true)
        renderer.rectangle(w/2-250, h-45, 500, 45, 10, 10, 10, 60*fade_hud)
        renderer.gradient(w/2+250, h-45, 35, 45, 10, 10, 10, 60*fade_hud, 10, 10, 10, 0, true)
        renderer.text(w/2-230, h-38, 220, 220, 220, 255*fade_hud, "+", 0, "LEVEL " .. data.lvl)
        renderer.rectangle(w/2-145, h-25, 370, 10, 90, 90, 90, 180*fade_hud)
        renderer.rectangle(w/2-144, h-24, 368*math.min(1, data.xp[1]/data.xp[2]), 8, 220, 220, 220, 255*fade_hud)
        if globals.curtime() < data.xp[5] then
            local xp_alpha = math.min(18, data.xp[7]-globals.tickcount())/18
            if entity.is_alive(entity.get_local_player()) == false then
                xp_alpha = 1;
            end
            if xp__ > 0 then
                renderer.text(w/2, h-70, 255, 210, 0, 255*xp_alpha, "c+", 0, "+" .. xp__ .. "xp")
            elseif xp__ < 0 then
                renderer.text(w/2, h-70, 255, 0, 0, 255*xp_alpha, "c+", 0, xp__ .. "xp")
            end
        end
    end
    --> render balance
    renderer.gradient(12, h/2, 10, balance_len[2]+15, 10, 10, 10, 0, 10, 10, 10, 60*math.min(18, globals.tickcount()-hud_m_fade)/18, true)
    renderer.rectangle(22, h/2, balance_len[1]+5, balance_len[2]+15, 10, 10, 10, 60*math.min(18, globals.tickcount()-hud_m_fade)/18)
    renderer.gradient(balance_len[1]+27, h/2, 35, balance_len[2]+15, 10, 10, 10, 60*math.min(18, globals.tickcount()-hud_m_fade)/18, 10, 10, 10, 0, true)
    renderer.text(25, h/2+6, 220, 220, 220, 255*math.min(18, globals.tickcount()-hud_m_fade)/18, "+", 0, "$" .. data.balance)
    if globals.curtime() < data.b_add[1] then
        local bal_alpha = math.min(18, data.b_add[3]-globals.tickcount())/18
        if entity.is_alive(entity.get_local_player()) == false then
            bal_alpha = 1;
        end
        if balance__ > 0 then
            renderer.text(25, 402, 172, 220, 13, 255*bal_alpha, "+", 0, "+ $" .. balance__)
        elseif balance__ < 0 then
            renderer.text(25, 402, 255, 0, 0, 255*bal_alpha, "+", 0, "- $" .. -balance__)
        end
    end
--

--> map objects
    --> quests
    if type(current_quest) == "table" or current_quest > 0 then
        if current_quest[1] == "hunt_quest" then
            for i=1, #all_enemies do
                enemy = all_enemies[i]
                local resource = entity.get_all("CCSPlayerResource")[1]
                local kills, deaths = entity.get_prop(resource, "m_iKills", enemy), entity.get_prop(resource, "m_iDeaths", enemy)
                local kdr = deaths == 0 and kills or kills/deaths
                if kdr >= 4.00 then
                    local esp = {entity.get_bounding_box(enemy)}
                    if esp[5] ~= 0 then
                        if not ui.get(ui.reference("visuals", "player esp", "name")) then
                            esp[2] = esp[2]+8
                        end
                        local mid = {x=(esp[1]-esp[3])/2, y=(esp[2]-esp[4])/2}
                        renderer.triangle(esp[1]-mid.x, esp[2]-12, esp[1]-mid.x+5, esp[2]-18, esp[1]-mid.x-5, esp[2]-18, 255, 220, 0, 180*esp[5])
                        renderer.triangle(esp[1]-mid.x, esp[2]-24, esp[1]-mid.x+5, esp[2]-18, esp[1]-mid.x-5, esp[2]-18, 255, 220, 0, 180*esp[5])
                    end
                end
            end
            for i=1, #entity.get_players(true) do
                enemy = entity.get_players(true)[i]
                local pos = vector(entity.get_origin(enemy))
                local lpos = vector(entity.get_origin(entity.get_local_player()))
                lpos.z = 0; pos.z = 0
                local view_x, view_y = client.camera_angles()
                local w2s = renderer.world_to_screen(pos.x, pos.y, pos.z)
                local resource = entity.get_all("CCSPlayerResource")[1]
                local kills, deaths = entity.get_prop(resource, "m_iKills", enemy), entity.get_prop(resource, "m_iDeaths", enemy)
                local kdr = deaths == 0 and kills or kills/deaths
                if not w2s and kdr >= 4.00 then
                    local angle_x, angle_y = lpos:to(pos):angles()
                    angle_y = 270-angle_y+view_y
                    local point = {x=w/2+1200*math.cos(math.rad(angle_y)), y=h/2+1200*math.sin(math.rad(angle_y))}
                    point.x = point.x < 50 and 50 or point.x > w-70 and w-70 or point.x
                    point.y = point.y < 70 and 70 or point.y > h-50 and h-50 or point.y
                    renderer.text(5, 515+15*i, 255, 255, 255, 255, "", 0, point.x, " ", point.y)
                    renderer.triangle(point.x+9, point.y, point.x, point.y-12, point.x+18, point.y-12, 255, 220, 0, 180)
                    renderer.triangle(point.x+9, point.y-25, point.x, point.y-12, point.x+18, point.y-12, 255, 220, 0, 180)
                end
            end
        end
    end
    --> NPC renderer
    if entity.is_alive(get_local) == false then return end
    for i=1, #npcs do
        npc = npcs[i]
        local x, y, z, height = npc[1], npc[2], npc[3], npc[4]
        npc[7] = current.local_pos:dist({x=x, y=y, z=z})
        local alpha = math.max(0, (math.min(200, npc[7])/200)*255)
        if npc[7] <= 200 then
            local wts = {
                --left_leg
                {renderer.world_to_screen(x-15, y, z)},
                {renderer.world_to_screen(x-10, y, z+15)},
                {renderer.world_to_screen(x-15, y+5, z+height/2)},
                --right_leg
                {renderer.world_to_screen(x-5, y+15, z)},
                {renderer.world_to_screen(x-5, y+15, z+15)},
                --body
                {renderer.world_to_screen(x-15, y+5, z+height/1.2)},
                --left_hand
                {renderer.world_to_screen(x-15, y-5, z+height/1.2)},
                {renderer.world_to_screen(x-8, y-5, z+height/1.4)},
                {renderer.world_to_screen(x+3, y-3, z+height/1.5)},
                --right_hand
                {renderer.world_to_screen(x-15, y+15, z+height/1.2)},
                {renderer.world_to_screen(x-8, y+10, z+height/1.4)},
                {renderer.world_to_screen(x+3, y+3, z+height/1.5)},
                --head
                {renderer.world_to_screen(x-10, y+5, z+height)}
            }
            --left_leg
            renderer.line(wts[1][1], wts[1][2], wts[2][1], wts[2][2], 255, 255, 255, 255-alpha)
            renderer.line(wts[2][1], wts[2][2], wts[3][1], wts[3][2], 255, 255, 255, 255-alpha)
            --right_leg
            renderer.line(wts[4][1], wts[4][2], wts[5][1], wts[5][2], 255, 255, 255, 255-alpha)
            renderer.line(wts[5][1], wts[5][2], wts[3][1], wts[3][2], 255, 255, 255, 255-alpha)
            --body
            renderer.line(wts[3][1], wts[3][2], wts[6][1], wts[6][2], 255, 255, 255, 255-alpha)
            --left_hand
            renderer.line(wts[6][1], wts[6][2], wts[7][1], wts[7][2], 255, 255, 255, 255-alpha)
            renderer.line(wts[7][1], wts[7][2], wts[8][1], wts[8][2], 255, 255, 255, 255-alpha)
            renderer.line(wts[8][1], wts[8][2], wts[9][1], wts[9][2], 255, 255, 255, 255-alpha)
            --right_hand
            renderer.line(wts[6][1], wts[6][2], wts[10][1], wts[10][2], 255, 255, 255, 255-alpha)
            renderer.line(wts[10][1], wts[10][2], wts[11][1], wts[11][2], 255, 255, 255, 255-alpha)
            renderer.line(wts[11][1], wts[11][2], wts[12][1], wts[12][2], 255, 255, 255, 255-alpha)
            --head
            renderer.line(wts[6][1], wts[6][2], wts[13][1], wts[13][2], 255, 255, 255, 255-alpha)
            if wts[13][1] then
                renderer.triangle(wts[13][1], wts[13][2]-15, wts[13][1]+5, wts[13][2]-23, wts[13][1]-5, wts[13][2]-23, 0, 150, 255, 255-alpha)
                renderer.text(wts[13][1], wts[13][2]-35, 255, 255, 255, 255-alpha, "c", 0, npc[5][1])
            end

            if wts[7][1] and wts[10][1] and wts[13][2] and wts[1][2] then
                npc[8] = npc[7] <= 60 and cross.x >= wts[7][1] and cross.x <= wts[10][1] and cross.y >= wts[13][2] and cross.y <= wts[1][2]
                if not npc[9] then
                    if npc[8] and not npc[6] then
                        renderer.text(cross.x, cross.y+15, 255, 255, 255, 255, "bc", 0, "Press E to start a dialogue")
                    end
                    if npc[6] then
                        if npc[7] > 60 then 
                            npc[6] = false
                            chat.print_("[\x0B" .. npc[5][1] .. "\x01] What a fucking retard.. he just walked away!")
                        end
                        render_dialogue(npc[5])
                    end
                end
            else
                npc[6] = false
            end
        end
    end
end)

client.set_event_callback("player_say", on_say)
client.set_event_callback("setup_command", on_setup_cmd)
client.set_event_callback("player_death", function(e)
    local victim = client.userid_to_entindex(e.userid)
    local current_quest = data.npc_quests[1][#data.npc_quests[1]] ~= nil and data.npc_quests[1][#data.npc_quests[1]] or 0
    if entity.is_enemy(victim) and client.userid_to_entindex(e.attacker) == entity.get_local_player() then
        if type(current_quest) == "table" or current_quest > 0 then
            if current_quest[1] == "hunt_quest" then
                local resource = entity.get_all("CCSPlayerResource")[1]
                local kills, deaths = entity.get_prop(resource, "m_iKills", victim), entity.get_prop(resource, "m_iDeaths", victim)
                local kdr = deaths == 0 and kills or kills/deaths
                if kdr >= 5 then
                    data.balance = data.balance+data.npc_quests[1][#data.npc_quests[1]][2][1]
                    data.xp[1] = data.xp[1]+data.npc_quests[1][#data.npc_quests[1]][2][2]
                    table.remove(data.npc_quests[1], #data.npc_quests[1])
                    chat.print_("Quest completed! - \x10Hunting high k/d target")
                end
            end
        end
        data.xp[1] = data.xp[1]+50
        data.balance = data.balance+10
        data.xp[5] = globals.curtime()+10
        data.b_add[1] = globals.curtime()+5
    end
    if victim == entity.get_local_player() then
        data.xp[1] = data.xp[1]-25
        data.balance = data.balance-50
        data.xp[5] = globals.curtime()+10
        data.b_add[1] = globals.curtime()+5
    end
end)

--> initialize map objects
if current.map == "de_mirage" then
    add_npc(1075, -216, -168, 65, {"Hunter", "hunt_quest", {300, 500}})
end

--> welcome screen
if data.username == nil then return end
local wlcm_fadein, wlcm_fadeout = globals.tickcount(), {globals.curtime(), globals.tickcount()}
client.delay_call(4, function() wlcm_fadeout[2] = globals.tickcount()+12 end)
local function welcome_rndr()
    local username_len, wlcm_len = {renderer.measure_text("c", data.username)}, {renderer.measure_text("c", "Welcome, ")}
    local fade_ = math.min(12, globals.tickcount()-wlcm_fadein)/12
    if globals.curtime()-wlcm_fadeout[1] >= 4.1 then fade_ = math.max(0, wlcm_fadeout[2]-globals.tickcount())/12 end
    renderer.gradient(w/2-135, h/2-15, 35, 30, 10, 10, 10, 0, 10, 10, 10, 60*fade_, true)
    renderer.rectangle(w/2-100, h/2-15, 200, 30, 10, 10, 10, 60*fade_)
    renderer.gradient(w/2+100, h/2-15, 35, 30, 10, 10, 10, 60*fade_, 10, 10, 10, 0, true)

    renderer.text(w/2-username_len[1]/2, h/2, 255, 255, 255, 255*fade_, "c", 0, "Welcome, ")
    renderer.text(w/2+wlcm_len[1]/2, h/2, 255, 0, 0, 255*fade_, "c", 0, data.username)
end
client.set_event_callback("paint_ui", welcome_rndr)
client.delay_call(5, function() client.unset_event_callback("paint_ui", welcome_rndr) end)

--> quick fixes
client.set_event_callback("player_connect_full", function(e)
    if client.userid_to_entindex(e.userid) ~= entity.get_local_player() then return end
    wlcm_fadein = globals.tickcount()
    current.map = globals.mapname()
    data.xp[5] = globals.curtime()
    data.xp[7] = globals.tickcount()
    data.b_add[1] = globals.curtime()
    data.b_add[3] = globals.tickcount()
    hud_fade, hud_m_fade = globals.tickcount(), globals.tickcount()
    if #npcs == 0 or #npcs == nil then
        if current.map == "de_mirage" then
            add_npc(1075, -216, -168, 65, {"Hunter", "hunt_quest", {300, 500}})
        end
    end
end)
