local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return end
    if (inst:HasTag("plant") or inst:HasTag("tree")) and inst.components.burnable ~= nil then
        local _OnIgnite = inst.components.burnable.onignite

        inst.components.burnable.onignite = function(inst, source, doer, ...)
            if TheWorld.state.issummer then
                inst.smog_task = inst:DoTaskInTime(math.random(10, 30) / 10, function()
                    for i = 1, math.random(3) do
                        local smog = SpawnPrefab("smog")
                        local x, y, z = inst.Transform:GetWorldPosition()

                        smog.Transform:SetPosition(x + math.random(-160, 160) / 10, math.random(0, 4),
                            z + math.random(-160, 160) / 10)
                        --smog.Transform:SetRotation(TheWorld.components.worldwind:GetWindAngle())
                    end
                end)
            end
            _OnIgnite(inst, source, doer, ...)
        end
    end
end)
