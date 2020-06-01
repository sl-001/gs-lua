local w, h = client.screen_size()
local aa_enabled = ui.reference( "aa", "anti-aimbot angles", "enabled" )
local byaw = ui.reference( "aa", "anti-aimbot angles", "body yaw" )

client.set_event_callback("paint", function( e )
    local body_yaw = math.max( -60, math.min(60, math.floor( ( entity.get_prop( entity.get_local_player( ), "m_flPoseParameter", 11 ) or 0 )*120-60+0.5 ) ) )
    local percentage = ( math.max( -60, math.min( 60, body_yaw*1.06 ) )+60 ) / 60

    if entity.is_alive( entity.get_local_player( ) ) ~= true then
        body_yaw = 0
    end
    if body_yaw ~= nil and body_yaw ~= 0 then
        if percentage > 1 then
            renderer.rectangle( w/2, h/2, 40*( percentage-1 ), 1, 255, 255, 255, 120 )
            renderer.text( w/2+( 40*( percentage-1 ) ), h/2, 255-( body_yaw*2.29824561404 ), body_yaw*3.42105263158, body_yaw*0.22807017543, 255, "c", 0, ">" )
        else
            renderer.rectangle( w/2+( 40*percentage )-40, h/2, 40-( 40*percentage ), 1, 255, 255, 255, 120)
            renderer.text( w/2+( 40*percentage )-40, h/2, 255-( -body_yaw*2.29824561404 ), -body_yaw*3.42105263158, -body_yaw*0.22807017543, 255, "c", 0, "<" )
        end
    end
end )
