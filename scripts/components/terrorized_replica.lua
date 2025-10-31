local Terrorized = Class(function(self, inst)
    self.inst = inst
	
    if TheWorld.ismastersim then
        self.classified = inst.player_classified
    elseif self.classified == nil and inst.player_classified ~= nil then
        self:AttachClassified(inst.player_classified)
    end
end)

--------------------------------------------------------------------------

function Terrorized:OnRemoveFromEntity()
    if self.classified ~= nil then
        if TheWorld.ismastersim then
            self.classified = nil
        else
            self.inst:RemoveEventCallback("onremove", self.ondetachclassified, self.classified)
            self:DetachClassified()
        end
    end
end

Terrorized.OnRemoveEntity = Terrorized.OnRemoveFromEntity

function Terrorized:AttachClassified(classified)
    self.classified = classified
    self.ondetachclassified = function() self:DetachClassified() end
    self.inst:ListenForEvent("onremove", self.ondetachclassified, classified)
end

function Terrorized:DetachClassified()
    self.classified = nil
    self.ondetachclassified = nil
end

----------------------------------------------------

function Terrorized:SetImmunity(current)
    if self.classified ~= nil then
        self.classified:SetValue("terror_immunity", current)
    end
end

function Terrorized:SetTerror(terror)
    if self.classified ~= nil then
        self.classified:SetValue("nightterror", terror)
    end
end


return Terrorized
