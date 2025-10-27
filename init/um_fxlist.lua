local fxlist = {
    {
        name = "um_ocean_splash",
        bank = "Bubble_fx",
        build = "crab_king_bubble_fx",
        anim = "waterspout",
        sound = "turnoftides/common/together/water/splash/medium",
        fn = function(inst)
            inst.AnimState:SetFinalOffset(1)
        end,
    },
}

local fxprefabs = require("fx")
for _, fx in pairs(fxlist) do
    table.insert(fxprefabs, fx)
end