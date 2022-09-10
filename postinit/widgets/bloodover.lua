local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddClassPostConstruct("widgets/bloodover", function(self, owner)
    local _UpdateState = self.UpdateState
    self.owner = owner

    function self:UpdateState()
        if self.inst:HasTag("amped") or self.owner:HasTag("amped") then
            print("amped! turning on bloodover")    --I have no idea what's self.owner but worth a shot.
            self:TurnOn()
        else
            print("not amped! returnign normal _updatestate")
            return _UpdateState(self)
        end
    end

    local function __UpdateState() self:UpdateState() end

    self.inst:ListenForEvent("adrenalinedelta", __UpdateState, owner)
end)