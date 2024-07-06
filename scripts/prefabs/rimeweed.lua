-- [TODO]


local assets =
{
	Asset("ANIM", "anim/um_rimeweed.zip"),
    Asset("ANIM", "anim/um_rimelash.zip"),
	Asset("ANIM", "anim/swap_um_rimeweed.zip"),

	-- Items
    Asset("ANIM", "anim/um_rimeweed_itemvine.zip"),
    Asset("ANIM", "anim/um_rimeweed_itemflower.zip"),
	Asset("ANIM", "anim/um_rimeweed_icepack.zip"),
	
	Asset("IMAGE", "images/inventoryimages/um_rimeweed_itemvine.tex"),
	Asset("ATLAS", "images/inventoryimages/um_rimeweed_itemvine.xml"),
	
	Asset("IMAGE", "images/inventoryimages/um_rimeweed_itemflower.tex"),
	Asset("ATLAS", "images/inventoryimages/um_rimeweed_itemflower.xml"),
	
	Asset("IMAGE", "images/inventoryimages/um_rimeweed_icepack.tex"),
	Asset("ATLAS", "images/inventoryimages/um_rimeweed_icepack.xml"),
}



--[[

	-- Check to see how growing works ingame [VERIFIED!]
	-- Spreading Function
	-- Saving Function
	-- Implement Mara's Whip Art

]]
--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-- Retaliation Spikes

--DSV uses 4 but ignores physics radius
local MAXRANGE = 4
local NO_TAGS_NO_PLAYERS =	{ "bramble_resistant", "INLIMBO", "notarget", "noattack", "flight", "invisible", "wall", "player", "companion" }
local NO_TAGS =				{ "bramble_resistant", "INLIMBO", "notarget", "noattack", "flight", "invisible", "wall", "playerghost","rimeweed" }
local COMBAT_TARGET_TAGS = { "_combat" }



local function Freeze(v)
	-- Freeze
	--TheNet:Announce("freeze code ran")
	if v.components.freezable then -- Freeze
		--TheNet:Announce("Add Coldness")
		v.components.freezable:AddColdness(3) 
	end
	if v.components.temperature ~= nil then -- Chill
		--TheNet:Announce("Got a lil chilly")
		local mintemp = math.max(v.components.temperature.mintemp, 0)
		local curtemp = v.components.temperature:GetCurrent()
		if mintemp < curtemp then
			v.components.temperature:DoDelta(math.max(-5, mintemp - curtemp))
		end
	end		
end

local function OnUpdateThorns(inst)
    inst.range = inst.range + 1

    local x, y, z = inst.Transform:GetWorldPosition()
    for i, v in ipairs(TheSim:FindEntities(x, y, z, inst.range + 2, COMBAT_TARGET_TAGS, inst.canhitplayers and NO_TAGS or NO_TAGS_NO_PLAYERS)) do
        if not inst.ignore[v] and
            v:IsValid() and
            v.entity:IsVisible() and
            v.components.combat ~= nil and
            not (v.components.inventory ~= nil and
                v.components.inventory:EquipHasTag("bramble_resistant")) then
            local range = inst.range + v:GetPhysicsRadius(0)
            if v:GetDistanceSqToPoint(x, y, z) < range * range then
                if inst.owner ~= nil and not inst.owner:IsValid() then
                    inst.owner = nil
                end
                if inst.owner ~= nil then
					if inst.owner.components.combat ~= nil and
						inst.owner.components.combat:CanTarget(v) and
						not inst.owner.components.combat:IsAlly(v)
					then
                        inst.ignore[v] = true
                        v.components.combat:GetAttacked(v.components.follower ~= nil and v.components.follower:GetLeader() == inst.owner and inst or inst.owner, inst.damage)
						Freeze(v)
                        --V2C: wisecracks make more sense for being pricked by picking
                        --v:PushEvent("thorns")
                    end
                elseif v.components.combat:CanBeAttacked() then
					local isally = false
					if not inst.canhitplayers then
						--non-pvp, so don't hit any player followers (unless they are targeting a player!)
						local leader = v.components.follower ~= nil and v.components.follower:GetLeader() or nil
						isally = leader ~= nil and leader:HasTag("player") and
							not (v.components.combat ~= nil and
								v.components.combat.target ~= nil and
								v.components.combat.target:HasTag("player"))
					end
					if not isally then
						inst.ignore[v] = true
						v.components.combat:GetAttacked(inst, inst.damage)
						Freeze(v)					
						
						--v:PushEvent("thorns")
					end
                end
            end
        end
    end

    if inst.range >= MAXRANGE then
        inst.components.updatelooper:RemoveOnUpdateFn(OnUpdateThorns)
    end
end

local function SetFXOwner(inst, owner)
    inst.Transform:SetPosition(owner.Transform:GetWorldPosition())
    inst.owner = owner
    inst.canhitplayers = not owner:HasTag("player") or TheNet:GetPVPEnabled()
    inst.ignore[owner] = true
end

local function MakeFX(name, anim)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        inst:AddTag("FX")
        inst:AddTag("thorny")
        if name == "bramblefx_trap" then
            inst:AddTag("trapdamage")
        end

        inst.Transform:SetFourFaced()

        inst.AnimState:SetBank("bramblefx")
        inst.AnimState:SetBuild("bramblefx")
        inst.AnimState:PlayAnimation(anim)

        inst:SetPrefabNameOverride("bramblefx")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("updatelooper")
        inst.components.updatelooper:AddOnUpdateFn(OnUpdateThorns)

        inst:ListenForEvent("animover", inst.Remove)
        inst.persists = false
        inst.damage = 20 -- This is where we define the damage of the thorns.
        inst.range = .75
        inst.ignore = {}
        inst.canhitplayers = true
        --inst.owner = nil

        inst.SetFXOwner = SetFXOwner

        return inst
    end

    return Prefab(name, fn)
end



--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



local function AnimateRetaliateOver(inst)
	inst.retaliating = nil
	if inst.components.health and not inst.components.health:IsDead() then
		inst.AnimState:PlayAnimation("bramble_"..inst.type.."_idle", true)
	end
	inst:RemoveEventCallback("animover", AnimateRetaliateOver)
end

local function Retaliate(inst)
	if not inst.retaliating then
		inst.retaliating = true

		inst:DoTaskInTime(6*FRAMES,function(inst) 
			SpawnPrefab("bramblefx_rime"):SetFXOwner(inst) 
			if inst.SoundEmitter then
				inst.SoundEmitter:PlaySound("dontstarve/wilson/blowdart_shoot")
			end			
		end) -- Slight Delay

		if inst.SoundEmitter then
			inst.SoundEmitter:PlaySound("dontstarve/common/together/armor/cactus")
		end
		if inst.components.health and not inst.components.health:IsDead() then
			inst.AnimState:PlayAnimation("bramble_"..inst.type.."_hit", false)
			inst:ListenForEvent("animover", function(inst)
				AnimateRetaliateOver(inst)
			end)
		end
	end
end

local function BarrierDie(inst)
	--TheNet:Announce("DODEATH")
	RemovePhysicsColliders(inst)
	inst.AnimState:PlayAnimation("bramble_"..inst.type.."_shrink", false)
	if math.random() < 0.1 then
		inst.components.lootdropper:SpawnLootPrefab("um_rimeweed_itemvine")
	end
	if math.random() < 0.01 then
		inst.components.lootdropper:SpawnLootPrefab("dug_marsh_bush")
	end
	local x,y,z = inst.Transform:GetWorldPosition()
	local weeds = TheSim:FindEntities(x,y,z,5,{"rimeweed"})
	
	if not inst.nospread then
		for i,v in ipairs(weeds) do
			if v.prefab == "rimeweed_barrier" then
				v.nospread = true
				v:DoTaskInTime(0.5*inst:GetDistanceSqToInst(v)^0.5,function(v) if v.components.health and not v.components.health:IsDead() then v.components.health:Kill() end end)
			end
		end
	end
end

local function BarrierSave(inst,data)
	if inst.type then
		data.type = inst.type
		return data
	end
end

local function BarrierLoad(inst,data)
	if data and data.type then
		inst.type = data.type
	end
end

local function barrierweed()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("um_rimeweed")
	inst.AnimState:SetBuild("um_rimeweed")

	inst:AddTag("plant")
	inst:AddTag("rimeweed")
	MakeObstaclePhysics(inst, 1.5)
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	
	
	inst:AddComponent("lootdropper")
	--inst:ListenForEvent("timerdone", TimerDone)
	
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(200)
    inst.components.health:StartRegen(TUNING.BUNNYMAN_HEALTH_REGEN_AMOUNT, TUNING.BUNNYMAN_HEALTH_REGEN_PERIOD)
	inst:AddComponent("combat")
	inst:AddComponent("inspectable")
	local multsize = math.random(15,17)/10
	
	if math.random() > 0.5 then
		inst.AnimState:SetScale(-multsize, multsize, multsize)
	else
		inst.AnimState:SetScale(multsize, multsize, multsize)
	end
	---------------------
	inst:ListenForEvent("attacked", Retaliate)
	inst:ListenForEvent("death", BarrierDie)
	
	--MakeSmallBurnableCharacter(inst, "catcoon_torso")
	
	MakeSmallPropagator(inst)
	MakeHauntableIgnite(inst)
	inst.OnSave = BarrierSave 
	inst.OnLoad = BarrierLoad
	inst:DoTaskInTime(0,
		function(inst) 
			if not inst.type then 
				inst.type = math.random(0,2)
				inst.AnimState:PlayAnimation("bramble_"..inst.type.."_idle", true)
			end
		end)
	return inst
end


local function OnSaveMain(inst,data)
    local ents = {}	
    if inst.bramble then
        data.bramble = {}
        for i,v in pairs(inst.bramble)do
            if v.prefab then
                data.bramble[i] = v.GUID
                table.insert(ents, v.GUID)
            end
        end
    end
	
	
	data.stage = inst.stage

    return ents
end

local function OnLoadMain(inst,data)
	if data then
		if data.stage then
			inst.stage = data.stage
		end
	end
end

local function OnLoadPostPassMain(inst, newents, data)
    if data then
        if data.bramble and #data.bramble > 0 then
            inst.bramble = {}
            for i,v in pairs(data.bramble) do
                if newents[v] then
                    inst.bramble[i] = newents[v].entity
                end
            end
        end
    end
end

local function MainDie(inst)
	inst:AddTag("dead")
	
	if #inst.bramble > 0 then
		for i,v in ipairs(inst.bramble) do
			--v:DoTaskInTime(0.5*inst:GetDistanceSqToInst(v)^0.5, function(v)
				if v.components.health and not v.components.health:IsDead() then
					v.components.health:Kill()
				end
			--end)
		end
	end
	inst.AnimState:PlayAnimation("flower_"..(inst.stage-1).."_shrink",false)
	if inst.stage >= 1 and not inst.noloot then
		inst.components.lootdropper:SpawnLootPrefab("um_rimeweed_itemvine")
	end
	if inst.stage == 2 and not inst.noloot then
		inst.components.lootdropper:SpawnLootPrefab("rimeweed_whip")
		inst.components.lootdropper:SpawnLootPrefab("um_rimeweed_itemvine")
	end
	if inst.stage >= 3 and not inst.noloot then
		inst.components.lootdropper:SpawnLootPrefab("um_rimeweed_itemflower")
		inst.components.lootdropper:SpawnLootPrefab("um_rimeweed_itemvine")
	end
end


local function PlayStagedAnim(inst)
	if not inst:HasTag("dead") then
		inst.AnimState:PushAnimation("flower_"..(inst.stage-1).."_idle")
	end
end

local function InitializePlant(inst)
	inst.stage = 1
	inst.components.timer:StartTimer("grow", 0.5*8*60)
	inst.AnimState:PlayAnimation("flower_"..(inst.stage-1).."_grow",false)
	inst.AnimState:PushAnimation("flower_"..(inst.stage-1).."_idle")
end

local function SetStage(inst)
	if not inst.stage then
		InitializePlant(inst)
	end
	PlayStagedAnim(inst)
end

local function FindPlant(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local plants = TheSim:FindEntities(x,y,z,32,{"plant"})
	for i,plant in ipairs(plants) do
		if plant.components.pickable and plant.components.pickable:CanBePicked() and not FindEntity(plant,3,nil,{"rimeweed"}) then
			return plant
		end
	end
	for i,plant in ipairs(plants) do
		if plant.components.pickable and not FindEntity(plant,6,nil,{"rimeweed"}) then
			return plant
		end
	end	
end


local function TryGrowPoint(inst,x,z)
	if TheWorld.Map:IsAboveGroundAtPoint(x, 0, z) then
		local weed = SpawnPrefab("rimeweed_barrier")
		weed.Transform:SetPosition(x,0,z)
		table.insert(inst.bramble,weed)
		weed.type = math.random(0,2)
		weed.AnimState:PlayAnimation("bramble_"..weed.type.."_grow", false)
		weed.AnimState:PushAnimation("bramble_"..weed.type.."_idle", true)
	end
end

local function GrowLine(inst,growPoint)
	local distance = (inst:GetDistanceSqToPoint(growPoint))^0.5
	local plants = math.floor(distance)
	local x,y,z = inst.Transform:GetWorldPosition()

	for i = 1,plants-1 do
		TryGrowPoint(inst,x+(growPoint.x-x)*i/plants+0.1*math.random(-2,2),z+(growPoint.z-z)*i/plants+0.1*math.random(-10,10))
	end
end

local function GrowRing(inst,growPoint)
	
	local maxRing = 7
	local radius = 1.5
	local random_angle = math.random(1,360)
	for i = 1,maxRing do
	
		local x = growPoint.x+radius*math.cos(random_angle+2*(i-1)/maxRing*180)
		local z = growPoint.z+radius*math.sin(random_angle+2*(i-1)/maxRing*180)
		TryGrowPoint(inst,x,z)
	end
end

local function GrowBranch(inst)
	local plant = FindPlant(inst)
	if plant then	
		local growPoint = Vector3(plant.Transform:GetWorldPosition())
		GrowRing(inst,growPoint)
		GrowLine(inst,growPoint)
	else
		--inst:Remove()
	end
end

local function TimerDone(inst,data)
	if data and data.name == "grow" then
		inst.AnimState:PlayAnimation("flower_"..(inst.stage).."_grow",false)
		inst.stage = inst.stage + 1
		if inst.stage == 2 and not inst:HasTag("dead") then
			inst.components.timer:StartTimer("growbranch", 0.5*8*60)
		end
		if inst.stage < 3 then
			inst.components.timer:StartTimer("grow", 1*8*60)
		end
		SetStage(inst)
	end
	
	if data and data.name == "growbranch" then
		if TheWorld.state.iswinter then
			inst.components.timer:StartTimer("growbranch", 0.15*8*60)
			GrowBranch(inst)
		elseif inst.components.health and not inst.components.health:IsDead() then
			inst.noloot = true
			inst.components.health:Kill()
		else
			inst:Remove()
		end
	end
end


local function mainweed()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()


	inst.AnimState:SetBank("um_rimeweed")
	inst.AnimState:SetBuild("um_rimeweed")
	--inst.AnimState:PlayAnimation("crop_full", true)

	inst:AddTag("plant")
	--inst:AddTag("lunarplant_target")
	inst:AddTag("rimeweed")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	local scale = 1.5
	inst.Transform:SetScale(scale,scale,scale)
	
	inst:AddComponent("lootdropper")
	
	inst:AddComponent("timer")
	inst:ListenForEvent("timerdone", TimerDone)
	inst:ListenForEvent("death", MainDie)


	inst:AddComponent("inspectable")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(200)
    inst.components.health:StartRegen(TUNING.BUNNYMAN_HEALTH_REGEN_AMOUNT, TUNING.BUNNYMAN_HEALTH_REGEN_PERIOD)	
	inst:AddComponent("combat")
	inst:ListenForEvent("attacked", function(inst)
		if inst.components.health and not inst.components.health:IsDead() then
			if inst.stage > 2 then
				inst:DoTaskInTime(4*FRAMES,function(inst) SpawnPrefab("bramblefx_rime"):SetFXOwner(inst) end) -- Slight Delay
				if inst.SoundEmitter then
					inst.SoundEmitter:PlaySound("dontstarve/common/together/armor/cactus")
				end
			end
			
			inst.AnimState:PlayAnimation("flower_"..(inst.stage-1).."_hit")
			inst.AnimState:PushAnimation("flower_"..(inst.stage-1).."_idle")
		end
	end)
	
	---------------------
	
	--MakeMediumBurnable(inst)
	MakeSmallPropagator(inst)
	MakeHauntableIgnite(inst)
	
    inst.OnSave = OnSaveMain
    inst.OnLoad = OnLoadMain
    inst.OnLoadPostPass = OnLoadPostPassMain
	inst:DoTaskInTime(0,SetStage)
	if not inst.bramble then
		inst.bramble = {}
	end
	
	return inst
end
----------------------------------------------------------------------------------------------------------------------------------------------------------
--[ Rime Lash ] ------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------
local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_um_rimeweed", "swap_whip")
    owner.AnimState:OverrideSymbol("whipline", "swap_um_rimeweed", "whipline")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function onattackwhip(inst, attacker, target, naughtlock)
	if target and target.components.combat and target.components.freezable then
		local resistance = target.components.freezable:ResolveResistance()
		local coldness = target.components.freezable.coldness
		
		local coldval = 1/resistance
		if resistance > coldness + 2 then
			target.components.freezable:AddColdness(coldval)
		elseif resistance > coldness + 1 then
			target.components.freezable:AddColdness(coldval/4)
		else
			target.components.freezable:AddColdness(coldval/8)
		end
		local bonusdamage = 68
		bonusdamage = bonusdamage * coldness/resistance
		
		if target.sg ~= nil and target.sg:HasStateTag("frozen") then
			SpawnPrefab("bramblefx_rime"):SetFXOwner(target)
		end
		

		target.components.combat:GetAttacked(attacker,bonusdamage) -- Frost-type damage, which is based on how close to freezing the enemy is
		target.components.freezable:SpawnShatterFX()
	end
end



local function whip()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("um_rimelash")
    inst.AnimState:SetBuild("um_rimelash")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("whip")

    inst:AddTag("weapon")

    MakeInventoryFloatable(inst, "med", nil, 0.9)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(51)
    inst.components.weapon:SetRange(TUNING.WHIP_RANGE)
    inst.components.weapon:SetOnAttack(onattackwhip)
	
	
    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(150)
    inst.components.finiteuses:SetUses(150)
    inst.components.finiteuses:SetOnFinished(inst.Remove)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/rimeweed_whip.xml"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
	
    MakeHauntableLaunch(inst)

    return inst
end

local function onperish(inst)
    local owner = inst.components.inventoryitem.owner
    if owner ~= nil then
        local stacksize = inst.components.stackable:StackSize()
        if owner.components.moisture ~= nil then
            owner.components.moisture:DoDelta(2 * stacksize)
        elseif owner.components.inventoryitem ~= nil then
            owner.components.inventoryitem:AddMoisture(4 * stacksize)
        end
    else
        local stacksize = inst.components.stackable:StackSize()
		local x, y, z = inst.Transform:GetWorldPosition()
        TheWorld.components.farming_manager:AddSoilMoistureAtPoint(x, y, z, stacksize * TUNING.ICE_MELT_GROUND_MOISTURE_AMOUNT)

		inst.persists = false
        inst.components.inventoryitem.canbepickedup = false
    end
end

local function fnvine()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("um_rimeweed_itemvine")
    inst.AnimState:SetBuild("um_rimeweed_itemvine")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("icebox_valid")
    inst:AddTag("show_spoilage")
	inst:AddTag("frozen")
	
	
	MakeInventoryFloatable(inst, "small", 0.15)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end


    inst:AddComponent("tradable")

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(4 * TUNING.PERISH_TWO_DAY)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "twigs"
	inst.components.perishable:SetOnPerishFn(onperish)

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/um_rimeweed_itemvine.xml"


    inst:AddComponent("forcecompostable")
    inst.components.forcecompostable.brown = true

    MakeHauntableLaunchAndIgnite(inst)


    return inst
end

local function fnflower()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("um_rimeweed_itemflower")
    inst.AnimState:SetBuild("um_rimeweed_itemflower")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("icebox_valid")
    inst:AddTag("show_spoilage")
	inst:AddTag("frozen")
	
	
	MakeInventoryFloatable(inst, "small", 0.15)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end


    inst:AddComponent("tradable")

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(3 * TUNING.PERISH_TWO_DAY)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"
	inst.components.perishable:SetOnPerishFn(onperish)

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/um_rimeweed_itemflower.xml"

    inst:AddComponent("edible")
    inst.components.edible.hungervalue = 25
    inst.components.edible.healthvalue = 3
    inst.components.edible.foodtype = FOODTYPE.VEGGIE

    inst:AddComponent("forcecompostable")
    inst.components.forcecompostable.brown = true

    MakeHauntableLaunchAndIgnite(inst)


    return inst
end




local function OnAttached(inst, target)
    inst.entity:SetParent(target.entity)
    inst.Transform:SetPosition(0, 0, 0) --in case of loading
	if target:HasTag("pyromaniac") then
		target.components.freezable:SetResistance(12)
	else
		target.components.freezable:SetResistance(16)
	end	
	inst.components.timer:StartTimer("ice_resist_over", 60*8*1.5) -- 1.5 Days of Ice Resist
    inst:ListenForEvent("death", function()
        inst.components.debuff:Stop()
    end, target)
end

local function OnTimerDone(inst, data)
    if data.name == "ice_resist_over" then
        inst.components.debuff:Stop()
    end
end

local function OnDetach(inst, target)
    inst.components.timer:StopTimer("ice_resist_over")
	inst.components.timer:StartTimer("ice_resist_over", 60*8*1.5)
end

local function OnExtended(inst, target)
    inst.components.timer:StopTimer("ice_resist_over")
	if target:HasTag("pyromaniac") then
		target.components.freezable:SetResistance(3)
	else
		target.components.freezable:SetResistance(4)
	end		
end

local function buff_fn()
    local inst = CreateEntity()

    if not TheWorld.ismastersim then
        --Not meant for client!
        inst:DoTaskInTime(0, inst.Remove)

        return inst
    end

    inst.entity:AddTransform()

    --[[Non-networked entity]]
    --inst.entity:SetCanSleep(false)
    inst.entity:Hide()
    inst.persists = false

    inst:AddTag("CLASSIFIED")

    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(OnAttached)
    inst.components.debuff:SetDetachedFn(OnDetach)
    inst.components.debuff:SetExtendedFn(OnExtended)
    inst.components.debuff.keepondespawn = true

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", OnTimerDone)

    return inst
end


local function OnUseBandage(inst, target)
	if target and target.components.temperature then
		target.components.temperature:DoDelta(-40)
	end
end



local function bandage_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("um_rimeweed_icepack")
    inst.AnimState:SetBuild("um_rimeweed_icepack")
    inst.AnimState:PlayAnimation("idle")


    inst:AddTag("icebox_valid")
    inst:AddTag("show_spoilage")
	inst:AddTag("frozen")
	
    MakeInventoryFloatable(inst, "small", 0.05, 0.95)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("healer")
    inst.components.healer:SetHealthAmount(20)
	inst.components.healer.onhealfn = OnUseBandage
	
    MakeHauntableLaunch(inst)
	inst.components.inventoryitem.atlasname = "images/inventoryimages/um_rimeweed_icepack.xml"
	
    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(10 * TUNING.PERISH_TWO_DAY)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "papyrus"
	inst.components.perishable:SetOnPerishFn(onperish)

    return inst
end

return Prefab("rimeweed_main", mainweed,assets),
Prefab("rimeweed_barrier", barrierweed),
MakeFX("bramblefx_rime", "idle"),
Prefab("um_rimeweed_itemvine", fnvine),
Prefab("um_rimeweed_itemflower", fnflower),
Prefab("rimeweed_whip", whip,assets),
Prefab("um_rimeweed_tequila_buff", buff_fn),
Prefab("um_rimeweed_icepack", bandage_fn)

