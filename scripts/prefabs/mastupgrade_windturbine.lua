local assets =
{
    Asset("ANIM", "anim/mastupgrade_lamp.zip"),
}

local prefabs =
{
	"collapse_small",
}

local LAMP_LIGHT_OVERRIDE = 1

local function ondeconstructstructure(inst, caster)
    local recipe = AllRecipes[inst.prefab]

    for i, v in ipairs(recipe.ingredients) do
        for n = 1, v.amount do
            inst._mast.components.lootdropper:SpawnLootPrefab(v.type)
        end
    end
end

local function mast_burnt(inst)
    if inst._mast ~= nil and inst._mast:IsValid() then
        inst.components.lootdropper:DropLoot(inst._mast:GetPosition())
        SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
    end
end

local function mast_lamp_off(inst)
    inst.AnimState:SetLightOverride(0)
    inst.AnimState:PlayAnimation("off")
    inst.SoundEmitter:KillSound("lamp")
end

local function mast_lamp_on(inst)
    inst.AnimState:SetLightOverride(LAMP_LIGHT_OVERRIDE)
    inst.AnimState:PlayAnimation("full", true)
    inst.SoundEmitter:PlaySound("dangerous_sea/common/mast_item/lamp_LP","lamp")
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.SoundEmitter:PlaySound("dangerous_sea/common/mast_item/place_lamp")
	
	inst.animqueueclear = inst:ListenForEvent("animover", function(inst)
		inst.startupdating = true
		
		if inst.animqueueclear ~= nil then
			inst.animqueueclear:Cancel()
		end
		
		inst.animqueueclear = nil
		inst.canupdatelight = true
	end)
end

local function onremove(inst)-----------------------------------------------------------------------------
    if inst._mast ~= nil and inst._mast:IsValid() then
        inst._mast._turbine = nil
    end
end

local function OnEntityReplicated(inst)
    local parent = inst.entity:GetParent()
    if parent ~= nil and parent.prefab == "mast" or parent.prefab == "mast_malbatross" then
        parent.highlightchildren = { inst }
    end
end

local function UpdateLight(inst)
	if inst._mast ~= nil and inst.canupdatelight ~= nil then
		local velocity = 0
		local sandstorm = 0

		local x, y, z = inst._mast.Transform:GetWorldPosition()

		local boat = TheWorld.Map:GetPlatformAtPoint(x, z)
		
		if boat ~= nil and boat:HasTag("boat") and boat.components ~= nil and boat.components.boatphysics ~= nil then
			velocity = boat.components.boatphysics:GetVelocity()
		end
		
		if TheWorld.components.sandstorms then
			sandstorm = (TheWorld.components.sandstorms ~= nil and TheWorld.components.sandstorms:IsSandstormActive()) and TheWorld.Map:FindVisualNodeAtPoint(x, y, z, "sandstorm") and 2 or 0
		end
		
		local snowstorm = ((TheWorld.net ~= nil and TheWorld.net:HasTag("snowstormstartnet")) or TheWorld:HasTag("snowstormstart")) and 2 or 0
		
		print(velocity)
		
		local finalnums = velocity + sandstorm + snowstorm
		
		if finalnums >= 1.5 then
			if not inst.AnimState:IsCurrentAnimation("spin") then
				inst.AnimState:PlayAnimation("spin", true)
			end
			if inst.powerlevel > 1000 then
				inst.powerlevel = 1000
			elseif inst.powerlevel < 400 then
				inst.powerlevel = inst.powerlevel + finalnums
			elseif inst.powerlevel > 400 and finalnums >= 3 then
				inst.powerlevel = inst.powerlevel + finalnums
			end
		elseif inst.powerlevel > 0 then
			if not inst.AnimState:IsCurrentAnimation("idle") then
				inst.AnimState:PlayAnimation("idle")
			end
			
			inst.powerlevel = inst.powerlevel - 5
		elseif inst.powerlevel < 0 then
			inst.powerlevel = 0
		end
		
		if inst.powerlevel < 0 then
			inst.lightlevel = 0
		else
			inst.lightlevel = inst.powerlevel / 800
		end
		
		if inst.lightlevel < 0 then
			inst.lightlevel = 0
		elseif inst.lightlevel > 1 then
			inst.lightlevel = 1
		end
		
		local lerpval = Lerp(.6, .9, inst.lightlevel)
		print(lerpval)
		if lerpval > .7 then
			lerpval = .7
		end
		
		if inst.lightlevel > 0 then
			inst.Light:SetIntensity(lerpval)
			inst.Light:SetRadius(inst.lightlevel * 7)
			inst.Light:SetFalloff(.9)
		else
			--inst.Light:Enable(false)
			inst.Light:SetIntensity(lerpval)
			inst.Light:SetRadius(inst.lightlevel * 7)
			inst.Light:SetFalloff(.9)
		end
		
		print(inst.powerlevel)

		inst.AnimState:SetDeltaTimeMultiplier(finalnums)
	end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("mastupgrade_windturbine")
    inst.AnimState:SetBuild("mastupgrade_windturbine")
    inst.AnimState:PlayAnimation("place")

    inst:AddTag("NOCLICK")
    inst:AddTag("DECOR")
	
    inst.Light:SetColour(180 / 255, 195 / 255, 150 / 255)
	inst.Light:Enable(true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = OnEntityReplicated
        return inst
    end
	
	inst.lightlevel = 0
	inst.powerlevel = 0
	inst.lightlevel = 0
	inst.maxlevel = 0
		
	inst.animqueueclear = nil
	inst.canupdatelight = nil

    inst.persists = false

    inst:AddComponent("updatelooper")
    inst.components.updatelooper:AddOnUpdateFn(UpdateLight)
	
	inst._mast = nil

    inst:AddComponent("lootdropper")

    inst:ListenForEvent("onbuilt", onbuilt)
    inst:ListenForEvent("onremove", onremove)

    inst:ListenForEvent("mast_burnt", mast_burnt)

    --inst:ListenForEvent("mast_lamp_on", mast_lamp_on)
    --inst:ListenForEvent("mast_lamp_off", mast_lamp_off)

    inst:ListenForEvent("ondeconstructstructure", ondeconstructstructure)

    return inst
end

local function itemfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("mastupgrade_lamp_item")
    inst.AnimState:SetBuild("mastupgrade_lamp")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", nil, 0.68)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("tradable")

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/mastupgrade_windturbine_item.xml"
    inst.components.inventoryitem:SetSinks(false)
	
    inst:AddComponent("upgrader")
    inst.components.upgrader.upgradetype = UPGRADETYPES.MAST
    inst.components.upgrader.upgradevalue = 1337

    MakeHauntableLaunchAndSmash(inst)

    return inst
end

return Prefab("mastupgrade_windturbine_item", itemfn, assets, prefabs),
    Prefab("mastupgrade_windturbine", fn, assets)