local function onmax(self, max)
    self.inst.counter_max:set(max)
    self.inst.replica.maxadrenaline = max
end

local function oncurrent(self, current)
    self.inst.counter_current:set(current)
    self.inst.replica.currentadrenaline = current
end

local function onamp(self, amped)
    print("onamp!!!")
    --transform it to binary because replica SetValue is numbers only, and I don't feel like messing with netvars...
    self.inst.replica.adrenaline:SetAmped(amped)
    --explicit true check because it's now a number
    if amped then
        self.inst:PushEvent("wathommusic_start")
    else
        self.inst:PushEvent("wathommusic_end")
    end
end

local Adrenaline = Class(function(self, inst)
    self.inst = inst
    self.max = 100
    self.current = 25
    self.adrenalinecheck = 0
    self.isamped = false
    self.inst:ListenForEvent("respawn", function(inst) self:OnRespawn() end)
end,
    nil,
    {
        max = onmax,
        current = oncurrent,
        isamped = onamp,
    })

function Adrenaline:OnRespawn()
    local old = self.current
    self.current = 25
    self.inst.replica.adrenaline:SetCurrent(25)

    self.inst:PushEvent("adrenalinedelta",
        { oldpercent = old / self.max, newpercent = self.current / self.max, overtime = overtime })
end

function Adrenaline:OnSave()
    return { adrenaline = self.current }
end

function Adrenaline:OnLoad(data)
    if data.adrenaline then
        self.current = data.adrenaline
        self:DoDelta(0)
    end
end

function Adrenaline:GetDebugString()
    return string.format("%2.2f / %2.2f", self.current, self.max)
end

function Adrenaline:DoDelta(delta, overtime)
    local old = self.current
    self.current = self.current + delta
    if self.current < 0 then
        self.current = 0
    elseif self.current > self.max then
        self.current = self.max
    end

    --    if self:GetPercent() <= 0.10 and self.pestilencecheck < 3 then
    --        self.inst.components.talker:Say("I must advance my cure immediately." , 3)
    --        self.pestilencecheck = 3
    --    elseif self:GetPercent() <= 0.33 and self.pestilencecheck < 2 then
    --        self.inst.components.talker:Say("I need a patient with human-like anatomy." , 3)
    --        self.pestilencecheck = 2
    --    elseif self:GetPercent() <= 0.5 and self.pestilencecheck < 1 then
    --        self.inst.components.talker:Say("The Pestilence grows stronger." , 3)
    --        self.pestilencecheck = 1
    --    end

    --    if self:GetPercent() > 0.5 then
    --        self.pestilencecheck = 0
    --    elseif self:GetPercent() > 0.33 then
    --        self.pestilencecheck = 1
    --    elseif self:GetPercent() > 0.10 then
    --        self.pestilencecheck = 2
    --    end

    if self:GetPercent() < 0.24 then
        --        self.inst.components.sanity.dapperness = -20 / 60
        if self.inst.components.grogginess ~= nil and not self.inst:HasTag("amped") and not self.inst:HasTag("playerghost") then
            self.inst.components.grogginess:AddGrogginess(0.5, 0)
        end
        --        local counterspeedmod = 1 / Remap(0, 1, 0, TUNING.MIN_GROGGY_SPEED_MOD, TUNING.MAX_GROGGY_SPEED_MOD)
        --        self.inst.components.locomotor:SetExternalSpeedMultiplier(self.inst, "countergrogginess", counterspeedmod)
    end

    self.inst:PushEvent("adrenalinedelta",
        { oldpercent = old / self.max, newpercent = self.current / self.max, overtime = overtime })
end

function Adrenaline:GetPercent()
    return self.current / self.max
end

function Adrenaline:GetCurrent()
    return self.current
end

function Adrenaline:SetPercent(p)
    local old = self.current
    self.current = p * self.max
    self.inst:PushEvent("adrenalinedelta", { oldpercent = old / self.max, newpercent = p })
end

function Adrenaline:SetAmped(amped)
    self.isamped = amped
end

return Adrenaline
