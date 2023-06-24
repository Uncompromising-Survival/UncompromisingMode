--DUMBEST FUCKING NAME I'VE SEEN SO FAR

local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

function DoHeatwaveGlow(inst)
    if TheWorld:HasTag("heatwavestart") or TheWorld.net:HasTag("heatwavestartnet") then
        inst.AnimState:SetSymbolAddColour("meter", 1, 0, 0, 0)
        inst.AnimState:SetSymbolLightOverride("meter", .5)
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetSymbolBloom("meter")
    else
        inst.AnimState:SetSymbolAddColour("meter", 0, 0, 0, 0)
        inst.AnimState:SetSymbolLightOverride("meter", 0)
        inst.AnimState:ClearSymbolBloom("meter")
        inst.AnimState:ClearBloomEffectHandle("shaders/anim.ksh")
    end
end

env.AddPrefabPostInit("winterometer", function(inst)
    inst:DoPeriodicTask(1, DoHeatwaveGlow, 0)
end)
