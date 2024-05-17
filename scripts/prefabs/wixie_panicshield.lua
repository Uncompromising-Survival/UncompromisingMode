local assets =
{
	Asset("ANIM", "anim/stalker_shield.zip"),
}

local SLEEPREPEL_MUST_TAGS = { "_combat" }
local SLEEPREPEL_CANT_TAGS = { "player", "companion", "shadow", "playerghost", "INLIMBO", "toadstool", "notarget" }

require("wixie_shove")

local function StartRepel(inst)
	if inst.host ~= nil then
		local x, y, z = inst.Transform:GetWorldPosition()

		local ents = TheSim:FindEntities(x, y, z, 4, SLEEPREPEL_MUST_TAGS, SLEEPREPEL_CANT_TAGS)

		for i, v in ipairs(ents) do
			if v.components.combat ~= nil then
				v:PushEvent("attacked", { attacker = inst.host, damage = 0, weapon = nil })
			end

			if v.components.locomotor ~= nil and not v:HasTag("stageusher") and (v.sg ~= nil and not v.sg:HasStateTag("noshove") or v.sg == nil) then
				WixieShove(inst.host, v, 2, false, nil, nil, true)
			end
		end
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst:AddTag("FX")

	inst.AnimState:SetBank("stalker_shield")
	inst.AnimState:SetBuild("stalker_shield")
	inst.AnimState:PlayAnimation("idle" .. math.random(3))
	inst.AnimState:SetFinalOffset(2)
	--inst.AnimState:SetScale(1, 1, 1)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/shield")

	inst.persists = false
	inst:ListenForEvent("animover", inst.Remove)
	inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + FRAMES, inst.Remove)

	inst:DoTaskInTime(2 * FRAMES, StartRepel)

	return inst
end

return Prefab("wixie_panicshield", fn, assets)
