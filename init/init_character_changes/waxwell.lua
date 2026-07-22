local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local UpvalueHacker = require("tools/upvaluehacker")
local ShadowWaxwellBrain = require("brains/shadowwaxwellbrain")

local DIG_TAGS = {"snowpile_basic", "snowpile"}
local TOWORK_CANT_TAGS = {"sludgestack"}

local _DIG_TAGS = UpvalueHacker.GetUpvalue(ShadowWaxwellBrain.OnStart, "DIG_TAGS")
local _TOWORK_CANT_TAGS = UpvalueHacker.GetUpvalue(ShadowWaxwellBrain.OnStart, "FindEntityToWorkAction", "TOWORK_CANT_TAGS")

for i, TAG in pairs(DIG_TAGS) do
    table.insert(_DIG_TAGS, TAG)
end

for i, TAG in pairs(TOWORK_CANT_TAGS) do
    table.insert(_TOWORK_CANT_TAGS, TAG)
end

if TUNING.DSTU.WAXWELL then
    local _IsLeaderInCombat = UpvalueHacker.GetUpvalue(ShadowWaxwellBrain.OnStart, "IsLeaderInCombat")
    if _IsLeaderInCombat then
        local function IsLeaderInCombat() return false end
        UpvalueHacker.SetUpvalue(ShadowWaxwellBrain.OnStart, IsLeaderInCombat, "IsLeaderInCombat")
    end

    local _ShouldAvoidExplosive = UpvalueHacker.GetUpvalue(ShadowWaxwellBrain.OnStart, "ShouldAvoidExplosive")
    local _ShouldRunAway = UpvalueHacker.GetUpvalue(ShadowWaxwellBrain.OnStart, "ShouldRunAway")

    local function RemoveNode(self, brainnode)
        if not brainnode then return end
        for id, node in pairs(self.bt.root.children) do
            if node.hunterfn and node.hunterfn == brainnode then
                table.remove(self.bt.root.children, id)
            end
        end
    end

    env.AddBrainPostInit("shadowwaxwellbrain", function(self)
        RemoveNode(self, _ShouldAvoidExplosive)
        RemoveNode(self, _ShouldRunAway)
    end)

    local shadows = {"shadowdancer", "shadowworker", "shadowprotector"}
    for _, prefab in pairs(shadows) do
        env.AddPrefabPostInit(prefab, function(inst)
            if not TheWorld.ismastersim then return end
            local locomotor = inst.components.locomotor
            if locomotor and locomotor.pathcaps then
                local pathcaps = {"allowocean", "ignorewalls"}
                for _, pathcap in pairs(pathcaps) do
                    locomotor.pathcaps[pathcap] = true
                end
            end
        end)
    end
end

--[[local ICON_SCALE = .6
local ICON_RADIUS = 50
local SPELLBOOK_RADIUS = 100
local SPELLBOOK_FOCUS_RADIUS = SPELLBOOK_RADIUS + 2
local NUM_MINIONS_PER_SPAWN = 1

local function _CheckMaxSanity(sanity, minionprefab)
    return sanity and sanity:GetPenaltyPercent() + (TUNING.SHADOWWAXWELL_SANITY_PENALTY[string.upper(minionprefab)] or 0) * NUM_MINIONS_PER_SPAWN <= TUNING.MAXIMUM_SANITY_PENALTY
end

local function CheckMaxSanity(doer, minionprefab)
    return _CheckMaxSanity(doer.components.sanity, minionprefab)
end

--I don't know why Klei does this, but i'm not gonna ask.

local function SpellCost(pct)
    return pct * TUNING.LARGE_FUEL * -4
end

local function ShadowMimicSpellFn(inst, doer)
    if inst.components.fueled:IsEmpty() then
        return false, "NO_FUEL"
    elseif doer.components.health.currenthealth <= TUNING.DSTU.SHADOWWAXWELL_HEALTH_COST then
        doer.components.talker:Say(GetString(doer.prefab, "ANNOUNCE_NOHEALTH"))
    elseif not CheckMaxSanity(doer, "shadowduelist") then
        return false, "NO_MAX_SANITY"
    else
        local x, y, z = doer.Transform:GetWorldPosition()
        local shadowmax = doer.components.petleash:SpawnPetAt(x, y, z, "old_shadowwaxwell")

        if shadowmax then
            inst.components.fueled:DoDelta(SpellCost(TUNING.WAXWELLJOURNAL_SPELL_COST.SHADOW_PILLARS * 2), doer)
            shadowmax:DoTaskInTime(0, function(shadowmax) shadowmax.sg:GoToState("jumpout") end)
            doer.components.health:DoDelta(-TUNING.DSTU.SHADOWWAXWELL_HEALTH_COST)
            doer.components.sanity:RecalculatePenalty()
            doer.SoundEmitter:PlaySound("dontstarve/maxwell/shadowmax_appear")
        end
        local x1, y1, z1 = doer.Transform:GetWorldPosition()
        SpawnPrefab("statue_transition").Transform:SetPosition(x1, y1, z1)
        return true
    end
end

local function ShadowPactArmorFn(inst, doer)
    if inst.components.fueled:IsEmpty() then
        return false, "NO_FUEL"
    else
        inst.components.fueled:DoDelta(SpellCost(TUNING.WAXWELLJOURNAL_SPELL_COST.SHADOW_PILLARS * 2), doer)
        doer.sg:GoToState("pact_armor_craft")
        doer.components.inventory:Equip(SpawnPrefab("pact_armor_sanity"))
        return true
    end
end

local function ShadowPactSwordFn(inst, doer)
    if inst.components.fueled:IsEmpty() then
        return false, "NO_FUEL"
    else
        inst.components.fueled:DoDelta(SpellCost(TUNING.WAXWELLJOURNAL_SPELL_COST.SHADOW_PILLARS * 2), doer)
        doer.sg:GoToState("pact_sword_craft")
        doer.components.inventory:Equip(SpawnPrefab("pact_sword_sanity"))
        return true
    end
end

env.AddPrefabPostInit("waxwelljournal", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("tradable")
end)]]

local function CalculateMaxHealthLoss(inst, data)
    local damage = data.damageresolved or data.damage
    if inst:HasTag("vetcurse") and damage and inst.components.health and not inst.components.health:IsDead() then
        local healthloss = (damage * .5) / 75
        inst.components.health:DeltaPenalty(healthloss)
    end
end

--[[local function DoEffects(pet)
    local x, y, z = pet.Transform:GetWorldPosition()

    SpawnPrefab("statue_transition_2").Transform:SetPosition(x, y, z)

    if pet.components.follower.leader then
        local x1, y1, z1 = pet.components.follower.leader.Transform:GetWorldPosition()
        SpawnPrefab("statue_transition").Transform:SetPosition(x1, y1, z1)
    end
end

local function doeffects(inst, pos)
    SpawnPrefab("statue_transition").Transform:SetPosition(pos:Get())
    SpawnPrefab("statue_transition_2").Transform:SetPosition(pos:Get())
end

local function KillPet(pet)
    pet.components.health:Kill()
end

local portals = {
    "multiplayer_portal",
    "multiplayer_portal_moonrock_constr",
    "multiplayer_portal_moonrock",
}

for i, v in ipairs(portals) do
    env.AddPrefabPostInit(v, function(inst)
        inst:ListenForEvent("ms_newplayercharacterspawned", function(world, data)
            if data and data.player and data.player.prefab == "waxwell" then
                local x, y, z = inst.Transform:GetWorldPosition()
                SpawnPrefab("waxwell_pact_trader").Transform:SetPosition(x + 5, 0, z - 5)
            end
        end, TheWorld)
    end)
end

local function ReskinPet(pet, player, nofx)
    pet._dressuptask = nil
    if player:IsValid() then
        if not nofx then
            local x, y, z = pet.Transform:GetWorldPosition()
            local fx = SpawnPrefab("slurper_respawn")
            fx.Transform:SetPosition(x, y, z)
        end
        pet.components.skinner:CopySkinsFromPlayer(player)
    end
end

local function OnSkinsChanged(inst, data)
    for k, v in pairs(inst.components.petleash:GetPets()) do
        if v:HasTag("classicshadow") then
            if v._dressuptask then
                v._dressuptask:Cancel()
                v._dressuptask = nil
            end
            if data and data.nofx then
                ReskinPet(v, inst, data.nofx)
            else
                v._dressuptask = v:DoTaskInTime(math.random() * 0.5 + 0.25, ReskinPet, inst)
            end
        end
    end
end

local function OnDeath(inst)
    for k, v in pairs(inst.components.petleash:GetPets()) do
        if v:HasTag("classicshadow") and not v._killtask then
            v._killtask = v:DoTaskInTime(math.random(), KillPet)
        end
    end
end

local function OnBecameGhost(inst)
    for k, v in pairs(inst.components.petleash:GetPets()) do
        if v:HasTag("classicshadow") then
            inst:RemoveEventCallback("onremove", inst._onpetlost, v)
            inst.components.sanity:RemoveSanityPenalty(v)
            if not v._killtask then
                v._killtask = v:DoTaskInTime(math.random(), KillPet)
            end
        end
    end
end

local function ForceDespawnShadowMinions(inst)
    local todespawn = {}
    for k, v in pairs(inst.components.petleash:GetPets()) do
        if v:HasTag("classicshadow") then
            table.insert(todespawn, v)
        end
    end
    for i, v in ipairs(todespawn) do
        inst.components.petleash:DespawnPet(v)
    end
end]]

local function OnGetItem(inst, data)
    local item = data and data.item
    if item and item:HasTag("shadowmagic") then
        item.components.inventoryitem.keepondeath = true
        item.components.inventoryitem.keepondrown = true
        item:AddTag("nosteal")
    end
end

local function OnLoseItem(inst, data)
    local item = data and (data.prev_item or data.item)
    if item and item:IsValid() and item:HasTag("shadowmagic") then
        item.components.inventoryitem.keepondeath = false
        item.components.inventoryitem.keepondrown = false
        item:RemoveTag("nosteal")
    end
end

local shadowgearlist = {["armor_sanity"] = "um_maxwell_armor_sanity", ["nightsword"] = "um_maxwell_nightsword"}
local function UnlockShadowGear(inst, data)
    local shadowgear = data and data.item and shadowgearlist[data.item.prefab]
    if not shadowgear then return end
    local builder = inst.components.builder
    if builder and not builder:KnowsRecipe(shadowgear, true) then
        builder:UnlockRecipe(shadowgear)
        inst:PushEvent("learnrecipe", {teacher = inst, recipe = shadowgear})
    end
end

local function ToggleUniqueVetCurse(inst, toggle)
    if toggle then
        inst:ListenForEvent("attacked", CalculateMaxHealthLoss)
    else
        inst:RemoveEventCallback("attacked", CalculateMaxHealthLoss)
    end
end

local function WaxwellUMStuff(inst)
    --[[inst.pact_sworn = false

    local _OnSave = inst.OnSave
    local _OnLoad = inst.OnLoad

    local function OnSave(inst, data)
        if inst.pact_sworn then
            data.pact_sworn = inst.pact_sworn
        end
        if _OnSave then
            return _OnSave(inst, data)
        end
    end

    local function OnLoad(inst, data)
        OnSkinsChanged(inst, { nofx = true })
        if data then
            if data.pact_sworn then
                inst.pact_sworn = data.pact_sworn
                if inst.pact_sworn then
                    inst:AddTag("codexmantrareader")
                    inst:RemoveTag("magician")
                    inst:RemoveTag("shadowmagic")
                    inst:DoTaskInTime(0, function()
                        inst:RemoveComponent("magician")
                    end)
                    inst.components.health:SetAbsorptionAmount(-TUNING.WATHGRITHR_ABSORPTION)
                end
            end
        end
        if _OnLoad then
            return _OnLoad(inst, data)
        end
    end

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst:ListenForEvent("onskinschanged", OnSkinsChanged) -- Fashion Shadows.
    inst:ListenForEvent("ms_becameghost", OnBecameGhost)
    inst:ListenForEvent("ms_playerreroll", ForceDespawnShadowMinions)]]

    if TUNING.DSTU.WAXWELL then
        inst:ListenForEvent("itemget", OnGetItem)
        inst:ListenForEvent("equip", OnGetItem)
        inst:ListenForEvent("itemlose", OnLoseItem)
        inst:ListenForEvent("unequip", OnLoseItem)
        inst:ListenForEvent("builditem", UnlockShadowGear)
    end

    --[[local petleash = inst.components.petleash
    if petleash then
        local OldOnSpawnPet = petleash.onspawnfn
        local OldOnDespawnPet = petleash.ondespawnfn
        local function OnSpawnPet(inst, pet)
            if pet:HasTag("classicshadow") then
                --Delayed in case we need to relocate for migration spawning
                pet:DoTaskInTime(0, DoEffects)
                if not (inst.components.health:IsDead() or inst:HasTag("playerghost")) then
                    inst.components.sanity:AddSanityPenalty(pet, TUNING.DSTU.OLD_SHADOWWAXWELL_SANITY_PENALTY)
                    inst:ListenForEvent("onremove", inst._onpetlost, pet)
                    pet.components.skinner:CopySkinsFromPlayer(inst)
                elseif not pet._killtask then
                    pet._killtask = pet:DoTaskInTime(math.random(), KillPet)
                end
            else
                OldOnSpawnPet(inst, pet)
            end
        end
        local function OnDespawnPet(inst, pet)
            if pet:HasTag("classicshadow") then
                DoEffects(pet)
                pet:Remove()
            else
                OldOnDespawnPet(inst, pet)
            end
        end
        petleash:SetOnSpawnFn(OnSpawnPet)
        petleash:SetOnDespawnFn(OnDespawnPet)
    end]]

    inst.UMToggleUniqueVetCurse = ToggleUniqueVetCurse
end

env.AddPrefabPostInit("waxwell", function(inst)
    if not TheWorld.ismastersim then return end
    WaxwellUMStuff(inst)
end)

if TUNING.DSTU.WAXWELL then
    local function ShadowGearClientFunctions(inst)
        local _displaynamefn = inst.displaynamefn
        inst.displaynamefn = function(_inst, ...)
            return _inst:HasTag("um_maxwellsummon") and STRINGS.NAMES[string.upper("um_maxwell_".._inst.prefab)] or _displaynamefn and _displaynamefn(_inst, ...) or nil
        end
    end

    local function ShadowGearOnTimerDone(inst, data)
        if data and data.name == "um_shadowgeardestroy" then
            local fx = SpawnPrefab("um_shadow_attune_fx")
            fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
            fx.AnimState:PlayAnimation("attune_out")
            fx.SoundEmitter:PlaySound("dontstarve/sanity/creature2/die")
            inst:Remove()
        end
    end

    local um_shadowgeardestroy_key = "um_shadowgeardestroy"
    local function ShadowGearOnDropped(inst)
        local timer = inst.components.timer
        if not timer then return end
        local despawntime = 5
        if timer:TimerExists(um_shadowgeardestroy_key) then
            timer:SetTimeLeft(um_shadowgeardestroy_key, despawntime)
        else
            timer:StartTimer(um_shadowgeardestroy_key, despawntime)
        end
    end

    local function ShadowGearOnPickup(inst, owner)
        local timer = inst.components.timer
        if not timer then return end
        if timer:TimerExists(um_shadowgeardestroy_key) then timer:StopTimer(um_shadowgeardestroy_key) end
        local inventoryitem = inst.components.inventoryitem
        local inventory = owner and owner:IsValid() and inventoryitem.grabbableoverridetag and not owner:HasTag(inventoryitem.grabbableoverridetag) and owner.components.inventory
        if inventory then inst:DoTaskInTime(0, function() if inventory then inventory:DropItem(inst, true, true) end end) end
    end

    local function ConvertToMaxwellSummon(inst)
        inst:AddTag("nosteal")
        local equippable = inst.components.equippable
        if equippable and equippable.equipslot == EQUIPSLOTS.HANDS then inst:AddTag("stickygrip") end
        inst:AddTag("um_maxwellsummon")
        inst:AddTag("um_nodeconstruct")
        local timer = inst.components.timer or inst:AddComponent("timer")
        local _OnSave = timer.OnSave
        timer.OnSave = function(self, ...)
            local data = _OnSave(self, ...) or {}
            if not data["add_component_if_missing"] then data["add_component_if_missing"] = true end
            return data
        end
        inst:ListenForEvent("timerdone", ShadowGearOnTimerDone)
        local inventoryitem = inst.components.inventoryitem
        if inventoryitem then
            inventoryitem.keepondeath = true
            inventoryitem.keepondrown = true
            inventoryitem.canonlygoinpocket = true
            inventoryitem.canbepickedup = false
            inventoryitem.grabbableoverridetag = "shadowmagic"
            inst:ListenForEvent("ondropped", ShadowGearOnDropped)
            inst:ListenForEvent("onputininventory", ShadowGearOnPickup)
        end
    end

    local function ShadowGearFunctions(inst)
        inst.UMConvertToMaxwellSummon = ConvertToMaxwellSummon
        local _OnSave = inst.OnSave
        inst.OnSave = function(_inst, data, ...)
            if _inst:HasTag("um_maxwellsummon") then data.um_maxwellsummon = true end
            return _OnSave and _OnSave(_inst, data, ...)
        end
        local _OnLoad = inst.OnLoad
        inst.OnLoad = function(_inst, data, ...)
            if data and data.um_maxwellsummon then _inst:UMConvertToMaxwellSummon() end
            return _OnLoad and _OnLoad(_inst, data, ...)
        end
        local _onPreBuilt = inst.onPreBuilt
        inst.onPreBuilt = function(_inst, builder, materials, recipe, ...)
            if recipe.name == "um_maxwell_".._inst.prefab then _inst:UMConvertToMaxwellSummon() end
            return _onPreBuilt and _onPreBuilt(_inst, builder, materials, recipe, ...)
        end
    end

    local shadowgear = {"armor_sanity", "nightsword"}
    for _, prefab in pairs(shadowgear) do
        env.AddPrefabPostInit(prefab, function(inst)
            ShadowGearClientFunctions(inst)
            if not TheWorld.ismastersim then return end
            ShadowGearFunctions(inst)
        end)
    end
end