local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddComponentPostInit("quaker", function(self)
    local MAGMA_CAVES_DEBRIS =
    {
        { -- common
            weight = 0.75,
            loot = {
                "rocks",
                "flint",
                "nitre",
            },
        },
        { -- uncomon
            weight = 0.15,
            loot = {
                "goldnugget",
                "redgem",
                "um_fyrite",
                "marble",
                --"um_ribopod", --Too much work to code in unfortunately
                "boneshard",
            },
        },
        { -- rare
            weight = 0.035,
            loot = {
                --"mole",
                "snapalm",
                "slurtle_shellpieces",
            },
        },
    }
    self:SetTagDebris( "magmacaves", MAGMA_CAVES_DEBRIS )

    --[[if debris ~= nil and (prefab == "um_ribopod") and debris.sg ~= nil then
        _mammalsremaining = _mammalsremaining - 1
        debris.sg:GoToState("fall")
    end]]
end)
