local assets =
{
    Asset("ANIM", "anim/um_moonglass_ceiling.zip"),
    
    Asset("IMAGE", "images/map_icons/um_grotto_glass_icon.tex"),
    Asset("ATLAS", "images/map_icons/um_grotto_glass_icon.xml"),    
}

local function Regrow(inst,data)
    inst.fullness = inst.fullness + 1
    inst.AnimState:PlayAnimation("full",true)
end

local NON_DAMAGEABLE_TAGS = {"INLIMBO", "notarget", "noattack", "playerghost", "irreplaceable", "outofreach", "quakeimmune"}
local DAMAGEABLE_TAGS = {"smashable", "quakedebris", "_combat"}
local function DamageSurroundings(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 2, nil, NON_DAMAGEABLE_TAGS, DAMAGEABLE_TAGS)
    for i, v in ipairs(ents) do
        if v ~= inst and v:IsValid() and not v:IsInLimbo() then
            if v:HasAnyTag("quakedebris", "gemology_geode") then
                local vx, vy, vz = v.Transform:GetWorldPosition()
                SpawnPrefab("ground_chunks_breaking").Transform:SetPosition(vx, 0, vz)
                v:Remove()
            elseif v.components.combat and not v:HasAnyTag("epic", "wall") then
                v.components.combat:GetAttacked(inst, 20)
            end
        end
    end
end

local function ListenForCrash(geode)
    if geode.entity:IsAwake() then
        geode.listenfall = geode:DoPeriodicTask(.1, function(geode)
            local x,y,z = geode.Transform:GetWorldPosition()
            if y < .5 then
                DamageSurroundings(geode)
                geode.listenfall:Cancel()
                geode.listenfall = nil
            end
        end)
    else
        local x,y,z = geode.Transform:GetWorldPosition()
        geode.Transform:SetPosition(x,0,z)
        DamageSurroundings(geode)
    end
end

local function DropLoot(inst)
    if math.random() < 0.25 then
        if inst.fullness ~= 0 then
            inst.fullness = inst.fullness - 1
            inst.AnimState:PlayAnimation("empty",true)
        end

        local x,y,z = inst.Transform:GetWorldPosition()
        local geode = SpawnPrefab("um_gemology_geode_glass")
        geode.Transform:SetPosition(x, y + 10, z)
        ListenForCrash(geode)

        if inst.components.timer and not inst.components.timer:TimerExists("regrow") then
            inst.components.timer:StartTimer("regrow", 80 * 8 * 5)
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddMiniMapEntity()
    inst.Transform:SetTwoFaced()

    inst.AnimState:SetBuild("um_moonglass_ceiling")
    inst.AnimState:SetBank("um_moonglass_ceiling")
    inst.AnimState:PlayAnimation("full", true)

    inst:AddTag("NOCLICK")
    inst.MiniMapEntity:SetIcon("um_grotto_glass_icon.tex")
    inst.no_wet_prefix = true

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:DoTaskInTime(0,function(inst)
        if not inst.rotation then
            inst.rotation = math.random(0, 1)
            if inst.rotation == 0 then
                inst.Transform:SetScale(-1, 1, 1)
            end
        end
        if not inst.fullness then
            inst.fullness = 1
            inst.AnimState:PlayAnimation("full")
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
                    inst.Transform:SetScale(-1, 1, 1)
                end
            end
            if data.fullness then
                inst.fullness = data.fullness
                if inst.fullness == 1 then
                    inst.AnimState:PlayAnimation("full")
                else
                    inst.AnimState:PlayAnimation("empty")
                end
            end
        end
    end

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone",Regrow)

    inst:ListenForEvent("startquake", function() inst:DoTaskInTime(math.random(4, 10), DropLoot) end, TheWorld.net)    

    return inst
end

return Prefab("um_moonglass_ceiling", fn, assets)