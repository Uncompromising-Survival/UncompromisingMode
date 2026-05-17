local ENV = env
GLOBAL.setfenv(1, GLOBAL)

--	Play funny sound on activation ~
-- Credit to ADM

local ServerCreationScreen = TheFrontEnd:GetActiveScreen()

if tostring(ServerCreationScreen) == "ServerCreationScreen" then
    staticScheduler:ExecuteInTime(0, function()
        TheFrontEnd:GetSound():PlaySound("dontstarve/common/teleportato/teleportato_maxwelllaugh", "laugh")
        TheFrontEnd:GetSound():SetVolume("laugh", 0.33)
        TheFrontEnd:GetSound():PlaySound("dontstarve/sanity/creature2/taunt")
    end)
end
