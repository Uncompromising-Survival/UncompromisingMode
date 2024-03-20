local ANIM_SMOKE_TEXTURE = "fx/animsmoke.tex"
local EMBER_TEXTURE = "fx/snow.tex"

local SHADER = "shaders/vfx_particle.ksh"
local ADD_SHADER = "shaders/vfx_particle_add.ksh"
local REVEAL_SHADER = "shaders/vfx_particle_reveal.ksh"

local COLOUR_ENVELOPE_NAME_SMOKE = "torch_pronged_colourenvelope_smoke"
local SCALE_ENVELOPE_NAME_SMOKE = "torch_pronged_scaleenvelope_smoke"
local COLOUR_ENVELOPE_NAME = "torch_pronged_colourenvelope"
local SCALE_ENVELOPE_NAME = "torch_pronged_scaleenvelope"
local COLOUR_ENVELOPE_NAME_EMBER = "torch_pronged_colourenvelope_ember"
local SCALE_ENVELOPE_NAME_EMBER = "torch_pronged_scaleenvelope_ember"

local assets =
{
    Asset("IMAGE", ANIM_SMOKE_TEXTURE),
    Asset("IMAGE", EMBER_TEXTURE),
    Asset("SHADER", SHADER),
    Asset("SHADER", ADD_SHADER),
    Asset("SHADER", REVEAL_SHADER),
}

--------------------------------------------------------------------------

local function IntColour(r, g, b, a)
    return { r / 255, g / 255, b / 255, a / 255 }
end

local function InitEnvelope()
    EnvelopeManager:AddColourEnvelope(
        COLOUR_ENVELOPE_NAME,
        {
            { 0,    IntColour(200, 85, 60, 25) },
            { .19,  IntColour(200, 125, 80, 256) },
            { .35,  IntColour(255, 20, 10, 256) },
            { .51,  IntColour(255, 20, 10, 256) },
            { .75,  IntColour(255, 20, 10, 256) },
            { 1,    IntColour(255, 7, 5, 0) },
        }
    )

    local fire_max_scale = .1
    EnvelopeManager:AddVector2Envelope(
        SCALE_ENVELOPE_NAME,
        {
            { 0,    { fire_max_scale * .75, fire_max_scale * .75 } },
            { 1,    { fire_max_scale * .5, fire_max_scale * .5 } },
        }
    )

    EnvelopeManager:AddColourEnvelope(
        COLOUR_ENVELOPE_NAME_EMBER,
        {
            { 0,    IntColour(200, 85, 60, 0) },
            { .2,   IntColour(230, 140, 90, 200) },
            { .3,   IntColour(255, 90, 70, 255) },
            { .6,   IntColour(255, 90, 70, 255) },
            { .9,   IntColour(255, 90, 70, 230) },
            { 1,    IntColour(255, 70, 70, 0) },
        }
    )

    local ember_max_scale = .2
    EnvelopeManager:AddVector2Envelope(
        SCALE_ENVELOPE_NAME_EMBER,
        {
            { 0,    { ember_max_scale, ember_max_scale } },
            { 1,    { ember_max_scale, ember_max_scale } },
        }
    )

    InitEnvelope = nil
    IntColour = nil
end

--------------------------------------------------------------------------

local FIRE_MAX_LIFETIME = .75
local EMBER_MAX_LIFETIME = .8

local function emit_fire_fn(effect, sphere_emitter)
    local vx, vy, vz = .01 * UnitRand(), 0, .01 * UnitRand()
    local lifetime = FIRE_MAX_LIFETIME * (.9 + UnitRand() * .1)
    local px, py, pz = sphere_emitter()
    local uv_offset = math.random(0, 3) * .25

    effect:AddRotatingParticleUV(
        0,
        lifetime,           -- lifetime
        px, py + 1, pz,         -- position
        vx, vy, vz,         -- velocity
        math.random() * 360,-- angle
        UnitRand() * 50,    -- angle velocity
        0, 0                -- uv offset
    )
end

local function emit_ember_fn(effect, sphere_emitter)
    local vx, vy, vz = .015 * UnitRand(), -.01 + .015 * UnitRand(), .015 * UnitRand()
    local lifetime = EMBER_MAX_LIFETIME * (.8 + UnitRand() * .2)
    local px, py, pz = sphere_emitter()
    -- the flame particles upwards a bit so they can be used on a torch

    effect:AddParticleUV(
        1,
        lifetime,           -- lifetime
        px, py + 1, pz,         -- position
        vx, vy, vz,         -- velocity
        0, 0                -- uv offset
   )
end

local function InitParticles(inst)
    --Dedicated server does not need to spawn local particle fx
    if TheNet:IsDedicated() then
        return
    elseif InitEnvelope ~= nil then
        InitEnvelope()
    end
	
    local effect = inst.entity:AddVFXEffect()
    effect:InitEmitters(2)

    --FIRE
    effect:SetRenderResources(0, ANIM_SMOKE_TEXTURE, REVEAL_SHADER)
    effect:SetMaxNumParticles(0, 64)
    effect:SetRotationStatus(0, true)
    effect:SetMaxLifetime(0, FIRE_MAX_LIFETIME)
    effect:SetColourEnvelope(0, COLOUR_ENVELOPE_NAME)
    effect:SetScaleEnvelope(0, SCALE_ENVELOPE_NAME)
    effect:SetBlendMode(0, BLENDMODE.AlphaAdditive)
    effect:EnableBloomPass(0, true)
    effect:SetUVFrameSize(0, 1, 1)
    effect:SetSortOrder(0, 0)
    effect:SetFollowEmitter(0, true)
    effect:SetAngularDragCoefficient(0, 0.1)

    --EMBER
    effect:SetRenderResources(1, EMBER_TEXTURE, ADD_SHADER)
    effect:SetMaxNumParticles(1, 128)
    effect:SetMaxLifetime(1, EMBER_MAX_LIFETIME)
    effect:SetColourEnvelope(1, COLOUR_ENVELOPE_NAME_EMBER)
    effect:SetScaleEnvelope(1, SCALE_ENVELOPE_NAME_EMBER)
    effect:SetBlendMode(1, BLENDMODE.Additive)
    effect:EnableBloomPass(1, true)
    effect:SetUVFrameSize(1, 1, 1)
    effect:SetSortOrder(1, 0)
    effect:SetAcceleration(1, 0, -0.1, 0 )
    effect:SetDragCoefficient(1, .05)

    -----------------------------------------------------

    local tick_time = TheSim:GetTickTime()

    local fire_desired_pps = 6
    local fire_particles_per_tick = fire_desired_pps * tick_time
    local fire_num_particles_to_emit = 1

    local ember_time_to_emit = -2
    local ember_num_particles_to_emit = 5

    local sphere_emitter = CreateSphereEmitter(.95)
    local ember_sphere_emitter = CreateSphereEmitter(1)

    EmitterManager:AddEmitter(inst, nil, function()
        --FIRE
        while fire_num_particles_to_emit > 1 do
            emit_fire_fn(effect, sphere_emitter)
            fire_num_particles_to_emit = fire_num_particles_to_emit - 1
        end
        fire_num_particles_to_emit = fire_num_particles_to_emit + fire_particles_per_tick * math.random() * 3

        --EMBERS
        if ember_time_to_emit < 0 then
            for i = 1, ember_num_particles_to_emit do
                emit_ember_fn(effect, ember_sphere_emitter)
            end
            ember_num_particles_to_emit = 6 + 4 * math.random() --4 + 9 * math.random()
            ember_time_to_emit = (math.random() * .6)
        end
        ember_time_to_emit = ember_time_to_emit - tick_time
    end)
end
--------------------------------------------------------------------------

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst:AddTag("FX")

    InitParticles(inst)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.persists = false
	
    inst.fx_offset = -110

    return inst
end

return Prefab("um_shadowcloaked_light", fn, assets)