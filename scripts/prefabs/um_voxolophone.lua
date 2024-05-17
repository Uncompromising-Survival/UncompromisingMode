local assets =
{
    Asset("ANIM", "anim/um_voxolophone.zip"),
}

local function GetStatus(inst)
    return inst.playingmusic and "WARN"
        or "WANING"
end

local function TalkAboutIt(inst)
	if inst.playingmusic then
		inst.fx = SpawnPrefab("dr_warm_loop_1")
		inst.fx.entity:SetParent(inst.entity)
		inst.fx.Transform:SetPosition(0, 0, 0)
		inst.components.talker:Say(STRINGS.UM_VOXOLOPHONE.SPAWN_TALK[math.random(#STRINGS.UM_VOXOLOPHONE.SPAWN_TALK)])
	end
end

local function WarnPlayer(inst, data)
	if data ~= nil and data.threat ~= nil then
		print(data.threat)
		inst.fx = SpawnPrefab("dr_warm_loop_1")
		inst.fx.entity:SetParent(inst.entity)
		inst.fx.Transform:SetPosition(0, 0, 0)
		inst.components.talker:Say(data.threat[math.random(#data.threat)])
	end
end

local function ondonetalking(inst)
    inst.SoundEmitter:KillSound("talk")
end

local function ontalk(inst)
	inst.SoundEmitter:KillSound("talk")
	inst.SoundEmitter:KillSound("um_voxolophone_static")
	inst.SoundEmitter:PlaySound("UCSounds/um_voxolophone/um_voxolophone_static", "um_voxolophone_static")
	inst.SoundEmitter:PlaySound("UCSounds/pawn/ping_warmer", "talk")
end

local function Despawn(inst)
	inst:Remove()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("um_voxolophone")
    inst.AnimState:SetBuild("um_voxolophone")
    inst.AnimState:PlayAnimation("idle")

	inst:AddTag("um_voxolophone")
	inst:AddTag("irreplaceable")

    MakeInventoryFloatable(inst, "med", nil, 0.62)

    inst.entity:SetPristine()
	
    inst:AddComponent("talker")
    inst.components.talker.fontsize = 28
    inst.components.talker.font = TALKINGFONT
    inst.components.talker.colour = Vector3(.9, .4, .4)
    inst.components.talker.offset = Vector3(0, 3, 0)
    inst.components.talker:MakeChatter()
    inst.components.talker.lineduration = TUNING.HERMITCRAB.SPEAKTIME * 1.25 -0.5
    --inst.components.talker.symbol = "swap_object"

    inst:AddComponent("npc_talker")

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    MakeHauntableLaunch(inst)

    inst.playingmusic = false      
	
	inst:ListenForEvent("um_voxolophone_warning", function(_, data)
		WarnPlayer(inst, data)
	end, TheWorld)
	
	inst:ListenForEvent("ontalk", ontalk)
	inst:ListenForEvent("donetalking", ondonetalking)
	
	inst:WatchWorldState("isday", Despawn)

    return inst
end

return Prefab("um_voxolophone", fn, assets)