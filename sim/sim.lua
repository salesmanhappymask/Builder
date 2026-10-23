local PROGRAM = arg[1] or "hubbuild"
local SEED = tonumber(arg[2] or 1)
local KILL_CHANCE = tonumber(arg[3] or 0.0005)
local USE_GPS = arg[4] ~= "nogps"
math.randomseed(SEED)

local source = assert(io.open(PROGRAM)):read("*a")

local world = {}
local turtleAt = {}
local function key(x, y, z) return x .. "," .. y .. "," .. z end
local function blockAt(x, y, z)
  local b = world[key(x, y, z)]
  if b then return b end
  if y < 0 then return { name = "dirt" } end
  return nil
end

local MAX = { tin = 64, glass = 64, lava = 1, bucket = 16, junk = 64 }

local function newChest(name)
  local c = { name = name, slots = {} }
  world[key(0, ({ tinchest = 0, glasschest = 1, fuelchest = 2 })[name], 0)] = c
  return c
end
local tinChest, glassChest, fuelChest = newChest("tinchest"), newChest("glasschest"), newChest("fuelchest")
fuelChest.slots[1] = { name = "bucket", count = 3 }

local clock = 0
local outage = { from = 400, to = 700 }
local stats = { tinIn = 0, glassIn = 0, lavaIn = 0, kills = 0, blocked = 0 }

local function keepStocked(c, item, stacks)
  if clock >= outage.from and clock < outage.to and item ~= "lava" then return end
  local have = 0
  for i = 1, 27 do if c.slots[i] and c.slots[i].name == item then have = have + 1 end end
  for i = 1, 27 do
    if have >= stacks then break end
    if not c.slots[i] then
      c.slots[i] = { name = item, count = MAX[item] }
      have = have + 1
      if item == "tin" then stats.tinIn = stats.tinIn + 64 elseif item == "glass" then stats.glassIn = stats.glassIn + 64 else stats.lavaIn = stats.lavaIn + 1 end
    end
  end
  if item == "lava" then
    for i = 1, 27 do
      local s = c.slots[i]
      if s and s.name == "bucket" and math.random() < 0.3 then
        s.count = s.count - 1
        if s.count == 0 then c.slots[i] = nil end
        break
      end
    end
  end
end

local function insert(slots, n, item, amount, first)
  local moved = 0
  local function try(i)
    local s = slots[i]
    if amount - moved <= 0 then return end
    if s == nil then
      local k = math.min(MAX[item], amount - moved)
      slots[i] = { name = item, count = k }
      moved = moved + k
    elseif s.name == item and s.count < MAX[item] then
      local k = math.min(MAX[item] - s.count, amount - moved)
      s.count = s.count + k
      moved = moved + k
    end
  end
  for j = 0, n - 1 do try((first - 1 + j) % n + 1) end
  return moved
end

local function serialize(v)
  local t = type(v)
  if t == "table" then
    local parts = {}
    for k, val in pairs(v) do
      local ks = type(k) == "number" and ("[" .. k .. "]") or ("[" .. string.format("%q", k) .. "]")
      parts[#parts + 1] = ks .. "=" .. serialize(val)
    end
    return "{" .. table.concat(parts, ",") .. "}"
  elseif t == "string" then
    return string.format("%q", v)
  else
    return tostring(v)
  end
end

local DX = { [0] = 1, 0, -1, 0 }
local DZ = { [0] = 0, 1, 0, -1 }
local FACE = { [0] = "east", "south", "west", "north" }
local ORIGIN = { x = 1000, y = 64, z = -500 }

local bots = {}

local function makeBot(id, x, z, f)
  local b = { id = id, x = x, y = 0, z = z, f = f, fuel = 0, inv = {}, sel = 1, files = {}, moves = 0, done = false, log = {} }
  b.inv[1] = { name = "lava", count = 1 }
  turtleAt[key(x, 0, z)] = b
  return b
end

local function occupied(x, y, z) return blockAt(x, y, z) ~= nil or turtleAt[key(x, y, z)] ~= nil end

local function env(b)
  local E = {}
  local function tick()
    clock = clock + 0.05
    if coroutine.running() then coroutine.yield() end
  end
  local function maybeKill()
    if math.random() < KILL_CHANCE then coroutine.yield("kill") end
  end
  local function moveTo(nx, ny, nz)
    tick()
    if b.fuel <= 0 or occupied(nx, ny, nz) then
      if turtleAt[key(nx, ny, nz)] then stats.blocked = stats.blocked + 1 end
      return false
    end
    turtleAt[key(b.x, b.y, b.z)] = nil
    b.x, b.y, b.z = nx, ny, nz
    turtleAt[key(nx, ny, nz)] = b
    b.fuel = b.fuel - 1
    b.moves = b.moves + 1
    maybeKill()
    return true
  end
  local function front() return b.x + DX[b.f], b.y, b.z + DZ[b.f] end
  local function item() return b.inv[b.sel] end
  local T = {}
  T.forward = function() local x, y, z = front(); return moveTo(x, y, z) end
  T.up = function() return moveTo(b.x, b.y + 1, b.z) end
  T.down = function() return moveTo(b.x, b.y - 1, b.z) end
  T.turnLeft = function() tick(); b.f = (b.f + 3) % 4; return true end
  T.turnRight = function() tick(); b.f = (b.f + 1) % 4; return true end
  T.detect = function() tick(); local x, y, z = front(); return occupied(x, y, z) end
  T.detectDown = function() tick(); return occupied(b.x, b.y - 1, b.z) end
  T.detectUp = function() tick(); return occupied(b.x, b.y + 1, b.z) end
  T.select = function(s) b.sel = s; return true end
  T.getItemCount = function(s) local it = b.inv[s or b.sel]; return it and it.count or 0 end
  T.getItemSpace = function(s) local it = b.inv[s or b.sel]; return it and (MAX[it.name] - it.count) or 64 end
  T.getFuelLevel = function() return b.fuel end
  T.getFuelLimit = function() return 20000 end
  T.placeDown = function()
    tick()
    local it = item()
    if not it or (it.name ~= "tin" and it.name ~= "glass") then return false end
    if occupied(b.x, b.y - 1, b.z) then return false end
    world[key(b.x, b.y - 1, b.z)] = { name = it.name, by = b.id }
    it.count = it.count - 1
    if it.count == 0 then b.inv[b.sel] = nil end
    maybeKill()
    return true
  end
  T.compareDown = function()
    tick()
    local blk, it = blockAt(b.x, b.y - 1, b.z), item()
    return blk ~= nil and it ~= nil and blk.name == it.name
  end
  T.compareTo = function(s)
    local a, c = item(), b.inv[s]
    return a ~= nil and c ~= nil and a.name == c.name
  end
  T.suck = function()
    tick()
    local c = blockAt(front())
    if not c or not c.slots then return false end
    for i = 1, 27 do
      local s = c.slots[i]
      if s then
        local moved = insert(b.inv, 16, s.name, s.count, b.sel)
        if moved == 0 then return false end
        s.count = s.count - moved
        if s.count == 0 then c.slots[i] = nil end
        return true
      end
    end
    return false
  end
  T.drop = function(n)
    tick()
    local it = item()
    if not it then return false end
    local c = blockAt(front())
    if not c or not c.slots then return false end
    n = math.min(n or it.count, it.count)
    if n <= 0 then return false end
    local moved = insert(c.slots, 27, it.name, n, 1)
    it.count = it.count - moved
    if it.count == 0 then b.inv[b.sel] = nil end
    return moved > 0
  end
  T.refuel = function(n)
    local it = item()
    if not it or it.name ~= "lava" then return false end
    if n == 0 then return true end
    b.fuel = math.min(20000, b.fuel + 1000)
    it.name = "bucket"
    return true
  end
  E.turtle = T

  local fsT = {}
  fsT.exists = function(p) return b.files[p] ~= nil end
  fsT.getSize = function(p) return #(b.files[p] or "") end
  fsT.delete = function(p) b.files[p] = nil end
  fsT.open = function(p, mode)
    if mode == "r" then
      if not b.files[p] then return nil end
      local data, pos = b.files[p], 1
      return {
        readAll = function() return data end,
        readLine = function()
          if pos > #data then return nil end
          local e = data:find("\n", pos, true) or (#data + 1)
          local l = data:sub(pos, e - 1); pos = e + 1; return l
        end,
        close = function() end,
      }
    end
    local buf = mode == "a" and (b.files[p] or "") or ""
    return {
      write = function(s) buf = buf .. s end,
      writeLine = function(s) buf = buf .. s .. "\n" end,
      close = function() b.files[p] = buf end,
    }
  end
  E.fs = fsT

  E.textutils = {
    serialize = serialize,
    unserialize = function(s) local f = loadstring("return " .. s); return f and f() end,
    formatTime = function() return "12:00" end,
  }
  E.os = {
    day = function() return 1 end,
    time = function() return 12 end,
    clock = function() return clock end,
    getComputerLabel = function() return "bot" .. b.id end,
    getComputerID = function() return b.id end,
    queueEvent = function() end,
    pullEvent = function(filter)
      if filter == "hubbuild_yield" then return filter end
      error("bot " .. b.id .. " waits for an event: " .. tostring(filter) .. " (" .. tostring(b.log[#b.log]) .. ")")
    end,
  }
  E.sleep = function(n)
    local untilT = clock + n
    repeat tick() until clock >= untilT
  end
  E.print = function(s) b.log[#b.log + 1] = tostring(s) end
  E.error = error
  E.peripheral = {
    getType = function(side)
      if side == "left" then return "compass" elseif side == "right" then return "modem" end
      return nil
    end,
    wrap = function(side)
      if side == "left" then return { getFacing = function() return FACE[b.f] end } end
      return nil
    end,
  }
  E.rednet = {
    open = function() end,
    broadcast = function(msg) b.status = msg end,
    receive = function() error("unused") end,
  }
  E.gps = {
    locate = function()
      tick()
      if not USE_GPS then return nil end
      return b.x + ORIGIN.x, b.y + ORIGIN.y, b.z + ORIGIN.z
    end,
  }
  E.shell = { getRunningProgram = function() return "hubbuild" end }
  E.parallel = { waitForAny = function(a) a() end }
  for _, n in ipairs({ "math", "string", "table", "ipairs", "pairs", "type", "tostring", "tonumber", "pcall", "select", "unpack", "next", "setmetatable", "getmetatable" }) do
    E[n] = _G[n]
  end
  return E
end

local function start(b)
  local fn = assert(loadstring(source, "hubbuild"))
  setfenv(fn, env(b))
  b.co = coroutine.create(fn)
end

bots[1] = makeBot(1, 1, 0, 2)
bots[2] = makeBot(2, 0, 1, 3)
bots[3] = makeBot(3, -1, 0, 0)
bots[4] = makeBot(4, 0, -1, 1)
for _, b in ipairs(bots) do start(b) end

local rounds = 0
while true do
  local alive = 0
  for _, b in ipairs(bots) do
    if not b.done then
      alive = alive + 1
      local ok, why = coroutine.resume(b.co)
      if not ok then
        print("bot " .. b.id .. " crashed: " .. tostring(why))
        for i = math.max(1, #b.log - 5), #b.log do print("   " .. b.log[i]) end
        os.exit(1)
      elseif why == "kill" then
        stats.kills = stats.kills + 1
        start(b)
      elseif coroutine.status(b.co) == "dead" then
        b.done = true
      end
    end
  end
  if alive == 0 then break end
  rounds = rounds + 1
  if rounds % 20 == 0 then
    keepStocked(tinChest, "tin", 6)
    keepStocked(glassChest, "glass", 6)
    keepStocked(fuelChest, "lava", 8)
  end
  if rounds > 5e6 then
    print("too long")
    for _, b in ipairs(bots) do print(b.id, b.x, b.y, b.z, b.fuel, b.log[#b.log], b.status and b.status.step, b.sel, serialize(b.inv)) end
    os.exit(1)
  end
end

local errors = 0
local function bad(msg)
  errors = errors + 1
  if errors <= 20 then print("BAD: " .. msg) end
end

local placed = { tin = 0, glass = 0 }
local minX, maxX, minZ, maxZ = 1e9, -1e9, 1e9, -1e9
for k, blk in pairs(world) do
  local x, y, z = k:match("^(%-?%d+),(%-?%d+),(%-?%d+)$")
  x, y, z = tonumber(x), tonumber(y), tonumber(z)
  if blk.name == "tin" or blk.name == "glass" then
    placed[blk.name] = placed[blk.name] + 1
    minX, maxX, minZ, maxZ = math.min(minX, x), math.max(maxX, x), math.min(minZ, z), math.max(maxZ, z)
    local want = (y <= 2) and "tin" or "glass"
    if blk.name ~= want then bad(string.format("%s at %d,%d,%d (want %s)", blk.name, x, y, z, want)) end
    if y < 0 or y > 6 then bad("block out of range at " .. k) end
  end
end

local reached, queue = {}, {}
local function push(x, y, z)
  local kk = key(x, y, z)
  if reached[kk] or blockAt(x, y, z) then return end
  if x < -52 or x > 52 or z < -52 or z > 52 or y < 0 or y > 9 then return end
  reached[kk] = true
  queue[#queue + 1] = { x, y, z }
end
push(-52, 0, -52)
local qi = 1
while qi <= #queue do
  local c = queue[qi]; qi = qi + 1
  push(c[1] + 1, c[2], c[3]); push(c[1] - 1, c[2], c[3])
  push(c[1], c[2] + 1, c[3]); push(c[1], c[2] - 1, c[3])
  push(c[1], c[2], c[3] + 1); push(c[1], c[2], c[3] - 1)
end
local interior = 0
for x = -52, 52 do for z = -52, 52 do for y = 0, 9 do
  if not blockAt(x, y, z) and not reached[key(x, y, z)] then interior = interior + 1 end
end end end
for _, p in ipairs({ { 0, 3, 0 }, { 0, 3, -40 }, { 40, 3, 0 }, { 40, 3, -40 }, { 0, 3, -20 }, { -40, 3, 40 } }) do
  if reached[key(p[1], p[2], p[3])] then bad("outside air reaches " .. table.concat(p, ",")) end
end
if interior == 0 then bad("no sealed interior") end

for _, b in ipairs(bots) do
  if not b.status or b.status.phase ~= "done" then bad("bot " .. b.id .. " not done: " .. tostring(b.log[#b.log])) end
  local left = {}
  for s = 1, 16 do if b.inv[s] then left[#left + 1] = b.inv[s].name .. "x" .. b.inv[s].count end end
  print(string.format("bot %d: %d moves, fuel left %d, ends at %d,%d,%d, inventory {%s}", b.id, b.moves, b.fuel, b.x, b.y, b.z, table.concat(left, " ")))
end
print(string.format("placed tin %d, glass %d; footprint x %d..%d z %d..%d (%dx%d); sealed interior air %d",
  placed.tin, placed.glass, minX, maxX, minZ, maxZ, maxX - minX + 1, maxZ - minZ + 1, interior))
print(string.format("seed %d, gps %s, restarts %d, turtle-turtle blocks %d, sim time %.0f s, lava used %d",
  SEED, tostring(USE_GPS), stats.kills, stats.blocked, clock, stats.lavaIn))
if errors > 0 then print(errors .. " problems"); os.exit(1) end
print("OK")
