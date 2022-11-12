local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

env.AddPrefabPostInit("icestaff", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    local _onattack = inst.components.weapon.onattack

    local function OnAttack(inst, attacker, target, skipsanity)
        if attacker:HasTag("wathom") then
            local ret = _onattack(inst, attacker, target, skipsanity)
            local x, y, z = target.Transform:GetWorldPosition()

            local ents = TheSim:FindEntities(x, y, z, 4, nil,
                { "player", "playerghost", "notarget", "companion", "abigail", "INLIMBO" })

            if target.components.freezable ~= nil then
                target.components.freezable:AddColdness(1)
            end
            for k, v in ipairs(ents) do
                if v ~= target then
                    if v.components.freezable ~= nil then
                        v.components.freezable:AddColdness(2)
                        v.components.freezable:SpawnShatterFX()
                    end
                end
            end
            if target.components.health ~= nil then
                target.components.health:DoDelta(-34)
            end
            return ret
        else
            return _onattack(inst, attacker, target, skipsanity)
        end
    end

    inst.components.weapon:SetOnAttack(OnAttack)
end)

env.AddPrefabPostInit("firestaff", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    local _onattack = inst.components.weapon.onattack

    local function OnAttack(inst, attacker, target, skipsanity)
        if attacker:HasTag("wathom") then
            local ret = _onattack(inst, attacker, target, skipsanity)
            local x, y, z = target.Transform:GetWorldPosition()

            local ents = TheSim:FindEntities(x, y, z, 4, { "_health" },
                { "player", "playerghost", "notarget", "companion", "abigail", "INLIMBO" })

            for k, v in ipairs(ents) do
                if v ~= target then
                    if v.components.burnable ~= nil then
                        v.components.burnable:Ignite(true)
                    end
                end
                if v.components.health ~= nil and not v.components.health:IsDead() and v.components.combat ~= nil then
                    v.components.combat:GetAttacked(attacker, 34, nil)
                end
            end
            return ret
        else
            return _onattack(inst, attacker, target, skipsanity)
        end
    end

    inst.components.weapon:SetOnAttack(OnAttack)
end)

if env.GetModConfigData("cooldown_orangestaff") then
    local function onblink(staff, pos, caster)
        if caster and staff.components.rechargeable:IsCharged() then
            if caster.components.staffsanity then
                caster.components.staffsanity:DoCastingDelta(-TUNING.SANITY_MED)
            elseif caster.components.sanity ~= nil then
                caster.components.sanity:DoDelta(-TUNING.SANITY_MED)
            end
            staff.components.rechargeable:Discharge(5)
        else
            staff.components.blinkstaff.blinktask:Cancel()
        end
    end

    env.AddPrefabPostInit("orangestaff", function(inst)
        if not TheWorld.ismastersim then
            return
        end
        inst:AddComponent("rechargeable")

        inst:RemoveComponent("finiteuses")
        if inst ~= nil and inst.components.blinkstaff ~= nil then
            inst.components.blinkstaff.onblinkfn = onblink
        end
    end)
end

--TELELOCATOR STAFF STUFF

local function GetAllActiveTelebases()
    local valid_telebases = {}
    for k, telebase in pairs(Ents) do
        if telebase.prefab == "telebase" then
            if telebase.canteleto(telebase) then
                table.insert(valid_telebases, telebase)
            end
        end
    end
    return valid_telebases
end

local ICON_SCALE = .6
local ICON_RADIUS = 50

local function ParseAreaHandlerData(inst)
    local data = inst.components.areaaware.current_area_data
    local _string = "Unknown"
    local x, y, z = inst.Transform:GetWorldPosition()
    --hoo boy...
    if data == nil then
        return _string
    end
    if string.match(data.id, "HermitcrabIsland") then
        _string = "Hermit's Island"
    elseif string.match(data.id, "MonkeyIsland") then
        _string = "Moon Quay"
    elseif string.match(data.id, "MoonIsland") then
        _string = "Lunar Island"
    elseif TheWorld.Map:GetPlatformAtPoint(x, z) then
        _string = "On a boat"
    elseif string.match(data.id, "Make a pick") then
        _string = "Make a pick"
    elseif string.match(data.id, "LightningBluffOasis") then
        _string = "Oasis"
    elseif string.match(data.id, "Lightning Bluff") then
        _string = "Oasis Desert"
    elseif string.match(data.id, "Squeltch") then
        _string = "Marsh"
    elseif string.match(data.id, "Forest hunters") then
        _string = "Forest Hunters"
    elseif string.match(data.id, "PigKingdom") then
        _string = "Pig King"
    elseif string.match(data.id, "Speak to the king") then
        _string = "Pig King Deciduous"
    elseif string.match(data.id, "For a nice walk") then
        _string = "Forest"
    elseif string.match(data.id, "MooseBreedingTask") then
        _string = "Moose Breeding Grounds"
    elseif string.match(data.id, "Beeeees!") then
        _string = "Bee Queen Grassland"
    elseif string.match(data.id, "The hunters") then
        _string = "Triple Mac Tusk"
    elseif string.match(data.id, "Magic meadow") then
        _string = "Meadow"
    elseif string.match(data.id, "GiantTrees") then
        _string = "Hooded Forest"
    elseif string.match(data.id, "Badlands") then
        _string = "Dragonfly Desert"
    elseif string.match(data.id, "Kill the spiders") then
        _string = "Spider Quarry region"
    elseif string.match(data.id, "Make a pick") then
        _string = "Make a Pick (Spawn Region)"
    elseif string.match(data.id, "Dig that rock") then
        _string = "Mosaic"
    elseif string.match(data.id, "Befriend the pigs") then
        _string = "Pig Village Surroundings"
    elseif string.match(data.id, "Great Plains") then
        _string = "Savannah"
    elseif string.match(data.id, "START") then
        _string = "Spawn"
    elseif string.match(data.id, "PigVillage") then
        _string = "Pig Village"
    end
    local ret = _string .. "."
    return ret
end

local function GetAllValidSpells(inst)
    local spells = {}
    for k, v in pairs(GetAllActiveTelebases()) do
        local spell = {
            atlas = "images/telocator_spell.xml",
            normal = "telocator_spell.tex",
            widget_scale = ICON_SCALE,
            hit_radius = ICON_RADIUS,
        }
        spell.target_focus = v
        local function GetLabel()
            local dist = inst.components.inventoryitem.owner ~= nil and spell.target_focus ~= nil and
                "Distance: " ..
                tostring(math.floor(math.sqrt(inst.components.inventoryitem.owner:GetDistanceSqToInst(spell.target_focus))))
                .. "." or "Distance: Unknown."
            local location = "\nLocation: ".. ParseAreaHandlerData(spell.target_focus)
            return dist..location
        end

        spell.label = GetLabel()
        spell.onselect = function(inst)
        end
        spell.execute = function(inst)
            inst.target_focus = spell.target_focus
            inst.components.inventoryitem.owner.sg:GoToState("castspell")
            inst.components.spellcaster:CastSpell(inst.components.inventoryitem.owner, inst)
        end
        table.insert(spells, spell)
    end
    return spells
end

local function OnOpen(inst)
    inst.components.spellbook.items = GetAllValidSpells(inst)
end

local function getrandomposition(caster, teleportee, target_in_ocean)
    if target_in_ocean then
        local pt = TheWorld.Map:FindRandomPointInOcean(20)
        if pt ~= nil then
            return pt
        end
        local from_pt = teleportee:GetPosition()
        local offset = FindSwimmableOffset(from_pt, math.random() * 2 * PI, 90, 16)
            or FindSwimmableOffset(from_pt, math.random() * 2 * PI, 60, 16)
            or FindSwimmableOffset(from_pt, math.random() * 2 * PI, 30, 16)
            or FindSwimmableOffset(from_pt, math.random() * 2 * PI, 15, 16)
        if offset ~= nil then
            return from_pt + offset
        end
        return teleportee:GetPosition()
    else
        local centers = {}
        for i, node in ipairs(TheWorld.topology.nodes) do
            if TheWorld.Map:IsPassableAtPoint(node.x, 0, node.y) and node.type ~= NODE_TYPE.SeparatedRoom then
                table.insert(centers, { x = node.x, z = node.y })
            end
        end
        if #centers > 0 then
            local pos = centers[math.random(#centers)]
            return Point(pos.x, 0, pos.z)
        else
            return caster:GetPosition()
        end
    end
end

local function teleport_end(teleportee, locpos, loctarget, staff)
    if loctarget ~= nil and loctarget:IsValid() and loctarget.onteleto ~= nil then
        loctarget:onteleto()
    end

    if teleportee.components.inventory ~= nil and teleportee.components.inventory:IsHeavyLifting() then
        teleportee.components.inventory:DropItem(teleportee.components.inventory:Unequip(EQUIPSLOTS.BODY), true, true)
    end

    --#v2c hacky way to prevent lightning from igniting us
    local preventburning = teleportee.components.burnable ~= nil and not teleportee.components.burnable.burning
    if preventburning then
        teleportee.components.burnable.burning = true
    end
    TheWorld:PushEvent("ms_sendlightningstrike", locpos)
    if preventburning then
        teleportee.components.burnable.burning = false
    end

    if teleportee:HasTag("player") then
        teleportee.sg.statemem.teleport_task = nil
        teleportee.sg:GoToState(teleportee:HasTag("playerghost") and "appear" or "wakeup")
        teleportee.SoundEmitter:PlaySound(staff.skin_castsound or "dontstarve/common/staffteleport")
    else
        teleportee:Show()
        if teleportee.DynamicShadow ~= nil then
            teleportee.DynamicShadow:Enable(true)
        end
        if teleportee.components.health ~= nil then
            teleportee.components.health:SetInvincible(false)
        end
        teleportee:PushEvent("teleported")
    end
    staff.target_focus = nil
end

local function teleport_continue(teleportee, locpos, loctarget, staff)
    if teleportee.Physics ~= nil then
        teleportee.Physics:Teleport(locpos.x, 0, locpos.z)
    else
        teleportee.Transform:SetPosition(locpos.x, 0, locpos.z)
    end
    staff.components.finiteuses:Use()
    if teleportee:HasTag("player") then
        teleportee:SnapCamera()
        teleportee:ScreenFade(true, 1)
        teleportee.sg.statemem.teleport_task = teleportee:DoTaskInTime(1, teleport_end, locpos, loctarget, staff)
    else
        teleport_end(teleportee, locpos, loctarget, staff)
    end
end

local function teleport_start(teleportee, staff, caster, loctarget, target_in_ocean)
    local ground = TheWorld

    --V2C: Gotta do this RIGHT AWAY in case anything happens to loctarget or caster
    local locpos = teleportee.components.teleportedoverride ~= nil and
        teleportee.components.teleportedoverride:GetDestPosition()
        or loctarget == nil and getrandomposition(caster, teleportee, target_in_ocean)
        or loctarget.teletopos ~= nil and loctarget:teletopos()
        or loctarget:GetPosition()

    if teleportee.components.locomotor ~= nil then
        teleportee.components.locomotor:StopMoving()
    end

    if ground:HasTag("cave") then
        -- There's a roof over your head, magic lightning can't strike!
        ground:PushEvent("ms_miniquake", { rad = 3, num = 5, duration = 1.5, target = teleportee })
        return
    end

    local isplayer = teleportee:HasTag("player")
    if isplayer then
        teleportee.sg:GoToState("forcetele")
    else
        if teleportee.components.health ~= nil then
            teleportee.components.health:SetInvincible(true)
        end
        if teleportee.DynamicShadow ~= nil then
            teleportee.DynamicShadow:Enable(false)
        end
        teleportee:Hide()
    end

    --#v2c hacky way to prevent lightning from igniting us
    local preventburning = teleportee.components.burnable ~= nil and not teleportee.components.burnable.burning
    if preventburning then
        teleportee.components.burnable.burning = true
    end
    ground:PushEvent("ms_sendlightningstrike", teleportee:GetPosition())
    if preventburning then
        teleportee.components.burnable.burning = false
    end

    if caster ~= nil then
        if caster.components.staffsanity then
            caster.components.staffsanity:DoCastingDelta(-TUNING.SANITY_HUGE)
        elseif caster.components.sanity ~= nil then
            caster.components.sanity:DoDelta(-TUNING.SANITY_HUGE)
        end
    end

    ground:PushEvent("ms_deltamoisture", TUNING.TELESTAFF_MOISTURE)

    if isplayer then
        teleportee.sg.statemem.teleport_task = teleportee:DoTaskInTime(3, teleport_continue, locpos, loctarget, staff)
    else
        teleport_continue(teleportee, locpos, loctarget, staff)
    end
end

local function validteleporttarget(inst)
    return true
end

function FindNearestActiveTelebase(x, y, z, range, minrange)
    range = (range == nil and math.huge) or (range > 0 and range * range) or 0
    minrange = math.min(range, minrange ~= nil and minrange > 0 and minrange * minrange or 0)
    if minrange < range then
        local mindistsq = math.huge
        local nearest = nil
        for k, v in pairs(TELEBASES) do
            if validteleporttarget(k) then
                local distsq = k:GetDistanceSqToPoint(x, y, z)
                if distsq < mindistsq and distsq >= minrange and distsq < range then
                    mindistsq = distsq
                    nearest = k
                end
            end
        end
        return nearest
    end
end

local function teleport_func(inst, target)
    local caster = inst.components.inventoryitem.owner or target
    if target == nil then
        target = caster
    end

    local x, y, z = target.Transform:GetWorldPosition()
    local target_in_ocean = target.components.locomotor ~= nil and target.components.locomotor:IsAquatic()

    local loctarget = target.components.minigame_participator ~= nil and
        target.components.minigame_participator:GetMinigame()
        or target.components.teleportedoverride ~= nil and target.components.teleportedoverride:GetDestTarget()
        or target.components.hitchable ~= nil and target:HasTag("hitched") and target.components.hitchable.hitched
        or nil

    if loctarget == nil and not target_in_ocean then
        loctarget = inst.target_focus ~= nil and inst.target_focus or FindNearestActiveTelebase(x, y, z, nil, 1)
    end
    teleport_start(target, inst, caster, loctarget, target_in_ocean)
end

env.AddPrefabPostInit("telestaff", function(inst)

    inst:AddTag("telestaff")
    --inst:RemoveComponent("spellcaster")
    --inst:AddComponent("spellcaster")
    inst:AddComponent("spellbook")

    if not TheWorld.ismastersim then
        return
    end

    if inst.components.finiteuses ~= nil then
        inst.components.finiteuses:SetUses(inst.components.finiteuses.total * 2)
        inst.components.finiteuses:SetMaxUses(inst.components.finiteuses.total * 2)
    end

    inst.components.spellcaster:SetSpellFn(teleport_func)
    inst.components.spellbook.items = GetAllValidSpells(inst)
    inst.components.spellbook:SetOnOpenFn(OnOpen)
    inst.components.spellbook:SetRequiredTag("telestaff_spellbook_user")

    local _OnUnequip = inst.components.equippable.onunequipfn

    inst.components.equippable.onunequipfn = function(inst, owner)
        if inst.components.spellbook ~= nil then
            inst.components.spellbook.items = GetAllValidSpells(inst)
        end
        if inst.spell_update_task ~= nil then
            inst.spell_update_task:Cancel()
            inst.spell_update_task = nil
        end
        owner:RemoveTag("telestaff_spellbook_user")
        _OnUnequip(inst, owner)
    end

    local _OnEquip = inst.components.equippable.onequipfn

    inst.components.equippable.onequipfn = function(inst, owner)
        if inst.components.spellbook ~= nil then
            inst.components.spellbook.items = GetAllValidSpells(inst)
        end
        inst.spell_update_task = inst:DoStaticPeriodicTask(1, function() --fuck it why not!!!
            if inst.components.spellbook ~= nil then
                inst.components.spellbook.items = GetAllValidSpells(inst)
            end
        end)
        owner:AddTag("telestaff_spellbook_user")
        _OnEquip(inst, owner)
    end
end)

local function teleport_target(inst)
    --nothing!!!
end

env.AddPrefabPostInit("telebase", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst:AddComponent("areaaware")

    inst.onteleto = teleport_target
    inst.canteleto = validteleporttarget
end)

--I basicly have to remake this thing, fun!!

local function OnGemGiven(inst, giver, item)
    --Disable trading, add teleports.
    inst.SoundEmitter:PlaySound("dontstarve/common/telebase_hum", "hover_loop")
    inst.SoundEmitter:PlaySound("dontstarve/common/telebase_gemplace")
    inst.AnimState:PlayAnimation("idle_full_loop", true)
    inst.components.trader:Disable()
end

local function OnLoad(inst, data)

end

local function OnSave(inst, data)
end

local function getstatus(inst)
    return "VALID"
end

local function ShatterGem(inst)
    inst.SoundEmitter:KillSound("hover_loop")
    inst.AnimState:ClearBloomEffectHandle()
    inst.AnimState:PlayAnimation("shatter")
    inst.AnimState:PushAnimation("idle_empty")
    inst.SoundEmitter:PlaySound("dontstarve/common/gem_shatter")
end

local function DestroyGem(inst)
    inst.components.trader:Enable()
    inst:DoTaskInTime(math.random() * 0.5, ShatterGem)
end

env.AddPrefabPostInit("gemsocket", function(inst)
    inst.teleports = 0

    if not TheWorld.ismastersim then
        return
    end

    inst:RemoveComponent("pickable")
    --I uhh, am lazy?
    OnGemGiven(inst)
    inst.components.trader.onaccept = OnGemGiven
    inst.components.inspectable.getstatus = getstatus
    inst.DestroyGemFn = DestroyGem

    inst.OnLoad = OnLoad
    inst.OnSave = OnSave
end)
