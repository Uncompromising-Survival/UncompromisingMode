local BoatBottle = Class(function(self, inst)
    self.inst = inst

    self.boat_prefab = nil
    self.inst:AddTag("boatbottle")

    if TheWorld.ismastersim then
        self.classified = inst.player_classified
    elseif self.classified == nil and inst.player_classified ~= nil then
        self:AttachClassified(inst.player_classified)
    end
end)

--------------------------------------------------------------------------


function BoatBottle:AttachClassified(classified)
    self.classified = classified
    self.ondetachclassified = function() self:DetachClassified() end
    self.inst:ListenForEvent("onremove", self.ondetachclassified, classified)
end

function BoatBottle:DetachClassified()
    self.classified = nil
    self.ondetachclassified = nil
end

-----------------------------
function BoatBottle:SetIsFull(isfull)
    if isfull then
        self.inst:AddTag("filled_boat_bottle")
    else
        self.inst:RemoveTag("filled_boat_bottle")
    end
end

function BoatBottle:SetBoatPrefab(prefab)
    self.boat_prefab = prefab
end


return BoatBottle