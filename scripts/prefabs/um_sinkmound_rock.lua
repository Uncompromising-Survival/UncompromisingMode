local assets =
{
    Asset("ANIM", "anim/um_sinkmound.zip"),
	Asset("IMAGE", "images/map_icons/um_sinkmound_rock_icon.tex"),
	Asset("ATLAS", "images/map_icons/um_sinkmound_rock_icon.xml"),		
}

local creature_features = {
	"spider",
	"rabbit",
	"mole",
	"worm",
	"catcoon",
	"slurtle",
	"snurtle",
	"spider_warrior",
	"spider_spitter",
	"spider_hider",
	"spider_dropper",
	"slurper",
}

local function GenerateCreature(inst,worker)
	local creature_prefab = creature_features[math.random(1,#creature_features)]
	for i = 1,math.random(1,3) do
		local creature = inst.components.lootdropper:SpawnLootPrefab(creature_prefab)
		creature.Transform:SetPosition(inst.Transform:GetWorldPosition())
		if creature:HasTag("hostile") and not (creature:HasTag("spider") and worker:HasTag("spiderwhisperer")) then --AXE if the creature is a hostile creature, make it automatically angry at the player, unless it's spiders + webber
			creature.components.combat:SetTarget(worker)
		end
	end
end

local function OnWork(inst, worker, workleft)
    if workleft <= 0 then
        local pt = inst:GetPosition()
        SpawnPrefab("rock_break_fx").Transform:SetPosition(pt.x, pt.y, pt.z)
        inst.components.lootdropper:DropLoot(pt)
		GenerateCreature(inst,worker) --AXE We decided to go against it just having random creatures... it wasn't as interesting as it being a bunnyman stash
		if inst.prefab == "um_sinkmound_rock" then -- gemmed version drops the geode too
			inst.components.lootdropper:SpawnLootPrefab("um_gemology_geode_sink")
		end		
		local spawner = SpawnPrefab("um_sinkmound_rock_respawner")
		spawner.Transform:SetPosition(inst.original_pos.x,0,inst.original_pos.z)
		spawner.original_pos = inst.original_pos
		inst:Remove()
    else
		inst.AnimState:PlayAnimation(
			(workleft < TUNING.ROCKS_MINE / 3 and "low") or
			(workleft < TUNING.ROCKS_MINE * 2 / 3 and "med") or
			"full"
		)
    end
end

SetSharedLootTable( 'um_sinkmound',
{
    {'rocks',   1.0},
    {'rocks',   1.0},
	{'rocks',   1.0},
	{'flint',   1.0},
	{'flint',   0.5},
	{'twigs',   0.5},
	{'cutgrass',   0.5},
	{'foliage',   0.5},
})

local function OnSave(inst)
	local data = {}
	data.original_pos = inst.original_pos
	return data
end

local function OnLoad(inst,data)
	if data and data.original_pos then
		inst.original_pos = data.original_pos
	else
		inst.original_pos = inst:GetPosition()
	end
end

local function rockmain(bank)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)

	inst.MiniMapEntity:SetIcon("um_sinkmound_rock_icon.tex")

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild("um_sinkmound")
	inst.AnimState:PlayAnimation("full")


    inst:AddTag("boulder")


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("um_sinkmound")
	
    local workable = inst:AddComponent("workable")
    workable:SetWorkAction(ACTIONS.MINE)
    workable:SetWorkLeft(TUNING.ROCKS_MINE)
	workable:SetOnWorkCallback(OnWork)
	

    local colour = math.random(75,100)*0.01
    inst.AnimState:SetMultColour(colour, colour, colour, 1)


    inst:AddComponent("inspectable")
	
	
    MakeHauntableWork(inst)
	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

    return inst
end

local function sinkmound_rock()
	return rockmain("um_sinkmound_gem")
end

local function sinkmound_rock_gemless()
	return rockmain("um_sinkmound_gemless")
end

local function SetUpTimer(inst)
	if not inst.components.timer:TimerExists("regrow") then
		inst.components.timer:StartTimer("regrow",10*480)
	end
end

local DAMAGE_ONEOF_TAGS = {"NPC_workable", "CHOP_workable", "HAMMER_workable", "MINE_workable", "DIG_workable" }


local function ReGrow(inst)
	local rock = SpawnPrefab(math.random() > 0.7 and "um_sinkmound_rock" or "um_sinkmound_rock_gemless")
	local offset = FindWalkableOffset(inst:GetPosition(), TWOPI*math.random(), math.random(4,10),12)
	local x,y,z = inst.Transform:GetWorldPosition()
	rock.Transform:SetPosition(x+offset.x,y,z+offset.z)
	rock.original_pos = inst.original_pos
	rock.AnimState:PlayAnimation("grow")
	rock.AnimState:PushAnimation("full")
	local structure_ents = TheSim:FindEntities(x, 0, z, 2,nil,nil,DAMAGE_ONEOF_TAGS)
	for i,v in ipairs(structure_ents) do
		if not (v.prefab == "um_sinkmound_rock" or v.prefab == "um_sinkmound_rock_gemless") then 
			SpawnPrefab("collapse_small").Transform:SetPosition(v.Transform:GetWorldPosition())
			v.components.workable:Destroy(inst)					
		end
	end
	inst:Remove()
end

local function OnGoHome(inst, child)
	-- Drops the hat before it goes home if it has any
	local hat = child.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
    if hat ~= nil then
        child.components.inventory:DropItem(hat)
    end
end

local function sinkmound_rock_respawner()
	local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst, 1)



    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
	inst.OnSave = OnSave
	inst.OnLoad = OnLoad
	
	inst:AddComponent("timer")
	inst:DoTaskInTime(0,SetUpTimer)
	inst:ListenForEvent("timerdone",ReGrow)
	
    return inst
end


return Prefab("um_sinkmound_rock", sinkmound_rock, assets),
Prefab("um_sinkmound_rock_gemless", sinkmound_rock_gemless, assets),
Prefab("um_sinkmound_rock_respawner",sinkmound_rock_respawner)