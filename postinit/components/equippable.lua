local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

local function GetVolatileGemologyData(self, tabletype, fn, ...)
    local gem_enchantable = self.inst.components.gem_enchantable
    if gem_enchantable then
        for enchant, tier in pairs(gem_enchantable.enchants) do
            local gemtable = self.inst.volatile_gemology_data[enchant][tabletype]
            if gemtable then fn(enchant, tier, gemtable, self, ...) end
        end
    end
end

env.AddComponentPostInit("equippable", function(self)
    local _GetDapperness = self.GetDapperness
    function self:GetDapperness(owner, ignore_wetness, ...)
        local _dapperness
        local _dapperfn
        GetVolatileGemologyData(self, "dapperness", function(enchant, tier, gemtable, _self)
            if _self.dapperfn and not _dapperfn then
                _dapperfn = _self.dapperfn
            elseif not _dapperness then
                _dapperness = _self.dapperness
            end
            if _dapperfn then
                local _dapperfnchanged = _self.dapperfn
                _self.dapperfn = function(inst, owner, ...)
                    return gemtable.fn(inst, tier, _dapperfnchanged(inst, owner, ...), gemtable)
                end
            else
                local _dappernesschanged = _self.dapperness
                _self.dapperness = gemtable.fn(_self.inst, tier, _dappernesschanged, gemtable)
            end
        end)
        local ret = {_GetDapperness(self, owner, ignore_wetness, ...)}
        if _dapperfn then self.dapperfn = _dapperfn end
        if _dapperness then self.dapperness = _dapperness end
        return unpack(ret)
    end
end)