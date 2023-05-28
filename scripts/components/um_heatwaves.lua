-- TODO: Rework this into a heat wave that goes across the map!!


--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------
local easing = require("easing")
local WorldTemperature = require("components/worldtemperature")
local UpvalueHacker = require("tools/upvaluehacker")

-- Keeping this here so it's centralized in one file, but maybe it should be in /postinit/components/worldtemperature instead - A
-- WorldTemperature hacking so heatwave's heat increase actually works. I'm suprised the old iteration even made it through.
local _CalculateTemperature  = UpvalueHacker.GetUpvalue(self.GetDebugString, "CalculateTemperature") -- This is an old copy of the function, right? This would cause a stackoverflow when it gets set again, right???

local function new_CalculateTemperature()
    print("Testing!")
    print("Heatwaves active: ", TheWorld:HasTag("heatwavestart"))
    print("Pre-Heatwave temp: ", _CalculateTemperature())
    print("Post: ", _CalculateTemperature() * 2)
    return _CalculateTemperature() * TheWorld:HasTag("heatwavestart") and 2 or 1 -- Is 2 too much?
end

UpvalueHacker.SetUpvalue(self.GetDebugString, new_CalculateTemperature, "CalculateTemperature")

--------------------------------------------------------------------------
--[[ UM_Heatwaves class definition ]]
--------------------------------------------------------------------------
return Class(function(self, inst)
    assert(TheWorld.ismastersim, "UM_Heatwaves should not exist on client!")

    local _worldsettingstimer = TheWorld.components.worldsettingstimer
    local UM_HEATWAVE_TIMERNAME = "um_heatwave_timer"
    local UM_STOPHEATWAVE_TIMERNAME = "um_stopheatwave_timer"

    --------------------------------------------------------------------------
    --[[ Public Member Variables ]]
    --------------------------------------------------------------------------

    self.inst = inst
    --self.old_temp = nil

    --------------------------------------------------------------------------
    --[[ Private Member Variables ]]
    --------------------------------------------------------------------------

    local _storming = false
    local _spawninterval = TUNING.TOTAL_DAY_TIME * 3
    local _despawninterval = TUNING.TOTAL_DAY_TIME / 2

    --------------------------------------------------------------------------
    --[[ Private member functions ]]
    --------------------------------------------------------------------------

    local function StopHeatwave()
        _storming = false

        TheWorld:RemoveTag("heatwavestart")

        if TheWorld.net ~= nil then
            TheWorld.net:RemoveTag("heatwavestartnet")
        end
        --TheWorld.state.temperature = self.old_temp


        if _worldsettingstimer:GetTimeLeft(UM_HEATWAVE_TIMERNAME) == nil then
            _worldsettingstimer:StartTimer(UM_HEATWAVE_TIMERNAME, _spawninterval + math.random(0, 120))
        end

        _worldsettingstimer:ResumeTimer(UM_HEATWAVE_TIMERNAME)
    end

    local function StartHeatWaving()
        _storming = true

        --for i, v in ipairs(AllPlayers) do
        --    --if v.components ~= nil and v.components.talker ~= nil and TheWorld.state.cycles >= TUNING.DSTU.WEATHERHAZARD_START_DATE_WINTER then
        --    v.components.talker:Say(GetString(v, "ANNOUNCE_SNOWSTORM"))
        --    --end
        --end

        TheWorld:PushEvent("ms_forceprecipitation", true)

        TheWorld:DoTaskInTime(5, function()
            TheWorld:AddTag("heatwavestart")
            if TheWorld.net ~= nil then
                TheWorld.net:AddTag("heatwavestartnet")
            end

            --self.old_temp = TheWorld.state.temperature
            --TheWorld.state.temperature = TheWorld.state.temperature * 2
            _worldsettingstimer:StartTimer(UM_STOPHEATWAVE_TIMERNAME, _despawninterval + math.random(80, 120))
        end)
    end

    local function StartHeatWaves()
        if _worldsettingstimer:GetTimeLeft(UM_HEATWAVE_TIMERNAME) == nil then
            _worldsettingstimer:StartTimer(UM_HEATWAVE_TIMERNAME, _spawninterval + math.random(0, 120))
        end

        _worldsettingstimer:ResumeTimer(UM_HEATWAVE_TIMERNAME)
    end

    local function StopHeatWaves()
        _worldsettingstimer:StopTimer(UM_HEATWAVE_TIMERNAME)
        _worldsettingstimer:StopTimer(UM_STOPHEATWAVE_TIMERNAME)
    end

    --------------------------------------------------------------------------
    --[[ Private event handlers ]]
    --------------------------------------------------------------------------

    local function OnSeasonChange(self)
        if TheWorld.state.season == "summer" then
            --if TheWorld.state.cycles >= TUNING.DSTU.WEATHERHAZARD_START_DATE_WINTER then
            if not _storming then
                StartHeatWaves()
            end
            --end
        else
            StopHeatwave()
            StopHeatWaves()
        end
    end

    function self:OnSave()
        local data =
        {
            storming = _storming,
            --old_temp = self.old_temp
        }

        return data
    end

    function self:OnLoad(data)
        _storming = data.storming or false
        --self.old_temp = data.old_temp

        if _storming then
            TheWorld:AddTag("heatwavestart")
            if TheWorld.net ~= nil then
                TheWorld.net:AddTag("heatwavestartnet")
            end

            if _worldsettingstimer:GetTimeLeft(UM_STOPHEATWAVE_TIMERNAME) == nil then
                _worldsettingstimer:StartTimer(UM_STOPHEATWAVE_TIMERNAME, _despawninterval + math.random(80, 120))
            end
        end
    end

    function self:OnPostInit()
        _worldsettingstimer:AddTimer(UM_HEATWAVE_TIMERNAME, _spawninterval + math.random(0, 120), true, StartHeatWaving)
        _worldsettingstimer:AddTimer(UM_STOPHEATWAVE_TIMERNAME, _despawninterval + math.random(80, 120), true,
            StopHeatwave)

        OnSeasonChange()
    end

    --[[function self:OnUpdate(dt)
        if TheWorld:HasTag("heatwavestart") then
            TheWorld:PushEvent("ms_forceprecipitation", false)
        end
    end]]

    --function self:LongUpdate(dt)
    --    self:OnUpdate(dt)
    --end

    self:WatchWorldState("season", OnSeasonChange)
    --self.inst:ListenForEvent("forcetornado", PickAttackTarget)
end)
