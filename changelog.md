# "On the Rocks!" v1.6 Beta v5.0.0 "Megapatch"

## New
### Grotto
- Added Maned Reeds
> Populate the lunar grotto, give cut grass and reeds, must be chopped.
- Added Gros Tentacle
> Appear in several regions of the grotto, are universally aggressive and throw tentacle darts/spines at entities that get too close. Tentacle darts pop into a small acid cloud that spoils things. Drops tentacle darts and gros peel (lunar tentacle spot).
- Added Tentacle Dart
> May be thrown as a weapon, may be thrown twice the distance away in comparison to normal throwables.
- Added Gros Peel, Transgrosgas Grenade and Amusement Pack
> Gros peels may be made into transgrosgas grenades at the lunar alter. These may be thrown slightly further than normal explosives. 
> They explode into a massive blast that mutates, does more damage to shadows, less damage to lunar aligned.
> Gros Peels and make the Amusement pack - a backpack that empowers gem amulets you slot into it, and lets you use them while wearing the pack.
- Added Moon Mushroom.
> Generates like normal red/green/blue mushrooms in the Grotto.
- Added new lunar mutateables - gros tentacle, maned reeds, moon mushroom.
⠀
### Hooded Forest
- Added Ferned Fox Hole
⠀
### Other
- Added Guano Rain
> Accumulates more guano rocks in the Guano biome.
> Wormwood likes this.
- Added Slimestone
> Renovated the lichen area of the entrance to the ruins, before the pawn area.
> Added many slimestone mounds and monkeys which guard them. They sometimes have precious gems.
> Slimestone falls from the ceiling if there is an earthquake during the nightmare cycle. This is also considered offscreen.
- Added Sinkhole Mounds
> Source of Mossy Geodes.
> House random gremlins inside. They may not be happy if you destroy their home.
> Reappear in the same area after some time.
- Added Pyre Mask.
> Spoils, inflicts user with pyre toxin, effective against nightmare fog and other gas-related problems.
- Maxwell's Veteran Curse:
> 50% of attack damage taken is applied as maximum health loss.
- Added and updated several map icons:
> Rain Coat
> Silk Sack
> Boomberry Plant
> Floral Vest
> Summer Frest
> Magma Caves Entrance Boulder
> Lunar Grotto Entrance Boulder
> Rain Coat
> Rimeweed
> Skull Chest
> Sludge Sack
> Snaildrake Hole
> Puffy Vest
> Breezy Vest
> Fox Hole
> Manny
> Maned Reeds
> Winona's Toolbox
> Swiss Sponge
> Sludge Stack (Corked and Uncorked)
> Tar Suit (IA)
> Life Jacket (IA)
> (Scaly) Snakeskin Jacket (IA + HAM)
> Windbreaker (IA)
> Blubber Suit (IA)

### Night Terrors
- Added sanity tiering system to night terrors
⠀
### Wormwood Skilltree Rework: New Skills
- Sympathetic Bloomer
> A wormwood in bloom near mushtrees or cactus makes them bloom too for a while.
- Flytrap
> Wormwood can catch bugs and spores with his hands.
- Equivalent Exchange 
> Wormwood can transmute seeds to other seeds.
- Resilient Crops I 
> Wormwood's crops cannot be stressed by weeds, debris, or rotting neighbor crops.
- Resilient Crops II 
> Wormwood's >wild< crops automatically tend themselves.
- Resilient Crops III 
> Wormwood's >wild< crops cannot rot, but instead will become extremely unhappy.
- Prick Adept 
> Wormwood can pick prickly things and pass through the thicket without a Bramble Husk.
- Bramble burst 
> Bramble-husk-type armors trigger a second time after being attacked, after a delay, when used by Wormwood.
⠀
### Wormwood Skilltree Rework: Other
- All crafting skills are now lumped into "Originator", which lets you craft any of them.
- All mushroom skills, but mooncap-one, are in "Mushroom Madness". Will also allow crafting mushtrees.
- All lunar ally crafting skills are lumped into "Mutator Novice".
-# NOTE - Skills are also reorganized.
⠀
### Gemology
- Geode Fruit now has a chance to yield Cracked Gemology Gems.
- Added a new, earlier-game Gem Magnifier, crafted at a Shadow Manipulator.
- Gemology Geodes are now hammerable instead of mineable.
- Gemology Pouch now uses the gem slot background, for higher visual clarity.
- Unknown gemology gems now have their color as well, e.g. "Strange Orange Gem"
- Renamed Gem Magnifier to Ancient Gem Magnifier.
- Increased Ancient Gem Magnifier uses to 100.
⠀
### Gemology: Gem Upgrading
- You may now upgrade your gemology gems (with some luck) by trading them with the following creatures. 
- You cannot get to a Flawless version without trading to the correct one!
- If you lose a gem, you gain some benefit for its loss.
- Sometimes trading the correct gem to a trader will yield a pure version, though most only with T3.
```
[- Color - Creature - On Destroyed - Information/Notes]
- Red - Snaildrake - Snapalm - Will become neutral to players after being traded with.
- Green - Slurtle - Slurtle Slime - Will no longer try to steal rocks after being traded with.
- Orange - Antlion - Desert Stone - None
- Pale - Rock Lobster - Friendship - None
- Blue - Abominamole - None - Will seek and devour blue gems, ice, and snow, must be killed to possibly get an upgraded one, increase your chances by feeding it more - you can hypothetically make this one guaranteed. Abominamoles become stronger when eating cold things.
```
⠀
## Changes
### Grotto
- Floodwater now has visual ripples underneath entities that are wading through it.
- The player now wades through the floodwater.
- Items that sink will no longer sink in floodwater.
- Floodwater detects if a player teleports onto it via wortox teleportation or lazy explorer.
- Burrowing creatures - moles and eels - produce bubbles underwater while in floodwater.
- Increased the size of the major flooded portion of the grotto, reduced the amount of natural light there.
- All worm waves will be populated with eels in the lunar grotto.
- IA Body Slot rain equipment now works for protecting against Floodwater.
- Changed Floodwater enter VFX
- Added floodwater waterfalls.
- Floodwater tiles now are animated.
- Changed floodwater tile texture.

### Magma Caves
- Magma caves are now as hot as the fumarole region.
- Depths Vipers:
> Reduced their numbers.
> They fear pyre nettles and will try to avoid them.
> All worm waves will be populated with vipers in the magma caves.
- Capsidragon:
> Will retreat home when harmed (33% health left)
> Has slow regeneration so they don't stay home forever
> Will breathe cold fire after eating enough ghost peppers, once, then regular fire again till they eat more ghost peppers.
> Will use pound attack more often.
> Capsidragon will prepare to breathe fire further from their target, instead of getting within melee distance.
- Dusk caps emit miasma during the nightmare cycle - no more shadow spores.
- Fumarole will always emit miasma, regardless of rift state.
- Worldgen changes have resulted in the gemology forge being placed more often in the middle of the magma biome.
- Gemology Forge has a new setpiece.
- Magma caves now have a color cube.
⠀
### Hooded Forest
- A majority of entities are affected by the thicket now.
> Detection of "being in the thicket" is done on the side of things that move instead of on the side of all individual loaded thickets.
- Aphids will appear less often, but when they do, they will appear in a mob. This mob will be larger when the world gets older.
- Aphids are significantly faster.
- Aphids are satisfied from eating the thicket for longer.
⠀
### Other
- Flame burster now allows some cold items as ammo, and will shoot cold-fire instead when used.
- Flame burster now allows dried fire nettles as ammo.
- Fire hounds now have a special firepoof attack they use every once in a while.
- Ice hounds now have a special shortrange ice wall attack they use every once in a while.
- Fire/Ice hounds drop gems more often than in vanilla.
- Magma hounds now use a Capsidragon-like flamethrower attack.
- Changed Ocupus loot table.
- Ocupus eyes now have water ripples.
- Characters now comment as their boat is being attacked by an Ocupus.
- Mother Goose and Wilting Dragonfly is now affected by the hostile flare.
> Moonmaw is too, but it means timing the spawn on a full moon. You can tell how close she is by checking with Plaunt Manny.
- Tentacles are repopulated every spring in the surface and in the caves - they will be placed where there is marsh turf and no detected significant base.
> Same goes for Gros Tentacles, though with floodwater.
- Snaildrakes and Magma Sludge now provides warmth.
- Snaildrakes can no longer get panicked from fire.
- Increased Magma Sludge damage radius to 3 units (3/4 of a tile)
- Magma sludge deployed by the snaildrake basin lasts significantly longer. (1 minute from 15 seconds)
- Added new Moonmaw art.
- Zaspberry (and related) Effects scale with quality (parfait > normal > lesser)
- Zaspberry buff now shocks attackers.
- Hooded Widow waits for a longer period of time before deciding to shake her tree when she passes the 3,6,9k health triggers. 8 seconds instead of 5 seconds.
- Hooded Widow gains 250 health from spiders instead of 300.
- Hooded Widow no longer causes debris to fall from trees whenever she shakes them. It's just spiders.
- Otter cocoon will always have a heavy fish.
- Pigmen performing the charge attack do double damage at the end of the charge, and no longer perform the additional standard attack.
- Wilting Dragonfly will sleep for 480 seconds instead of 240 seconds when satisfied with ash.
- Abominamoles have 250 instead of 350 health.
- Klaus drops the Krampus sack again if he dies while enraged. Remember that he will recover all health when he enrages. --I HATE THIS!!
- Chess Junk now has a 1/3 chance to awaken instead of 1/10.
- Snaildrakes now have a 50% chance to drop their items instead of 75%.
- Smolder spore detection range reduced to 8 tiles from 16.
- Alpha lightning goats release one fewer electric rings before stopping their special attack.
- Leafy wing hat is now named Elated Helm.
- Elated helm now spoils in 6 days instead of 4.
- Desert Goggles require a blueprint from the oasis like vanilla again. Fashion goggles do not.
- Bear traps have a lower-to-the-ground arc when thrown.
- Beefalo brush provides more obedience and domestication.
- Watermelon lantern is now lost tech and may only be learned by performing an easter egg.
- Rime husk now freezes for 1 instead of 3. (Ice stave hits are 1).
- Nerfed Wortox Steals - significantly less likely to get a krampus sack or pan flute from krampus.
- Thulecite club now uses the vanilla system for spawning tentacles, so luck may affect it in UM.
- Fire nettles now rot into ash.
- Boomberry tart is now Warly only.
- Tuned gemology mushtrees spawn chances.
- Mushtree Petrification Disasters are of shorter range for blue mushrooms.
- Rice is no longer required on worldgen, making worldgen restart less.
- Seawreath makes you wet and has 60 summer insulation, similar to the fashion melon.
- Strawhat rain protection increased from 20% to 35%
- Friendly Viperlings now remain for 4 minutes, instead of 60 seconds.
- You can now get multiple Friendly Viperlings by any source of them; however, you can only have 6 Friendly Viperlings at once, if you try spawning more than 6, the Friendly Viperling with less amount of time will despawn.

## Fixes
- Fixed Deerclops's timer not starting.
- Fixed Heat waves's timer not starting.
- Fixed Worldgen throwing Ancient Guardian into the void (Labyrinth generating with segments not connected to the central landmass).
- Shadow Goo now removes itself after some time. As soon as rain starts, the timer will be cut in half.
- Shadow Goo will no longer be placed if there's already shadow goo where it is. (It won't spawn a billion of itself in the AG fight).
- Glass Geodes should break each other.
- Fixed Portable Raft crashing the game when it's destroyed by the Giant Whirlpool.
- Mushgnomes now spawn in the lunar grotto again.
- Fixed bugged Capsidragon fire breath animations.
- Fixed positioning issue with the night terror swirl indicating the nightmare fog's effect on your mind. Works with combined status. (Thanks for the suggestions Summerrr!!!!111)
- Fixed Night Terror music continuing after the Night Terror ends.
- Fixed Lunar Bees not showing their fire.
- Hooded widow will now no longer leap away when trying to leap to her cocoons.
- Fixed lunarmelodist regen being lost on shard change.
- Rimeweeds now respect the "Start Date for Winter weather" config.
- Snaildrakes panic when haunted again.
- Fixed an issue with Wixie being able to kill Butterflies with her Slingshot shove.
- Fixed Ancient Hooded Forest turf placing Flood Water.
- Fixed Telelocator Staff not draining durability when causing mini earthquakes.
- Implemented missing art and recipes for new Magma Caves and Hooded Forest turf items.
- Fixed Boat Bottle boat VFX sort order.
- Updated Telelocator Focus recipe description change.
- Fixed battle songs losing lunar melodist effects on shard change and world load.
- Fixed an issue with Boulder Crabs "unfreezing" themselves when their boulder is mined and attempted to fix an issue with them walking.
⠀
## Removed
- Removed old deprecated Pyre Nettles config, updated Heat Waves config description.

## Technical
- Added particle tile system from IA. Huge credits to Half!
- Added un-implemented magma tiles. Maybe used later, maybe not.