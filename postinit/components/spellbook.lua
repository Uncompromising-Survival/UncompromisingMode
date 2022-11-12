local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddComponentPostInit("spellbook", function(self)
    --[[local _OpenSpellBook = self.OpenSpellBook

    function self:OpenSpellBook(user)
        self.inst:PushEvent("openspellwheel")
        if user ~= nil then
            return _OpenSpellBook(user)
        end
    end]]
end)
