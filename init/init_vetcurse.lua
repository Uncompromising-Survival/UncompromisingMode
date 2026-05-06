local require = GLOBAL.require
local env = env
GLOBAL.setfenv(1, GLOBAL)
local UMVetCurse = require("tools/um_vetcurseutility")

--[[Deprecated
    inst.um_deathcount = 1
    
    inst:ListenForEvent("death", function()
        if inst:HasTag("vetcurse") then
            if inst:HasTag("vetcurse") and inst.um_deathcount < 4 and inst.wilson_vetcurse then
                inst.um_deathcount = inst.um_deathcount + 1
            end
            print("deathcount"..inst.um_deathcount)
            
            inst:AddTag("um_"..inst.um_deathcount.."_deaths")
        end
    end)

    local function OnLoad(inst, data, ...)
        if data ~= nil then
            if data.wilson_vetcurse then
                inst.wilson_vetcurse = data.wilson_vetcurse
            end
            
            if data.walter_vetcurse ~= nil then
                inst.walter_vetcurse = data.walter_vetcurse
            end
            
            if data.wortox_vetcurse then
                inst.wortox_vetcurse = data.wortox_vetcurse
            end
            
            if data.maxwell_vetcurse then
                inst.maxwell_vetcurse = data.maxwell_vetcurse
            end
            
            if data.willow_vetcurse then
                inst.willow_vetcurse = data.willow_vetcurse
            end
            
            if data.warly_vetcurse then
                inst.warly_vetcurse = data.warly_vetcurse
            end
            
            if data.winky_vetcurse then
                inst.winky_vetcurse = data.winky_vetcurse
            end
            
            if data.vetcurse_sleepiness then
                inst.vetcurse_sleepiness = data.vetcurse_sleepiness
            end
            
            if data.wickerbottom_vetcurse then
                inst.wickerbottom_vetcurse = data.wickerbottom_vetcurse
            end
            
            if data.wixie_vetcurse then
                inst.wixie_vetcurse = data.wixie_vetcurse
            end
            
            if data.woodie_vetcurse then
                inst.woodie_vetcurse = data.woode_vetcurse
            end
            
            if data.wolfgang_curse then
                inst.wolfgang_curse = data.wolfgang_curse
            end
            
            if data.wanda_vetcurse then
                inst.wanda_vetcurse = data.wanda_vetcurse
            end
            
            if data.wathgrithr_vetcurse then
                inst.wathgrithr_vetcurse = data.wathgrithr_vetcurse
            end
            
            if data.um_deathcount then
                inst.um_deathcount = data.um_deathcount
            end

            if data.wes_vetcurse then
                inst.wes_vetcurse = data.wes_vetcurse
            end

            if data.wendy_vetcurse then
                inst.wendy_vetcurse = data.wendy_vetcurse
            end
        
            if data.vetscurse then
                inst:ListenForEvent("respawnfromghost", function()
                    inst:DoTaskInTime(3, function(inst) 
                        
                        inst.components.debuffable:AddDebuff("buff_vetcurse", "buff_vetcurse")
                    end)
                end, inst)
                
                inst:ListenForEvent("ms_playerseamlessswaped", function()
                    inst:DoTaskInTime(3, function(inst) 
                        
                        inst.components.debuffable:AddDebuff("buff_vetcurse", "buff_vetcurse")
                    end)
                end, inst)
            end
        end
    
        return _OldOnLoad(inst, data, ...)
    end
    
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
]]

env.AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return inst end
    
    local _OnSave = inst.OnSave
    local function OnSave(inst, data, ...)
        if inst.vetcurse then
            data.vetscurse = inst.vetcurse
        end
        return _OnSave(inst, data, ...)
    end

    local _OnLoad = inst.OnLoad
    local function OnLoad(inst, data, ...)
        if data and data.vetscurse then
            inst:UMToggleVetCurse(true)
        end
        return _OnLoad(inst, data, ...)
    end

    inst.UMToggleVetCurse = UMVetCurse.ToggleVetCurse

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
end)

env.AddClassPostConstruct("widgets/healthbadge", function(self, owner)
    local _OldOnUpdate = self.OnUpdate
    self.owner = owner

    function self:OnUpdate(dt)
        if self.owner ~= nil and self.owner:HasTag("wes_vetcurse") then
            if self.owner.replica.health ~= nil and self.owner.replica.health:GetPercent() and self._vet_updatetask == nil then
                if not TheFocalPoint.SoundEmitter:PlayingSound("heartbeat") then
                    TheFocalPoint.SoundEmitter:PlaySound("UCSounds/vets_heartbeat/heartbeat", "heartbeat")
                end
            
                self._vet_updatetask = self.inst:DoTaskInTime(.1, function()
                    TheFocalPoint.SoundEmitter:SetParameter("heartbeat", "pitch", 1 - self.owner.replica.health:GetPercent())
                    self._vet_updatetask = nil
                end)
            end
        
            self:Hide()
        else
            return _OldOnUpdate(self, dt)
        end
    end
end)

local dupe_widgets = {
    "hungerbadge",
    "sanitybadge",
    "wandaagebadge",
    "moisturemeter",
}
for i, v in pairs(dupe_widgets) do
    env.AddClassPostConstruct("widgets/"..v, function(self, owner)
        local _OldOnUpdate = self.OnUpdate
        self.owner = owner

        function self:OnUpdate(dt)
            if self.owner ~= nil and self.owner:HasTag("wes_vetcurse") then
                self:Hide()
            else
                return _OldOnUpdate(self, dt)
            end
        end
    end)
end

--env.AddClassPostConstruct("widgets/uiclock", function(self, owner)
env.AddClassPostConstruct("widgets/controls", function(self, owner)
    local _OldOnUpdate = self.OnUpdate
    self.owner = owner
    
    function self:OnUpdate(dt)
        if self.clock ~= nil and self.owner ~= nil and self.owner:HasTag("wes_vetcurse") then
            self.clock:Hide()
        end
        
        return _OldOnUpdate(self, dt)
    end
end)