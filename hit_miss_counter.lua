local shots = {
    hit = {},
    missed = { 0, 0, 0, 0, 0 },
    total = 0
}
local hitgroups = { "generic", "head", "chest", "stomach", "left arm", "right arm", "left leg", "right leg", "neck", "unknown", "gear" }

client.set_event_callback("aim_hit", function(shot)
    table.insert(shots.hit, {
        entity.get_player_name(shot.target),
        shot.hit_chance,
        shot.damage,
        hitgroups[shot.hitgroup + 1] or "unknown"
    })
end)
client.set_event_callback("aim_miss", function(shot)
    if shot.reason == "spread" then shots.missed[1] = shots.missed[1] + 1 end;if shot.reason == "prediction error" then shots.missed[2] = shots.missed[2] + 1 end;if shot.reason == "death" then shots.missed[3] = shots.missed[3] + 1 end;if shot.reason == "?" then shots.missed[4] = shots.missed[4] + 1 end
end)

client.set_event_callback("paint", function()
    shots.missed[5] = shots.missed[1] + shots.missed[2] + shots.missed[4]
    renderer.text(5, 500, 255, 255, 255, 255, "", 0, string.format("%d / %d (%s)", #shots.hit, shots.missed[5], #shots.hit+shots.missed[5] ~= 0 and string.format("%.1f%%", (#shots.hit/(#shots.hit+shots.missed[5]))*100) or "no data"))
end)

client.set_event_callback("console_input", function(inp)
    if inp:sub(1, 12) == "print_misses" then
        client.color_log(180, 180, 180, string.format("spread: %d\nprediction errors: %d\ndeath: %d\nunknown: %d", shots.missed[1], shots.missed[2], shots.missed[3], shots.missed[4]))
        return true
    end
    if inp:sub(1, 10) == "print_hits" then
        for i=1, #shots.hit do
            curr = shots.hit[i]
            client.color_log(180, 180, 180, string.format("[%d] %s's %s - hc:%d%%, dmg:%d", i, curr[1], curr[4], curr[2], curr[3]))
        end
        return true
    end
end)
client.set_event_callback("player_connect_full", function(e)
    if client.userid_to_entindex(e.userid) == entity.get_local_player() then
        shots.missed[1] = 0;shots.missed[2] = 0;shots.missed[3] = 0;shots.missed[4] = 0
        for k in pairs(shots.hit) do shots.hit[k] = nil end
    end
end)
