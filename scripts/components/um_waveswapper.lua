return Class(function(self, inst)

local unpack = unpack
local VecUtil_DistSq = VecUtil_DistSq

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local DEFAULT_WAVE

local WAVE_TILES = {}

--------------------------------------------------------------------------
--[[ Private Member variables ]]
--------------------------------------------------------------------------

local _world = TheWorld
local _map = _world.Map
local _waves = _world.WaveComponent
local prev_x, prev_z

local _current_wave

--------------------------------------------------------------------------
--[[ Public Member variables ]]
--------------------------------------------------------------------------

self.inst = inst

--------------------------------------------------------------------------
--[[ Private Member functions ]]
--------------------------------------------------------------------------

local function SetWaveData(wave_data)
    if wave_data ~= nil then
        _waves:SetWaveParams(unpack(wave_data.params))	    -- wave texture u repeat, forward distance between waves
        _waves:SetWaveSize(unpack(wave_data.size))			-- wave mesh width and height
        _waves:SetWaveMotion(unpack(wave_data.motion))
        _waves:SetWaveTexture(wave_data.texture)
        _waves:SetWaveEffect(wave_data.shader)
        inst.Map:AlwaysDrawWaves(true)
        _waves:Init(0, 0)
    else
        inst.Map:AlwaysDrawWaves(false)
    end
end

--------------------------------------------------------------------------
--[[ Public Member functions ]]
--------------------------------------------------------------------------

function self:SetDefaultWaveData(wave_data)
    DEFAULT_WAVE = wave_data
    SetWaveData(wave_data)
end

function self:SetTileWaveData(tile, wave_data)
    WAVE_TILES[tile] = wave_data
end

--------------------------------------------------------------------------
--[[ Update ]]
--------------------------------------------------------------------------

function self:OnUpdate(dt)
    local player = ThePlayer
    if player == nil then
        prev_x, prev_z = nil, nil
        return
    end

    local x, y, z = ThePlayer.Transform:GetWorldPosition()

    if prev_x == x and prev_z == z then
        return
    end
    prev_x, prev_z = x, z

    local selected_wave = DEFAULT_WAVE
    local selected_wave_dist = math.huge
    for tile, wave_data in pairs(WAVE_TILES) do
        local dist = _map:GetClosestTileDist(x, y, z, tile, wave_data.radius)
        if dist < selected_wave_dist then
            selected_wave = wave_data
            selected_wave_dist = dist
        end
    end

    if selected_wave ~= _current_wave then
        _current_wave = selected_wave

        SetWaveData(_current_wave)
    end
end

function self:GetDebugString()
    local function dumpinternal(t, outstr, indent)
        outstr = outstr or {}
        indent = indent or "\t"
        for key, value in pairs(t) do
            if type(value) == "table" then
                table.insert(outstr,indent.."<table name='"..tostring(key).."'>\n")
                dumpinternal(value, outstr, indent.."\t")
                table.insert(outstr, indent.."</table>\n")
            else
                table.insert(outstr, indent.."<"..type(value).." name='"..tostring(key).."' val='"..tostring(value).."'/>\n")
            end
        end
        return outstr
    end

    local str = "WaveSwapper\n"
    if _current_wave then
        local outstr = dumpinternal(_current_wave)
        for i, _str in pairs(outstr) do
            str = str .. _str
        end
    else
        str = " NO WAVE\n"
    end

    str = str .. "\n Distances:\n"

    local x, y, z = ThePlayer.Transform:GetWorldPosition()

    for tile, wave_data in pairs(WAVE_TILES) do
        local dist = _map:GetClosestTileDist(x, y, z, tile, wave_data.radius)
        str = str .. string.format("%s : %2.2f\n", INVERTED_WORLD_TILES[tile], dist)
    end

    return str
end

inst:StartUpdatingComponent(self)

end)
