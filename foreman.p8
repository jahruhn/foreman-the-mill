pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- foreman the mill
-- by antigravity for toulcit

-- constants
STATE_TITLE = 1
STATE_NIGHT = 2
STATE_TRANSITION = 3
STATE_DAY_FISH = 4
STATE_DAY_TANK = 5
STATE_SHOP = 6
STATE_ENDING = 7

-- game state
state = STATE_TITLE
t = 0 -- global timer

-- player stats (shared across days)
player = {
 wages = 0,
 fish = {},
 upgrades = {
  gun_level = 1,
  line_length = 1
 }
}

function _init()
 t = 0
 change_state(STATE_TITLE)
end

function change_state(new_state)
 state = new_state
 t = 0 -- reset timer for state
 
 if state == STATE_TITLE then
  -- init title
 elseif state == STATE_NIGHT then
  init_night()
 elseif state == STATE_TRANSITION then
  init_transition()
 elseif state == STATE_DAY_FISH then
  init_day_fish()
 elseif state == STATE_DAY_TANK then
  init_day_tank()
 elseif state == STATE_SHOP then
  init_shop()
 elseif state == STATE_ENDING then
  init_ending()
 end
end

function _update60()
 t += 1
 if state == STATE_TITLE then
  update_title()
 elseif state == STATE_NIGHT then
  update_night()
 elseif state == STATE_TRANSITION then
  update_transition()
 elseif state == STATE_DAY_FISH then
  update_day_fish()
 elseif state == STATE_DAY_TANK then
  update_day_tank()
 elseif state == STATE_SHOP then
  update_shop()
 elseif state == STATE_ENDING then
  update_ending()
 end
end

function _draw()
 cls()
 if state == STATE_TITLE then
  draw_title()
 elseif state == STATE_NIGHT then
  draw_night()
 elseif state == STATE_TRANSITION then
  draw_transition()
 elseif state == STATE_DAY_FISH then
  draw_day_fish()
 elseif state == STATE_DAY_TANK then
  draw_day_tank()
 elseif state == STATE_SHOP then
  draw_shop()
 elseif state == STATE_ENDING then
  draw_ending()
 end
 
 -- debug
 print("state: "..state, 1, 1, 7)
end

-- state functions

-- title
function update_title()
 if (btnp(4) or btnp(5)) then -- z or x
  change_state(STATE_NIGHT)
  sfx(0) -- start sfx
 end
end

function draw_title()
 print("foreman the mill", 35, 50, 7)
 if (t % 30 < 15) then
  print("press x to start", 38, 70, 6)
 end
end

-- night (shooter)
-- player properties
p = {}

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
  bullets = {}
 }
 -- music(0) -- noisia style
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
  -- sfx(0)
 end
 
 -- shoot
 if (btnp(5)) then
  shoot_bullet()
 end

 -- physics
 p.dy += 0.25 -- gravity
 p.x += p.dx
 p.y += p.dy
 
 -- floor collision (placeholder)
 if (p.y > 100) then
  p.y = 100
  p.dy = 0
  p.grounded = true
 end
 
 -- wall collision
 if (p.x < 0) p.x = 0 p.dx = 0
 if (p.x > 120) p.x = 120 p.dx = 0
 
 -- max speed
 p.dx = mid(-2, p.dx, 2)
 
 update_bullets()
 update_enemies()
 check_collisions()
 
 -- spawn enemies randomly
 if (rnd(100) < 2) spawn_enemy()
end

function update_bullets()
 for b in all(p.bullets) do
  b.x += b.dx
  if (b.x < 0 or b.x > 128) del(p.bullets, b)
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
 -- sfx(1)
end

-- enemies
enemies = {}

function spawn_enemy()
 local e = {
  x = (rnd(2) < 1) and 0 or 120, -- spawn left or right
  y = 100,
  w = 6,
  h = 8,
  dx = 0,
  speed = 0.5 + rnd(0.5),
  type = flr(rnd(3)) -- 0: tie, 1: papers, 2: coffee
 }
 -- walk towards center
 if (e.x == 0) e.dx = e.speed
 else e.dx = -e.speed
 
 add(enemies, e)
end

function update_enemies()
 for e in all(enemies) do
  e.x += e.dx
  -- simple bounce
  if (e.x < 0 or e.x > 120) e.dx = -e.dx
 end
end

function check_collisions()
 -- bullets vs enemies
 for b in all(p.bullets) do
  for e in all(enemies) do
   if (check_col(b, e)) then
    del(p.bullets, b)
    del(enemies, e)
    player.wages += 10 -- got paid!
    -- sfx(2)
    break -- bullet can only hit one enemy
   end
  end
 end
 
 -- player vs enemies
 for e in all(enemies) do
  if (check_col(p, e)) then
   -- game over or restart night
   init_night()
   -- sfx(3)
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
 
 -- draw ground
 rectfill(0, 108, 127, 127, 3) -- green ground
 
 -- draw player
 local color = 12 -- blue
 if (t % 20 < 10) color = 7 -- flash
 rectfill(p.x, p.y, p.x+p.w, p.y+p.h, color)
 
 -- draw enemies
 for e in all(enemies) do
  local ecol = 8 -- red
  if (e.type == 1) ecol = 9 -- orange
  if (e.type == 2) ecol = 10 -- yellow
  rectfill(e.x, e.y, e.x+e.w, e.y+e.h, ecol)
  -- draw tie
  line(e.x+3, e.y+2, e.x+3, e.y+6, 7)
 end
 
 -- draw bullets
 for b in all(p.bullets) do
  pset(b.x, b.y, 8) -- red bullet
  pset(b.x+1, b.y, 10) -- trail
 end
 
 print("night: protect the mill!", 20, 10, 7)
 print("wages: $"..player.wages, 20, 20, 6)
end

-- transition (larry cutscene)
function init_transition()
 -- sfx(1) -- funny sound
end

function update_transition()
 if (t > 180) change_state(STATE_DAY_FISH)
end

function draw_transition()
 cls(5)
 -- larry style suit removal / funny graphic
 print("shift over!", 45, 40, 7)
 print("time to relax...", 35, 50, 6)
 
 -- simple animation
 if (t % 60 < 30) then
  print("ooh la la!", 45, 80, 14)
 else
  print("*wink*", 50, 80, 14)
 end
end

-- day (fishing)
boat = {x=64, y=20}
hook = {x=64, y=20, dy=0, state=0} -- 0:idle, 1:down, 2:up
fishes = {}
caught_fish = nil

function init_day_fish()
 -- music(1) -- jazz
 boat.x = 64
 hook.dy = 0
 hook.state = 0
 fishes = {}
 caught_fish = nil
 
 -- spawn fish
 for i=1,10 do
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
 if (btn(0)) boat.x -= 1
 if (btn(1)) boat.x += 1
 boat.x = mid(0, boat.x, 120)
 
 -- hook logic
 hook.x = boat.x + 4
 
 if (hook.state == 0) then -- idle
  hook.y = boat.y + 5
  if (btnp(4)) hook.state = 1 -- drop
 elseif (hook.state == 1) then -- down
  hook.y += 2
  if (hook.y > 120 or btnp(4)) hook.state = 2 -- retract
  
  -- check collision with fish
  for f in all(fishes) do
   if (abs(hook.x - f.x) < 5 and abs(hook.y - f.y) < 4) then
    caught_fish = f
    del(fishes, f)
    hook.state = 2
    -- sfx(4) -- catch sound
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
    -- sfx(5) -- got fish
    -- show message?
   end
  end
 end
 
 -- fish movement
 for f in all(fishes) do
  f.x += f.dx
  if (f.x < 0 or f.x > 128) f.x = 0 f.dx = -f.dx -- flip dir? no just wrap or bounce
  if (f.x > 128) f.x = -5
 end
 
 if (btnp(5)) change_state(STATE_DAY_TANK) -- done fishing
end

function draw_day_fish()
 rectfill(0,0,127,127, 12) -- sky/water
 rectfill(0,30,127,127, 1) -- deep water
 
 -- draw boat
 rectfill(boat.x, boat.y, boat.x+8, boat.y+5, 4)
 
 -- draw line
 line(hook.x, boat.y+2, hook.x, hook.y, 7)
 pset(hook.x, hook.y, 7) -- hook
 
 -- draw fish
 for f in all(fishes) do
  local c = 10 -- yellow
  if (f.type == 1) c = 11 -- green
  if (f.type == 2) c = 8 -- red
  
  pset(f.x, f.y, c)
  pset(f.x+1, f.y, c)
  pset(f.x+2, f.y, c)
  pset(f.x+1, f.y-1, c) -- fin
 end
 
 if (caught_fish) then
  print("GOTCHA!", hook.x-10, hook.y-10, 7)
  pset(hook.x, hook.y+2, 8) -- show fish on hook
 end
 
 print("fishing: x to drop, z to finish", 5, 5, 7)
 print("fish caught: "..#player.fish, 5, 12, 6)
end

-- day (tank/tamagotchi)
function init_day_tank()
 -- music(2) -- lo-fi
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
  if (f.x < 10 or f.x > 110) f.dx = -f.dx
 end
 
 if (btnp(4)) then -- feed
  -- sfx(6) -- feed sound
  -- increase value logic placeholder
 end
 
 if (btnp(5)) change_state(STATE_SHOP) -- go to shop
end

function draw_day_tank()
 rectfill(0,0,127,127, 1) -- dark blue
 rect(5, 15, 122, 110, 7) -- tank glass
 
 for f in all(player.fish) do
  local c = 10 -- yellow
  if (f.type == 1) c = 11 -- green
  if (f.type == 2) c = 8 -- red
  
  pset(f.x, f.y, c)
  pset(f.x+1, f.y, c)
  pset(f.x+2, f.y, c)
  pset(f.x+1, f.y-1, c)
 end
 
 print("fish care", 45, 5, 7)
 print("z: feed, x: shop", 30, 115, 6)
end

-- shop
function init_shop()
 -- music(3) -- bossa nova
end

function update_shop()
 if (btnp(5)) then -- Sell All
  local total = 0
  for f in all(player.fish) do
   local val = 10
   if (f.type == 1) val = 50
   if (f.type == 2) val = 200
   total += val
  end
  player.wages += total
  player.fish = {} -- empty inventory
  -- sfx(7) -- chaching
  
  if (player.wages >= 500) then -- win condition
   change_state(STATE_ENDING)
  else
   change_state(STATE_NIGHT) -- loop back to night
  end
 end
end

function draw_shop()
 rectfill(0,0,127,127, 4) -- brown background
 
 print("fish market", 40, 10, 7)
 print("current wages: $"..player.wages, 30, 30, 6)
 
 local val = 0
 for f in all(player.fish) do
   if (f.type == 0) val += 10
   if (f.type == 1) val += 50
   if (f.type == 2) val += 200
 end
 
 print("fish value: $"..val, 35, 50, 11)
 print("goal: $500", 90, 30, 12)
 
 print("press x to sell all", 30, 80, 5)
 print("and start night shift", 25, 90, 5)
end

-- ending
function init_ending()
 -- music(4) -- thai romantic
end

function update_ending()
 if (btnp(4) or btnp(5)) change_state(STATE_TITLE)
end

function draw_ending()
 cls(14) -- pink
 
 -- draw heart
 circfill(64, 50, 20, 8)
 circfill(50, 40, 15, 8)
 circfill(78, 40, 15, 8)
 
 -- draw couple (placeholder)
 rectfill(55, 60, 63, 80, 12) -- foreman
 rectfill(65, 60, 73, 80, 10) -- wife (yellow dress)
 
 print("retirement achieved!", 25, 20, 7)
 print("love & riches", 35, 90, 7)
 print("press x to restart", 30, 110, 6)
end

__gfx__
__gff__
__map__
__sfx__
__music__
