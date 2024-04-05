local assets =
{
    Asset("ANIM", "anim/thurible.zip"),
    Asset("ANIM", "anim/swap_thurible.zip"),
}

local prefabs =
{
    "thuriblebody",
    "thurible_smoke",
}

local function DoExtinguishSound(inst, owner)
    inst._soundtask = nil
    (owner ~= nil and owner:IsValid() and owner.SoundEmitter or inst.SoundEmitter):PlaySound("dontstarve/common/fireOut")
end

local function PlayExtinguishSound(inst)
    if inst._soundtask == nil and inst:GetTimeAlive() > 0 then
        inst._soundtask = inst:DoTaskInTime(0, DoExtinguishSound, inst.components.inventoryitem.owner)
    end
end

local function PlayIgniteSound(inst)
    if inst._soundtask ~= nil then
        inst._soundtask:Cancel()
        inst._soundtask = nil
    elseif not POPULATING then
        inst._light.SoundEmitter:PlaySound("dontstarve/wilson/torch_swing")
    end
end

local function onremovesmoke(smoke)
    smoke._thurible._light = nil
end

local function turnon(inst)

        if inst._body ~= nil or not inst.components.inventoryitem:IsHeld() then
            if inst._light == nil then
                inst._light = SpawnPrefab("um_moonfly_lantern_light")
                inst._light.entity:AddFollower()
                inst._light._thurible = inst
                inst:ListenForEvent("onremove", onremovesmoke, inst._light)
                PlayIgniteSound(inst)
            end
            if inst._body ~= nil and
                not inst._body.entity:IsVisible() and
                inst.components.inventoryitem.owner ~= nil then
                inst._light.Follower:FollowSymbol(inst.components.inventoryitem.owner.GUID, "swap_object", 68, -70, 0)
            else
                inst._light.Follower:FollowSymbol((inst._body or inst).GUID, "thurible_swing", 0, 185, 0)
            end
        elseif inst._light ~= nil then
            inst._light:Remove()
            PlayExtinguishSound(inst)
        end
end

local function turnoff(inst)
    if inst._light ~= nil then
        inst._light:Remove()
        PlayExtinguishSound(inst)
    end
end

local function OnRemove(inst)
    if inst._light ~= nil then
        inst._light:Remove()
    end
    if inst._body ~= nil then
        inst._body:Remove()
    end
    if inst._soundtask ~= nil then
        inst._soundtask:Cancel()
    end
end

local function ondropped(inst)
    turnoff(inst)
    turnon(inst)
end

local function ToggleOverrideSymbols(inst, owner)
    if owner.sg == nil or (owner.sg:HasStateTag("nodangle")
            or (owner.components.rider ~= nil and owner.components.rider:IsRiding()
                and not owner.sg:HasStateTag("forcedangle"))) then
        owner.AnimState:OverrideSymbol("swap_object", "swap_dy", "swap_thurible")
        inst._body:Hide()
        if inst._light ~= nil then
            inst._light.Follower:FollowSymbol(owner.GUID, "swap_object", 65, 0, 0)
        end
    else
        owner.AnimState:OverrideSymbol("swap_object", "swap_thurible", "swap_thurible_stick")
        inst._body:Show()
        if inst._light ~= nil then
            inst._light.Follower:FollowSymbol(inst._body.GUID, "thurible_swing", 0, 185, 0)
        end
    end
end

local function onremovebody(body)
    body._thurible._body = nil
end

local function CheckForLight(owner)
	local x, y, z = owner.Transform:GetWorldPosition()
	local lights = TheSim:FindEntities(x, y, z, 1.8, { "um_moonfly_trail" })
	
	if lights == nil or lights ~= nil and #lights == 0 then
		SpawnPrefab("um_moonfly_lantern_trail").Transform:SetPosition(x, y, z)
	end
end

local function onequip(inst, owner)
	if not owner:HasTag("vetcurse") then
		inst:DoTaskInTime(0, function(inst, owner)
			local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner
			local tool = owner ~= nil and owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
			if tool ~= nil and owner ~= nil then
				owner.components.inventory:Unequip(EQUIPSLOTS.HANDS)
				owner.components.inventory:DropItem(tool)
				owner.components.inventory:GiveItem(inst)
				owner.components.talker:Say(GetString(owner, "CURSED_ITEM_EQUIP"))
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/HUD_hot_level1")

				if owner.sg ~= nil then
					owner.sg:GoToState("hit")
				end
			end
		end)
	else
		owner.AnimState:Show("ARM_carry")
		owner.AnimState:Hide("ARM_normal")

		if inst._body ~= nil then
			inst._body:Remove()
		end
		inst._body = SpawnPrefab("um_moonfly_lantern_body")
		inst._body._thurible = inst
		inst:ListenForEvent("onremove", onremovebody, inst._body)

		inst._body.entity:SetParent(owner.entity)
		inst._body.entity:AddFollower()
		inst._body.Follower:FollowSymbol(owner.GUID, "swap_object", 68, -130, 0)
		inst._body:ListenForEvent("newstate", function(owner, data)
			ToggleOverrideSymbols(inst, owner)
		end, owner)
		
		owner:AddTag("um_moonfly_lantern_user")
		
		owner.moonfly_lantern_trail_task = owner:DoPeriodicTask(.15, CheckForLight)

		ToggleOverrideSymbols(inst, owner)

		turnon(inst)
	end
end

local function onunequip(inst, owner)
    if inst._body ~= nil then
        if inst._body.entity:IsVisible() then
            --need to see the thurible when animating putting away the object
            owner.AnimState:OverrideSymbol("swap_object", "swap_thurible", "swap_thurible")
        end
        inst._body:Remove()
    end

    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
	
	owner:RemoveTag("um_moonfly_lantern_user")
	
	if owner.moonfly_lantern_trail_task ~= nil then
		owner.moonfly_lantern_trail_task:Cancel()
	end
	
	owner.moonfly_lantern_trail_task = nil

    turnoff(inst)
end

local function onequiptomodel(inst, owner, from_ground)
    turnoff(inst)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("um_moonfly_lantern")
    inst.AnimState:SetBuild("um_moonfly_lantern")
    inst.AnimState:PlayAnimation("idle_loop", true)
    inst.AnimState:SetFinalOffset(1)

    inst:AddTag("light")
    inst:AddTag("nopunch")
    inst:AddTag("vetcurse_item")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)

    inst:AddComponent("tradable")
    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnDroppedFn(ondropped)
    inst.components.inventoryitem:SetOnPutInInventoryFn(turnoff)
    inst.components.inventoryitem:SetSinks(true)

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable:SetOnEquipToModel(onequiptomodel)
    inst.components.equippable.walkspeedmult = TUNING.CANE_SPEED_MULT - 0.1

    MakeHauntableLaunch(inst)

    inst.OnRemoveEntity = OnRemove
    --inst.OnLoad = OnLoad

    inst._light = nil
    inst._light = nil
    turnon(inst)

    return inst
end

local function thuriblebodyfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("um_moonfly_lantern")
    inst.AnimState:SetBuild("um_moonfly_lantern")
    inst.AnimState:PlayAnimation("idle_body_loop", true)
    inst.AnimState:SetFinalOffset(1)

    inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)

    inst.persists = false

    return inst
end

local function OnLightWake(inst)
    if not inst.SoundEmitter:PlayingSound("loop") then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/lantern_LP", "loop")
    end
end

local function OnLightSleep(inst)
    inst.SoundEmitter:KillSound("loop")
end

local function lanternlightfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddLight()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst.Light:SetColour(0 / 255, 155 / 255, 255 / 255)
	inst.Light:SetIntensity(.6)
	inst.Light:SetRadius(5)
	inst.Light:SetFalloff(.9)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst.OnEntityWake = OnLightWake
    inst.OnEntitySleep = OnLightSleep

    return inst
end

local function TrySpeedUp(inst, target)
	local debuffkey = inst.prefab
	if target._moonfly_lantern_speedmulttask ~= nil then
		target._moonfly_lantern_speedmulttask:Cancel()
	end
	
	target._moonfly_lantern_speedmulttask = target:DoTaskInTime(0.25, function(i) i.components.locomotor:RemoveExternalSpeedMultiplier(i, debuffkey) i._moonfly_lantern_speedmulttask = nil end)

	target.components.locomotor:SetExternalSpeedMultiplier(target, debuffkey, 1.15)
end

local function DoAreaChecks(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
	
	local ents = TheSim:FindEntities(x, y, z, 2.1, { "locomotor" }, { "INLIMBO" }, { "player", "companion", "abigail" })
	for i, v in ipairs(ents) do
		if v:HasTag("flying") or not v:HasTag("flying") then
			if v.components ~= nil and v.components.locomotor ~= nil then
				TrySpeedUp(inst, v)
			end
		end
	end
	
	local lantern_users = TheSim:FindEntities(x, y, z, 2, { "um_moonfly_lantern_user" })
	if lantern_users ~= nil and #lantern_users > 0 then
		if inst.strength < 2 then
			inst.strength = inst.strength + .1
		end
	elseif inst.StartUpTask == nil then
		inst.strength = inst.strength - .02
	end
	
    inst.AnimState:SetMultColour(0.6, 0.6, 1, inst.strength / 2)
	inst.Light:SetIntensity(inst.strength / 3)
	
	if inst.strength <= 0 then
		inst:Remove()
	end
end

local function trailfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddPhysics()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

	inst.Light:SetFalloff(.9)
    inst.Light:SetIntensity(0)
    inst.Light:SetRadius(2)
    inst.Light:SetColour(0/255, 155/255, 255/255)
    inst.Light:Enable(true)

    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst.AnimState:SetBank("fireflies")
    inst.AnimState:SetBuild("fireflies")
	inst.AnimState:PlayAnimation("swarm_pre")
	inst.AnimState:PushAnimation("swarm_loop", true)
    inst.AnimState:SetRayTestOnBB(true)

    inst:AddTag("NOBLOCK")
    inst:AddTag("NOCLICK")
	inst:AddTag("um_moonfly_trail")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
	inst.strength = 1.5
	
	inst:DoPeriodicTask(0.1, DoAreaChecks, 0)

    return inst
end

return Prefab("um_moonfly_lantern", fn, assets, prefabs),
    Prefab("um_moonfly_lantern_body", thuriblebodyfn),
    Prefab("um_moonfly_lantern_light", lanternlightfn),
    Prefab("um_moonfly_lantern_trail", trailfn)