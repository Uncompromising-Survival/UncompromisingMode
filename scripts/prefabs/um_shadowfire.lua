local assets =
{
    Asset("ANIM", "anim/snowball.zip"),
}

local prefabs =
{
    "splash_snow_fx",
}

local firelevels =
{
    {anim="level1", sound="dontstarve/common/campfire", radius=2, intensity=.75, falloff=.33, colour = {0/255,255/255,0/255}, soundintensity=.1},
    {anim="level2", sound="dontstarve/common/campfire", radius=3, intensity=.8, falloff=.33, colour = {0/255,255/255,0/255}, soundintensity=.3},
    {anim="level3", sound="dontstarve/common/campfire", radius=4, intensity=.8, falloff=.33, colour = {0/255,255/255,0/255}, soundintensity=.6},
    {anim="level4", sound="dontstarve/common/campfire", radius=5, intensity=.9, falloff=.25, colour = {0/255,255/255,0/255}, soundintensity=1},
    {anim="level4", sound="dontstarve/common/forestfire", radius=6, intensity=.9, falloff=.2, colour = {0/255,255/255,0/255}, soundintensity=1},
    {anim="level5", sound="dontstarve/common/forestfire", radius=7, intensity=.9, falloff=.2, colour = {0/255,255/255,0/255}, soundintensity=1},
}

local function Burning(inst)
	local x, y, z = inst.Transform:GetWorldPosition() 
	local ents = TheSim:FindEntities(x, y, z, inst.stage / 2, nil, { "player", "willow_vetcurse" })
	for i, v in ipairs(ents) do
		if v ~= inst and v:IsValid() and not v:IsInLimbo() then
			if v:IsValid() and not v:IsInLimbo() then
				if v.components.health ~= nil and not (v.components.health ~= nil and v.components.health:IsDead()) then
					local dmg = -5
						
					if v:HasTag("pyromaniac") then
						dmg = -2.5
					end
						
					v.components.health:DoDelta(dmg, false, inst)
				end
			end
		end
	end
end

local function AdvanceStage(inst)
	inst.stage = inst.stage + 1

	if inst.burningtask == nil and inst.stage >= 3 then
		inst.burningtask = inst:DoPeriodicTask(0.5, Burning)
	else
		if inst.burningtask ~= nil then
			inst.burningtask:Cancel()
		end
		
		inst.burningtask = nil
	end
	
    inst.components.sanityaura.aura = 0.1 * inst.stage
end

local function ReverseStage(inst)
	inst.stage = inst.stage - 1

	if inst.burningtask ~= nil and inst.stage < 3 then
		inst.burningtask:Cancel()
		
		inst.burningtask = nil
	end
	
	if inst.stage <= 0 then
		inst:Remove()
	end
	
	
    inst.components.sanityaura.aura = 0.1 * inst.stage
end

local function cursedfirefn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
	
    if not TheNet:IsDedicated() then
		-- this is purely view related
		inst:AddComponent("um_shambler_transparency")
		inst.components.um_shambler_transparency.tag = "willow_vetcurse"
		inst.components.um_shambler_transparency:ForceUpdate()
	end
	
    inst.AnimState:SetBank("fire")
    inst.AnimState:SetBuild("fire")
    inst.AnimState:PlayAnimation("level4", true)
    inst.AnimState:SetRayTestOnBB(true)
    inst.AnimState:SetFinalOffset(FINALOFFSET_MAX)
	inst.AnimState:SetMultColour(0, 0, 0, 0.8)

    inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
	inst.stage = 1
	
	inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = 0
	
	inst.SoundEmitter:PlaySound("dontstarve/common/forestfire", "cursedfire")
	
	inst.AdvanceStage = AdvanceStage
	inst:DoPeriodicTask(3, ReverseStage)

    return inst
end

return Prefab("um_shadowfire", cursedfirefn, assets, prefabs)