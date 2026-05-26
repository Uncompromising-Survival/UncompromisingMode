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
    {
        name = "um_brokentool",
        bank = "broketool",
        build = "broken_tool",
        anim = "used",
        sound = "dontstarve/wilson/use_break",
        nofaced = true,
    },
}

local fxprefabs = require("fx")
for _, fx in pairs(fxlist) do
    table.insert(fxprefabs, fx)
end