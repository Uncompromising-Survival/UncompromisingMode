local env = env
GLOBAL.setfenv(1, GLOBAL)

-----------------------------------------------------------------
-- Krampii will knock the items out of players
-----------------------------------------------------------------

local function OnHitOther(inst, data)
    local target = data.target
    if target then
        if inst.components.thief then
            inst.components.thief:StealItem(target)
        end
    
        if target:HasTag("creatureknockbackable") or target:HasTag("player") and UMCommonFns.ShouldKnockback(target) then
            inst.sg:GoToState("taunt")
        end
    end
end

local function CheckLeaving(inst, data)
    if data.statename ~= nil and data.statename == "exit" then
        if not inst.components.health:IsDead() then
            inst.components.health:SetInvincible(false)
            
            inst:DoTaskInTime(1, function()
                inst.components.health:SetInvincible(true)
                local klaus_sack = TheSim:FindFirstEntityWithTag("klaussacklock")
                local current_middleman = TheSim:FindFirstEntityWithTag("krampus_middleman")
                
                if klaus_sack ~= nil and klaus_sack.components.inventory ~= nil then
                    inst.components.inventory:TransferInventory(klaus_sack)
                else
                    local middleman = SpawnPrefab("krampus_middleman_inventory")
                    middleman.Transform:SetPosition(inst.Transform:GetWorldPosition())
                    inst.components.inventory:TransferInventory(middleman)
                end
            end)
        end
    end
end

env.AddPrefabPostInit("krampus", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst:AddComponent("thief")

    inst.components.combat:SetAttackPeriod(TUNING.KRAMPUS_ATTACK_PERIOD)
    inst:ListenForEvent("onhitother", OnHitOther)
    inst:ListenForEvent("newstate", CheckLeaving)
end)