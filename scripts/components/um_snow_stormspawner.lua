--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------
local easing = require("easing")

--------------------------------------------------------------------------
--[[ UM_Snowstorms class definition ]]
--------------------------------------------------------------------------

local _storming = false
local _spawninterval = TUNING.TOTAL_DAY_TIME * 3
local _despawninterval = TUNING.TOTAL_DAY_TIME / 2
local _rimebasetime =  TUNING.TOTAL_DAY_TIME / 6 -- Enough to trigger at least twice during a snowstorm, more likely 3 times
local _worldsettingstimer = TheWorld.components.worldsettingstimer
local UM_SNOWSTORM_TIMERNAME = "um_snowstorm_timer"
local UM_STOPSNOWSTORM_TIMERNAME = "um_stopsnowstorm_timer"
local UM_RIMEWEED_TIMERNAME = "um_rimeweed_timer"

local _stormtask = nil



local function SpawnRimeweed(plant)
	local offset = FindWalkableOffset(Vector3(plant.Transform:GetWorldPosition()), math.random()*2*PI, 4, 12)
	if offset then
		local rimeweed = SpawnPrefab("rimeweed_main")
		local x,y,z = plant.Transform:GetWorldPosition()
		rimeweed.Transform:SetPosition(x+offset.x,0,z+offset.z)
	end
end

local function SpawnRimeweeds()
	--TheNet:Announce("trying to spawn rimeweeds")
	local harvestible_plants = {}
	local rimeweeds = 0
	for i,ent in pairs(Ents) do
		if ent.components.pickable and ent.components.pickable:CanBePicked() and ent:HasTag("plant") then --  and not FindEntity(ent,60^2,nil,{"rimeweed"}) then
			table.insert(harvestible_plants,ent)
		end
		if ent.prefab == "rimeweed_main" then
			rimeweeds = rimeweeds + 1
		end
	end
	
	if #harvestible_plants > 0 then
		--TheNet:Announce("Rimeweeds = ")
		--TheNet:Announce(rimeweeds)
		if rimeweeds < 3 then
			local rnd = math.random(1,#harvestible_plants)
			SpawnRimeweed(harvestible_plants[rnd])
			table.remove(harvestible_plants,rnd)
		end
		if rimeweeds < 8 then
			local rnd = math.random(1,#harvestible_plants)
			SpawnRimeweed(harvestible_plants[rnd])
			table.remove(harvestible_plants,rnd)
		end
		if rimeweeds < 20 then
			local rnd = math.random(1,#harvestible_plants)
			SpawnRimeweed(harvestible_plants[rnd])
			table.remove(harvestible_plants,rnd)
		end
		if rimeweeds < 30 then
			local rnd = math.random(1,#harvestible_plants)
			SpawnRimeweed(harvestible_plants[rnd])
			table.remove(harvestible_plants,rnd)
		end
	end
    if _worldsettingstimer:GetTimeLeft(UM_STOPSNOWSTORM_TIMERNAME) then
		--TheNet:Announce("new timer")
        _worldsettingstimer:StartTimer(UM_RIMEWEED_TIMERNAME, _rimebasetime + math.random(0, 30))
    end
end




local function StopSnowstorm()
    _storming = false

    if TheWorld.snowstorm_task ~= nil then
        TheWorld.snowstorm_task:Cancel()
        TheWorld.snowstorm_task = nil
    end

    TheWorld:RemoveTag("snowstormstart")

    if TheWorld.net ~= nil then
        TheWorld.net:RemoveTag("snowstormstartnet")
    end

    if _worldsettingstimer:GetTimeLeft(UM_SNOWSTORM_TIMERNAME) == nil then
        _worldsettingstimer:StartTimer(UM_SNOWSTORM_TIMERNAME, _spawninterval + math.random(0, 120))
    end
	_worldsettingstimer:StopTimer(UM_RIMEWEED_TIMERNAME)
    _worldsettingstimer:ResumeTimer(UM_SNOWSTORM_TIMERNAME)
end

local function StartStorming()
    _storming = true

    TheWorld:PushEvent("ms_forceprecipitation", true)

    for i, v in ipairs(AllPlayers) do
        if v.components.talker ~= nil then
            v:DoTaskInTime(math.random() * 4, function(inst)
                inst.components.talker:Say(GetString(v, "ANNOUNCE_SNOWSTORM"))
            end)
        end
    end

    TheWorld.snowstorm_task = TheWorld:DoTaskInTime(60, function()
        TheWorld:AddTag("snowstormstart")
        if TheWorld.net ~= nil then
            TheWorld.net:AddTag("snowstormstartnet")
        end
		
        _worldsettingstimer:StartTimer(UM_STOPSNOWSTORM_TIMERNAME, _despawninterval + math.random(80, 120))
		
		_worldsettingstimer:StartTimer(UM_RIMEWEED_TIMERNAME, _rimebasetime+math.random(0,30))
    end)
end

local function StartSnowstorms()
    if _worldsettingstimer:GetTimeLeft(UM_SNOWSTORM_TIMERNAME) == nil then
        if not _storming then
            _worldsettingstimer:StartTimer(UM_SNOWSTORM_TIMERNAME, _spawninterval + math.random(0, 120))
        end
    end

    _worldsettingstimer:ResumeTimer(UM_SNOWSTORM_TIMERNAME)
end

local function StopSnowstorms()
    _worldsettingstimer:StopTimer(UM_SNOWSTORM_TIMERNAME)
    _worldsettingstimer:StopTimer(UM_STOPSNOWSTORM_TIMERNAME)
	_worldsettingstimer:StopTimer(UM_RIMEWEED_TIMERNAME)
end

local function OnSeasonChange(self)
    if TheWorld.state.season == "winter" then
        if TheWorld.state.cycles >= TUNING.DSTU.WEATHERHAZARD_START_DATE_WINTER then
            --if not _storming then
            StartSnowstorms()
            --end
        end
    else
        StopSnowstorm()
        StopSnowstorms()
    end
end

local SnowstormInitiator = Class(function(self, inst)
    assert(TheWorld.ismastersim, "SnowstormInitiator should not exist on client!")

    self.inst = inst

    self:WatchWorldState("season", OnSeasonChange)
    self:WatchWorldState("cycles", function(inst)
        if not TheWorld.state.season == "winter" then
            OnSeasonChange()
        end
    end)

    self.inst:StartUpdatingComponent(self)
end)


function SnowstormInitiator:OnPostInit()

	-- Snowstorm
    if not _worldsettingstimer:ActiveTimerExists(UM_SNOWSTORM_TIMERNAME) then
        _worldsettingstimer:AddTimer(UM_SNOWSTORM_TIMERNAME, _spawninterval + math.random(0, 120), true, StartStorming)
    end
    if not _worldsettingstimer:ActiveTimerExists(UM_STOPSNOWSTORM_TIMERNAME) then
        _worldsettingstimer:AddTimer(UM_STOPSNOWSTORM_TIMERNAME, _despawninterval + math.random(80, 120), true,
            StopSnowstorm)
    end
	
	-- Rimeweed
	if not _worldsettingstimer:ActiveTimerExists(UM_RIMEWEED_TIMERNAME) then
        _worldsettingstimer:AddTimer(UM_RIMEWEED_TIMERNAME, _rimebasetime+math.random(0,30), true, SpawnRimeweeds)
    end
	
	
    OnSeasonChange()
end

function SnowstormInitiator:OnUpdate(dt)
    if not TheWorld.state.issnowing and TheWorld:HasTag("snowstormstart") then
        TheWorld:PushEvent("ms_forceprecipitation", true)
    end

    if not TheWorld.state.iswinter then
        StopSnowstorm()
        StopSnowstorms()
    end
end

function SnowstormInitiator:OnSave()
    local data = {
        storming = _storming
        -- old_temp = self.old_temp
    }

    return data
end

function SnowstormInitiator:ToggleSnowstorm(toggle)
    if toggle == nil or type(toggle) ~= "boolean" then
        if not _storming then
            StartStorming()
            return true
        else
            StopSnowstorm()
            return false
        end
    else
        if toggle then
            StartStorming()
            return true
        else
            StopSnowstorm()
            return false
        end
    end
end

function SnowstormInitiator:OnLoad(data)
    _storming = data.storming or false

    if _storming then
        StartStorming()
    end
end

function SnowstormInitiator:LongUpdate(dt) self:OnUpdate(dt) end

return SnowstormInitiator
