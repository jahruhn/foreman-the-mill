pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- foreman the mill
-- a game where you shoot bureaucratic zombies at night
-- and fish/care for fish during the day

-- game states
STATE_TITLE = 1
STATE_NIGHT = 2
STATE_DAY_FISH = 3
STATE_DAY_TANK = 4
STATE_SHOP = 5

-- game state
state = STATE_TITLE
t = 0 -- global timer

-- player stats
player = {
    wages = 0,
    fish = {},
    upgrades = {
        gun_level = 1,
        line_length = 1
    }
}

-- player properties for night phase
p = {}

-- enemies for night phase
enemies = {}

-- fishing properties for day phase
boat = {x = 64, y = 20}
hook = {x = 64, y = 20, dy = 0, state = 0} -- 0:idle, 1:down, 2:up
fishes = {}
caught_fish = nil

function _init()
    t = 0
    change_state(STATE_TITLE)
    music(0, 0, 7) -- fade in title music
end

function change_state(new_state)
    state = new_state
    t = 0 -- reset timer for state
    
    if state == STATE_TITLE then
        -- init title
    elseif state == STATE_NIGHT then
        init_night()
        music(1, 0, 7) -- fade in night music
    elseif state == STATE_DAY_FISH then
        init_day_fish()
        music(2, 0, 7) -- fade in day music
    elseif state == STATE_DAY_TANK then
        init_day_tank()
        music(3, 0, 7) -- fade in tank music
    elseif state == STATE_SHOP then
        -- init shop
        music(3, 0, 7) -- use tank music for shop
    end
end

function _update60()
    t += 1
    
    if state == STATE_TITLE then
        update_title()
    elseif state == STATE_NIGHT then
        update_night()
    elseif state == STATE_DAY_FISH then
        update_day_fish()
    elseif state == STATE_DAY_TANK then
        update_day_tank()
    elseif state == STATE_SHOP then
        update_shop()
    end
end

function _draw()
    cls()
    
    if state == STATE_TITLE then
        draw_title()
    elseif state == STATE_NIGHT then
        draw_night()
    elseif state == STATE_DAY_FISH then
        draw_day_fish()
    elseif state == STATE_DAY_TANK then
        draw_day_tank()
    elseif state == STATE_SHOP then
        draw_shop()
    end
    
    -- debug
    print("state: "..state, 1, 1, 7)
end

-- title screen
function update_title()
    if (btnp(4) or btnp(5)) then -- z or x
        change_state(STATE_NIGHT)
        sfx(0) -- play gunshot sfx
    end
end

function draw_title()
    -- draw epic title screen
    rectfill(0, 0, 127, 127, 1) -- dark blue background
    
    -- draw "foreman the mill" title
    print("foreman the mill", 20, 40, 7)
    print("a game by you", 35, 50, 12)
    
    -- draw instructions
    if (t % 30 < 15) then
        print("press x to start", 35, 70, 6)
    end
    
    -- draw decorative elements
    circfill(30, 30, 10, 8) -- sun/moon
    circfill(90, 30, 8, 10) -- another decorative element
end

-- night phase: shoot bureaucratic zombie officials
function init_night()
    p = {
        x = 60,
        y = 60,
        dx = 0,
        dy = 0,
        w = 4,
        h = 8,
        grounded = false,
        facing = 1, -- 1 right, -1 left
        bullets = {},
        health = 100
    }
    enemies = {}
end

function update_night()
    -- player input
    if (btn(0)) then -- left
        p.dx -= 0.5
        p.facing = -1
    elseif (btn(1)) then -- right
        p.dx += 0.5
        p.facing = 1
    else
        p.dx *= 0.8 -- friction
    end
    
    -- jump
    if (btnp(4) and p.grounded) then
        p.dy = -4
        p.grounded = false
        sfx(1) -- jump sfx
    end
    
    -- shoot
    if (btnp(5)) then
        shoot_bullet()
    end
    
    -- physics
    p.dy += 0.25 -- gravity
    p.x += p.dx
    p.y += p.dy
    
    -- floor collision
    if (p.y > 100) then
        p.y = 100
        p.dy = 0
        p.grounded = true
    end
    
    -- wall collision
    if (p.x < 0) then
        p.x = 0
        p.dx = 0
    end
    if (p.x > 120) then
        p.x = 120
        p.dx = 0
    end
    
    -- max speed
    p.dx = mid(-2, p.dx, 2)
    
    update_bullets()
    update_enemies()
    check_collisions()
    
    -- spawn enemies randomly
    if (rnd(100) < 2) then
        spawn_enemy()
    end
    
    -- transition to day after some time
    if (t > 1000) then
        change_state(STATE_DAY_FISH)
    end
end

function update_bullets()
    for b in all(p.bullets) do
        b.x += b.dx
        if (b.x < 0 or b.x > 128) then
            del(p.bullets, b)
        end
    end
end

function shoot_bullet()
    local b = {
        x = p.x + (p.w/2),
        y = p.y + (p.h/2),
        dx = p.facing * 4,
        r = 1
    }
    add(p.bullets, b)
    sfx(0) -- gunshot sfx
end

function spawn_enemy()
    local e = {
        x = (rnd(2) < 1) and 0 or 120, -- spawn left or right
        y = 100,
        w = 6,
        h = 8,
        dx = 0,
        speed = 0.5 + rnd(0.5),
        type = flr(rnd(3)), -- 0: tie, 1: papers, 2: coffee
        health = 30
    }
    
    -- walk towards center
    if (e.x == 0) then
        e.dx = e.speed
    else
        e.dx = -e.speed
    end
    
    add(enemies, e)
end

function update_enemies()
    for e in all(enemies) do
        e.x += e.dx
        -- simple bounce
        if (e.x < 0 or e.x > 120) then
            e.dx = -e.dx
        end
    end
end

function check_collisions()
    -- bullets vs enemies
    for b in all(p.bullets) do
        for e in all(enemies) do
            if (check_col(b, e)) then
                del(p.bullets, b)
                e.health -= 10
                if (e.health <= 0) then
                    del(enemies, e)
                    player.wages += 10 -- got paid!
                    sfx(1) -- explosion sfx
                end
                break -- bullet can only hit one enemy
            end
        end
    end
    
    -- player vs enemies
    for e in all(enemies) do
        if (check_col(p, e)) then
            -- take damage
            p.health -= 5
            if (p.health <= 0) then
                init_night() -- restart
            end
            -- knockback
            p.dx = (p.x < e.x) and -2 or 2
            sfx(3) -- hurt sfx
        end
    end
end

function check_col(a, b)
    return not (a.x > b.x+b.w or
                a.x+(a.w or a.r or 1) < b.x or
                a.y > b.y+b.h or
                a.y+(a.h or a.r or 1) < b.y)
end

function draw_night()
    cls(0) -- black background
    
    -- draw starry night sky
    for i=1,50 do
        pset(rnd(128), rnd(64), 7)
    end
    
    -- draw ground
    rectfill(0, 108, 127, 127, 3) -- green ground
    
    -- draw player
    local color = 12 -- blue
    if (t % 20 < 10) then
        color = 7 -- flash when hit
    end
    rectfill(p.x, p.y, p.x+p.w, p.y+p.h, color)
    
    -- draw gun
    if (p.facing == 1) then
        line(p.x+p.w, p.y+2, p.x+p.w+4, p.y+2, 7) -- gun pointing right
    else
        line(p.x-1, p.y+2, p.x-4, p.y+2, 7) -- gun pointing left
    end
    
    -- draw enemies
    for e in all(enemies) do
        local ecol = 8 -- red
        if (e.type == 1) then
            ecol = 9 -- orange
        elseif (e.type == 2) then
            ecol = 10 -- yellow
        end
        rectfill(e.x, e.y, e.x+e.w, e.y+e.h, ecol)
        -- draw tie
        line(e.x+3, e.y+2, e.x+3, e.y+6, 7)
        -- draw briefcase
        rect(e.x+1, e.y-2, e.x+4, e.y, 6)
    end
    
    -- draw bullets
    for b in all(p.bullets) do
        pset(b.x, b.y, 8) -- red bullet
        pset(b.x+1, b.y, 10) -- trail
    end
    
    -- draw health bar
    rectfill(0, 0, p.health/2, 4, 8) -- red health bar
    
    print("night: protect the mill!", 20, 10, 7)
    print("wages: $"..player.wages, 20, 20, 6)
    print("health: "..p.health, 20, 28, 11)
end

-- day phase: fishing
function init_day_fish()
    boat.x = 64
    hook.dy = 0
    hook.state = 0
    fishes = {}
    caught_fish = nil
    
    -- spawn fish
    for i=1, 10 do
        add(fishes, {
            x = rnd(120),
            y = 40 + rnd(80),
            w = 6,
            h = 3,
            dx = 0.5 + rnd(0.5),
            type = flr(rnd(3)) -- 0:common, 1:rare, 2:legendary
        })
    end
end

function update_day_fish()
    -- boat movement
    if (btn(0)) then
        boat.x -= 1
    end
    if (btn(1)) then
        boat.x += 1
    end
    boat.x = mid(0, boat.x, 120)
    
    -- hook logic
    hook.x = boat.x + 4
    
    if (hook.state == 0) then -- idle
        hook.y = boat.y + 5
        if (btnp(4)) then
            hook.state = 1 -- drop
            sfx(2) -- splash sfx
        end
    elseif (hook.state == 1) then -- down
        hook.y += 2
        if (hook.y > 120 or btnp(4)) then
            hook.state = 2 -- retract
        end
        
        -- check collision with fish
        for f in all(fishes) do
            if (abs(hook.x - f.x) < 5 and abs(hook.y - f.y) < 4) then
                caught_fish = f
                del(fishes, f)
                hook.state = 2
                sfx(3) -- fish caught sfx
                break
            end
        end
        
    elseif (hook.state == 2) then -- up
        hook.y -= 3
        if (hook.y <= boat.y + 5) then
            hook.state = 0
            if (caught_fish) then
                add(player.fish, caught_fish)
                caught_fish = nil
            end
        end
    end
    
    -- fish movement
    for f in all(fishes) do
        f.x += f.dx
        if (f.x < 0 or f.x > 128) then
            f.x = 0
            f.dx = -f.dx
        end
        if (f.x > 128) then
            f.x = -5
        end
    end
    
    if (btnp(5)) then
        change_state(STATE_DAY_TANK) -- done fishing
    end
end

function draw_day_fish()
    -- draw sky and water
    rectfill(0, 0, 127, 30, 12) -- sky
    rectfill(0, 30, 127, 127, 1) -- water
    
    -- draw sun
    circfill(100, 20, 10, 10)
    
    -- draw boat
    rectfill(boat.x, boat.y, boat.x+8, boat.y+5, 4) -- brown boat
    
    -- draw line
    line(hook.x, boat.y+2, hook.x, hook.y, 7) -- fishing line
    pset(hook.x, hook.y, 7) -- hook
    
    -- draw fish
    for f in all(fishes) do
        local c = 10 -- yellow
        if (f.type == 1) then
            c = 11 -- green
        elseif (f.type == 2) then
            c = 8 -- red
        end
        
        pset(f.x, f.y, c)
        pset(f.x+1, f.y, c)
        pset(f.x+2, f.y, c)
        pset(f.x+1, f.y-1, c) -- fin
    end
    
    if (caught_fish) then
        print("gotcha!", hook.x-10, hook.y-10, 7)
        pset(hook.x, hook.y+2, 8) -- show fish on hook
    end
    
    print("fishing: x to drop, z to finish", 5, 5, 7)
    print("fish caught: "..#player.fish, 5, 12, 6)
end

-- day tank phase: fish care
function init_day_tank()
    -- setup fish positions in tank
    for f in all(player.fish) do
        f.x = 10 + rnd(100)
        f.y = 20 + rnd(80)
        f.dx = 0.5
    end
end

function update_day_tank()
    for f in all(player.fish) do
        f.x += f.dx
        if (f.x < 10 or f.x > 110) then
            f.dx = -f.dx
        end
    end
    
    if (btnp(4)) then -- feed
        for f in all(player.fish) do
            f.type = min(f.type + 1, 2) -- upgrade fish rarity
        end
        sfx(4) -- feed sfx
    end
    
    if (btnp(5)) then
        change_state(STATE_SHOP) -- go to shop
    end
end

function draw_day_tank()
    rectfill(0, 0, 127, 127, 1) -- dark blue background
    rect(5, 15, 122, 110, 7) -- tank glass
    
    -- draw water
    for i=16,110 do
        line(6, i, 121, i, 12) -- light blue water
    end
    
    -- draw fish
    for f in all(player.fish) do
        local c = 10 -- yellow
        if (f.type == 1) then
            c = 11 -- green
        elseif (f.type == 2) then
            c = 8 -- red
        end
        
        pset(f.x, f.y, c)
        pset(f.x+1, f.y, c)
        pset(f.x+2, f.y, c)
        pset(f.x+1, f.y-1, c) -- fin
    end
    
    -- draw bubbles
    for i=1,10 do
        circfill(rnd(110)+10, rnd(80)+30, 1, 7)
    end
    
    print("fish care", 45, 5, 7)
    print("z: feed, x: shop", 30, 115, 6)
end

-- shop phase: sell fish and buy upgrades
function update_shop()
    if (btnp(5)) then -- Sell All
        local total = 0
        for f in all(player.fish) do
            local val = 10
            if (f.type == 1) then
                val = 50
            elseif (f.type == 2) then
                val = 200
            end
            total += val
        end
        player.wages += total
        player.fish = {} -- empty inventory
        sfx(5) -- cash register sfx
        
        change_state(STATE_NIGHT) -- loop back to night
    end
end

function draw_shop()
    rectfill(0, 0, 127, 127, 4) -- brown background
    
    -- draw shop counter
    rectfill(0, 90, 127, 127, 6)
    
    print("fish market", 40, 10, 7)
    print("current wages: $"..player.wages, 30, 30, 6)
    
    local val = 0
    for f in all(player.fish) do
        if (f.type == 0) then
            val += 10
        elseif (f.type == 1) then
            val += 50
        elseif (f.type == 2) then
            val += 200
        end
    end
    
    print("fish value: $"..val, 35, 50, 11)
    print("press x to sell all", 30, 80, 5)
    print("and start night shift", 25, 90, 5)
    
    -- draw fish in inventory
    local x = 10
    for f in all(player.fish) do
        local c = 10 -- yellow
        if (f.type == 1) then
            c = 11 -- green
        elseif (f.type == 2) then
            c = 8 -- red
        end
        rectfill(x, 60, x+4, 64, c)
        x += 8
    end
end

__gfx__
-- sprites will be drawn here using pico-8's sprite editor
-- example: player sprite at 0, zombie at 8, fish at 16, etc.
-- use the sprite editor to create detailed 8x8 or 16x16 sprites

-- player sprite (idle)
pset(0,0,12) pset(1,0,12) pset(2,0,12)
pset(0,1,12) pset(2,1,12)
pset(0,2,3) pset(1,2,3) pset(2,2,3)
pset(0,3,1) pset(1,3,1) pset(2,3,1)
pset(2,4,7)

-- zombie sprite
pset(8,0,10) pset(9,0,10) pset(10,0,10)
pset(8,1,8) pset(9,1,8) pset(10,1,8)
pset(9,2,7)
pset(8,3,8) pset(9,3,8) pset(10,3,8)

-- fish sprite (yellow)
pset(16,0,10) pset(17,0,10)
pset(18,0,9)
pset(16,1,10)

__gff__
-- flags for sprites (if needed)

__map__
-- tilemap for backgrounds (if needed)
-- example: 000000000000000
--          011111111111110
--          01..........10
--          01..........10
--          011111111111110

__sfx__
-- 0: gunshot
0 1 0 0 0 15 10
-- 1: explosion
3 0 2 0 0 10 5
-- 2: water splash
1 0 0 0 0 8 12
-- 3: fish caught
2 0 4 0 0 12 7
-- 4: feed fish
1 0 3 0 0 10 8
-- 5: cash register
2 0 0 0 0 14 6

__music__
-- title music (heroic, slow build)
0:
0: 0 1 2 1

-- night music (intense action)
1:
0: 3 4 5 4

-- day music (calm, adventurous)
2:
0: 6 7 7 8

-- tank/shop music (whimsical)
3:
0: 9 10 10 11

-- patterns:
-- 0: 0000 10102030 4.....5. .......6 .......7 (title intro)
-- 1: 0101 10102030 40506070 40506070 (title main)
-- 2: 0202 10102030 40506070 70605040 (title climax)
-- 3: 0303 10101010 20203030 40405050 (night action)
-- 4: 0404 ....5... ....6... ....7... (night brass stabs)
-- 5: 0505 10101010 30303030 70707070 (night tension)
-- 6: 0606 1.....2. 3.....4. 5.....6. (day intro)
-- 7: 0707 10203040 50607010 20304050 (day main)
-- 8: 0808 1.....2. .......3 .......4 (day outro)
-- 9: 0909 1.2.3.4. 5.6.7.1. 2.3.4.5. (tank intro)
--10:1010 10203040 50607010 20304050 (tank main)
--11:1111 1.2.3.4. ....5... ....1... (tank outro)