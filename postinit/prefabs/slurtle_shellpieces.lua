local env = env
GLOBAL.setfenv(1, GLOBAL)

local prefabs = {"slurtle_shellpieces", "boneshard"}
for i,v in ipairs(prefabs) do
    env.AddPrefabPostInit(v, function(inst)
        if not TheWorld.ismastersim then return end
        inst:AddTag("quakedebris")
    end)
end