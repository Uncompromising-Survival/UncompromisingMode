local Minerologyable = Class(function(self, inst)
    self.inst = inst
    self._enchantnum = net_smallbyte(inst.GUID, "minerologyable._enchantnum")
    self._chilling = net_smallbyte(inst.GUID, "minerologyable._chilling")
    self._durability = net_float(inst.GUID, "minerologyable._durability", "minerologyable._durabilitydirty")

    inst:ListenForEvent("minerologyable._durabilitydirty", function(inst)
        inst:PushEvent("gemdurabilitychanged")
        if inst._parent ~= nil then
            inst._parent:PushEvent("gemdurabilitychanged")
        end
    end)
end)

function Minerologyable:SetEnchantClient(num)
    self._enchantnum:set(num)
end

function Minerologyable:SetChillingClient(chilling)
    local inst = self.inst
    if chilling then
        if not inst:HasTag("show_spoilage") then
            inst:AddTag("show_spoilage")
            inst:AddTag("icebox_valid")
        end
    elseif inst:HasTag("show_spoilage") then
        inst:RemoveTag("show_spoilage")
        inst:RemoveTag("icebox_valid")
    end
end

function Minerologyable:SetDurabilityClient(durability)
    print("replica durability changed")
    self._durability:set(durability)
end

function Minerologyable:GetDurabilityClient()
    return self._durability:value()
end

return Minerologyable
