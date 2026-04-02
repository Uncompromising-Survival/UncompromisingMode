local env = env
GLOBAL.setfenv(1, GLOBAL)
local UpvalueHacker = require("tools/upvaluehacker")
-----------------------------------------------------------------

-----------------------------------------------------------------
-- Remove pathing collision exploit by making objects noclip
-----------------------------------------------------------------
local IMPASSABLES = {    
    ["fossil_stalker"] = true,    
    ["endtable"] = true,
    ["lureplant"] = true,
    ["klaus_sack"] = true,
    ["spiderden"] = true,
    ["spiderden_2"] = true,
    ["spiderden_3"] = true,    
    ["skeleton"] = true,
    ["skeleton_player"] = true,
    ["wood_table_round"] = true,
    ["wood_table_square"] = true,
    ["stone_table_round"] = true,
    ["stone_table_square"] = true,
}

if TUNING.DSTU.IMPASSBLES then
    env.AddPrefabPostInitAny(function(inst)
        if (IMPASSABLES[inst.prefab] --or string.find(inst.prefab, "chesspiece_")
        or inst:HasTag("heavy")) --or string.find(inst.prefab, "oversized"))
        and inst.Physics ~= nil then
            RemovePhysicsColliders(inst)
        end
        if (IMPASSABLES[inst.prefab] --or string.find(inst.prefab, "chesspiece_")
        or inst:HasTag("heavy")) --or string.find(inst.prefab, "oversized")) 
        and inst.Physics ~= nil and inst.components.heavyobstaclephysics ~= nil then
            RemovePhysicsColliders(inst)
            inst.components.heavyobstaclephysics:SetRadius(0)
        end
    end)
end

if TUNING.DSTU.SHAVE_MODE then
    env.AddPrefabPostInitAny(function(inst)
        if not TheWorld.ismastersim then return end
        
        if inst.components.shaveable and inst.components.shaveable.prize_prefab then
            local _OnShaved = inst.components.shaveable.on_shaved
            local function OnShaved(inst, shaver, shave_item, ...)
                if shave_item:HasTag("extra_shaver") and shaver and shaver.components.inventory and math.random() > .5 then
                    local prize = SpawnPrefab(inst.components.shaveable.prize_prefab)
                    local position = inst:GetPosition()
                    local x, y, z = shaver.Transform:GetWorldPosition()
                    if prize.components.inventoryitem then
                        prize.components.inventoryitem:InheritWorldWetnessAtTarget(inst)
                    end
                    if shaver and shaver.components.inventory then
                        shaver.components.inventory:GiveItem(prize, nil, position)
                        SpawnPrefab("shadow_despawn").Transform:SetPosition(x, y, z)
                    else
                        LaunchAt(prize, inst, nil, 1, 1)
                        SpawnPrefab("shadow_despawn").Transform:SetPosition(x, y, z)
                    end
                end
                _OnShaved(inst, shaver, shave_item, ...)
            end
            inst.components.shaveable.on_shaved = OnShaved
        end

        if inst.components.pickable and not inst.components.shaveable then
            local function CanShave(inst, shaver, shave_item)
                return inst.components.pickable and inst.components.pickable:CanBePicked()
            end

            local _onpickedfn = inst.components.pickable.onpickedfn

            local function OnShaved(inst, picker, shaver, shave_item, ...)
                if inst.prefab ~= "mandrake_planted" then
                    if shaver:HasTag("extra_shaver") and picker and picker.components.inventory and math.random() > .5 then
                        local product = inst.components.pickable and inst.components.pickable.product or nil
                        local prize = SpawnPrefab(product)
                        local position = inst:GetPosition()
                        local x, y, z = picker.Transform:GetWorldPosition()
                        if prize.components.inventoryitem then
				            prize.components.inventoryitem:InheritWorldWetnessAtTarget(inst)
                        end
                        picker.components.inventory:GiveItem(prize, nil, position)
                        if product then
                            SpawnPrefab("shadow_despawn").Transform:SetPosition(x, y, z)
                        end
                    end
                    inst.components.pickable:UMForcePick(picker)
                end
                if inst.components.pickable.remove_when_picked == true then
                    inst:Remove()
                end
                if inst.components.pickable.onpickedfn then
                    _onpickedfn(inst, picker, ...)
                end
            end


            --local prize = inst.components.pickable and inst.components.pickable.product
            local shaveable = inst:AddComponent("shaveable")
            shaveable:SetPrize(nil, 1)
            shaveable.can_shave_test = CanShave
            shaveable.on_shaved = OnShaved
            inst.components.pickable:SetStuck(true)
        end
    end)

    env.AddPrefabPostInit("razor", function(inst)
        if not TheWorld.ismastersim then return end

        local finiteuses = inst:AddComponent("finiteuses")
        finiteuses:SetMaxUses(25)
        finiteuses:SetUses(25)
        finiteuses:SetConsumption(ACTIONS.SHAVE, 1)
	    finiteuses:SetOnFinished(inst.Remove)
    end)
end

local function TeleportOverrideFn(inst)
    local pt = inst:GetPosition()
    local offset = FindWalkableOffset(pt, math.random() * 2 * PI, 4, 8, true, false) or
        FindWalkableOffset(pt, math.random() * 2 * PI, 8, 8, true, false)
    if offset ~= nil then
        pt = pt + offset
    end

    return pt
end

env.AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return end
    if inst ~= nil and inst:IsValid() and inst:HasTag("epic") then
        if inst.components.teleportedoverride == nil then
            inst:AddComponent("teleportedoverride")
            inst.components.teleportedoverride:SetDestPositionFn(TeleportOverrideFn)
        end
    end
end)

-- hornet; i dont care enough to know where to put this
env.AddReplicableComponent("hayfever")
env.AddReplicableComponent("adrenaline")
env.AddReplicableComponent("boatbottle")
env.AddReplicableComponent("terrorized")

-- for the super spawner tags
env.AddPrefabPostInitAny(function(inst)
    local old_OnSave = inst.OnSave

    inst.OnSave = function(inst, data, ...)
        if inst.umss_tags then
            data.umss_tags = inst.umss_tags
        end

        if old_OnSave ~= nil then
            return old_OnSave(inst, data, ...)
        end
    end

    local old_OnLoad = inst.OnLoad
    inst.OnLoad = function(inst, data, ...)
        if data ~= nil and data.umss_tags ~= nil then
            for k, v in ipairs(data.umss_tags) do
                inst:AddTag("umss_" .. v)
            end
        end

        if old_OnLoad ~= nil then
            return old_OnLoad(inst, data, ...)
        end
    end
end)

local function FullHide(inst)
    inst.um_visibilityclient = 0
    inst:Hide()
    inst.AnimState:SetMultColour(1, 1, 1, 0)
    if inst.DynamicShadow then inst.DynamicShadow:Enable(false) end
end

local function AdjustVisibility(inst, distance, angle)
    local maintaindistance = 32
    if angle > -0.4 and angle < 0.4 then
        inst.um_visibilityclient = -(maintaindistance - distance) * 1e-3 + inst.um_visibilityclient
        if inst.um_visibilityclient > 1 then inst.um_visibilityclient = 1 end
    elseif angle > -0.6 and angle < 0.6 then
        inst.um_visibilityclient = -(maintaindistance - distance) * 1e-3 + inst.um_visibilityclient
        if inst.um_visibilityclient > 1 then inst.um_visibilityclient = 1 end
        inst.um_visibilityclient = inst.um_visibilityclient * math.abs(1 / angle)
    end
    local seebehinddistance = 1.5
    if distance < seebehinddistance then
        inst.um_visibilityclient = -(seebehinddistance - distance) + inst.um_visibilityclient
        if inst.um_visibilityclient > 1 then inst.um_visibilityclient = 1 end
    end
   
   
    if inst.um_visibilityclient <= 0 then
        FullHide(inst)
    else
        inst:Show()
        inst.AnimState:SetMultColour(1, 1, 1, inst.um_visibilityclient)
    end
    if inst.um_visibilityclient > 0.5 and inst.DynamicShadow then inst.DynamicShadow:Enable(true) end
end

local visradsmall = 0.6
local visradlarge = 0.8
local function AdjustVisibility(inst, distance, angle)
    local maintaindistance = 32
    local mindistance = 1.5
    if angle < visradsmall then
        inst.um_visibilityclient = 5e-2 + inst.um_visibilityclient
    elseif angle < visradlarge then
        inst.um_visibilityclient = 1e-4 + inst.um_visibilityclient
        if inst.um_visibilityclient > 1 then inst.um_visibilityclient = 1 end
        inst.um_visibilityclient = inst.um_visibilityclient * math.abs(1 / angle)
    elseif angle > visradlarge and distance > mindistance and inst.um_visibilityclient ~= 0 then
        inst.um_visibilityclient = -5e-2 + inst.um_visibilityclient
    end

    if distance < mindistance then
        inst.um_visibilityclient = (mindistance - distance) + inst.um_visibilityclient
        if inst.um_visibilityclient > 1 then inst.um_visibilityclient = 1 end
    end
    if inst.um_visibilityclient <= 0 then
        FullHide(inst)
    else
        inst:Show()
        inst.AnimState:SetMultColour(1, 1, 1, inst.um_visibilityclient)
    end
    if inst.um_visibilityclient > 0.5 and inst.DynamicShadow then inst.DynamicShadow:Enable(true) end
end

local function UpdateVisibility(inst)
   
    --if ThePlayer and ThePlayer:HasTag("um_darkwood") then
    local distance = math.sqrt(ThePlayer:GetDistanceSqToInst(inst))
    local x, y, z = inst.Transform:GetWorldPosition()
    local x1, y1, z1 = ThePlayer.Transform:GetWorldPosition()
    local x2, z2
    if ThePlayer.um_mouseposition_x then
        x2 = ThePlayer.um_mouseposition_x
    else
        x2 = x1 + 1
    end
    if ThePlayer.um_mouseposition_z then
        z2 = ThePlayer.um_mouseposition_z
    else
        z2 = z1 + 1
    end
    local angle1 = -math.atan2((z2 - z1), (x2 - x1))
    local angle2 = -math.atan2(z - z1, x - x1)
    local angle = math.abs(angle1 - angle2)
   
   
    if distance > 20 then
        FullHide(inst)
    else
        AdjustVisibility(inst, distance, angle)
    end
    --end
end

local function PrepareVisibility(inst)
    inst:ListenForEvent("entitywake", function(inst)
        inst.um_visibilitycheck = inst:DoPeriodicTask(FRAMES, UpdateVisibility)
        inst.um_visibilityclient = 0
        FullHide(inst)
    end)
    inst:ListenForEvent("entitysleep", function(inst)
        inst.um_visibilitycheck:Cancel()
        inst.um_visibilitycheck = nil
        inst.um_visibilityclient = 0
        FullHide(inst)
    end)
end

env.AddPrefabPostInitAny(function(inst)
    if TheWorld.ismastersim then return inst end
    if ThePlayer ~= inst and (inst.entity or inst.replica.inventoryitem) and (inst:HasTag("monster") or inst:HasTag("smallcreature") or inst:HasTag("EPIC") or inst:HasTag("animal") or inst:HasTag("largecreature") or inst:HasTag("character") or inst.prefab == "carrot_planted" or inst.prefab == "red_mushroom" or inst.prefab == "green_mushroom" or inst.prefab == "blue_mushroom" or inst.prefab == "lichen" or inst:HasTag("oceanfishinghookable")) then
        -- if inst.prefab == "shadowheart" then
        --PrepareVisibility(inst)
    end
end)

local _AddPlatformFollower = EntityScript.AddPlatformFollower
--local _RemovePlatformFollower = EntityScript.RemovePlatformFollower

function EntityScript:AddPlatformFollower(child)
    if child ~= nil then
        _AddPlatformFollower(self, child)
    end
    if child ~= nil and child:HasTag("structure") then --probably a bad assumption, but i'm assuming structures cant/wont leave the boat - yell at me if this messes anything.
        RemovePhysicsColliders(child)                  --altough removing the structure collision instead of the player's seems like a more reasonable idea.
    end
end

local _SpawnChild = EntityScript.SpawnChild
function EntityScript:SpawnChild(name, ...)
    if self:HasTag("no_epichealth_proxy") and name == "epichealth_proxy" then return end
    return _SpawnChild(self, name, ...)
end

local UM_BLOCKED_STATES = {"wortox_teleport_reviver_selfuse"}
local _GoToState = StateGraphInstance.GoToState
function StateGraphInstance:GoToState(statename, ...)
    if self.inst.um_blockgotostate and table.contains(UM_BLOCKED_STATES, statename) then return end
    return _GoToState(self, statename, ...)
end

local hermitcrabtea_defs = require("prefabs/hermitcrabtea_defs")
for _, data in ipairs(hermitcrabtea_defs.buffs) do
    if data.name == "moon_tree_blossom" then
        local _MoonBlossom_OnAttacked = UpvalueHacker.GetUpvalue(data.onattachedfn, "MoonBlossom_OnAttacked")
        if _MoonBlossom_OnAttacked then
            local hitsparks_fx_colouroverride = { 0, 0, 1 }
            local function SparkLunarOnShadow(inst, attacker)
                local spark = SpawnPrefab("hitsparks_fx")
                spark:Setup(attacker, inst, nil, hitsparks_fx_colouroverride)
            end
            local function AttackShadow(inst, attacker)
                if inst.components.combat:CanTarget(attacker) then
                    if not (attacker.components.health and attacker.components.health:IsDead()) and attacker.sg:HasStateTag("attack") and attacker.sg:HasState("hit") then
                        attacker.sg:GoToState("hit")
                    end
                    attacker.components.combat:GetAttacked(inst, TUNING.DSTU.HERMITCRAB_MOONTREEBLOSSOMTEA_SHADOWCREATURE_DAMAGE)
                end
            end
            local function MoonBlossom_OnAttacked(inst, data)
                local attacker, damage = data and data.attacker, data and data.original_damage
                if attacker and attacker:IsValid() and attacker:HasTag("shadowsubmissive") then
                    SparkLunarOnShadow(inst, attacker)
                    AttackShadow(inst, attacker)
                end
            end
            UpvalueHacker.SetUpvalue(data.onattachedfn, MoonBlossom_OnAttacked, "MoonBlossom_OnAttacked")
        end
    end
end

--[[local NO_UM_SPIRITBUFF_TAGS = {"companion", "abigail", "shadowminion"}
env.AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then 
        return inst
    end

    if not inst:HasAnyTag(NO_UM_SPIRITBUFF_TAGS) and inst.components and inst.components.combat then
        inst:AddComponent("um_spiritbuff")
    end
end)]]