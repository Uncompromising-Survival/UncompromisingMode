local env = env
GLOBAL.setfenv(1, GLOBAL)

if TheNet:IsDedicated() then
    local nullfunc = function() end
    SpawnHoodedforestCanopy = nullfunc
    DespawnHoodedforestCanopy = nullfunc
    ShadeRendererEnabled = nil
    return
end

ShadeTypes.HoodedForestCanopy = ShadeRenderer:CreateShadeType()

ShadeRenderer:SetShadeMaxRotation(ShadeTypes.HoodedForestCanopy, TUNING.DSTU.HOODEDFOREST_CANOPY_MAX_ROTATION)
ShadeRenderer:SetShadeRotationSpeed(ShadeTypes.HoodedForestCanopy, TUNING.DSTU.HOODEDFOREST_CANOPY_ROTATION_SPEED)

ShadeRenderer:SetShadeMaxTranslation(ShadeTypes.HoodedForestCanopy, TUNING.DSTU.HOODEDFOREST_CANOPY_MAX_TRANSLATION)
ShadeRenderer:SetShadeTranslationSpeed(ShadeTypes.HoodedForestCanopy, TUNING.DSTU.HOODEDFOREST_CANOPY_TRANSLATION_SPEED)

ShadeRenderer:SetShadeTexture(ShadeTypes.HoodedForestCanopy, resolvefilepath("images/giant_tree.tex"))

function SpawnHoodedforestCanopy(x, z)
    return ShadeRenderer:SpawnShade(ShadeTypes.HoodedForestCanopy, x, z, math.random() * 360, TUNING.DSTU.HOODEDFOREST_CANOPY_SCALE*GetRandomWithVariance(1, 0.25))
end

function DespawnHoodedforestCanopy(id)
    ShadeRenderer:RemoveShade(ShadeTypes.HoodedForestCanopy, id)
end

local _ShadeEffectUpdate = ShadeEffectUpdate
function ShadeEffectUpdate(dt, ...)
    local r, g, b = TheSim:GetAmbientColour()

    ShadeRenderer:SetShadeStrength(ShadeTypes.HoodedForestCanopy, Lerp(TUNING.DSTU.HOODEDFOREST_CANOPY_MIN_STRENGTH, TUNING.DSTU.HOODEDFOREST_CANOPY_MAX_STRENGTH, ((r + g + b) / 3) / 255))
    return _ShadeEffectUpdate(dt, ...)
end

ShadeRendererEnabled = false
local _EnableShadeRenderer = EnableShadeRenderer
function EnableShadeRenderer(enable, ...)
    ShadeRendererEnabled = enable
    local _world = TheWorld
    if _world ~= nil and _world.components.canopymanager ~= nil then
        _world.components.canopymanager:SetEnabled(enable)
    end

    return _EnableShadeRenderer(enable, ...)
end
