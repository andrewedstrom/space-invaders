pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

local game_objects

function _init()
    game_objects={}
    make_player() 
    make_invader(20,20)
    make_invader(35,20)
    make_invader(50,20)
    make_invader(65,20)
end

function _update()
    for obj in all(game_objects) do
        obj:update()
        if obj:is_expired() then
            del(game_objects, obj)
        end
    end
end

function _draw()
    cls()
    for obj in all(game_objects) do
        obj:draw()
    end
end

function make_player()
    return make_game_object("player",64,110,13,8,{
        draw=function(self)
            sspr(8,0,self.width,self.height,self.x,self.y)
        end,
        update=function(self)
            if btn(0) then
                self.x-=2
            end
            if btn(1) then
                self.x+=2
            end
            if btnp(4) or btnp(5) then
                self:shoot()
            end
        end,
        shoot=function(self)
            make_bullet(self.x+self.width/2,self.y)
        end
    })
end

function make_bullet(x, y)
    return make_game_object("bullet",x,y,1,2,{
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

function make_invader(x,y)
    return make_game_object("invader",x,y,11,8, {
        alive=true,
        draw=function(self)
            if self.alive then
                sspr(24,0,self.width,self.height,self.x,self.y)
            else
                sspr(24,9,13,self.height,self.x,self.y)
            end
            -- self:draw_bounding_box(10)
        end,
        update=function(self)
            foreach_game_object_of_kind("bullet", function(bullet)
                if rects_overlapping(self.x,self.y,self.x+self.width,self.y+self.height,bullet.x,bullet.y,bullet.x+bullet.width,bullet.y+bullet.height) and self.alive then
                    self.alive = false
                    del(game_objects, bullet)
                end
            end)
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
00000000000000b00000000000700000700000700000700000077000000000777700000000077000000007777000000000000000000000000000000000000000
0000000000000bbb0000000000070007000070070007007000777700000777777777700000777700007777777777000000000000000000000000000000000000
0070070000000bbb0000000000777777700070777777707007777770007777777777770007777770077777777777700000000000000000000000000000000000
000770000bbbbbbbbbbb000007707770770077707770777077077077007770077007770077077077077700770077700000000000000000000000000000000000
00077000bbbbbbbbbbbbb00077777777777007777777770077777777007777777777770077777777077777777777700000000000000000000000000000000000
00700700bbbbbbbbbbbbb00070777777707000777777700007077070007777777777770000700700077777777777700000000000000000000000000000000000
00000000bbbbbbbbbbbbb00070700000707000700000700070000007000007700770000007077070000077007700000000000000000000000000000000000000
00000000bbbbbbbbbbbbb00000077077000007000000070007000070000077077077000070700707000770770770000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000007700000000770000000000000000000000000000000000000000000000000000000000
00000000000000000000000000007000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000007000707000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000700000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000070000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000077000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000070000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000700707007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000007007000700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
