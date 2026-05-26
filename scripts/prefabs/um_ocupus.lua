local assets =
{
    Asset("ANIM", "anim/ocupus.zip"),
}

SetSharedLootTable( 'um_ocupus_eyetacle',
{
    {'um_ocupus_eyetacle_item',  1.00},
})

local function RemoveAllTentacles(inst) --This is mainly meant to catch any stragglers, usually the boat itself is saved in the tentacles, so it shouldn't miss em
    --TheNet:Announce("toldtoremove")
    if inst.surfacetents then
        for i,v in ipairs(inst.surfacetents) do
            if v and v:IsValid() then
                v:Leave()
            end
        end
    end
    if inst.regulartents then
        for i,v in ipairs(inst.regulartents) do
            if v and v:IsValid() then
                v:Leave()
            end
        end
    end
    if inst.beak and inst.beak:IsValid() then
        inst.beak.boat = nil
        inst.beak:AddTag("notarget")
    end
    inst.boatvictim = nil
end

local function SpawnLoot(inst,x,y,z,item,spoiled)
    local loot = SpawnPrefab(item)
    if not loot then return end
    local offset = FindSwimmableOffset(inst:GetPosition(), math.random() * PI * 2, math.random(1,12))
    if offset then
        x = offset.x + x
        z = offset.z + z
    end
    if spoiled and loot.components.perishable then
        loot.components.perishable:SetPercent(0.33)
    end
    loot.Transform:SetPosition(x,y,z)
    SpawnPrefab("splash_ocean").Transform:GetWorldPosition(x,0,z)
end

local random_loot = {
    blank_map = {num = 1, items = {"messagebottleempty","papyrus"}, counts = {1,1}},
    fresh_barnacles = {num = 2, items = {"barnacle"}, counts = {5}},
    salty_barnacles = {num = 3, items = {"barnacle","saltrock"}, counts = {3,2}},
    sludge = {num = 4, items = {"sludge"}, counts = {4}},
    sludge_gem = {num = 5, items = {"sludge","redgem"}, counts = {2,1}}, 
    spoiled_lure = {num = 6, items = {"fishmeat_small","spoiled_fish","oceanfishinglure_hermit_drowsy"}, counts = {2,1,1},spoiled = true},
    morning_fish = {num = 7, items = {"fishmeat","oceanfishingbobber_oval","oceanfishinglure_spoon_red"}, counts = {1,1,1}},
    heavy_fish = {num = 8, items = {"fishmeat","oceanfishinglure_hermit_heavy"}, counts = {3,1}},
    shark1 = {num = 9, items = {"fishmeat","rockjawleather"}, counts = {4,1}},
    shark2 = {num = 10, items = {"fishmeat","rockjawleather"}, counts = {4,1}}, --AXE Duplicate for the very slight chance increase
    cookiecutters = {num = 11, items = {"monstersmallmeat","cookiecuttershell"}, counts = {4,5}},
    cookiecutters_salty = {num = 12, items = {"monstersmallmeat","cookiecuttershell","saltrock"}, counts = {2,1,5}},
    bumper_boat = {num = 13, items = {"boatpatch","boat_bumper_shell_kit"}, counts = {4,3}},
    not_so_floaty = {num = 14, items = {"flotationcushion","boneshard","spoiled_food"}, counts = {1,2,4}},
    monkey_captain = {num = 15, items = {"meat","monkey_mediumhat","stash_map","oar_monkey"}, counts = {1,1,1,1}},
    monkey_crew = {num = 16, items = {"boards","monkey_smallhat","cave_banana"}, counts = {4,2,3}},
    sail_boat = {num = 17, items = {"boards","rope","silk"}, counts = {8,3,4}},
    turbine_boat = {num = 18, items = {"boards","transistor","mastupgrade_windturbine_item"}, counts = {6,2,1}},
}

local function grab_random_loot()
    local loot_num = math.random(1,18) --AXE need to manually update this number if you add to the table, doing #random_loot doesn't return the length.
    for i,v in pairs(random_loot) do
        if loot_num == v.num then
            return v
        end
    end
end

local function UnpackRandomLoot(inst,x,y,z)
    local loot_table = grab_random_loot()
    if loot_table then
        for i,v in ipairs(loot_table.items) do
            for j = 1,loot_table.counts[i] do
                SpawnLoot(inst,x,y,z,v,loot_table.perishable and true or nil)
            end
        end
    end
end

local function OcupusKilled(inst) --The ocupus sustained enough damage to be killed, likely due to the beak being beaten up
    RemoveAllTentacles(inst)
    if inst.beak then
        inst.beak.retract(inst.beak)
    end
    inst:DoTaskInTime(math.random(3,5),function(inst) --Loot Time
        local boat = inst.boatvictim
        local x,y,z = inst.Transform:GetWorldPosition()
        if inst.beakkilled then --AXE If you broke the beak, you'll get it as a drop
            SpawnLoot(inst,x,y,z,"ocupus_beak")
        end
        for i = 1,4 do
            SpawnLoot(inst,x,y,z,"fishmeat")
        end
        for i = 1,math.random(6,8) do
            SpawnLoot(inst,x,y,z,"boneshard")
        end
        for i = 1,3 do
            UnpackRandomLoot(inst,x,y,z)
        end
        inst:Remove()
    end)
end

local function IsOcean(x,y,z)
    return not TheWorld.Map:IsVisualGroundAtPoint(x,y,z)
end

local function FindStalkingGrounds(inst,alreadyused)
    local x,y,z = inst.Transform:GetWorldPosition()
    local seastacks = TheSim:FindEntities(x,y,z,25,{"seastack"})
    local choice
    for i,v in ipairs(seastacks) do
        local x,y,z = v.Transform:GetWorldPosition()
        if TheWorld.Map:GetTileAtPoint(x, 0, z) == WORLD_TILES.OCEAN_HAZARDOUS or TheWorld.Map:GetTileAtPoint(x, 0, z) == WORLD_TILES.OCEAN_ROUGH and v ~= alreadyused then
            --TheNet:Announce("found spot")
            return v
        end
    end
    if not choice then
        return inst
    end
end

local function FindPointEyeTentacle(inst,x,y,z,rot,stalkinggrounds) --Note that "rot" stands for "rotation" referring to how the submerged eyetacles are spread around a point.
    if not rot then -- If rot is somehow not passed (shouldn't ever happen) then have some dummy values JIC
        rot = math.random(1,5)
    end    
    local oldx,oldy,oldz,oldrot = x,y,z,rot
    rot = 2 * PI * rot/5 
    if oldrot > 5 then -- If we're up to the 5th tentacle looks for an area decently far away, perhaps another seastack.
        local potentialrock = FindStalkingGrounds(inst,stalkinggrounds)
        if potentialrock then --okay, we found a rock that we're not sitting by, put it near this rock please.
            x,y,z = potentialrock.Transform:GetWorldPosition()
            x = x + 10 * math.cos(rot)+ math.random(-2,2)
            z = z + 10 * math.sin(rot) + math.random(-2,2)
        else -- no rocks... sometimes it does happen, just pick an area somewhat near already chosen rock
            local x,y,z = stalkinggrounds.Transform:GetWorldPosition()
            x = x + math.random(-10,10)
            z = z + math.random(-10,10)
        end
    else -- Still not hit the 5th yet, so it's a good idea to just spread 'em out around the already chosen site
        x = x + 10 * math.cos(rot)+ math.random(-2,2)
        z = z + 10 * math.sin(rot) + math.random(-2,2)    
    end
    if IsOcean(x,y,z) then --okay.. just some basic tests here.... are we near a tentacle already? are we in the water?
        return x,y,z --good, now we can finally spawn a SINGULAR tentacle.
    else
        return FindPointEyeTentacle(inst,oldx,oldy,oldz,oldrot+2.5,stalkinggrounds) --yeah something didn't work, the land thing is highly unlikely unless someone spawned the creature on land, should add a remove to the prefab itself if it happens to appear on land (likely via console meddling).
    end 
end

local function AddEyeTentacle(inst,x,y,z,rot,stalkinggrounds) -- Do it one at a time, we want to spread these in a way to give the illusion of a large creature on the bottom of the ocean
    local tent = SpawnPrefab("um_ocupus_eye")
    tent.core = inst
    local homex,homey,homez = FindPointEyeTentacle(inst,x,y,z,rot,stalkinggrounds)
    tent.rot = rot --Idk why I pass the rotation to the tentacle, it doesn't need it, probably depricated. (this is what happens when you drop something for some time then come back.)
    tent.Transform:SetPosition(homex,homey,homez)
    if not inst.undertents then
        inst.undertents = {}
    end
    table.insert(inst.undertents,tent) --Need to keep track of our tentacles, particularly just to tell them to hide if a boat is coming near (you know, preparing for assault)
end

local function Born(inst)
    --TheNet:Announce("born")
    local stalkinggrounds = FindStalkingGrounds(inst)
    local x,y,z = stalkinggrounds.Transform:GetWorldPosition()
    if stalkinggrounds == inst then
        x = x + math.random(-5,5)
        z = z + math.random(-5,5)
    end    
    for i = 1,5+math.random(1,5) do
        AddEyeTentacle(inst,x,y,z,i,stalkinggrounds) --"Stalkinggrounds" just refers to the prefab the ocupus controller prefab is currently working around, be it itself or a rock, it's passed along so that if the ocupus wants to put some tentacles near other rocks it doesn't just choose the same rock over again.
    end
end

local function GetOffset(inst)
    local offset = FindSwimmableOffset(inst.boatvictim:GetPosition(), math.random() * PI * 2, math.random(6,12))
    if offset then
        return offset
    --elseif inst.boatvictim then
        --GetOffset(inst)
    else
        RemoveAllTentacles(inst)
        inst:DoTaskInTime(math.random(10,20),Born)        
    end
end

local function AddEyeTentacle2(inst)
    if inst.boatvictim and inst.boatvictim:IsValid() then
        local tent = SpawnPrefab("um_ocupus_eyetacle")
        tent.core = inst
        local x,y,z = inst.boatvictim.Transform:GetWorldPosition()
        local offset = GetOffset(inst) --For this case, will need to make sure we don't accidentally spawn under a boat, using this nifty function gnarwails use.

        if offset then
            tent.Transform:SetPosition(x + offset.x,y + offset.y,z + offset.z)
            tent.boatvictim = inst.boatvictim
            if not inst.surfacetents then
                inst.surfacetents = {}
            end
            table.insert(inst.surfacetents,tent)
            tent.number = #inst.surfacetents --Number, incase we need to refer to a specific one
            inst.eyetentcount = #inst.surfacetents --Total
        end
    end
end

local function EyeTentKilled(inst)
    inst.availableeyes = inst.availableeyes - 1
    --TheNet:Announce(inst.availableeyes)
    --TheNet:Announce(inst.availableeyes/7)
    local newdrag = TUNING.BOAT.ANCHOR.BASIC.ANCHOR_DRAG*(inst.availableeyes/7)
    --TheNet:Announce(newdrag)
    inst.components.boatdrag.drag = newdrag
    if inst.availableeyes == 0 then
        newdrag = 0
        if inst.boatvictim and inst.boatvictim:IsValid() then
            inst.boatvictim.components.boatphysics:RemoveBoatDrag(inst)
        end
        OcupusKilled(inst)
    end
end

local function SpawnTentacle(inst)
    local tent = SpawnPrefab("um_ocupus_tentacle")
    tent.core = inst
    local x,y,z = inst.boatvictim.Transform:GetWorldPosition()
    local offset = GetOffset(inst) --For this case, will need to make sure we don't accidentally spawn under a boat, using this nifty function gnarwails use.
    if not inst.regulartents then
        inst.regulartents = {}
    end    
    table.insert(inst.regulartents,tent)
    tent.Transform:SetPosition(x + offset.x,y + offset.y,z + offset.z)
    tent.boat = inst.boatvictim
end

local function PullOut(inst)
    RemoveAllTentacles(inst)
    if inst.Evaluate then
        inst.Evaluate:Cancel()
        inst.Evaluate = nil
    end
    inst:DoTaskInTime(math.random(10,20),Born)
end

local function Evaluate(inst) -- This is the psuedo brain for the ocupus, this triggers while it's attacking a boat on an interval. It spawns more tentacles, checks to see if the boat's still there, and adjusts the beak.
    --TheNet:Announce("evaluating")
    if inst.Evaluate then
        inst.Evaluate:Cancel()
        inst.Evaluate = nil
    end
    if inst.boatvictim and inst.boatvictim:IsValid() then
        --TheNet:Announce("Boat was found.")
        local x,y,z = inst.boatvictim.Transform:GetWorldPosition()
        local tentacles = TheSim:FindEntities(x,y,z,20,{"um_ocupus_tentacle"})
        local players = TheSim:FindEntities(x,y,z,20,{"player"})
        local playerval,tentaclesval
        if not players then
            playerval = 0
        else
            playerval = #players
        end
        if not tentacles then
            tentaclesval = 0
        else
            tentaclesval = #tentacles
        end
        if tentaclesval < 3 then
            SpawnTentacle(inst)
            --SpawnTentacle(inst)
        else
            if math.random() > 0.6 then --Don't always proc the tentacle to spawn, especially if there already is one
                SpawnTentacle(inst)
            end
        end
        if inst.beak and inst.beak:IsValid() then --It shouldn't always remove the beak...
            if math.random() > 0.5  then
                if inst.beak.components.health then
                    inst.beakhealth = inst.beak.components.health:GetPercent()
                end
                inst.beak.retract(inst.beak)
            end
        elseif not inst.beakkilled then
            inst.beak = SpawnPrefab("um_ocupus_beak")
            inst.beak.ocupus = inst
            if inst.availableeyes < 3 then --less than three eyes? we need to start yelling! A LOT!
                inst.beak.screechmod = 0.5
            end
            if inst.beakhealth then
                inst.beak.components.health:SetPercent(inst.beakhealth)
            end
            -- Also damage the boat we just pierced.
            if inst.boatvictim ~= nil and inst.boatvictim:IsValid()
                    and inst.boatvictim.components.hullhealth ~= nil and inst.boatvictim.components.health ~= nil then
                inst.boatvictim.components.health:DoDelta(-TUNING.GNARWAIL.HORN_BOAT_DAMAGE)
            end

            inst.beak.SoundEmitter:PlaySoundWithParams("turnoftides/common/together/boat/damage", {intensity=0.8})
            inst.beak.Transform:SetPosition(x+0.1*math.random(-20,20),0,z+0.1*math.random(-20,20)) -- Somewhat random in where the beak appears at within the boat, but don't push players into the water... rip wormiest.
        end
        inst.evaltime = 30
        if inst.availableeyes < 6 then
            inst.evaltime = 10 + math.random(-2,2)
        elseif inst.availableeyes < 3 then
            inst.evaltime = 4 + math.random(-1,3)
        end
        inst.Evaluate = inst:DoTaskInTime(inst.evaltime, Evaluate)
    else
        PullOut(inst)
    end
end

local function BoatCheck(inst)
    if not inst.boatvictim or (inst.boatvictim and inst.boatvictim.components.health and inst.boatvictim.components.health:IsDead()) then
        inst.boatcheck:Cancel()
        inst.boatcheck = nil
        PullOut(inst)
    end
end

local function WarnThePassengers(inst)
    local x,y,z = inst.boatvictim.Transform:GetWorldPosition()
    local players = TheSim:FindEntities(x,y,z,4,{"player"})
    for i,v in ipairs(players) do
        if v.components.talker and v:HasTag("player") then
            v:DoTaskInTime(math.random(1,2),function(v)
                v.components.talker:Say(GetString(v, "ANNOUNCE_OCEAN_SILHOUETTE_INCOMING"))
            end)
        end
    end
end

local function EngageBoat(inst)
    if not (inst.boatvictim and inst.boatvictim:IsValid()) then return end
    inst.components.boatdrag.drag = TUNING.BOAT.ANCHOR.BASIC.ANCHOR_DRAG
    inst.boatvictim.components.boatphysics:AddBoatDrag(inst)
    inst.totaleyetents = 0
    local x,y,z = inst.boatvictim.Transform:GetWorldPosition()
    for i = 1,inst.availableeyes do
        inst:DoTaskInTime(math.random(1,5),AddEyeTentacle2)
    end
    inst:DoTaskInTime(15,Evaluate)
    inst.boatcheck = inst:DoPeriodicTask(1,BoatCheck)
    WarnThePassengers(inst)
end

local function BoatVictimSpotted(inst,boat)
    if not (inst.boatvictim and inst.boatvictim:IsValid()) then
        inst.boatvictim = boat
        for i,tent in ipairs(inst.undertents) do
            tent.Hide(tent)
        end
        
        inst:DoTaskInTime(3, EngageBoat)
    end
end

local function Bubbles(inst)
    if not inst:IsAsleep() and TheWorld.state.isday then
        local x,y,z = inst.Transform:GetWorldPosition()
        SpawnPrefab("crab_king_bubble1").Transform:SetPosition(x + math.random(-10,10),y,z+math.random(-10,10))
        inst:DoTaskInTime(math.random(1,6),function(inst)
            local x,y,z = inst.Transform:GetWorldPosition()
            SpawnPrefab("crab_king_bubble2").Transform:SetPosition(x + math.random(-10,10),y,z+math.random(-10,10))
        end)
        inst:DoTaskInTime(math.random(5,9),function(inst)
            local x,y,z = inst.Transform:GetWorldPosition()
            SpawnPrefab("crab_king_bubble3").Transform:SetPosition(x + math.random(-10,10),y,z+math.random(-10,10))
        end)        
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst, 0.80, 2, 0.75)

    inst.Transform:SetFourFaced()
    inst.AnimState:SetBank("um_ocupus")
    inst.AnimState:SetBuild("ocupus")
    inst.AnimState:PlayAnimation("eyetacle_idle_down", true)

    inst:AddTag("noattack")

    MakeInventoryFloatable(inst, "med", 0.1, {0.4, 0.4, 0.4})

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    --inst:SetBrain(brain)
    
    inst:AddComponent("knownlocations")
    
    inst:AddTag("um_ocupus_core")
    
    inst:SetStateGraph("SGum_ocupus_eyetacle")

    inst:AddComponent("sanityaura")

    inst:AddComponent("inspectable")

    inst:AddComponent("combat")
    inst:AddComponent("boatdrag")
    inst.components.boatdrag.drag = TUNING.BOAT.ANCHOR.BASIC.ANCHOR_DRAG --Total Drag without killing eyes

    ------------------
    inst.EyeTentKilled = EyeTentKilled
    inst.notifycore = BoatVictimSpotted
    inst:DoTaskInTime(0, Born)
    inst.AddEyeTentacle2 = AddEyeTentacle2

    inst:Hide()
    
    inst.OnSave = function(inst,data)
        if data and inst.availableeyes then
            if inst.availableeyes then
                data.availableeyes = inst.availableeyes
            end
            --[[if inst.boatvictim then
                data.engagedboat = inst.boatvictim
            end        ]]
        end
    end
    inst.OnLoad = function(inst,data)
        if data then
            if data.availableeyes then
                inst.availableeyes = data.availableeyes
            end
            --[[if data.boatvictim then
                inst.boatvictim = data.boatvictim
            end]]
        end
    end
    
    inst:DoTaskInTime(0,function(inst) --Pst load engagements
        if not inst.availableeyes then
            inst.availableeyes = 7 
        end
        --[[if inst.boatvictim then
            EngageBoat(inst,inst.boatvictim)
        end]]
    end)
    inst.PullOut = PullOut
    inst:DoPeriodicTask(10,Bubbles)
    return inst
end

return Prefab("um_ocupus", fn, assets)