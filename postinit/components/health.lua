local env = env
GLOBAL.setfenv(1, GLOBAL)

local function HasSkill(inst,name)
    return inst.components.skilltreeupdater and inst.components.skilltreeupdater:IsActivated(name)
end

local function DoSleep(inst, revived)
    if inst ~= revived and
        (TheNet:GetPVPEnabled() or not inst:HasTag("player")) and
        not (inst.components.freezable and inst.components.freezable:IsFrozen()) and
        not (inst.components.pinnable and inst.components.pinnable:IsStuck()) and
        not (inst.components.fossilizable and inst.components.fossilizable:IsFossilized()) then
        local mount = inst.components.rider and inst.components.rider:GetMount() or nil
        if mount then
            mount:PushEvent("ridersleep", { sleepiness = 10, sleeptime = TUNING.PANFLUTE_SLEEPTIME })
        end
        if inst.components.sleeper then
            inst.components.sleeper:AddSleepiness(10, TUNING.PANFLUTE_SLEEPTIME)
        elseif inst.components.grogginess then
            inst.components.grogginess:AddGrogginess(10, TUNING.PANFLUTE_SLEEPTIME)
        else
            inst:PushEvent("knockedout")
        end
    end
end

local function FindSleepable(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 7, { "_combat", "_health" }, { "player" })
    if ents then
        for i, v in ipairs(ents) do
            if v.components.health and not v.components.health:IsDead() then
                DoSleep(v, inst)
            end
        end
    end
end

local function TriggerPocketResurrection(self, item)
    if self.inst.components.timer and self.inst:HasTag("wathom") then
        if self.inst.components.timer:TimerExists("shadowwathomcooldown") then
            self.inst.components.timer:StopTimer("shadowwathomcooldown")
            self.inst.components.timer:StartTimer("shadowwathomcooldown", TUNING.TOTAL_DAY_TIME)
        else
            self.inst.components.timer:StartTimer("shadowwathomcooldown", TUNING.TOTAL_DAY_TIME)
        end
    end

    if item.prefab == "amulet" then
        FindSleepable(self.inst)
        if self.inst.components.grogginess then
            self.inst.components.grogginess:ResetGrogginess()
        end
        if self.inst.components.moisture then
            self.inst.components.moisture:ForceDry(true, self.inst)
            self.inst.components.moisture:ForceDry(false, self.inst)
        end
        if self.inst.components.hunger then
            self.inst.components.hunger:SetPercent(2 / 3, true)
        end
        if self.inst.components.temperature then
            self.inst.components.temperature:SetTemperature(TUNING.STARTING_TEMP)
        end
        if self.inst.components.debuffable then
            self.inst.components.debuffable:Enable(false) -- Removes all debuffs.
            self.inst.components.debuffable:Enable(true)
        end
        if self.inst.components.burnable then
            self.inst.components.burnable:Extinguish(true, 0)
        end
        if self.inst.components.freezable then
            self.inst.components.freezable:Reset()
        end
        if self.inst.components.sanity then
            self.inst.components.sanity:SetPercent(.5, true)
        end
        SpawnPrefab("slingshotammo_hitfx_gold").Transform:SetPosition(self.inst.Transform:GetWorldPosition())
        SpawnPrefab("shadow_despawn").Transform:SetPosition(self.inst.Transform:GetWorldPosition())
    elseif item.prefab == "wortox_reviver" then -- Preserves debuffs and hunger.
        local fx = SpawnPrefab("wortox_soul_heal_fx")
        fx.entity:AddFollower():FollowSymbol(self.inst.GUID, self.inst.components.combat.hiteffectsymbol, 0, -50, 0)
        fx:Setup(self.inst)

        local linkeditem = item.components.linkeditem
        local owner = linkeditem and linkeditem:GetOwnerInst() or nil
        if owner and owner.components.skilltreeupdater and owner.components.skilltreeupdater:IsActivated("wortox_lifebringer_2") then
            linkeditem.owner_inst = self.inst
            self.inst.um_blockgotostate = true -- Blocking the heart's GoToState here to avoid state cancelling issues.
            item.components.spellcaster.spell(item, nil, nil, self.inst)
            if item:IsValid() then -- Blocking it also means we have to break the heart here.
                if item.components.perishable then item.components.perishable:StartPerishing() end
                if item.OnStopBody then item:OnStopBody(self.inst) end
                if item.OnConsume then item:OnConsume(self.inst) end
            end
            self.inst.um_blockgotostate = nil
            linkeditem.owner_inst = owner
        end
        self.inst.components.health:DeltaPenalty(.25)
    end

    local cause = self.inst.components.oldager and "pocketwatch_heal" or item
    self:SetCurrentHealth(TUNING.RESURRECT_HEALTH * (self.inst.resurrect_multiplier or 1)) -- Set to Resurrection value.
    if cause == "pocketwatch_heal" then
        self.inst.components.oldager:StopDamageOverTime()
    else
        self:DoDelta(0, false, cause, true, nil, true)
    end

    if self.inst:HasTag("wathom") then
        self.inst.AnimState:SetBuild("wathom")
    end

    self.inst:PushEvent("PocketResurrection")
    self:SetInvincible(true)
    self.inst:DoTaskInTime(.2, function(inst) 
        if inst.components.health then 
            inst.components.health:SetInvincible(false) 
        end 
    end)
    item:DoTaskInTime(0, function(item) item:Remove() end)
end

local function HasPocketResurrection(self)
    local inventory = self.inst.components.inventory
    if inventory then
        local item = inventory:GetEquippedItem(EQUIPSLOTS.NECK)
        if not item or not (item.prefab == "amulet" or item:HasTag("resurrector")) then
            local bodyslot = inventory:GetEquippedItem(EQUIPSLOTS.BODY)
            item = bodyslot ~= nil and (bodyslot.prefab == "amulet" or bodyslot:HasTag("resurrector")) and bodyslot
                or inventory:FindItem(function(item) return item.prefab == "wortox_reviver" end)
        end
        if self.inst.components.timer and not self.inst.components.timer:TimerExists("shadowwathomcooldown") then
            if item then
                return item
            end
        end
    end
end

local function IsCharlieRose(item)
    return item.prefab == "charlierose"
end

local function HasCharlieRose(self)
    return self.inst.components.inventory and self.inst.components.inventory:FindItem(IsCharlieRose)
end

local function TriggerRose(self)
    local rose = HasCharlieRose(self)

    if rose then
        if rose.components.stackable then
            rose.components.stackable:Get():Remove()
        else
            rose:Remove()
        end
    end

    self.inst.components.sanity:SetPercent(.5, true)
    self.inst.components.hunger:SetPercent(2 / 3, true)
    self.inst.components.temperature:SetTemp(TUNING.STARTING_TEMP)
    self:DeltaPenalty(.25)
    self:SetPercent(.5)
    self.inst:PushEvent("PocketResurrection")

    for i = 0, 3 do
        self.inst:DoTaskInTime(math.random(), function(inst)
            local x, y, z = inst.Transform:GetWorldPosition()
            local fx = SpawnPrefab("rose_petals_fx")
            fx.Transform:SetPosition(x + GetRandomMinMax(-1, 1), y, z + GetRandomMinMax(-1, 1))
        end)
    end
end

local function StopDeathStuffHere(self, amount, cause, afflicter, ...)
    local res_item = HasPocketResurrection(self)
    local maykill = math.max(amount, self.minhealth or 0) <= 0
    if TUNING.DSTU.SHADOW_WATHOM and self.inst:HasTag("wathom") then
        if maykill and cause == "shadowvortex" and TUNING.DSTU.COMPROMISING_SHADOWVORTEX and not self.inst.sg:HasStateTag("blackpuddle_death") then
            self.inst.components.rider:ActualDismount()
            self.inst.sg:GoToState("blackpuddle_death")
            return true
        elseif maykill and res_item and (not self.inst:HasTag("deathamp") or self.inst:HasTag("deathamp") and cause == "deathamp" and self.inst.components.timer and not self.inst.components.timer:TimerExists("shadowwathomcooldown")) then
            if self.inst:HasTag("deathamp") and not self.inst:HasTag("playerghost") and self.inst.ToggleUndeathState then
                self.inst:ToggleUndeathState(self.inst, false)
            end

            TriggerPocketResurrection(self, res_item) -- Don't trigger the LLA here, let it happen in our own component, so this doesn't break whenever canis moves it to his own mod.
            return true
        elseif maykill and (self.inst:HasTag("wathom") and self.inst:HasTag("amped")) and not self.inst:HasTag("deathamp") and cause ~= "deathamp" and HasSkill(self.inst,"shadow_wathom_1") then -- Suggest that we add a trigger here to show that wathom is still being hit, despite his lack of flinching or anything.
            self.inst:AddTag("deathamp")
            self.inst:ToggleUndeathState(self.inst, true)
            self:DoDelta(-self.currenthealth + 1, false, cause, true) -- Needed to do this for ignore_invincible...
            return true
        elseif self.inst:HasTag("deathamp") and cause ~= "deathamp" then
            self.inst.components.adrenaline:DoDelta(amount * 1)
            return true
        end
    elseif maykill then
        if res_item then
            TriggerPocketResurrection(self, res_item)
            return true
        elseif env.GetModConfigData("winonarose") and self.inst:HasTag("handyperson") and HasCharlieRose(self) then
            TriggerRose(self)
            return true
        end
    end
    return false
end

env.AddComponentPostInit("health", function(self)
    local _SetVal = self.SetVal
    function self:SetVal(val, cause, afflicter, ...)
        if StopDeathStuffHere(self, val, cause, afflicter, ...) then
            return
        end
        return _SetVal(self, val, cause, afflicter, ...)
    end
    
    if TUNING.DSTU.ONEHP == true then-- All this code is here
        TUNING.WX78_MAXHEALTH_BOOST = 0
        TUNING.WX78_MAXHEALTH2_MULT = 0
        local _SetMaxHealth = self.SetMaxHealth
        function self:SetMaxHealth(amount)
            if self.inst:HasTag("player") then
                return _SetMaxHealth(self, 1)
            else
                return _SetMaxHealth(self, amount)
            end
        end    
    end
end)