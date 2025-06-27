local BoatBottle = Class(function(self, inst)
    self.inst = inst

    self.boat_prefab = nil
    self.inst:AddTag("boatbottle")
    self.fx = nil
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
    local fx = self.inst.fx or self.fx

    if isfull then
        --re-follow in case we start following when this symbol doesn't exist.

        if fx ~= nil then
            fx.Follower:FollowSymbol(self.inst.GUID, "boat", 0, 50, 0) --TODO, check offsets.
            fx:Show()
        end
        self.inst:AddTag("filled_boat_bottle")
    else
        if fx ~= nil then
            fx:Hide()
        end
        self.inst:RemoveTag("filled_boat_bottle")
    end
end

function BoatBottle:SetBoatPrefab(prefab)
    self.boat_prefab = prefab
end

return BoatBottle