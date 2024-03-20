local assets =
{
    Asset("ANIM", "anim/um_voxolophone.zip"),
}

local function GetStatus(inst)
    return inst.playingmusic and "WARN"
        or "WANING"
end

local function toground(inst)
	if TheWorld.state.isnewmoon then
		inst:StartMusic()
	end

	if inst.ringfx == nil then
		inst.ringfx = SpawnPrefab("um_vox_ring")
		inst.ringfx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	end
end

local function topocket(inst, owner)
	if inst.playingmusic then
		inst.playingmusic = false
        inst.SoundEmitter:KillSound("um_voxolophone_music")
        inst.SoundEmitter:KillSound("um_voxolophone_static")
        inst.SoundEmitter:PlaySound("UCSounds/gramaphone_music/gramaphone_end")
	end

	if inst.ringfx ~= nil then
		inst.ringfx:Remove()
		inst.ringfx = nil
	end
end

local function StartMusic(inst)
	inst.playingmusic = true
    inst.AnimState:PlayAnimation("playing")
	inst.SoundEmitter:PlaySound("UCSounds/um_voxolophone/um_voxolophone_static", "um_voxolophone_static")
	inst.SoundEmitter:PlaySound("UCSounds/um_voxolophone/um_voxolophone_music", "um_voxolophone_music")
end

local function OnSave(inst, data)
    data.playingmusic = inst.playingmusic
end

local function OnLoad(inst, data)
    if data then
        inst.playingmusic = data.playingmusic
		
		if inst.playingmusic then
			inst:StartMusic()
        end
    end
end

local function TalkAboutIt(inst)
	if inst.playingmusic then
		inst.fx = SpawnPrefab("dr_warm_loop_1")
		inst.fx.entity:AddFollower()
		inst.components.talker:Say(STRINGS.UM_VOXOLOPHONE.SPAWN_TALK)
	end
end

local function WarnPlayer(inst, data)
	if data ~= nil and data.threat ~= nil then
		print("Voxolophone Try Warning = "..data.threat)
		inst.fx = SpawnPrefab("dr_warm_loop_1")
		inst.fx.entity:AddFollower()
		inst.components.talker:Say(STRINGS.UM_VOXOLOPHONE.SHADOW_WARNING.data.threat)
	end
end

local function ondonetalking(inst)
    inst.SoundEmitter:KillSound("talk")
end

local function ontalk(inst)
	inst.SoundEmitter:KillSound("talk")
	inst.SoundEmitter:PlaySound("UCSounds/pawn/ping_warmer", "talk")
end

local function SpawnRing(inst)
	if TheWorld.state.isnewmoon then
	end
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

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/um_voxolophone.xml"

    MakeHauntableLaunch(inst)
	
    inst:AddComponent("talker")
    inst.components.talker.fontsize = 28
    inst.components.talker.font = TALKINGFONT
    inst.components.talker.colour = Vector3(.9, .4, .4)
    inst.components.talker.offset = Vector3(0, 0, 0)
    --inst.components.talker.symbol = "swap_object"

    inst.playingmusic = false
    inst.StartMusic = StartMusic
	
    inst:ListenForEvent("onputininventory", topocket)
    inst:ListenForEvent("ondropped", toground)
	
	inst:DoPeriodicTask(10, TalkAboutIt)
	
	inst:ListenForEvent("um_voxolophone_warning", function(_, data)
		inst:WarnPlayer(inst, data)
	end, TheWorld)
	
	inst:ListenForEvent("ontalk", ontalk)
	inst:ListenForEvent("donetalking", ondonetalking)
	
	inst:WatchWorldState("isnewmoon", SpawnRing)
	
	inst:DoTaskInTime(0, StartMusic)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

local function ringfn()
	local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
	
    inst.AnimState:SetBank("firefighter_placement")
    inst.AnimState:SetBuild("firefighter_placement")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
	inst.AnimState:SetMultColour(0, 0, 1, 1)
	
	inst.Transform:SetScale(1.15, 1.15, 1.15)
	
	inst:AddTag("um_vox_ring")
	inst:AddTag("FX")
	inst:AddTag("NOCLICK")

	if not TheWorld.ismastersim then
		return inst
	end
	
	inst.persists = false
	
	return inst
end

return Prefab("um_voxolophone", fn, assets),
		Prefab( "um_vox_ring", ringfn, assets) 