local env = env
GLOBAL.setfenv(1, GLOBAL)
local infestables = {
    "bat",
    "vampirebat",
    "bunnyman",
    "pigman",
    "slurtle",
    "slurper",
    "monkey",
    "rocky",
    "spider",
    "spiderqueen",
    "spider_warrior",
    "spider_dropper",
    "spider_spitter",
    "spider_hider",
    "spider_moon",
    "beefalo",
    "bee",
    "killerbee",
    "mosquito"
}

local function MakeInfestable(inst)
    if not inst.components.infestable then
        inst:AddComponent("infestable")
    end

    if not inst:HasTag("infestable") then
        inst:AddTag("infestable")
    end
end

for _, prefab in pairs(infestables) do
    env.AddPrefabPostInit(prefab, function(inst)
        if not TheWorld.ismastersim then
            return inst
        end

        MakeInfestable(inst)
    end)
end

env.AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then
        return inst
    end

    MakeInfestable(inst)

    inst:ListenForEvent("respawnfromghost", MakeInfestable)
    inst:ListenForEvent("respawnfromcorpse", MakeInfestable)
end)