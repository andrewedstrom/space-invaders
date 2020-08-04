pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

local game_objects
local hive_mind
local invader_speed
local move_timer
local move_sounds = {0,1,2,3}
local curr_sound
local swarm_direction -- 1: right, -1: left
local number_of_invaders
local lives_remaining
local player_is_dying


function _init()
    move_timer=0
    time_to_move=false 
    curr_sound=1
    swarm_direction=1
    lives_remaining=2
    player_is_dying = false

    game_objects={}
    make_player() 

    number_of_invaders = make_invaders()
    invader_speed=number_of_invaders
end

function _update()
    local moved_this_frame = move_swarm()

    for obj in all(game_objects) do
        obj:update()
        if obj:is_expired() then
            del(game_objects, obj)
        end
    end

    if moved_this_frame then
        postprocess_move()
    end
end

function move_swarm()
    move_timer+=1
    if move_timer > invader_speed then
        move_timer = 0
        time_to_move = true

        if number_of_invaders >= 1 then
            sfx(move_sounds[curr_sound])
            curr_sound += 1
            if curr_sound > #move_sounds then
                curr_sound = 1
            end
            return true
        end
    end
    return false
end

function postprocess_move()
    time_to_move = false

    should_switch_dir = false
    foreach_game_object_of_kind("invader", function(invader)
        if invader.status == "alive" and (invader.x >= 113 or invader.x <= 5) then
            should_switch_dir = true
        end
    end)

    if should_switch_dir then
        swarm_direction *= -1

        -- move all invaders down, ominously
        foreach_game_object_of_kind("invader", function(invader)
            invader.y += 5
        end)
    end
end

function _draw()
    cls()
    for obj in all(game_objects) do
        obj:draw()
    end

    line(0,118,128,118,11)
    print(life_icons(), 4, 120, 11)
end

function life_icons()
    local icons=""
    local i
    for i = 1,lives_remaining do
        icons=icons.."\x92"
    end
    return icons
end

function make_player()
    return make_game_object("player",64,108,13,8,{
        death_counter = 0,
        draw=function(self)
            if not player_is_dying then
                sspr(8,0,self.width,self.height,self.x,self.y)
            else
                local sprite_x = 8
                if self.death_counter % 2 == 0 then
                    sprite_x = 40
                end
                sspr(sprite_x,8,self.width,self.height,self.x,self.y)
            end
        end,
        update=function(self)
            if not player_is_dying then
                self:handle_input()
                self:check_if_shot()
            else
                self.death_counter+=1
                if self.death_counter > 20 then
                    player_is_dying = false
                    lives_remaining-=1
                    self.death_counter=0
                end
            end
        end,
        shoot=function(self)
            make_player_bullet(self.x+self.width/2,self.y)
        end,
        check_if_shot=function(self)
            foreach_game_object_of_kind("alien_bullet", function(bullet)
                if rects_overlapping(self.x,self.y,self.x+self.width,self.y+self.height,bullet.x,bullet.y,bullet.x+bullet.width,bullet.y+bullet.height) then
                    player_is_dying = true
                    sfx(4)
                    del(game_objects, bullet)
                end
            end)
        end,
        handle_input=function(self)
            if btn(0) then
                self.x-=2
            elseif btn(1) then
                self.x+=2
            end
            if btnp(4) or btnp(5) then
                self:shoot()
            end
        end
    })
end

function make_player_bullet(x, y)
    return make_game_object("player_bullet",x,y,1,2,{
        draw=function(self)
            line(self.x,self.y,self.x,self.y+self.height,9)
        end,
        update=function(self)
            self.y-=3
        end,
        is_expired=function(self)
            return self.y < 0
        end
    })
end

function make_alien_bullet(x, y)
    return make_game_object("alien_bullet",x,y,2,4,{
        draw=function(self)
            sspr(98,0,self.width,self.height,self.x,self.y)
        end,
        update=function(self)
            self.y+=1.5
        end,
        is_expired=function(self)
            return self.y > 128
        end
    })
end


function make_invaders()
    local row
    local cnt = 0
    for row = 20, 50, 10 do
        for col = 5, 95, 15 do
            make_invader(col,row)
            cnt += 1
        end
    end
    return cnt
end

function make_invader(x,y)
    return make_game_object("invader",x,y,11,8, {
        status="alive", -- alive, dead, or dying
        death_counter = 0,
        draw=function(self)
            if self.status == "alive" then
                local sprite_x = 24
                if curr_sound % 2 == 0 then
                    sprite_x = 36
                end
                sspr(sprite_x,0,self.width,self.height,self.x,self.y)
            elseif self.status == "dying" then
                sspr(24,9,13,self.height,self.x-1,self.y)
            end
        end,
        update=function(self)
            -- todo who should own this? bullet, invader, or someone else?
            foreach_game_object_of_kind("player_bullet", function(bullet)
                if rects_overlapping(self.x,self.y,self.x+self.width,self.y+self.height,bullet.x,bullet.y,bullet.x+bullet.width,bullet.y+bullet.height) and self.status == "alive" then
                    self.status = "dying"
                    invader_speed = max(invader_speed-1,0)
                    number_of_invaders -= 1
                    del(game_objects, bullet)
                end
            end)

            if self.status == "alive" then
                if time_to_move then
                    self:move()
                end
                if not player_is_dying and rnd(600) > 599 then
                    make_alien_bullet(self.x+self.width/2,self.y)
                end
            else
                self.death_counter+=1
                if self.death_counter > 10 then
                    self.status = "dead"
                end
            end
        end,
        is_expired=function(self)
            return self.status == "dead"
        end,
        move=function(self)
            local new_x = self.x + swarm_direction*2
            self.x = mid(5,new_x,113)
        end
    })
end

-- shared game_object things
function make_game_object(kind,x,y,width,height,props)
    local obj = {
        kind=kind,
        x=x,
        y=y,
        width=width,
        height=height,
        draw=function(self)
        end,
        update=function(self)
        end,
        is_expired=function(self)
            return false
        end,
        draw_bounding_box=function(self,col)
            rect(self.x,self.y,self.x+self.width,self.y+self.height,col)
        end
    }

    -- add aditional object properties
    for k,v in pairs(props) do
        obj[k] = v
    end

    -- add new object to list of game objects
    add(game_objects, obj)
end

function lines_overlapping(l1,r1,l2,r2)
    return r1>l2 and r2>l1
end

function rects_overlapping(left1,top1,right1,bottom1,left2,top2,right2,bottom2)
    return lines_overlapping(left1,right1,left2,right2) and lines_overlapping(top1,bottom1,top2,bottom2)
end

function foreach_game_object_of_kind(kind, callback)
    local obj
    for obj in all(game_objects) do
        if obj.kind == kind then
            callback(obj)
        end
    end
end

__gfx__
00000000000000b00000000000700000700000700000700000077000000000777700000000077000000007777000000000700000000000000000000000000000
0000000000000bbb0000000000070007000070070007007000777700000777777777700000777700007777777777000000070000000000000000000000000000
0070070000000bbb0000000000777777700070777777707007777770007777777777770007777770077777777777700000700000000000000000000000000000
000770000bbbbbbbbbbb000007707770770077707770777077077077007770077007770077077077077700770077700000070000000000000000000000000000
00077000bbbbbbbbbbbbb00077777777777007777777770077777777007777777777770077777777077777777777700000700000000000000000000000000000
00700700bbbbbbbbbbbbb00070777777707000777777700007077070007777777777770000700700077777777777700000000000000000000000000000000000
00000000bbbbbbbbbbbbb00070700000707000700000700070000007000007700770000007077070000077007700000000000000000000000000000000000000
00000000bbbbbbbbbbbbb00000077077000007000000070007000070000077077077000070700707000770770770000000000000000000000000000000000000
000000000000b000000b000000000000000000000000b0000b000000007700000000770000000000000000000000000000000000000000000000000000000000
0000000000b000b0b00000000000700070000000000000b00000b000000000000000000000000000000000000000000000000000000000000000000000000000
000000000b0000b0000b00000700070700070000000000b0b0b00000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000b0000000b00000700000007000000000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000b0000000000070000070000000000000b0b000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000b0bb0b00b0b000007700000000077000b0bb0b00b0b00000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000b000000000000070000070000000000bbb0000b0000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000bbb0b0000000007007070070000000b0bb00b0000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000b0bbbbb00b0000000700700070070000b00bbbb0bb000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
011300000215500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500005000050000500005000050000500005000000000000000000000000000000
011300000115500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105
011300000015500100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
011300000515500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000a00000060003660036500366008650006500564000620006100065001650016500063000620016100062000610006000060000600006000060000600006000060000600006000060000600006000060000600
