local assets = {
	Asset("ANIM", "anim/um_poofshrooms.zip"),
}

local function OnSave(inst)
	local data
	data.color = inst.color
	data.variant = inst.variant
	return data
end

local function OnLoad(inst,data)
	if data then
		inst.color = data.color
		inst.variant = data.variant
	end
end


local colors = {"r","g","b"}
local function Init(inst)
	if not inst.color then
		inst.color = colors[math.random(1,#colors)]
	end
	if not inst.variant then
		inst.variant = math.random(1,11)
	end

end

local function poofshroom()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("NOBLOCK")
	inst.AnimState:SetBuild("um_poofshroom")

    inst.entity:SetPristine()
	
    if not TheWorld.ismastersim then
        return inst
    end


	inst:DoTaskInTime(0,Init)

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad



    MakeMediumBurnable(inst)
    MakeSmallPropagator(inst)
end

return Prefab("um_poofshroom", poofshroom,assets)