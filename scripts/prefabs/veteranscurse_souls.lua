local wortox_soul_common = require("prefabs/wortox_soul_common")

local assets =
{
    Asset("ANIM", "anim/wortox_soul_ball.zip"),
    Asset("SCRIPT", "scripts/prefabs/wortox_soul_common.lua"),
}

local prefabs =
{
    "wortox_soul_heal_fx",
}

local function topocket(inst)
    inst.persists = true
    if inst._task ~= nil then
        inst._task:Cancel()
        inst._task = nil
    end
end

local function StartRepel(inst)
	local x, y, z = inst.Transform:GetWorldPosition() 
	local ents = TheSim:FindEntities(x, y, z, 4, nil, { "wortox_vetcurse" })
	for i, v in ipairs(ents) do
		if v ~= inst and v:IsValid() and not v:IsInLimbo() then
			print(v)
			if v.components.combat ~= nil and not (v.components.health ~= nil and v.components.health:IsDead()) then
				print("should do attack")
				v.components.combat:GetAttacked(inst, inst.damage)
			end
		end
	end
end

local function KillSoul(inst)
    inst.AnimState:PlayAnimation("idle_pst")
	
	if inst.animover ~= nil then
		inst.animover:Cancel()
	end
	
    inst:RemoveEventCallback("animover", KillSoul, inst)
    inst.AnimState:PlayAnimation("idle_pst")
	
	local fx = SpawnPrefab("explosive_vetscurse_soul_burst")
    fx.damage = inst.damage
	fx.entity:SetParent(inst.entity)
	
	inst:DoTaskInTime(2 * FRAMES, StartRepel)
	
    inst:ListenForEvent("animover", inst.Remove)
	
    inst.SoundEmitter:PlaySound("dontstarve/characters/wortox/soul/spawn", nil, .5)
end

local function IdleLoop(inst)
    inst.AnimState:PlayAnimation("idle_loop")
	
	if inst.animover ~= nil then
		inst.animover:Cancel()
	end
	
    inst:RemoveEventCallback("animover", IdleLoop, inst)
	
    inst.animover = inst:ListenForEvent("animover", KillSoul)
end

local function Init(inst)
    inst.AnimState:PlayAnimation("idle_pre")
    inst.animover = inst:ListenForEvent("animover", IdleLoop)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("wortox_soul_ball")
    inst.AnimState:SetBuild("wortox_soul_ball")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    --inst:AddComponent("inspectable")
	
	Init(inst)
	
	inst.persists = false
	
    inst.damage = 1

    return inst
end

local function burstfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

	inst.AnimState:SetBank("stalker_shield")
	inst.AnimState:SetBuild("stalker_shield")
	inst.AnimState:PlayAnimation("idle"..math.random(3))
	inst.AnimState:SetFinalOffset(2)
	inst.Transform:SetScale(1.3, 1.3, 1.3)
	
    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
	inst:AddComponent("highlight")
	inst.AnimState:SetHighlightColour(255, 0, 0, 0)

	inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/shield")

	inst:ListenForEvent("animover", inst.Remove)
	inst.persists = false

    inst.damage = 1

    return inst
end

local function vestigefn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)
	--RemovePhysicsColliders(inst)

	inst.AnimState:SetBank("wortox_soul_ball")
	inst.AnimState:SetBuild("wortox_soul_ball")
	inst.AnimState:PlayAnimation("idle_loop", true)
    inst.AnimState:SetMultColour(0, 0, 0, .6)
	inst.AnimState:UsePointFiltering(true)
	
	inst:AddTag("nosteal")

	inst:AddTag("waterproofer")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("waterproofer")
	inst.components.waterproofer:SetEffectiveness(0)
			
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/um_dark_vestiges.xml"

	return inst
end

local function KillVetSoul(inst)
    inst:ListenForEvent("animover", inst.Remove)
    inst.AnimState:PlayAnimation("idle_pst")
    inst.SoundEmitter:PlaySound("dontstarve/characters/wortox/soul/spawn", nil, .5)
end

local function toground(inst)
    inst.persists = false
    if inst._task == nil then
        inst._task = inst:DoTaskInTime(.4 + math.random() * .7, KillVetSoul) -- NOTES(JBK): This is 1.1 max keep it in sync with "[WST]"
    end
    if inst.AnimState:IsCurrentAnimation("idle_loop") then
		inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)
    end
end

local function ColorRando(inst)
		inst.AnimState:SetSymbolAddColour("moon_glow", math.random(), math.random(), math.random(), math.random())
		inst.AnimState:SetSymbolAddColour("blob", math.random(), math.random(), math.random(), math.random())
		
		inst.AnimState:SetSymbolAddColour("moon_glow2", math.random(), math.random(), math.random(), math.random())
		
		inst.AnimState:SetSymbolAddColour("spiral_ripple", math.random(), math.random(), math.random(), math.random())
		inst.AnimState:SetSymbolAddColour("tail", math.random(), math.random(), math.random(), math.random())
		inst.AnimState:SetSymbolAddColour("outer_fire", math.random(), math.random(), math.random(), math.random())
		inst.AnimState:SetSymbolAddColour("swirl1", math.random(), math.random(), math.random(), math.random())
		inst.AnimState:SetSymbolAddColour("swirl2", math.random(), math.random(), math.random(), math.random())
		inst.AnimState:SetSymbolAddColour("swirl3", math.random(), math.random(), math.random(), math.random())
end

local function MakeSoul(name, glow, glow2, swirl, multcolor, chaotic, colortype)
	local function func()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddNetwork()

		MakeInventoryPhysics(inst)
		--RemovePhysicsColliders(inst)

		inst.AnimState:SetBank("wortox_soul_ball")
		
		if colortype ~= nil then
			inst.AnimState:SetBuild("wortox_soul_ball"..colortype)
		else
			inst.AnimState:SetBuild("wortox_soul_ball")
		end
		
		inst.AnimState:PlayAnimation("idle_loop", true)
		
		local mult_r, mult_g, mult_b, mult_a = unpack(multcolor)
		inst.AnimState:SetMultColour(mult_r, mult_g, mult_b, mult_a)

		local glow_r, glow_g, glow_b, glow_a = unpack(glow)
		inst.AnimState:SetSymbolAddColour("moon_glow", glow_r, glow_g, glow_b, glow_a)
		inst.AnimState:SetSymbolAddColour("blob", glow_r, glow_g, glow_b, glow_a)
		
		local glow2_r, glow2_g, glow2_b, glow2_a = unpack(glow2)
		inst.AnimState:SetSymbolAddColour("moon_glow2", glow2_r, glow2_g, glow2_b, glow2_a)
		inst.AnimState:SetSymbolAddColour("shimmer_sprite", glow2_r, glow2_g, glow2_b, glow2_a)
		
		local swirl_r, swirl_g, swirl_b, swirl_a = unpack(swirl)
		inst.AnimState:SetSymbolAddColour("spiral_ripple", swirl_r, swirl_g, swirl_b, swirl_a)
		inst.AnimState:SetSymbolAddColour("tail", swirl_r, swirl_g, swirl_b, swirl_a)
		inst.AnimState:SetSymbolAddColour("outer_fire", swirl_r, swirl_g, swirl_b, swirl_a)
		inst.AnimState:SetSymbolAddColour("swirl1", swirl_r, swirl_g, swirl_b, swirl_a)
		inst.AnimState:SetSymbolAddColour("swirl2", swirl_r, swirl_g, swirl_b, swirl_a)
		inst.AnimState:SetSymbolAddColour("swirl3", swirl_r, swirl_g, swirl_b, swirl_a)

		inst:AddTag("nosteal")
		--inst:AddTag("NOCLICK")
		inst:AddTag("vetsoul")

		inst:AddTag("waterproofer")

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		--inst:AddComponent("inventoryitem")

		inst:AddComponent("inspectable")
		inst.components.inspectable.nameoverride = "UM_BOSS_SOUL"

		inst:AddComponent("waterproofer")
		inst.components.waterproofer:SetEffectiveness(0)
			
		inst:AddComponent("inventoryitem")
		inst.components.inventoryitem.atlasname = "images/inventoryimages/"..name..".xml"
		
		if chaotic then
			inst:DoPeriodicTask(1, ColorRando)
		end
			
		--inst:ListenForEvent("onputininventory", topocket)
		--inst:ListenForEvent("ondropped", toground)
		--inst._task = nil
		--toground(inst)

		return inst
	end

    return Prefab(name, func)
end

return Prefab("explosive_vetscurse_soul", fn, assets, prefabs),
		Prefab("explosive_vetscurse_soul_burst", burstfn, assets, prefabs),
		Prefab("um_dark_vestiges", vestigefn, assets, prefabs),
		MakeSoul("um_cherry_beequeen_soul", {1, 1, 0, 1}, {1, 1, 0, 1}, {0, .5, 0, 1}, {.6, 1, 0, 1}),
		MakeSoul("um_deerclops_soul", {1, 1, 1, 1}, {0, .5, 1, 1}, {1, 1, 1, 1}, {.5, 1, 1, 1}),
		MakeSoul("um_crabking_soul", {0, 0, 0, 1}, {0, .5, 1, 1}, {0, 0, 0, 1}, {.5, 1, 1, 1}),
		MakeSoul("um_goose_soul", {1, 1, 0, 1}, {1, 1, 0, 1}, {0, .5, 0, 1}, {1, 1, 0, 1}),
		MakeSoul("um_malbatross_soul", {0, 0, 1, 1}, {0, 0, 1, 1}, {0, 0, 1, 1}, {.5, .5, 1, 1}),
		MakeSoul("um_beequeen_soul", {1, 1, 0, 1}, {0, 0, 0, 1}, {1, 1, 0, 1}, {1, 1, 0, 1}, false, "_blue"),
		MakeSoul("um_dragonfly_soul", {.7, .5, .1, 1}, {0, .4, .5, 1}, {.3, .6, .1, 1}, {1, .5, .3, 1}, false, "_green"),
		MakeSoul("um_bearger_soul", {0, 0, 1, 1}, {1, 1, .3, 1}, {0, 0, .5, 1}, {.6, .3, .4, 1}, false, "_green"),
		MakeSoul("um_klaus_soul", {.2, 0, .8, 1}, {.8, 0, 0, 1}, {0, 0, 0, 1}, {1, 0, 1, 1}, false, "_green"),
		MakeSoul("um_hoodedwidow_soul", {0, 0, 0, 1}, {1, 0, 0, 1}, {1, .3, .2, 1}, {1, .9, .7, 1}, false, "_blue"),
		MakeSoul("um_fuelweaver_soul", {0, 0, 1, 1}, {0, 0, 0, 1}, {.5, 0, 0, 1}, {1, 0, .2, 1}, false, "_blue"),
		MakeSoul("um_minotaur_soul", {0, 0, 0, 1}, {0, 0, 0, 1}, {0, 0, 0, 1}, {1, .2, 1, 1}, false, "_green"),
		MakeSoul("um_moonmaw_soul", {0, 0, 1, 1}, {1, 1, .3, 1}, {0, 0, .5, 1}, {.6, .3, .4, 1}, false, "_blue"),
			
		
		
		MakeSoul("um_chaotic_soul", {0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0}, {1, 1, 1, 1}, true)