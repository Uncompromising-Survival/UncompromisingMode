local assets =
{
    Asset("ANIM", "anim/ocupus.zip"),
}

local prefabs =
{
}

SetSharedLootTable( 'um_ocupus_eyetacle',
{
    {'um_ocupus_eyetacle_item',  1.00},
})

local brain = require "brains/um_ocupus_eyetaclebrain"

local function OnDeath(inst)
	if inst.core then
		inst.core:EyeTentKilled(inst.core)
	end
	local loot = SpawnPrefab("ocupus_tentacle_eye")
	loot.Transform:SetPosition(inst.Transform:GetWorldPosition())
	loot.AnimState:PlayAnimation("eyetacle_item_flop")
	loot.AnimState:PushAnimation("eyetacle_item",true)
end

local function OnAttacked(inst, data)
--    print("onattack", data.attacker, data.damage, data.damageresolved)
end

local function findtargetcheck(target)
	local x, y, z = target.Transform:GetWorldPosition()
	return TheWorld.Map:IsOceanAtPoint(x, y, z, target:HasTag("boat")) and target.components.boatphysics
end

local FINDEDIBLE_CANT_TAGS = { "INLIMBO", "fire", "smolder" }
local FINDEDIBLE_ONEOF_TAGS = { "boat", "edible_WOOD" }
local function CheckForBoats(inst,range)
	return FindEntity(inst, range, findtargetcheck, nil, FINDEDIBLE_CANT_TAGS, FINDEDIBLE_ONEOF_TAGS)
end

local function CheckForBoatsShort(inst)
	local boat = CheckForBoats(inst,10) --Seems like it looks for the center of the boat entity, so the search radius may seem a bit large without knowing that.
	--Tell The Ocupus Core that we've got dinner ready, those poor souls won't know what hit em.
	if inst.core and boat and not inst.core.boatvictim then
		inst.core.notifycore(inst.core,boat)
	end
end

local function CheckForVictimsLong(inst,fishonly)
	local boat = CheckForBoats(inst,30)
	if boat and not fishonly then
		inst.interestpoint = boat
		inst.droptask = inst:DoPeriodicTask(10,function(inst) 
							if inst.interestpoint and inst.interestpoint:IsValid() and inst.interestpoint:GetDistanceSqToInst(inst)^0.5 > 20 then 
								inst.interestpoint = nil
								if inst.droptask then
									inst.droptask:Cancel()
									inst.droptask = nil
								end
							end
						end)
		return
	end
	local fish = FindEntity(inst,30,nil,nil,nil,{"oceanfish","shark","gnarwail","grassgator","oceanfishable"})
	if fish then
		inst.interestpoint = fish
		inst.droptask = inst:DoPeriodicTask(10,function(inst) 
							if not (inst.interestpoint and inst.interestpoint:IsValid() and inst.interestpoint:GetDistanceSqToInst(inst)^0.5 < 20) then 
								inst.interestpoint = nil
								if inst.droptask then
									inst.droptask:Cancel()
									inst.droptask = nil
								end
							end
						end)
		return	
	end
end

local function FindBoat(inst,range)
	if inst.target_wood then
		return inst.target_wood
	else
		inst.target_wood = CheckForBoats(inst,range)
		if inst.target_wood then
			return inst.target_wood
		end
	end
end

local function Investigate(inst)
	if inst.core then
		local pos = inst.core:GetPosition()
		if FindBoat(inst,30) then
			pos = inst.target_wood:GetPosition()
		else
			local rot = 2 * PI * inst.rot/5
			pos.x = pos.x + 8 * math.cos(rot) + math.random(-3,3)
			pos.z = pos.z + 8 * math.sin(rot) + math.random(-3,3)
			inst.investigationspot = pos 
		end
	end
end

local function EvaluateDistanceToBoat(inst)
	if inst.boatvictim and inst.boatvictim:IsValid() and inst:GetDistanceSqToInst(inst.boatvictim)^0.5 > 10 then
		inst.AnimState:PlayAnimation("eyetacle_leave")
		inst:ListenForEvent("animover",function(inst)
			local splash = SpawnPrefab("splash_ocean")
			splash.Transform:SetPosition(inst.Transform:GetWorldPosition())
			splash.Transform:SetScale(1.5,1.5,1.5)
			inst.core:DoTaskInTime(math.random(3,5),function(inst) if inst.boatvictim then inst.AddEyeTentacle2(inst) end end)
			inst:Remove() --Replace with submerging
		end)
	elseif not inst.boatvictim then	
		inst.AnimState:PlayAnimation("eyetacle_leave")
		inst:ListenForEvent("animover",function(inst)
			inst:Remove() --Replace with submerging
		end)
	end
end

local function teleport_override_fn(inst)
    local pt = inst:GetPosition()
    local offset = FindSwimmableOffset(pt, math.random() * 2 * PI, 3, 8, true, false) or
					FindSwimmableOffset(pt, math.random() * 2 * PI, 8, 8, true, false)
    if offset ~= nil then
		pt = pt + offset
    end

	return pt
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst, nil, 0.7)

	inst.Transform:SetFourFaced()
    inst.AnimState:SetBank("um_ocupus")
    inst.AnimState:SetBuild("ocupus")
    --inst.AnimState:PlayAnimation("eyetacle_idle_down", true)

    inst:AddTag("monster")
    inst:AddTag("hostile")
	inst:AddTag("ocupus")

	
    inst.Light:SetIntensity(.6)
    inst.Light:SetRadius(1)
    inst.Light:SetFalloff(.6)
    inst.Light:Enable(false)
    inst.Light:SetColour(180/255, 195/255, 225/255)
    MakeInventoryFloatable(inst, "med", 0.1, {0.7, 0.7, 0.7})
    --[[inst.components.floater.bob_percent = 0.1
    local land_time = (POPULATING and math.random()*5*FRAMES) or 0
    inst:DoTaskInTime(land_time, function(inst)
        inst.components.floater:OnLandedServer()
    end)	]]
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:SetBrain(brain)


	inst:AddComponent("knownlocations")
	

	
    inst:SetStateGraph("SGum_ocupus_eyetacle")

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

    inst:AddComponent("inspectable")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(300)

    inst:AddComponent("combat")
	inst:AddComponent("lootdropper")
    inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("attacked", OnAttacked)
	inst:Hide()
	inst:DoTaskInTime(0,function(inst)
		inst.Appear(inst)
		inst:DoPeriodicTask(math.random(5,7),EvaluateDistanceToBoat)
	end)

	inst:DoPeriodicTask(10,CheckForVictimsLong)
	
	inst:AddComponent("teleportedoverride")
	inst.components.teleportedoverride:SetDestPositionFn(teleport_override_fn)
	inst.persists = false
	inst.Leave = function(inst)
		inst.AnimState:PlayAnimation("eyetacle_leave")
		inst:ListenForEvent("animover",function(inst)
			inst:Remove() --Replace with submerging
		end)
	end
	
	inst.Appear = function(inst)
		inst.Light:Enable(true)
		inst.shadow = inst:SpawnChild("crabking_claw_shadow")
		inst.shadow.Transform:SetScale(0.75,0.75,0.75)
		inst:Show()
		local splash = SpawnPrefab("splash_ocean")
		splash.Transform:SetPosition(inst.Transform:GetWorldPosition())
		splash.Transform:SetScale(1.5,1.5,1.5)
		inst.AnimState:PlayAnimation("eyetacle_appear")
		inst.AnimState:PushAnimation("eyetacle_idle",true)
		inst.AnimState:SetDeltaTimeMultiplier(math.random(-5,5)*0.01+1)
		inst:DoPeriodicTask(1,function(inst) --Keep the eyetacle looking at the boat
			if inst.boatvictim and inst.boatvictim.Transform:GetWorldPosition() then
				inst:ForceFacePoint(inst.boatvictim.Transform:GetWorldPosition())
			end
		end)
	end
	
    ------------------
    return inst
end



local function LookForVictims(inst)
	local fish = FindEntity(inst,10,nil,nil,nil,{"oceanfish","shark","gnarwail","grassgator","oceanfishable"}) --Fish and the Sorts
	if fish then
		local tentacle = SpawnPrefab("um_ocupus_tentacle_fisher")
		tentacle.fish = fish
	end
	CheckForBoatsShort(inst) --Boats
	if not inst.interestpoint then
		CheckForVictimsLong(inst)
	end
end

local function Redirect(inst)
	if inst.interestpoint and inst.interestpoint.Transform:GetWorldPosition() then
		inst:ForceFacePoint(inst.interestpoint.Transform:GetWorldPosition())
	else
		local x,z = inst.homex,inst.homez
		inst:ForceFacePoint(x+math.random(-4,4),0,z+math.random(-4,4))
	end
	inst.components.locomotor.walkspeed = 0.1 * math.random(1,6)
	inst.components.locomotor:WalkForward()
end


local function Hide(inst)
	inst.components.locomotor:Stop()
	inst.AnimState:PlayAnimation("eye_retract")
	inst.Light:Enable(false)
	inst.isvisible = nil
	inst.AnimState:PushAnimation("eye_hide",true)
	if inst.grabtask then
		inst.grabtask:Cancel()
		inst.grabtask = nil
	end
	if inst.movin then
		inst.movin:Cancel()
		inst.grabtask = nil
	end
end

local function Appear(inst)
	local x,z = inst.homex,inst.homez
	
	if x ~= nil and z ~= nil then
		x = x + math.random(-4,4)
		z = z + math.random(-4,4)
		inst.isvisible = true
		inst.Transform:SetPosition(x,0,z)
		inst.Light:Enable(true)
		inst.AnimState:PlayAnimation("eye_arrive")
		inst.AnimState:PushAnimation("eye_idle",true)
		inst.grabtask = inst:DoPeriodicTask(5, LookForVictims)
		inst.movin = inst:DoPeriodicTask(math.random(7,15),Redirect)
	end
end

local function EvaluateTime(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	inst.homex = x
	inst.homez = z
	if TheWorld.state.isday then
		Hide(inst)
	elseif not (inst.grabtask or inst.movin) then
		inst:DoTaskInTime(0.01*math.random(50,500),Appear)
	end
end

local function fneye()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
	inst.entity:AddLight()
	
    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("um_ocupus")
    inst.AnimState:SetBuild("ocupus")
    inst.AnimState:PlayAnimation("eye_hide", true)
	inst.AnimState:UsePointFiltering(true)
    inst.AnimState:SetSortOrder(ANIM_SORT_ORDER_BELOW_GROUND.UNDERWATER)
	inst.AnimState:SetLayer(LAYER_WIP_BELOW_OCEAN)
	
	
    inst.Light:SetIntensity(.6)
    inst.Light:SetRadius(1)
    inst.Light:SetFalloff(.6)
    inst.Light:Enable(false)
    inst.Light:SetColour(180/255, 195/255, 225/255)
	inst:AddTag("ocupus")
	
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	--inst.AnimState:SetMultColour(1, 1, 1, 0.2)
    inst:AddComponent("stackable")
	
    inst:AddComponent("inspectable")
	inst:AddComponent("locomotor")
	inst:AddTag("um_ocupus_eye")
    MakeHauntableLaunch(inst)
	inst:WatchWorldState("isday", Hide)
	inst:WatchWorldState("isdusk", function(inst) 
		if not inst.isvisible then
			Appear(inst)
		end
	end)
	inst.AnimState:SetDeltaTimeMultiplier(math.random(-5,5)*0.01+1)
	inst:DoTaskInTime(0,EvaluateTime)

	inst.Hide = function(inst)
		inst.AnimState:PlayAnimation("eye_retract")
		inst:ListenForEvent("animover",function(inst) inst:Remove() end)
	end
    return inst
end

local function PullFish(inst)
	inst:RemoveEventCallback("animover",PullFish)
	if inst.fish then
		local x,y,z = inst.fish.Transform:GetWorldPosition()
		inst.fish:RemoveChild(inst)
		inst.Transform:SetPosition(x,y,z)
		inst.fish.entity:AddFollower()
		inst.fish.Follower:FollowSymbol(inst.GUID, "fish",0,0,0)
		inst.AnimState:PlayAnimation("snatch_pst")
		inst:ListenForEvent("animover", function(inst)
			inst.fish:Remove()
			inst:DoTaskInTime(0,function(inst) inst:Remove() end)
		end)
	else
		inst:Remove()
	end
end

local function PullBig(inst)
	inst:RemoveEventCallback("animover",PullBig)
	if inst.fish then
		local x,y,z = inst.Transform:GetWorldPosition()
		inst.fish:RemoveChild(inst)
		inst.Transform:SetPosition(x,y,z)
		local splash = SpawnPrefab("splash_ocean")
		splash.Transform:SetPosition(x,y,z)
		splash.Transform:SetScale(1.5,1.5,1.5)
		inst.AnimState:PlayAnimation("snatchbig_pst")
		inst:DoTaskInTime(0,function(inst) --requires a delay for some reason before moving on
			inst.fish:Remove()
			inst:ListenForEvent("animover", function(inst)
				inst:Remove()
			end)
		end)
	else
		inst:Remove()
	end
end

local function GrabFish(inst)
	if inst.fish and not inst.fish:HasTag("doomed") then
		inst.fish:AddChild(inst)
		inst.fish:AddTag("doomed")
		if inst.fish:HasTag("oceanfish") then
			inst.AnimState:PlayAnimation("snatch_pre")
			inst:ListenForEvent("animover",PullFish)
		else
			inst.Transform:SetScale(1.5,1.5,1.5)
			inst.AnimState:PlayAnimation("snatchbig_pre")
			inst:ListenForEvent("animover",PullBig)
		end
	else
		inst:Remove()
	end
end

local function fnfishtentacle()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
	
    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("um_ocupus")
    inst.AnimState:SetBuild("ocupus")
    --inst.AnimState:PlayAnimation("eye_idle", true)
	inst.AnimState:UsePointFiltering(true)
    inst.AnimState:SetSortOrder(ANIM_SORT_ORDER_BELOW_GROUND.UNDERWATER)
	inst.AnimState:SetLayer(LAYER_WIP_BELOW_OCEAN)
	
	
	inst:AddTag("NOCLICK")	
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	--inst.AnimState:SetMultColour(1, 1, 1, 0.2)
	
    inst:AddComponent("inspectable")

    MakeHauntableLaunch(inst)
	inst:DoTaskInTime(0,GrabFish)
    return inst
end


local function ReaperLeave(inst)
	local function HideBottomReaper(tent)
		tent.tent:Remove()
		inst:Remove()
	end
	inst:Hide()
	inst.AnimState:PlayAnimation("tentacle_under_leave")
end

local function GrabEntity(inst) 
	if inst.target and not inst.target:HasTag("doomed") then
		inst:Show()
		inst.target:AddTag("doomed")
		inst.AnimState:PlayAnimation("reapergrab",false)
		inst:ListenForEvent("animover",ReaperLeave)
	else
		inst:Remove()
	end
end


local function fnreapertentacle() --Reaper Tentacle is scrapped/shelved. It was supposed to grab players if they somehow got into the water, and kill them. (Also killing goose if it ran over the eyes).
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
	
    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("um_ocupus_tentacle")
    inst.AnimState:SetBuild("ocupus")
    --inst.AnimState:PlayAnimation("eye_idle", true)
	inst.AnimState:UsePointFiltering(true)
    inst.AnimState:SetSortOrder(ANIM_SORT_ORDER_BELOW_GROUND.UNDERWATER)
	inst.AnimState:SetLayer(LAYER_WIP_BELOW_OCEAN)
	
	
	inst:AddTag("NOCLICK")	
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	--inst.AnimState:SetMultColour(1, 1, 1, 0.2)
	
    inst:AddComponent("inspectable")
	inst:Hide()
    MakeHauntableLaunch(inst)
    return inst
end

local function UpperTentAppear(inst)
	inst.tent.Appear(inst.tent)
	inst.AnimState:PlayAnimation("eyetacle_under",true)
	inst:RemoveEventCallback("animover",UpperTentAppear)
end

local function fneyetacleunder()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
	
    --MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("um_ocupus")
    inst.AnimState:SetBuild("ocupus")
    --inst.AnimState:PlayAnimation("eye_idle", true)
	inst.AnimState:UsePointFiltering(true)
    inst.AnimState:SetSortOrder(ANIM_SORT_ORDER_BELOW_GROUND.UNDERWATER)
	inst.AnimState:SetLayer(LAYER_WIP_BELOW_OCEAN)
	
	
	inst:AddTag("NOCLICK")
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
	
	inst.Appear = function(inst) --A tentacle is coming!
		if inst.noeyes then
			--TheNet:Announce("no eyes!")
			inst.AnimState:PlayAnimation("tentacle_under_appear")
		else
			--TheNet:Announce("eyes!")
			inst.AnimState:PlayAnimation("eyetacle_under_appear")
		end
		inst:ListenForEvent("animover",UpperTentAppear)
	end
	
	inst.Leave = function(inst,death) --The undertentacle is leaving, remove it afterwards
		if death then
			inst.AnimState:PlayAnimation("eyetacle_under_death")
		else
			if inst.noeyes then
				inst.AnimState:PlayAnimation("tentacle_under_leave")
			else
				inst.AnimState:PlayAnimation("eyetacle_under_leave")
			end
		end
		inst:ListenForEvent("animover",function(inst) inst:Remove() end)
	end
	
	
    MakeHauntableLaunch(inst)
	inst.persists = false
    return inst
end

return Prefab("um_ocupus_eyetacle", fn, assets),
Prefab("um_ocupus_eye", fneye, assets),
Prefab("um_ocupus_tentacle_fisher",fnfishtentacle),
Prefab("um_ocupus_tentacle_reaper",fnreapertentacle)

