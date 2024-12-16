local UpvalueHacker = GLOBAL.require("tools/upvaluehacker")

AddPrefabPostInitAny(function(inst)
	if not GLOBAL.TheWorld.ismastersim then
		return inst
	end
	--if inst.components.health ~= nil and inst:HasTag("insect") and inst.components.health ~= nil and not inst.components.health:IsDead() and inst.components.health.maxhealth <= 100 then
	if inst:HasTag("butterfly") or inst:HasTag("bird") or (not GetModConfigData("wortox_beesouls") and inst:HasTag("bee")) then
		inst:AddTag("soulless")
	end
end)
	
--local function MakeSoulless(prefab)
    --AddPrefabPostInit(prefab, function(inst)
        --if inst ~= nil then
            --inst:AddTag("soulless")
        --end
    --end)
--end

--local REMOVE_SOULS =
--{
	--"birchnutdrake",
	--"stumpling",
	--"birchling",
--}

--if GLOBAL.TUNING.DSTU.WORTOX == "UMNERF" then
    --for k, v in pairs(REMOVE_SOULS) do
        --MakeSoulless(v)
    --end
--end

local function UncompromisingSoulHeal(inst)
    if GLOBAL.TUNING.BOOK_FIRE_RADIUS ~= nil then
        --wicker rework doesn't have a release ID :/ had to use this as a workaround
        local healtargets = {}
        local healtargetscount = 0
        local sanitytargets = {}
        local sanitytargetscount = 0
        local x, y, z = inst.Transform:GetWorldPosition()

        for i, v in ipairs(GLOBAL.AllPlayers) do
            if not (v.components.health:IsDead() or v:HasTag("playerghost")) and v.entity:IsVisible() and v:GetDistanceSqToPoint(x, y, z) < TUNING.WORTOX_SOULHEAL_RANGE * TUNING.WORTOX_SOULHEAL_RANGE then
                -- NOTES(JBK): If the target is hurt put them on the list to do heals.
                if v.components.health:IsHurt() then
                    table.insert(healtargets, v)
                    healtargetscount = healtargetscount + 1
                end
                -- NOTES(JBK): If the target is another "soulstealer" give some sanity even when they did not drop the soul but not in overload state.
                if v._souloverloadtask == nil and v.components.sanity and v:HasTag("soulstealer") then
                    table.insert(sanitytargets, v)
                    sanitytargetscount = sanitytargetscount + 1
                end
            end
        end

        if healtargetscount > 0 then
            local amt = GLOBAL.TUNING.DSTU.WORTOX == "SHOT" and
                math.max(TUNING.WORTOX_SOULHEAL_MINIMUM_HEAL,
                    TUNING.HEALING_MED - TUNING.WORTOX_SOULHEAL_LOSS_PER_PLAYER * (healtargetscount - 1)) or
                math.max(TUNING.WORTOX_SOULHEAL_MINIMUM_HEAL,
                    10 - TUNING.WORTOX_SOULHEAL_LOSS_PER_PLAYER * (healtargetscount - 1))

            for i = 1, healtargetscount do
                local v = healtargets[i]
                v.components.debuffable:AddDebuff("healthregenbuff_vetcurse_soul", "healthregenbuff_vetcurse",
                    { duration = (amt * 0.1) })
                if v.components.combat then -- Always show fx now that the heals do special targeting to show the player that it stops working when everyone is full.
                    local fx = GLOBAL.SpawnPrefab("wortox_soul_heal_fx")
                    fx.entity:AddFollower():FollowSymbol(v.GUID, v.components.combat.hiteffectsymbol, 0, -50, 0)
                    fx:Setup(v)
                end
            end
        end

        --if TUNING.DSTU.WORTOX ~= "APOLLO" then
            --if sanitytargetscount > 0 then
                --local amt = TUNING.SANITY_TINY * 0.5
                --for i = 1, sanitytargetscount do
                    --local v = sanitytargets[i]
                    --v.components.sanity:DoDelta(amt)
                --end
            --end
        --end
    else
        local targets = {}
        local x, y, z = inst.Transform:GetWorldPosition()
        for i, v in ipairs(GLOBAL.AllPlayers) do
            if not (v.components.health:IsDead() or v:HasTag("playerghost")) and v.entity:IsVisible() and v:GetDistanceSqToPoint(x, y, z) < TUNING.WORTOX_SOULHEAL_RANGE * TUNING.WORTOX_SOULHEAL_RANGE then
                table.insert(targets, v)
            end
        end
        if #targets > 0 then
            local amt = TUNING.HEALING_MED - math.min(8, #targets) + 1
            for i, v in ipairs(targets) do
                --always heal, but don't stack visual fx
                v.components.debuffable:AddDebuff("healthregenbuff_vetcurse_soul", "healthregenbuff_vetcurse",
                    { duration = (amt * 0.1) })
                if v.blocksoulhealfxtask == nil and v.components.combat then
                    v.blocksoulhealfxtask = v:DoTaskInTime(.5, EndBlockSoulHealFX)
                    local fx = GLOBAL.SpawnPrefab("wortox_soul_heal_fx")
                    fx.entity:AddFollower():FollowSymbol(v.GUID, v.components.combat.hiteffectsymbol, 0, -50, 0)
                    fx:Setup(v)
                end
            end
        end
    end
end

--beta uses
	local wortox_soul_common = require("prefabs/wortox_soul_common")
	wortox_soul_common.DoHeal = UncompromisingSoulHeal


local function AdjustLighting(inst, ambient)

	local relativetemp = inst.components.temperature:GetCurrent() - ambient
	local baseline = relativetemp - 10
	local brightline = 10 + 20
	inst._soullight.Light:SetIntensity( math.clamp(0.5 * baseline/brightline, 0, 0.5 ) )

	--inst._soullight.Light:SetIntensity(0)
end

local function CheckToggleWortoxFurnace(inst,data)
	local ambient_temp = GLOBAL.TheWorld.state.temperature
	local cur_temp = inst.components.temperature:GetCurrent()
	if cur_temp > 40 then
		inst.components.heater:SetThermics(true, false)
		AdjustLighting(inst, ambient_temp)
		inst._soullight.Light:Enable(true)
	else
		inst.components.heater:SetThermics(false, false)
		inst._soullight.Light:SetIntensity(0)
		inst._soullight.Light:Enable(false)
	end
end

local function GetThermicTemperatureFn(inst, observer)
    return TUNING.WX78_HEATERTEMPPERMODULE
end

local function FindAndMeltPiles(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local piles = TheSim:FindEntities(x,y,z,4,{"snowpile"},{"_health"})
	for i,pile in ipairs(piles) do
		if  pile.components.workable ~= nil and pile.components.workable:CanBeWorked() then
			GLOBAL.SpawnPrefab("splash_snow_fx").Transform:SetPosition(pile.Transform:GetWorldPosition())
		end
		pile:Remove()
	end
end

local function UndoAllSoulInheritances(inst)
	-- Tier 2 Dragonfly soul
	if inst.wortox_furnace then
		inst:RemoveEventCallback("temperaturedelta",CheckToggleWortoxFurnace)
		inst:RemoveComponent("heater")
		inst._soullight:Remove()
		inst._soullight = nil
		inst.wortox_furnace = nil
		inst.SnowPileTask:Cancel()
		inst.SnowPileTask = nil
	end
	
	
end

local function AddSoulInheritances(inst)
	-- Tier 2 Dragonfly soul
	if inst.soul_inheritance == "um_dragonfly_soul2" then
		inst._soullight = GLOBAL.SpawnPrefab("heatrocklight")
		inst:AddChild(inst._soullight)
		inst._soullight.Transform:SetPosition(0, 0, 0)
	    inst:AddComponent("heater")
		inst.components.heater:SetThermics(false, false)
		inst.components.heater.heatfn = GetThermicTemperatureFn
		inst.wortox_furnace = inst:ListenForEvent("temperaturedelta",CheckToggleWortoxFurnace)
		inst.SnowPileTask = inst:DoPeriodicTask(0.5,FindAndMeltPiles)
	end
	
	
end

local function EatBossSoul(inst,soul)
	-- Stat manipulation
    inst.components.hunger:DoDelta(TUNING.CALORIES_LARGE)
    inst.components.sanity:DoDelta(-TUNING.SANITY_MED)
    if inst._checksoulstask ~= nil then
        inst._checksoulstask:Cancel()
    end
	
	-- Soul Inheritance 
	if inst.soul_inheritance then
		if soul.prefab == inst.soul_inheritance then
			inst.soul_inheritance = soul.prefab.."2" 
			UndoAllSoulInheritances(inst)
			AddSoulInheritances(inst)
		elseif not soul.prefab == inst.soul_inheritance.."2" then
			inst.soul_inheritance = soul.prefab
			UndoAllSoulInheritances(inst)
			AddSoulInheritances(inst)
		end
	else
		inst.soul_inheritance = soul.prefab
	end
	
end

local function GeneralFadeOut(fx)
	fx.fadeout = fx.fadeout - 0.001
	fx.AnimState:SetMultColour(1,1,1,fx.fadeout)	
	if fx.fadeout ~= 0 then
		fx:Remove()
	else
		fx:DoTaskInTime(FRAMES,GeneralFadeOut)
	end
end


local function OnEatenSoulInheritance(inst,inh)
	-- Dragonfly
	if inh == "um_dragonfly_soul" or inh == "um_dragonfly_soul2" then
		local fx = GLOBAL.SpawnPrefab("smoke_plant")
		inst:AddChild(fx)
		fx.Transform:SetPosition(0, 0, 0)
		fx.fadeout = 1
		fx:DoTaskInTime(1,GeneralFadeOut)
		inst.components.temperature:SetTemperature(inst.components.temperature:GetCurrent()+15) -- bypass shenanagins from DoDelta
	end
end

AddPrefabPostInit("wortox", function(inst)
	if not GLOBAL.TheWorld.ismastersim then
		return
	end
	
	if inst.components.foodaffinity ~= nil then
		inst.components.foodaffinity:AddPrefabAffinity("devilsfruitcake", 1.24)
	end
	
	if inst.components.souleater ~= nil then
		local oneatsoulfn_ = inst.components.souleater.oneatsoulfn

		inst.components.souleater.oneatsoulfn = function(inst, soul)
			if soul:HasTag("vetsoul") then
				EatBossSoul(inst,soul)
			else
				if inst.soul_inheritance then
					OnEatenSoulInheritance(inst,inst.soul_inheritance)
				end
				oneatsoulfn_(inst, soul)
				inst.components.sanity:DoDelta(-TUNING.SANITY_TINY)
			end
		end
	end
	
	-- Save/Load Soul Inheritance
	local _OnSave = inst.OnSave
	local _OnLoad = inst.OnLoad
	
    inst.OnSave = function(inst,data)
		if inst.soul_inheritance then
			data.soul_inheritance = inst.soul_inheritance
		end
		_OnSave(inst,data)
	end
	
    inst.OnLoad = function(inst,data)
		if data.soul_inheritance then
			inst.soul_inheritance = data.soul_inheritance
			inst:DoTaskInTime(0,AddSoulInheritances)
		end		
		_OnLoad(inst,data)
	end
	
	-- local function OnRemove(inst)
		-- if inst._soullight then
			-- inst._soullight:Remove()
		-- end
	-- end
	-- inst.OnRemoveEntity = OnRemove
	
end)

