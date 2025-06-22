local assets =
{
    Asset("ANIM", "anim/um_steamcloud.zip"),
}

local function SetOff(inst)
	local days = TheWorld.state.cycles
	inst.Transform:SetRotation(days) -- Rotate the direction of wind as the world gets older
	inst.components.locomotor:RunForward()
end

local function FadeOut(inst)
	inst.AnimState:PlayAnimation("loop_pst")
	inst:ListenForEvent("animover",function(inst) inst:Remove() end)
end

local function MakeWet(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x,y,z,4)
	for i,v in ipairs(ents) do
		if v.components.moisture then
			local waterproofness = v.components.inventory and math.min(v.components.inventory:GetWaterproofness(),1) or 0
			v.components.moisture:DoDelta(2 * (1 - waterproofness), true)
		elseif not v:HasTag("wet") and not v.prefab == "um_hotspring" then
			v:AddTag("wet")
			v:DoTaskInTime(10,function(v) v:RemoveTag("wet") end) -- temporarily make things wet that usually aren't
		end
		if v.components.health and not v.components.health:IsDead() and v.components.temperature and v.components.temperature.current < 80 then
			v.components.temperature:DoDelta(3)
		end
	end
end


local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
	
    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("um_steamcloud")
    inst.AnimState:SetBuild("um_steamcloud")
    inst.AnimState:PlayAnimation("loop_pre",false)
	inst.AnimState:PushAnimation("loop",true)
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	inst.Transform:SetScale(0.5,0.5,0.5)

	inst:DoPeriodicTask(0,SetOff)
	inst:DoTaskInTime(math.random(30,60),function(inst)
		inst:ListenForEvent("animover",FadeOut)
	end)
    MakeHauntableLaunch(inst)
	inst.persists = false

    inst.AnimState:SetLayer(LAYER_WORLD)
    inst.AnimState:SetSortOrder(1)
	
	inst:AddComponent("locomotor")
	inst.components.locomotor.walkspeed = 2
	inst.components.locomotor.runspeed = 2
	inst:DoPeriodicTask(0.5,MakeWet)
    return inst
end


return Prefab("um_steamcloud", fn, assets)
