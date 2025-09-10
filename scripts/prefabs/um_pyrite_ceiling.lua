local assets =
{
    Asset("ANIM", "anim/um_pyrite_ceiling.zip"),
	
	Asset("IMAGE", "images/map_icons/um_pyrite_ceiling.tex"),
	Asset("ATLAS", "images/map_icons/um_pyrite_ceiling.xml"),	
}

local function Regrow(inst,data)
	inst.fullness = inst.fullness + 1
	if inst.fullness == 2 then
		inst.AnimState:PlayAnimation("idle_full",true)
	elseif inst.fullness ~= 2 then
		inst.AnimState:PlayAnimation("idle_medium",true)
		inst.components.timer:StartTimer("regrow",80*8*5)
	end
end

local dont_damage = { "FX", "notarget", "noattack", "playerghost","irreplaceable"}
local function DamageSurroundings(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, 2, nil,dont_damage)
	if #ents > 0 then
		for i, v in pairs(ents) do
			if v ~= inst then
				if v.components.burnable ~= nil then
					v.components.burnable:Ignite()
				elseif v.components.inventoryitem then
					v:Remove()
				end
				if v.components.combat then
					v.components.combat:GetAttacked(inst,50)
				end
			end
		end
	end
end

local function ListenForCrash(pyre)
	pyre.listenfall = pyre:DoPeriodicTask(0.1,function(pyre)
		local x,y,z = pyre.Transform:GetWorldPosition()
		if y < 0.5 then
			local fx = SpawnPrefab("explosivehit")
			fx.Transform:SetPosition(pyre.Transform:GetWorldPosition())
			fx.Transform:SetScale(1.25,1.25,1.25)
			fx:DoTaskInTime(2,function(fx) fx:Remove() end)
			DamageSurroundings(pyre)
			pyre.listenfall:Cancel()
			pyre.listenfall = nil
		end
	end)
end

local function DropLoot(inst)
	if inst.fullness ~= 0 then
		inst.fullness = inst.fullness - 1
		if inst.fullness == 0 then
			inst.AnimState:PlayAnimation("shatter_empty")
			inst.AnimState:PushAnimation("idle_empty",true)
		else
			inst.AnimState:PlayAnimation("shatter_medium",true)
			inst.AnimState:PushAnimation("idle_medium",true)
		end
	end
	local x,y,z = inst.Transform:GetWorldPosition()
	local pyre = SpawnPrefab("um_fyrite")
	pyre.Transform:SetPosition(x+math.random(-2,2),y+10,z+math.random(-2,2))
	local fx = SpawnPrefab("explosivehit")
	fx.Transform:SetPosition(pyre.Transform:GetWorldPosition())
	fx.Transform:SetScale(1.25,1.25,1.25)
	fx:DoTaskInTime(2,function(fx) fx:Remove() end)
	ListenForCrash(pyre)
	
	if math.random() > 0.9 then
		local pyre = SpawnPrefab("um_fyrite")
		pyre.Transform:SetPosition(x+math.random(-2,2),y+10,z+math.random(-2,2))
		ListenForCrash(pyre)
	end
	if inst.components.timer and not inst.components.timer:TimerExists("regrow") then
		inst.components.timer:StartTimer("regrow",80*8*5)
	end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
	inst.entity:AddMiniMapEntity()
    inst.Transform:SetTwoFaced()

    inst.AnimState:SetBuild("um_pyrite_ceiling")
    inst.AnimState:SetBank("um_pyrite_ceiling")
    inst.AnimState:PlayAnimation("idle_full", true)

    inst:AddTag("NOCLICK")
	inst.MiniMapEntity:SetIcon("um_pyrite_ceiling.tex")
    inst.no_wet_prefix = true


    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

	inst:DoTaskInTime(0,function(inst)
		if not inst.rotation then
			inst.rotation = math.random(0,1)
			if inst.rotation == 0 then
				inst.Transform:SetScale(-1,1,1)
			end
		end
		if not inst.fullness then
			inst.fullness = 2
			inst.AnimState:PlayAnimation("idle_full")
		end
	end)
	
	inst.OnSave = function(inst,data)
		if data then
			data.rotation = inst.rotation or nil
			data.fullness = inst.fullness
		end
	end
	
	inst.OnLoad = function(inst,data)
		if data then
			if data.rotation then
				inst.rotation = data.rotation
				if inst.rotation == 0 then
					inst.Transform:SetScale(-1,1,1)
				end
			end
			if data.fullness then
				inst.fullness = data.fullness
				if inst.fullness == 2 then
					inst.AnimState:PlayAnimation("idle_full")
				elseif inst.fullness == 1 then
					inst.AnimState:PlayAnimation("idle_medium")
				else
					inst.AnimState:PlayAnimation("idle_empty")
				end
			end
		end
	end
	
	inst:AddComponent("timer")
	inst:ListenForEvent("timerdone",Regrow)

    inst:ListenForEvent("startquake", function()
        inst:DoTaskInTime(math.random(4,10), DropLoot)
    end, TheWorld.net)	
    return inst
end

return Prefab("um_pyrite_ceiling", fn, assets)
