local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------


env.AddClassPostConstruct("screens/playerhud", function(self)
    local _OpenSpellWheel = self.OpenSpellWheel
    function self:OpenSpellWheel(invobject, items, radius, focus_radius)
        print("is this running")
        invobject:PushEvent("openspellwheel")
        self:CloseSpellWheel(false)
        _OpenSpellWheel(self, invobject, items, radius, focus_radius)
    end
end)