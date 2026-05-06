
local assets=
{
	Asset("ANIM", "anim/um_ghost_pepper.zip"),
	Asset("ANIM", "anim/um_ghost_pepper_item.zip"),
	Asset("ATLAS", "images/inventoryimages/um_ghost_pepper_item.xml"),
	Asset("IMAGE", "images/inventoryimages/um_ghost_pepper_item.tex"),
	
    Asset("IMAGE", "images/map_icons/um_ghost_pepper.tex"),
    Asset("ATLAS", "images/map_icons/um_ghost_pepper.xml"),
}

local function placegoffgrids(inst, radiusMax, prefab,tags)
    local x,y,z = inst.Transform:GetWorldPosition()
    local offgrid = false
    local inc = 1
    while offgrid == false do

        if not radiusMax then 
        	radiusMax = 12
        end
        local rad = math.random()*radiusMax
        local xdiff = math.random()*rad
        local ydiff = math.sqrt( (rad*rad) - (xdiff*xdiff))

        if math.random() > 0.5 then
        	xdiff= -xdiff
        end

        if math.random() > 0.5 then
        	ydiff= -ydiff
        end
        x = x+ xdiff
        z = z+ ydiff

        local ents = TheSim:FindEntities(x,y,z, 1, tags)
        local test = true
        for i,ent in ipairs(ents) do
            local entx,enty,entz = ent.Transform:GetWorldPosition()
           -- print("checing round x:",round(x),round(entx),"z:", round(z), round(entz),"diff:",round(math.abs(entx-x)),round( math.abs(entz-z)) )
            if round(x) == round(entx) or round(z) == round(entz) or ( math.abs(round(entx-x)) == math.abs(round(entz-z)) )  then
                test = false
         --       print("test fail")
                break
            end
        end
        
        offgrid = test
        inc = inc +1 
    end

    local tile = GetWorld().Map:GetTileAtPoint(x,y,z)
    if  tile == WORLD_TILES.DEEPRAINFOREST then
    	local plant = SpawnPrefab(prefab)
    	plant.Transform:SetPosition(x,y,z) 
    	plant.spawnpatch = inst
    	return true
	end
	return false
end

local function spawnitem(inst,prefab)
	local rad = 14
	if prefab == "grabbing_vine" then
		rad = 12
	end
	placegoffgrids(inst, rad, prefab,{"hangingvine"})
end

local function spawnvines(inst)
	inst.spawnedchildren = true
    for i=1,math.random(8,16),1 do
        spawnitem(inst,"hanging_vine")
    end	

    for i=1,math.random(6,9),1 do
    	spawnitem(inst,"grabbing_vine")
    end	   
end

local function spawnNewVine(inst,prefab)
	if not inst.spawntasks then
		inst.spawntasks = {}
	end
	local spawntime = TUNING.TOTAL_DAY_TIME*2 + (TUNING.TOTAL_DAY_TIME*math.random())
	local newtask = {}
    inst.spawntasks[newtask] = newtask
	newtask.prefab = prefab
    newtask.task, newtask.taskinfo = inst:ResumeTask(spawntime,
        function()
            spawnitem(inst,newtask.prefab)
            inst.spawntasks[newtask] = nil
        end)
    inst.spawntasks[newtask] = newtask
end

local function onsave(inst, data)
    data.spawnedchildren = inst.spawnedchildren
    if inst.spawntasks then
    	data.spawntasks= {}
    	for i,oldtask in pairs(inst.spawntasks)do
            local test = inst:DoTaskInTime(5,function()end)
            dumptable(test,1,1)

    		local newtask = {}
    		newtask.prefab = oldtask.prefab
    		newtask.time = inst:TimeRemainingInTask(oldtask.taskinfo)
            table.insert(data.spawntasks,newtask)
    	end
    end
end

local function onload(inst, data)
    if data then
        if data.spawnedchildren then
        	inst.spawnedchildren = true
        end      
        if data.spawntasks then
        	inst.spawntasks = {}
        	for i,oldtask in ipairs(data.spawntasks)do
        		local newtask = {}
                inst.spawntasks[newtask] = newtask  
        		newtask.prefab = oldtask.prefab
                newtask.task, newtask.taskinfo = inst:ResumeTask(oldtask.time,
					function()
						spawnitem(inst,oldtask.prefab) 
                        inst.spawntasks[newtask] = nil
					end)        		
        	end
        end
    end
end

local function patchfn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst:DoTaskInTime(0,function() if not inst.spawnedchildren then spawnvines(inst) end end) 
    --inst:DoTaskInTime(0, function() inst:Remove() end)
    inst.OnSave = onsave
    inst.OnLoad = onload
    inst.spawnNewVine = spawnNewVine
	return inst
end

local function falldown(inst)
    inst.AnimState:PlayAnimation("spawn", false)
    inst.AnimState:PushAnimation("idle_fruit", true)
end

local function onpicked(inst, picker, loot)

    inst.AnimState:PlayAnimation("harvest", false)
    inst.AnimState:PushAnimation("idle_nofruit", true)

    if inst.components.inspectable ~= nil then
        inst:RemoveComponent("inspectable")
    end
	inst.Light:Enable(false)
end

local function makeempty(inst)
    inst.AnimState:Hide("fig")
    inst.AnimState:PlayAnimation("idle_nofruit", true)

    if inst.components.inspectable ~= nil then
        inst:RemoveComponent("inspectable")
    end
end

local function makefull(inst)
	inst.Light:Enable(true)
    inst.AnimState:Show("fig")
    if POPULATING then
        inst.AnimState:PlayAnimation("idle_fruit", true)
    else
        inst.AnimState:PlayAnimation("fruit_grow", false)
        inst.AnimState:PushAnimation("idle_fruit", true)
    end

    if inst.components.inspectable == nil then
        inst:AddComponent("inspectable")
    end
end

local function onloadpostpass(inst, newents, savedata)
	inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)
end

local function fall(inst)
    inst.persists = false
    local point = inst:GetPosition()
    local onland = TheWorld.Map:IsVisualGroundAtPoint(point.x,point.y,point.z) or TheWorld.Map:GetPlatformAtPoint(point.x,point.z) 
    if onland then
        inst.AnimState:PlayAnimation("fall_land", false)
        inst:ListenForEvent("animover", function() ErodeAway(inst) end)
    else
        inst.AnimState:PlayAnimation("fall_ocean", false)
        inst:ListenForEvent("animover", function() inst:Remove() end)
    end
    inst:DoTaskInTime(19*FRAMES, function() 
        if inst.components.pickable ~= nil and inst.components.pickable:CanBePicked() then
            local point = inst:GetPosition()
            inst.components.pickable:MakeEmpty()
            local product = SpawnPrefab(inst.components.pickable.product)
            product.Transform:SetPosition(point.x,0,point.z)
        end
    end)

end

local function FadingOut(inst)
	inst.color = inst.color - FRAMES
	if inst.color < 0 then
		inst.color = 0
	else
		inst:DoTaskInTime(2*FRAMES,FadingOut)
	end
	inst.Light:SetIntensity(inst.color*0.6)
    -- inst.Light:SetRadius(inst.color*0.6+0.01)
    -- inst.Light:SetFalloff(inst.color*0.6)
	inst.AnimState:SetMultColour(1,1,1,inst.color)	
end

local function FadingIn(inst)
	inst.color = inst.color + FRAMES
	if inst.color > 1 then
		inst.color = 1
	else
		inst:DoTaskInTime(2*FRAMES,FadingIn)
	end
	inst.Light:SetIntensity(0.6)
    -- inst.Light:SetRadius(inst.color*0.6+0.01)
    -- inst.Light:SetFalloff(inst.color*0.6)
	inst.AnimState:SetMultColour(1,1,1,inst.color)	
end

local function Fading(inst)
	if inst.color == 0 then
		if inst.components.pickable and not inst.components.pickable.targettime then
			inst.components.pickable.caninteractwith = true
		end
		inst.shadow:Enable(true)
		FadingIn(inst)
	else
		if inst.components.pickable then
			inst.components.pickable.caninteractwith = false
		end
		inst.shadow:Enable(false)
		FadingOut(inst)
	end
end


local function commonfn(Sim)
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.shadow = inst.entity:AddDynamicShadow()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()
	inst.entity:AddLight()
    inst.MiniMapEntity:SetIcon("um_ghost_pepper.tex")

	inst.shadow:SetSize( 1.5, .75 )
    
	
	inst.Light:SetIntensity(.6)
    inst.Light:SetRadius(.6)
    inst.Light:SetFalloff(.6)
    inst.Light:Enable(true)
    inst.Light:SetColour(180/255, 195/255, 225/255)   
	
	
	inst.AnimState:SetBank("um_ghost_pepper")
    inst.AnimState:SetBuild("um_ghost_pepper")
	inst.AnimState:PlayAnimation("idle_fruit", true)
    inst.scrapbook_anim = "idle_fruit"

	inst:AddTag("hangingvine")
    inst:AddTag("flying")
    inst:AddTag("NOBLOCK")                  -- To not block boat deployment.
    inst:AddTag("oceanvine")
--[[
    if not TheNet:IsDedicated() then
        inst:AddComponent("distancefade")
        inst.components.distancefade:Setup(15,25)
    end
    ]]

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -- inst.source_tree = nil -- source_tree is only used to tally number of vines per watertree_pillar on loading in the world after creation, doesn't hold a saved reference after that
    inst.fall_down_fn = falldown

	inst:AddComponent("inspectable")
    
    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/harvest_berries"
    inst.components.pickable.onpickedfn = onpicked
    inst.components.pickable.makeemptyfn = makeempty
    inst.components.pickable.makefullfn = makefull
    inst.components.pickable:SetUp("um_ghost_pepper_item", 10*8*60)
    inst.components.pickable.max_cycles = nil
    inst.components.pickable.cycles_left = 1

    MakeSmallPropagator(inst)

    inst.placegoffgrids = placegoffgrids
    inst.fall = fall
    inst.OnLoadPostPass = onloadpostpass
	
	inst:DoPeriodicTask(math.random(8,12),Fading)
	
	if math.random() > 0.5 then
		inst.color = 1
		inst.shadow:Enable(false)
		inst.components.pickable.caninteractwith = false
		FadingOut(inst)	
	else
		inst.color = 0
		inst.shadow:Enable(true)
		inst.components.pickable.caninteractwith = true
		FadingIn(inst)
	end
	
	return inst
end

--===================================================================================================
--[[ Ghost Pepper Item  ]] ------------
--===================================================================================================

local function UnGhost(eater)
    if not (eater:HasTag("psuedo_ghost") or eater:HasTag("playerghost")) then
        if eater.flashingtask then
            eater.flashingtask:Cancel()
            eater.flashghost = nil
            eater.flashingtask = nil
        end
        eater.Physics:CollidesWith(COLLISION.OBSTACLES)
        eater.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
        eater.Physics:CollidesWith(COLLISION.CHARACTERS)
        eater.Physics:CollidesWith(COLLISION.FLYERS)
        eater.AnimState:SetHaunted(false)
    end
end

local function Ghost(eater)
    if eater.flashingtask then
        eater.flashingtask:Cancel()
        eater.flashghost = nil
        eater.flashingtask = nil
    end

    eater.Physics:ClearCollidesWith(COLLISION.OBSTACLES)
    eater.Physics:ClearCollidesWith(COLLISION.SMALLOBSTACLES)
    eater.Physics:ClearCollidesWith(COLLISION.CHARACTERS)
    eater.Physics:ClearCollidesWith(COLLISION.FLYERS)
    eater.AnimState:SetHaunted(true)
	if eater.unghosttask then
		eater.unghosttask:Cancel()
		eater.unghosttask = nil
	end
	eater.unghosttask = eater:DoTaskInTime(60,UnGhost)
end

local function oneatenfn(inst, eater)
	if  not (eater.components.health ~= nil and eater.components.health:IsDead()) and not eater:HasTag("playerghost") then
		Ghost(eater)
		if eater.components.temperature then
			eater.components.temperature:DoDelta(-30)
		end
	end
end

local function fnfood()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
	inst.entity:AddLight()
    inst.entity:AddNetwork()
	inst.entity:AddLight()
    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("um_ghost_pepper_item")
    inst.AnimState:SetBuild("um_ghost_pepper_item")
    inst.AnimState:PlayAnimation("idle")
    MakeInventoryFloatable(inst)

	inst.Light:SetIntensity(.6)
    inst.Light:SetRadius(.5)
    inst.Light:SetFalloff(.6)
    inst.Light:Enable(true)
    inst.Light:SetColour(180/255, 195/255, 225/255)   
	
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    --inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDIUMITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("edible")
    inst.components.edible.healthvalue = -3
    inst.components.edible.hungervalue = 12.5
    inst.components.edible.sanityvalue = -10
    inst.components.edible.foodtype = FOODTYPE.VEGGIE
	inst.components.edible:SetOnEatenFn(oneatenfn)
    inst:AddComponent("perishable")
	inst:AddComponent("tradable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST/6) -- 1 day
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "pepper"

    MakeHauntableLaunchAndPerish(inst)
    return inst
end


return Prefab("um_ghost_pepper", commonfn, assets),
Prefab("um_ghost_pepper_item", fnfood, assets)