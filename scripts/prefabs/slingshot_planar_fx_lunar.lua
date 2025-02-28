local function MakePlanarLunarFx(name, customassets, customprefabs, common_postinit, master_postinit)
    local assets =
    {
        Asset("SCRIPT", "scripts/prefabs/torchfire_common.lua"),
    }

    if customassets ~= nil then
        for i, v in ipairs(customassets) do
            table.insert(assets, v)
        end
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst:AddTag("FX")

        inst.SoundEmitter:PlaySound("dontstarve/wilson/torch_LP", "torch")
        inst.SoundEmitter:SetParameter("torch", "intensity", 1)

        if common_postinit ~= nil then
            common_postinit(inst)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.persists = false

        if master_postinit ~= nil then
            master_postinit(inst)
        end

        return inst
    end

    return Prefab(name, fn, assets, customprefabs)
end

local ANIM_HAND_TEXTURE = "fx/animhand.tex"
local ANIM_SMOKE_TEXTURE = "fx/animsmoke.tex"

local SHADER = "shaders/vfx_particle.ksh"
local REVEAL_SHADER = "shaders/vfx_particle_reveal.ksh"

local COLOUR_ENVELOPE_NAME_SMOKE = "torch_shadow_colourenvelope_smoke-sugma"
local SCALE_ENVELOPE_NAME_SMOKE = "torch_shadow_scaleenvelope_smoke-sugma"
local COLOUR_ENVELOPE_NAME = "torch_shadow_colourenvelope-sugma"
local SCALE_ENVELOPE_NAME = "torch_shadow_scaleenvelope-sugma"
local COLOUR_ENVELOPE_NAME_HAND = "torch_shadow_colourenvelope_hand-sugma"
local SCALE_ENVELOPE_NAME_HAND = "torch_shadow_scaleenvelope_hand-sugma"

local assets =
{
    Asset("IMAGE", ANIM_HAND_TEXTURE),
    Asset("IMAGE", ANIM_SMOKE_TEXTURE),
    Asset("SHADER", SHADER),
    Asset("SHADER", REVEAL_SHADER),
}

--------------------------------------------------------------------------

local function IntColour(a)
    return { 200 / 255, 200 / 255, 255 / 255, a / 255 }
end

local function InitEnvelope()
    EnvelopeManager:AddColourEnvelope(
        COLOUR_ENVELOPE_NAME_SMOKE,
        {
            { 0,    IntColour(64) },
            { .2,   IntColour(240) },
            { .7,   IntColour(256) },
            { 1,    IntColour(0) },
        }
    )

    local smoke_max_scale = .3
    EnvelopeManager:AddVector2Envelope(
        SCALE_ENVELOPE_NAME_SMOKE,
        {
            { 0,    { smoke_max_scale * .2, smoke_max_scale * .2} },
            { .40,  { smoke_max_scale * .7, smoke_max_scale * .7} },
            { .60,  { smoke_max_scale * .8, smoke_max_scale * .8} },
            { .75,  { smoke_max_scale * .7, smoke_max_scale * .7} },
            { 1,    { smoke_max_scale, smoke_max_scale } },
        }
    )

    EnvelopeManager:AddColourEnvelope(
        COLOUR_ENVELOPE_NAME,
        {   { 0,    IntColour(25) },
            { .19,  IntColour(256) },
            { .35,  IntColour(256) },
            { .51,  IntColour(256) },
            { .75,  IntColour(256) },
            { 1,    IntColour(0) },
        }
    )

    EnvelopeManager:AddColourEnvelope(
        COLOUR_ENVELOPE_NAME_HAND,
        {
            { 0,    IntColour(64) },
            { .2,   IntColour(256) },
            { .75,  IntColour(256) },
            { 1,    IntColour(0) },
        }
    )

    local hand_max_scale = 1
    EnvelopeManager:AddVector2Envelope(
        SCALE_ENVELOPE_NAME_HAND,
        {
            { 0,    { hand_max_scale * .3, hand_max_scale * .3} },
            { .2,   { hand_max_scale * .7, hand_max_scale * .7} },
            { 1,    { hand_max_scale, hand_max_scale } },
        }
    )

    InitEnvelope = nil
    IntColour = nil
end

--------------------------------------------------------------------------

local SMOKE_MAX_LIFETIME = 1.1
local HAND_MAX_LIFETIME = 1.7

local function emit_smoke_fn(effect, sphere_emitter)
    local vx, vy, vz = .01 * UnitRand(), .06 + .02 * UnitRand(), .01 * UnitRand()
    local lifetime = SMOKE_MAX_LIFETIME * (.9 + UnitRand() * .1)
    local px, py, pz = sphere_emitter()
    --offset the flame particles upwards a bit so they can be used on a torch

    effect:AddRotatingParticleUV(
        1,
        lifetime,           -- lifetime
        px, py + .35, pz,   -- position
        vx, vy, vz,         -- velocity
        math.random() * 360,--* 2 * PI, -- angle
        UnitRand() * 2,     -- angle velocity
        0, 0                -- uv offset
    )
end

local function emit_hand_fn(effect, sphere_emitter)
    local vx, vy, vz = 0, .07 + .01 * UnitRand(), 0
    local px, py, pz = sphere_emitter()
    --offset the flame particles upwards a bit so they can be used on a torch

    local uv_offset = math.random(0, 3) * .25

    effect:AddRotatingParticleUV(
        2,
        HAND_MAX_LIFETIME,  -- lifetime
        px, py + .65, pz,   -- position
        vx, vy, vz,         -- velocity
        0,                  --* 2 * PI, -- angle
        UnitRand(),         -- angle velocity
        uv_offset, 0        -- uv offset
    )
end

--------------------------------------------------------------------------

local function common_postinit(inst)
    --Dedicated server does not need to spawn local particle fx
    if TheNet:IsDedicated() then
        return
    elseif InitEnvelope ~= nil then
        InitEnvelope()
    end

    -----------------------------------------------------

    local effect = inst.entity:AddVFXEffect()
    effect:InitEmitters(3)

    --SMOKE
    effect:SetRenderResources(1, ANIM_SMOKE_TEXTURE, REVEAL_SHADER) --REVEAL_SHADER --particle_add
    effect:SetMaxNumParticles(1, 32)
    effect:SetRotationStatus(1, true)
    effect:SetMaxLifetime(1, SMOKE_MAX_LIFETIME)
    effect:SetColourEnvelope(1, COLOUR_ENVELOPE_NAME_SMOKE)
    effect:SetScaleEnvelope(1, SCALE_ENVELOPE_NAME_SMOKE)
    effect:SetBlendMode(1, BLENDMODE.AlphaBlended) --AlphaBlended Premultiplied
    effect:EnableBloomPass(1, true)
    effect:SetUVFrameSize(1, 1, 1)
    effect:SetSortOrder(1, 0)
    effect:SetSortOffset(1, 1)

    --HAND
    effect:SetRenderResources(2, ANIM_HAND_TEXTURE, REVEAL_SHADER) --REVEAL_SHADER --particle_add
    effect:SetMaxNumParticles(2, 32)
    effect:SetRotationStatus(2, true)
    effect:SetMaxLifetime(2, HAND_MAX_LIFETIME)
    effect:SetColourEnvelope(2, COLOUR_ENVELOPE_NAME_HAND)
    effect:SetScaleEnvelope(2, SCALE_ENVELOPE_NAME_HAND)
    effect:SetBlendMode(2, BLENDMODE.AlphaBlended) --AlphaBlended Premultiplied
    effect:EnableBloomPass(2, true)
    effect:SetUVFrameSize(2, .25, 1)
    effect:SetSortOrder(2, 0)
    effect:SetSortOffset(2, 1)
    --effect:SetDragCoefficient(2, 50)

    -----------------------------------------------------

    local tick_time = TheSim:GetTickTime()

    local smoke_desired_pps = 10
    local smoke_particles_per_tick = smoke_desired_pps * tick_time
    local smoke_num_particles_to_emit = 0 --start delay

    local hand_desired_pps = .3
    local hand_particles_per_tick = hand_desired_pps * tick_time
    local hand_num_particles_to_emit = 0 ---50 --start delay

    local sphere_emitter = CreateSphereEmitter(.05)

    EmitterManager:AddEmitter(inst, nil, function()
        --SMOKE
        while smoke_num_particles_to_emit > 1 do
            emit_smoke_fn(effect, sphere_emitter)
            smoke_num_particles_to_emit = smoke_num_particles_to_emit - 1
        end
        smoke_num_particles_to_emit = smoke_num_particles_to_emit + smoke_particles_per_tick

        --HAND
        while hand_num_particles_to_emit > 1 do
            emit_hand_fn(effect, sphere_emitter)
            hand_num_particles_to_emit = hand_num_particles_to_emit - 1
        end
        hand_num_particles_to_emit = hand_num_particles_to_emit + hand_particles_per_tick
    end)
end

local function master_postinit(inst)
    inst.fx_offset = -100
end

return MakePlanarLunarFx("slingshot_planar_fx_lunar", assets, nil, common_postinit, master_postinit)