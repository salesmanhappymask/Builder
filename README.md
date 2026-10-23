# Hub Builder

Four wireless Dizzy Turtles (ComputerCraft 1.63 with MoarPeripherals) build a sealed, hollow base
from three Ender Chests stacked in the middle of the site.

The base is a square hub with four straight hallways leading out to four big rooms, and each pair of
neighbouring rooms is joined by an L-shaped hallway around the corner. The whole thing is
4-way symmetric and fits in a 99 x 99 area.

- Floor, and the bottom 2 layers of every wall: Tin Decoration Block (590:4)
- Wall layers 3 to 5 and the whole roof: Thickened Glass (4095)
- Inside height: 5 blocks. Outside height: 7 blocks (floor + 5 + roof)
- Hub: 15 x 15. Rooms: 31 x 19. All hallways: 5 wide outside, 3 wide inside
- Fully sealed. Checked by the simulator with a flood fill from the outside.

## Map

Top down, north is up, each text row is two blocks. `#` wall, `.` floor under open air inside.

```
                                  ###############################
                                  #.............................#
                                  #.............................#
       ############################.............................############################
       #...................................................................................#
       #...########################.............................########################...#
       #...#                      #.............................#                      #...#
       #...#                      #.............................#                      #...#
       #...#                      #.............................#                      #...#
       #...#                      ##############...##############                      #...#
       #...#                                   #...#                                   #...#
       #...#                                   #...#                                   #...#
       #...#                                   #...#                                   #...#
       #...#                                   #...#                                   #...#
       #...#                                   #...#                                   #...#
       #...#                                   #...#                                   #...#
       #...#                                   #...#                                   #...#
########...########                            #...#                            ########...########
#.................#                            #...#                            #.................#
#.................#                            #...#                            #.................#
#.................#                            #...#                            #.................#
#.................#                       ######...######                       #.................#
#.................#                       #.............#                       #.................#
#.................#########################.............#########################.................#
#.................................................................................................#
#.................#########################.............#########################.................#
#.................#                       #.............#                       #.................#
#.................#                       #.............#                       #.................#
#.................#                       ######...######                       #.................#
#.................#                            #...#                            #.................#
#.................#                            #...#                            #.................#
#.................#                            #...#                            #.................#
########...########                            #...#                            ########...########
       #...#                                   #...#                                   #...#
       #...#                                   #...#                                   #...#
       #...#                                   #...#                                   #...#
       #...#                                   #...#                                   #...#
       #...#                                   #...#                                   #...#
       #...#                                   #...#                                   #...#
       #...#                                   #...#                                   #...#
       #...#                      ##############...##############                      #...#
       #...#                      #.............................#                      #...#
       #...#                      #.............................#                      #...#
       #...########################.............................########################...#
       #...................................................................................#
       ############################.............................############################
                                  #.............................#
                                  #.............................#
                                  #.............................#
                                  ###############################
```

## What you need

| | Whole build | Per turtle |
|---|---|---|
| Tin Decoration Block | 5,956 (93.1 stacks) | 1,489 |
| Thickened Glass | 6,925 (108.2 stacks) | 1,731 (the east turtle places 1 more) |
| Lava buckets | about 20 to 28 | about 5 to 7 |

Each turtle loads whole stacks, so it ends the build with up to 63 spare glass on board. Run
`hubbuild count` on a turtle to print these numbers.

## Setting up

1. **Pick a flat, clear site.** The turtles have a modem and a compass, so neither side is free for a
   pickaxe. They can't dig, so the ground has to be flat and everything from ground level up to 8
   blocks high has to be empty across the whole 99 x 99 area. The floor is laid **on top of** the
   ground.
2. **Place the Ender Chests in the middle**, stacked: tin chest on the ground, glass chest on top of
   it, fuel chest on top of that. The tin chest also takes the place of the floor block in the very
   middle, so the floor has no hole there.
3. **Fill the chests.** Keep each chest pure: the tin chest only tin, the glass chest only glass, the
   fuel chest only lava buckets. CC 1.63 turtles can't read item IDs, so a turtle knows what a block
   is by which chest it came from. The turtles put their empty buckets back into the fuel chest, so
   whatever refills it should turn empty buckets back into lava buckets or take them out.
4. **Place the four turtles** on the ground next to the tin chest, one on each side, each facing the
   chest. It doesn't matter which turtle goes where: each one asks its compass which way it faces and
   works out from that which quarter of the base is its job.
5. **Fuel.** A turtle needs at least 10 fuel to start. Give each turtle one lava bucket in any slot
   (it burns it and returns the bucket to the fuel chest). Otherwise keep their inventories empty.
6. **Copy `hubbuild` onto each turtle** and run `hubbuild`. The turtles don't need to start at the
   same time.

To download it with the HTTP API turned on, type `lua` on the turtle and run:

```lua
local r = http.get("https://raw.githubusercontent.com/salesmanhappymask/Builder/claude/epic-gauss-p8gmkp/hubbuild") local f = fs.open("hubbuild", "w") f.write(r.readAll()) f.close() r.close()
```

If old Java on the server can't reach GitHub, copy the file over on a floppy disk instead, or use
pastebin.

**Chunk loading:** turtles stop working when their chunk unloads, and MoarPeripherals has no chunk
loader. The rooms are 49 blocks from the middle, so stay near the hub while they work, or use chunk
loaders from another mod covering the whole 99 x 99 area. A turtle in a loaded chunk that tries to
move into an unloaded one waits and says so ("Chunk not loaded?") until it can move again.

## How the build goes

Each turtle owns one quarter of the base, turned 90 degrees from the next one, so all four do exactly
the same amount of work. Every move a turtle makes stays inside its own quarter, so they never get in
each other's way.

1. Floor, then wall layer 1, then wall layer 2, all tin, each placed from one block above.
2. The turtle hands its leftover tin back to the tin chest, moves up one, and fills the spot it
   started on. That seals the floor next to the chest. After this it can only reach the glass chest
   and the fuel chest, which are at the same height as the inside of the base.
3. Glass wall layers 3, 4 and 5.
4. The roof, placed from above. To restock, a turtle flies back to the hub and drops down through the
   one roof spot it has kept open above where it started.
5. The east turtle caps the roof spot above the chest stack. Then each turtle seals its own roof spot
   and stops, parked on the roof above the hub.

Before every trip a turtle checks that it has enough fuel to get there and back. It tops up from the
fuel chest whenever it's below what the rest of its job needs.

## Restarts and GPS

The turtle saves its progress before every move and installs a `startup` file, so it carries on by
itself after a reboot, a chunk reload or a server restart. When it starts from `startup` it waits 5
seconds first. The progress file is written to a new file and then swapped in, so a turtle that
shuts down in the middle of a save still has the last good copy. If the program crashes, the turtle
shows the error, writes it to its log, waits 30 seconds and reboots to try again (hold Ctrl+T to stop
it).

- **Facing** always comes from the Dizzy Turtle's compass (`getFacing()`), so it can never be lost.
- **Position** comes from counting moves, like the SkylineCity turtles: it saves the move it's about to
  make together with its fuel level, and after a reboot fuel that's one lower means the move happened.
- **GPS** is only used as a check. If GPS disagrees with the turtle's count after a reboot, the
  turtle keeps going by its count and writes the difference in its log, which usually means a GPS
  host was set up with the wrong coordinates.

Keep the GPS computers above the build, at least 9 blocks over the ground.

If a turtle is stopped and its screen shows no error, open it (right click). Opening a computer
that's switched off starts it, and it carries on from `startup`.

### Recovering a turtle that lost its progress

Versions before this one could lose their progress file if the chunk unloaded during a save. They'd
then show "Put me right next to the tin Ender Chest" and stop. To get one going again:

1. Download the new `hubbuild` onto it.
2. Take everything out of its inventory and put the blocks back in their chests.
3. Pick it up and put it back on **the same side** of the chests it started on, facing them:
   - If its start spot is still open (it hasn't finished the tin yet): on the ground, facing the tin
     chest.
   - If its start spot is filled with tin: on top of that block, facing the glass chest.
4. Run `hubbuild recover`. It reads its log to find the last layer it finished, tells you, and asks
   you to confirm. You can type a layer number instead (0 floor, 1 and 2 tin walls, 3 to 5 glass
   walls, 6 roof). It redoes that whole layer, skipping every spot that already has a block.

Don't move a turtle by hand while it runs. To start one over: `hubbuild reset`, put it back next to
the tin chest facing it, and run `hubbuild` again. It skips any spot that already has a block in it.

## Commands

| Command | What it does |
|---|---|
| `hubbuild` | Starts the build, or carries on after a reboot |
| `hubbuild status` | Which turtle this is, how far along it is, where it is, its fuel |
| `hubbuild count` | Blocks needed per turtle and for the whole build |
| `hubbuild log` | The last lines of this turtle's log |
| `hubbuild recover` | Gets a turtle going again after it lost its progress (see above) |
| `hubbuild reset` | Forgets this turtle's progress |

Each turtle keeps a log in `hubbuild.log`.

## Watching the build

`hubmon` runs on any computer with a wireless modem (and an optional monitor next to it). It shows
every turtle's progress, layer, fuel, position and latest message. A turtle that hasn't been heard
from for a minute is marked SILENT, and one whose program crashed is marked CRASHED. Press `p` to pause all turtles
(each stops after its current block), `r` to resume, `q` to quit.

The turtles send their status on rednet protocol `hubbuild` every 15 seconds and whenever something
happens, like waiting for blocks or a finished layer.

## When something goes wrong

- **"Waiting for ... in its Ender Chest"**: a chest is empty. Refill it and the turtle carries on.
- **"Something is in my way"**: there's a block where the turtle wants to fly, and it can't dig. Clear
  it.
- **"Can't place at ..."**: usually a mob standing in the spot. The turtle keeps trying.
- **"A block that isn't tin/glass is already at ..."**: something solid was already in a spot the
  turtle wanted to fill (uneven ground, for example). The turtle leaves it, since it still seals the
  base, and writes it in the log.

## Changing the shape

The sizes are at the top of `hubbuild`: `HUB` (half the hub's width), `HALL` (half a hallway's
width), `ROOM_HALF`, `ROOM_IN`, `ROOM_OUT` (the rooms' half length and how far they are from the middle),
`LINK` (where the corner hallways run), `HEIGHT` (inside height) and `TIN_WALLS` (how many wall
layers are tin). Use the same file on all four turtles, keep `ROOM_OUT` at 49 or less to stay inside
100 x 100, and run the simulator after any change.

## Simulator

`sim/sim.lua` runs all four turtles against a fake CC 1.63 world: the Ender Chests get refilled now
and then (with an outage in the middle), lava pumps refill the returned buckets, and turtles are killed
at random moments (including in the middle of saving) and rebooted through their `startup` file.
`badgps` makes GPS give wrong answers half the time. `recover` wipes two turtles' progress partway
through and brings them back with `hubbuild recover`. At the end it checks every block's material, that the footprint fits
in 99 x 99, that no air from outside reaches the inside, and that every turtle finished.

```
lua5.1 sim/sim.lua hubbuild [seed] [restart chance per action] [nogps|badgps|recover]
lua5.1 sim/sim.lua hubbuild 5 0.005 nogps
```

Based on the ideas in [SkylineCity-CC](https://github.com/landonracer109/SkylineCity-CC): state saved
before every move, the fuel check to recover a move lost in a restart, Ender Chest restocking, and
rednet status reports.
