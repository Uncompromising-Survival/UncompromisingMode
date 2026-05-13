local env = env
GLOBAL.setfenv(1, GLOBAL)


local NightTerrorsWidget = require "widgets/nightterrorwidget"

env.AddClassPostConstruct("widgets/statusdisplays", function(self, owner)

	self.nightterrorswidget = self:AddChild( NightTerrorsWidget(owner) )

    local x, y, z = self.brain:GetPosition():Get()
    self.nightterrorswidget:SetPosition(x, y-100, z)

end)
