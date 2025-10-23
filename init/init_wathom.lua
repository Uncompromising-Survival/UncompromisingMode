AddMinimapAtlas("images/map_icons/wathom.xml")

require "class"
local require = GLOBAL.require
local STRINGS = GLOBAL.STRINGS
local FRAMES = GLOBAL.FRAMES
local TimeEvent = GLOBAL.TimeEvent
local EventHandler = GLOBAL.EventHandler
local EQUIPSLOTS = GLOBAL.EQUIPSLOTS
local SpawnPrefab = GLOBAL.SpawnPrefab
local ActionHandler = GLOBAL.ActionHandler


-- It's 1 AM and I don't want to pick apart which local is needed so I'll just grab all of it.

--------------------------------------------------------------------------
-- 90% of code here is taken from Warfarin, made by the wonderful Tiddler.

-- Setting up new actions

local function HasSkill(inst,name)
	return inst.components.skilltreeupdater and inst.components.skilltreeupdater:IsActivated(name)
end

local function SpreadGoo(inst,number)
	local circle = number*2+3
	local x,y,z = inst.Transform:GetWorldPosition()
	local radius = number*2
	for i = 1,circle do
		local x1 = x+radius*math.cos(2*3.14*i/circle)
		local z1 = z+radius*math.sin(2*3.14*i/circle)
		local puddle = 	GLOBAL.SpawnPrefab("wathom_puddle")
		puddle.Transform:SetPosition(x1,y,z1)
		puddle.wathom = inst
	end
	
	if number < 2 then
		inst:DoTaskInTime(.2,function(inst) SpreadGoo(inst,number+1) end)
	end
end

local function SurvivorBarkEffect(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local players = TheSim:FindEntities(x,y,z,8,{"player"})
	for i,player in ipairs(players) do
		if player.components.wereness then
			player.components.wereness:DoDelta(25)
		end
		if player.components.mightiness then
			player.components.mightiness:DoDelta(25)
		end
		if player.components.singinginspiration then
			player.components.singinginspiration:DoDelta(25)
		end
	end
end

local function HoldingCane(inst)
	return inst:HasTag("wathom") and inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) and 
	(inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS).prefab == "cane" or inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS).prefab == "orangestaff" or
	inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS).prefab == "walking_stick") and true
end

local function OnCooldownBark(inst)
	inst._barkcdtask = nil
end

local function OnCooldownCantBark(inst)
	inst._cantbarkcdtask = nil
end

local function Effect(inst) -- I dumbed the shit out of this.
	if GLOBAL.TheWorld.state.wetness > 25 then
		local puff = SpawnPrefab("weregoose_splash_med2")
		puff.Transform:SetPosition(inst.Transform:GetWorldPosition())
	end
end

local SGWilson = require "stategraphs/SGwilson"
local SGWilsonClient = require "stategraphs/SGwilson_client"
local Attack_Old
local ClientAttack_Old

for k1, v1 in pairs(SGWilson.actionhandlers) do
	if SGWilson.actionhandlers[k1]["action"]["id"] == "ATTACK" then
		Attack_Old = SGWilson.actionhandlers[k1]["deststate"]
	end
end

local special_staff = {
	"staff_lunarplant",
	"icestaff",
	"firestaff"
}

local function Attack_New(inst, action, ...)
	inst.sg.mem.localchainattack = not action.forced or nil
	local weapon = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil
	if weapon and not ((weapon:HasTag("blowdart") or weapon:HasTag("thrown") or (weapon:HasTag("rangedweapon") and not table.contains(special_staff, weapon.prefab)))) and inst:HasTag("wathom") and
		not inst.sg:HasStateTag("attack") and (inst.components.rider ~= nil and not inst.components.rider:IsRiding()) then
		return ("wathomleap")
	elseif not weapon and HasSkill(inst,"bite_1") then
		return ("wathombite")
	else
		return Attack_Old(inst, action, ...)
	end
end

--Client

for k1, v1 in pairs(SGWilsonClient.actionhandlers) do
	if SGWilsonClient.actionhandlers[k1]["action"]["id"] == "ATTACK" then
		ClientAttack_Old = SGWilsonClient.actionhandlers[k1]["deststate"]
	end
end

local function AttackClient_New(inst, action, ...)
	local weapon = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil
	if weapon and not ((weapon:HasTag("blowdart") or weapon:HasTag("thrown"))) and inst:HasTag("wathom") and
		not inst.sg:HasStateTag("attack") and (inst.components.rider ~= nil and not inst.components.rider:IsRiding() or inst.replica.rider ~= nil and not inst.replica.rider:IsRiding()) then
		return ("wathomleap_pre")
	elseif not weapon and HasSkill(inst,"bite_1") then
		return ("wathombite")
	else	
		return ClientAttack_Old(inst, action, ...)
	end
end

--Pack it up

AddStategraphActionHandler("wilson", ActionHandler(GLOBAL.ACTIONS.ATTACK, Attack_New))
GLOBAL.package.loaded["stategraphs/SGwilson"] = nil

AddStategraphActionHandler("wilson_client", ActionHandler(GLOBAL.ACTIONS.ATTACK, AttackClient_New))
GLOBAL.package.loaded["stategraphs/SGwilson_client"] = nil

AddStategraphActionHandler("wilson", ActionHandler(GLOBAL.ACTIONS.ATTACK, Attack_New))
------------------------
-- the MEAT

local function ConfigureRunState(inst)
	if inst.components.rider ~= nil and inst.components.rider:IsRiding() then
		inst.sg.statemem.riding = true
		inst.sg.statemem.groggy = inst:HasTag("groggy")
		inst.sg:AddStateTag("nodangle")

		local mount = inst.components.rider:GetMount()
		inst.sg.statemem.ridingwoby = mount and mount:HasTag("woby")
	elseif inst.components.inventory ~= nil and inst.components.inventory:IsHeavyLifting() then
		inst.sg.statemem.heavy = true
		inst.sg.statemem.heavy_fast = inst.components.mightiness ~= nil and inst.components.mightiness:IsMighty()
	elseif inst:HasTag("wereplayer") then
		inst.sg.statemem.iswere = true
		if inst:HasTag("weremoose") then
			if inst:HasTag("groggy") then
				inst.sg.statemem.moosegroggy = true
			else
				inst.sg.statemem.moose = true
			end
		elseif inst:HasTag("weregoose") then
			if inst:HasTag("groggy") then
				inst.sg.statemem.goosegroggy = true
			else
				inst.sg.statemem.goose = true
			end
		elseif inst:HasTag("groggy") then
			inst.sg.statemem.groggy = true
		else
			inst.sg.statemem.normal = true
		end
	elseif inst:GetStormLevel() >= TUNING.SANDSTORM_FULL_LEVEL and not inst.components.playervision:HasGoggleVision() then
		inst.sg.statemem.sandstorm = true
	elseif inst:HasTag("groggy") then
		inst.sg.statemem.groggy = true
	elseif inst:IsCarefulWalking() then
		inst.sg.statemem.careful = true
	else
		inst.sg.statemem.normal = true
		inst.sg.statemem.normalwonkey = inst:HasTag("wonkey") or nil
	end
end

local skilltree_defs = require("prefabs/skilltree_defs")
local BuildSkillsData = require("prefabs/skilltree_wathom")
if BuildSkillsData then
	local data = BuildSkillsData(skilltree_defs.FN)

	skilltree_defs.CreateSkillTreeFor("wathom", data.SKILLS)
	skilltree_defs.SKILLTREE_ORDERS["wathom"] = data.ORDERS

	--RegisterSkilltreeBGForCharacter(GLOBAL.resolvefilepath("images/wathom_background.xml"), "wathom")
	
	for k, v in pairs(data.SKILLS) do
		if v.icon then
			table.insert(Assets, Asset("IMAGE", "images/"..v.icon..".tex"))
			table.insert(Assets, Asset("ATLAS", "images/"..v.icon..".xml"))
			RegisterSkilltreeIconsAtlas("images/".. v.icon ..".xml", v.icon .. ".tex")
		end
	end
end
	
local function GetAdrenalShove(inst)
	if inst.components.adrenaline then
		return inst:HasTag("amped") and 1 or .5 + inst.components.adrenaline:GetPercent() * .5
	else
		return .5
	end
end
	
-- This is Scrimble's Shove Code, it's used for both Charles T Horse and Wixie, be appreciative, swine.
local SLEEPREPEL_MUST_TAGS = { "_combat" }
local SLEEPREPEL_CANT_TAGS = { "player", "companion", "abigail", "shadowminion", "playerghost", "INLIMBO", "wixieshoved", "invisible",
	"hiding", "notarget", "noattack", "flight", "wall" }
local NO_SHOVE_TAGS = {"stageusher", "toadstool"}
local NO_SHOVE_ATTACK_LEADER_TAGS = {"player", "irreplaceable"}
local function Check_Bowling(inst, target)
	if inst ~= nil then
		local x, y, z = inst.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x, y, z, 2, SLEEPREPEL_MUST_TAGS, SLEEPREPEL_CANT_TAGS)
		for i, v in ipairs(ents) do
			if inst.components.combat:CanTarget(v) and not (v.components.follower and v.components.follower:GetLeader()
				and v.components.follower:GetLeader():HasAnyTag(NO_SHOVE_ATTACK_LEADER_TAGS)) then --(not target) or (target and v ~= target)
				v:AddTag("wixieshoved")
				SpawnPrefab("round_puff_fx_sm").Transform:SetPosition(v.Transform:GetWorldPosition())

				if not (v.components.health and v.components.health:IsDead()) then
					local damage = HasSkill(inst, "rampage_2") and inst.components.adrenaline and (inst:HasTag("amped") and 25 or 12.5 + 2 * 12.5 * inst.components.adrenaline:GetPercent()) or 0  
					v.components.combat:GetAttacked(inst, damage)
				end

				if v.components.locomotor ~= nil and not v:HasAnyTag(NO_SHOVE_TAGS) then
					for i = 1, 50 do
						v:DoTaskInTime((i - 1) / 50, function(v)
							if v ~= nil and inst ~= nil then
								local x, y, z = inst.Transform:GetWorldPosition()
								local tx, ty, tz = v.Transform:GetWorldPosition()

								local rad = math.rad(inst:GetAngleToPoint(tx, ty, tz))
								local velx = math.cos(rad)  --* 4.5
								local velz = -math.sin(rad) --* 4.5

								local giantreduction = v:HasTag("epic") and 1.5 or v:HasTag("smallcreature") and .8 or 1
								local cursemultiplier = v:HasDebuff("wixiecurse_debuff") and 1.75 or 1.25
								local shovevalue = GetAdrenalShove(inst)

								local dx, dy, dz =
									tx + (((shovevalue / (i + 3)) * velx) / giantreduction) * cursemultiplier, ty,
									tz + (((shovevalue / (i + 3)) * velz) / giantreduction) * cursemultiplier
								local ground = GLOBAL.TheWorld.Map:IsPassableAtPoint(dx, dy, dz)
								local boat = GLOBAL.TheWorld.Map:GetPlatformAtPoint(dx, dz)
								local ocean_collision = GLOBAL.TheWorld.Map:IsOceanAtPoint(dx, dy, dz)

								if not (v.sg and v.sg:HasAnyStateTag("swimming", "invisible")) then
									if v ~= nil and dx ~= nil and (ground or boat or ocean_collision and v.components.locomotor:CanPathfindOnWater() or v.components.tiletracker ~= nil and not v:HasTag("whale")) then
										--[[if ocean_collision and v.components.amphibiouscreature and not v.components.amphibiouscreature.in_water then
												v.components.amphibiouscreature:OnEnterOcean()
											end]]
										v.Transform:SetPosition(dx, dy, dz)
									end
								end

								if i >= 50 then
									v:RemoveTag("wixieshoved")
								end
							end
						end)
					end
				end
			end
		end
	end
end	

------------------------If Wathom is Terror, he needs to not gain lunacy during the day-----------------------------------------
AddComponentPostInit("sanity", function(self)
    local _OldRecalc = self.Recalc
    function self:Recalc(dt)
		if HasSkill(self.inst,"wathom_allegiance_shadow") and TheWorld.state.isday then
			local rate = TUNING.DAPPERNESS_LARGE * 10 / 6.6		
			self:DoDelta(rate * dt, true)
		end
		return _OldRecalc(self,dt)
    end
end)


local function AddEnemyDebuffFx(fx, target)
	target:DoTaskInTime(math.random() * .25, function()
		local x, y, z = target.Transform:GetWorldPosition()
		local fx = SpawnPrefab(fx)
		if fx then
			fx.Transform:SetPosition(x, y, z)
		end
		return fx
	end)
end


AddStategraphPostInit("wilsonghost", function(inst)
	local _RunOnEnter = inst.states["run"].onenter
	local function NewOnEnter(inst, ...)
		_RunOnEnter(inst, ...)
		if HasSkill(inst,"shadow_wathom_2") then
			inst.AnimState:PlayAnimation("umrun",true)
		end
	end

	inst.states["run"].onenter = NewOnEnter
	
	local _haunt = inst.states["haunt_pre"].onenter
	local function NewOnEnter(inst, ...)
		_haunt(inst, ...)
		if HasSkill(inst,"shadow_wathom_2") then
			if HasSkill(inst,"wathom_friends_2") then
				SurvivorBarkEffect(inst)
			end
			inst.AnimState:PlayAnimation("emote_angry", false)
			inst.SoundEmitter:PlaySound("wathomcustomvoice/wathomvoiceevent/shadowbark")
			local fx = SpawnPrefab("statue_transition_2")
			if fx ~= nil then
				fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
				fx.Transform:SetScale(1.2, 1.2, 1.2)
			end
			fx = SpawnPrefab("statue_transition")
			if fx ~= nil then
				fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
				fx.Transform:SetScale(1.2, 1.2, 1.2)
			end
			
			if HasSkill(inst,"bark_mastery") then
				SpreadGoo(inst,1)
			end
			local x,y,z = inst.Transform:GetWorldPosition()
			local ents = GLOBAL.TheSim:FindEntities(x, y, z, 8) --added playertags because of the taunt.
			for i, v in ipairs(ents) do
				if v.components.hauntable ~= nil and v.prefab ~= "wathom_corpse" and v.prefab ~= "lifeamulet" and v.prefab ~= "ancient_amulet_red" and v.prefab ~= "resurrectionstone" then
					AddEnemyDebuffFx("battlesong_instant_panic_fx", v)
					v.components.hauntable:DoHaunt(inst)
					if HasSkill(inst,"wathom_friends_1") then
						v:AddTag("wathom_really_spooking_me")
						v:DoTaskInTime(8,function(v) v:RemoveTag("wathom_really_spooking_me") end)
					end
				end
			end
		end
	end

	inst.states["haunt_pre"].onenter = NewOnEnter
	
	local _haunt = inst.states["haunt"].onenter
	local function NewOnEnter(inst, ...)
		_haunt(inst, ...)
		if HasSkill(inst,"shadow_wathom_2") then
			inst.AnimState:PlayAnimation("idle", false)
		end
	end

	inst.states["haunt"].onenter = NewOnEnter

	local runstateonexit = inst.states["run"].onexit
	inst.states["run"].onexit = function(inst, ...)
		if runstateonexit then runstateonexit(inst, ...) end
		if HasSkill(inst,"shadow_wathom_2") then
			inst.AnimState:PlayAnimation("idle",true)
		end 
	end
end)
	
local function MarkDontEatFoods(inst,target)
	local x,y,z = target.Transform:GetWorldPosition()
	local loot = TheSim:FindEntities(x,y,z,4,{"_inventoryitem"})
	for i,v in ipairs(loot) do
		if v:HasAnyTag("meat", "smallmeat", "rawmeat") and v.components.edible and not v:HasTag("badfood") then
			v.wathom_dont_eat = true
			v:DoTaskInTime(3,function(v) v.wathom_dont_eat = nil end)
		end
	end
end
	
	
local bite2MustTags = { "_inventoryitem" }
local bite2MustOneOfTags = { "meat", "smallmeat", "rawmeat" }

local function CheckIfDead(inst, target)
	if (target and target.components.health and target.components.health:IsDead() and target:IsValid()) and not (target:HasTag("shadow") or target:HasTag("chess")) then
		if HasSkill(inst,"bite_mastery") and inst.components.health then
			inst.components.health:DeltaPenalty(-.01)
		end
		inst.components.health:DoDelta(4)
		if HasSkill(inst,"bite_2") then
			local x,y,z = target.Transform:GetWorldPosition()
			local loot = TheSim:FindEntities(x, y, z, 4, bite2MustTags, nil, bite2MustOneOfTags)
			for i,v in ipairs(loot) do
				if v.components.edible and not v.wathom_dont_eat and v.components.edible.healthvalue >= 0 and not v.components.inventoryitem:IsHeld() then
					local health_restore = v.components.edible.healthvalue*1.1
					local hunger_restore = v.components.edible.hungervalue*1.1
					local sanity_restore = v.components.edible.sanityvalue*1.1
					if (inst.components.hunger.current + hunger_restore) < inst.components.hunger.max then
						inst.components.hunger:DoDelta(hunger_restore)
						inst.components.health:DoDelta(health_restore)
						if inst:HasTag("skill_wathom_allegiance_shadow") or sanity_restore > 0 then
							inst.components.sanity:DoDelta(sanity_restore)
						end
						SpawnPrefab("collapse_small").Transform:SetPosition(v.Transform:GetWorldPosition())
						v:Remove()
					end
				end
			end
		end
	end
end

AddStategraphPostInit("wilson", function(inst)
	local _RunOnEnter = inst.states["run_start"].onenter
	local function NewOnEnter(inst, ...)
		if (inst:HasTag("wathom") and inst:HasTag("wathomrun") and inst.components.rider ~= nil and not inst.components.rider:IsRiding()) or (inst:HasTag("wathom") and inst:HasTag("wathomrun") and inst.components.rider == nil) then
			inst.sg.mem.footsteps = 0
			inst.sg:GoToState("run_wathom")
			return
		else
			_RunOnEnter(inst, ...)
		end
	end

	inst.states["run_start"].onenter = NewOnEnter

	local actionhandlers =
	{
		ActionHandler(GLOBAL.ACTIONS.WATHOMBARK,
			function(inst, action)
				if inst._cantbarkcdtask == nil and
					(
						inst.components.adrenaline ~= nil and inst.components.adrenaline:GetPercent() < .5 or
						inst.replica ~= nil and inst.replica.currentadrenaline < 5) and not inst:HasTag("amped") then
					inst._cantbarkcdtask = inst:DoTaskInTime(5, OnCooldownCantBark)
					return "cantbark"
				elseif inst._cantbarkcdtask == nil and inst._barkcdtask ~= nil then
					inst._cantbarkcdtask = inst:DoTaskInTime(5, OnCooldownCantBark)
					return "cantbark"
				elseif inst._barkcdtask == nil and inst:HasTag("amped") then
					inst._barkcdtask = inst:DoTaskInTime(12, OnCooldownBark)
					return "wathombark"
				elseif inst._barkcdtask == nil and
					(
						inst.components.adrenaline ~= nil and inst.components.adrenaline:GetPercent() >= .5 or
						inst.replica ~= nil and inst.replica.currentadrenaline >= 50) then
					inst._barkcdtask = inst:DoTaskInTime(12, OnCooldownBark)
					return "wathombark"
				else
					return --	"idle"
				end
			end),
	}



	local states = {
		GLOBAL.State {
			name = "run_wathom",
			tags = { "moving", "running", "canrotate", "autopredict" },

			onenter = function(inst)
				ConfigureRunState(inst)
				if ((inst.components.adrenaline and inst.components.adrenaline:GetPercent() > .75) or (HasSkill(inst,"digitigrade_1") and inst.components.adrenaline and inst.components.adrenaline:GetPercent() > .48)) or inst:HasTag("amped") then
					inst.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED + TUNING.WONKEY_SPEED_BONUS
				end

				--inst.components.hunger:SetRate(TUNING.WILSON_HUNGER_RATE * TUNING.WONKEY_RUN_HUNGER_RATE_MULT)
				inst.components.locomotor:RunForward()
				
				if not inst.AnimState:IsCurrentAnimation("umrun") then
					inst.AnimState:PlayAnimation("umrun", true)
				end

				--V2C: adding half a frame time so it rounds up
				inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength() + .5 * FRAMES)
			end,

			timeline =
			{
				TimeEvent(6 * FRAMES, function(inst) GLOBAL.PlayFootstep(inst, .5) end),
				TimeEvent(7 * FRAMES, function(inst) GLOBAL.PlayFootstep(inst, .5) end),
			},

			onupdate = function(inst)
				if inst.components.rider ~= nil and inst.components.rider:IsRiding() and not inst:HasTag("wathomrun") or not inst:HasTag("wathomrun") then
					inst.sg:GoToState("run")
					return
				end
				inst.components.locomotor:RunForward()
				
			end,

			events =
			{
				--[[EventHandler("gogglevision", function(inst, data)
                if not data.enabled and inst:GetStormLevel() >= TUNING.SANDSTORM_FULL_LEVEL then
                    inst.sg:GoToState("run")
                end
            end),
            EventHandler("sandstormlevel", function(inst, data)
                if data.level >= TUNING.SANDSTORM_FULL_LEVEL and not inst.components.playervision:HasGoggleVision() then
                    inst.sg:GoToState("run")
                end
            end),
            EventHandler("carefulwalking", function(inst, data)
                if data.careful then
                    inst.sg:GoToState("run")
                end
            end),]]
			},

			ontimeout = function(inst)
				inst.sg.statemem.funkyrunning = true
				inst.sg:GoToState("run_wathom")
			end,

			onexit = function(inst)
				if not inst.sg.statemem.funkyrunning then
					inst.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED
					inst.Transform:ClearPredictedFacingModel()
				end
				if HoldingCane(inst) and HasSkill(inst,"digitigrade_2") and inst.components.adrenaline and inst.components.adrenaline:GetPercent() < .51 then
					inst.components.adrenaline:DoDelta(1)
				end
			end,
		},

		GLOBAL.State {
			name = "wathombark",
			tags = { "attack", "backstab", "busy", "notalking", "abouttoattack", "pausepredict", "nointerrupt" },

			onenter = function(inst, data)
				local buffaction = inst:GetBufferedAction()
				local target = buffaction ~= nil and buffaction.target or nil
				inst.AnimState:PlayAnimation("emote_angry", false)
				inst.components.locomotor:Stop()
				if inst.components.playercontroller ~= nil then
					inst.components.playercontroller:RemotePausePrediction()
				end
			end,

			onexit = function(inst)
				if not inst.components.playercontroller ~= nil then
					inst.components.playercontroller:Enable(true)
				end
			end,

			timeline =
			{
				TimeEvent(0 * FRAMES, function(inst)
					inst.SoundEmitter:PlaySound("wathomcustomvoice/wathomvoiceevent/bark") --place your funky sounds here
					local fx = SpawnPrefab("statue_transition_2")
					if fx ~= nil then
						fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
						fx.Transform:SetScale(1.2, 1.2, 1.2)
					end
					fx = SpawnPrefab("statue_transition")
					if fx ~= nil then
						fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
						fx.Transform:SetScale(1.2, 1.2, 1.2)
					end
				end),


				TimeEvent(10 * FRAMES, function(inst)
					inst.components.locomotor:Stop()
					inst:PerformBufferedAction() --Dis is the important part, canis -Axe
					inst.sg:RemoveStateTag("busy")
					inst.sg:RemoveStateTag("nointerrupt")
				end),
			},

			events =
			{
				EventHandler("animover", function(inst)
					inst.sg:GoToState("idle")
				end),
			},
		},

		GLOBAL.State {
			name = "wathombark_shadow",
			tags = { "attack", "backstab", "busy", "notalking", "abouttoattack", "pausepredict", "nointerrupt" },

			onenter = function(inst, data)
				local buffaction = inst:GetBufferedAction()
				local target = buffaction ~= nil and buffaction.target or nil
				inst.AnimState:PlayAnimation("emote_angry", false)
				inst.components.locomotor:Stop()
				if inst.components.playercontroller ~= nil then
					inst.components.playercontroller:RemotePausePrediction()
				end
			end,

			onexit = function(inst)
				if not inst.components.playercontroller ~= nil then
					inst.components.playercontroller:Enable(true)
				end
			end,

			timeline =
			{
				TimeEvent(0 * FRAMES, function(inst)
					inst.SoundEmitter:PlaySound("wathomcustomvoice/wathomvoiceevent/shadowbark") --place your funky sounds here
					local fx = SpawnPrefab("statue_transition_2")
					if fx ~= nil then
						fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
						fx.Transform:SetScale(1.2, 1.2, 1.2)
					end
					fx = SpawnPrefab("statue_transition")
					if fx ~= nil then
						fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
						fx.Transform:SetScale(1.2, 1.2, 1.2)
					end
				end),


				TimeEvent(10 * FRAMES, function(inst)
					inst.components.locomotor:Stop()
					inst:PerformBufferedAction() --Dis is the important part, canis -Axe
					inst.sg:RemoveStateTag("busy")
					inst.sg:RemoveStateTag("nointerrupt")
				end),
			},

			events =
			{
				EventHandler("animover", function(inst)
					inst.sg:GoToState("idle")
				end),
			},
		},

		GLOBAL.State {
			name = "cantbark",
			tags = { busy },

			onenter = function(inst)
				inst:ClearBufferedAction()

				--				inst.components.talker:Say("Can't... Breathe...", nil, true) -- I can't think of something cool for Wathom to say, so away this goes.

				inst.AnimState:PlayAnimation("sing_fail", false)

				inst.SoundEmitter:PlaySound("wathomcustomvoice/wathomvoiceevent/leap") -- maybe make something new later?
			end,
			timeline =
			{
				TimeEvent(12 * FRAMES, function(inst)
					inst.SoundEmitter:PlaySound("wathomcustomvoice/wathomvoiceevent/leap") --place your funky sounds here
				end),                                                       --bark twice.
			},
			events =
			{
				EventHandler("animover", function(inst)
					if inst.AnimState:AnimDone() then
						inst.sg:GoToState("idle")
						inst.sg:RemoveStateTag("busy")
						inst:ClearBufferedAction()
					end
				end),
			}
		},

		GLOBAL.State {
			name = "wathomleap",
			tags = { "attack", "backstab", "busy", "notalking", "abouttoattack", "pausepredict", "nointerrupt" },

			onenter = function(inst, data)
				Effect(inst)
				local buffaction = inst:GetBufferedAction()
				local target = buffaction ~= nil and buffaction.target or nil
				
				if target ~= nil and (target:HasTag("bird_mutant") or not target:HasTag("bird")) then
					inst.components.combat:SetTarget(target)
				else
					inst.components.combat:SetTarget(nil)
				end
				
				inst.components.combat:StartAttack()
				--            inst.components.health:SetInvincible(true) -- I wonder why Tiddler did this?
				--inst.AnimState:PlayAnimation("atk_leap_pre", false)
				inst.AnimState:PlayAnimation("atk_leap", false)
				inst.Transform:SetEightFaced()
				inst.AnimState:ClearOverrideBuild("player_lunge")
				inst.AnimState:ClearOverrideBuild("player_attack_leap")
				inst.components.locomotor:Stop()
				inst.components.locomotor:EnableGroundSpeedMultiplier(false)
				if inst.components.playercontroller ~= nil then
					inst.components.playercontroller:RemotePausePrediction()
				end
			end,

			onexit = function(inst)
				--            inst.components.health:SetInvincible(false)
				inst.components.combat:SetTarget(nil)
				if inst.sg:HasStateTag("abouttoattack") then
					inst.components.combat:CancelAttack()
				end
				inst.Transform:SetFourFaced()
				inst.components.locomotor:Stop()
				inst.Physics:ClearMotorVelOverride()
				inst:DoTaskInTime(0, function(inst)
					if inst.components.playercontroller then
						inst.components.playercontroller:Enable(true)
					end
				end)
				inst.components.locomotor:EnableGroundSpeedMultiplier(true)
				inst.AnimState:AddOverrideBuild("player_lunge")
				inst.AnimState:AddOverrideBuild("player_attack_leap")
			end,

			timeline =
			{
				TimeEvent(0 * FRAMES, function(inst)
					inst.SoundEmitter:PlaySound("wathomcustomvoice/wathomvoiceevent/leap")
					inst.Physics:ClearCollisionMask() -- all of this physics stuff will give the impression that Wathom is jumping over things. It also allows him to slide past targets instead of ending his leap in front.
					-- 					inst.components.hunger:DoDelta(-1, 2)
					inst.Physics:CollidesWith(GLOBAL.COLLISION.WORLD)
					local buffaction = inst:GetBufferedAction()
					local target = buffaction ~= nil and buffaction.target or nil
					if target ~= nil then
						inst.sg.statemem.startingpos = inst:GetPosition()
						inst.sg.statemem.targetpos = target:GetPosition()
						if target ~= nil then
							if inst.sg.statemem.startingpos.x ~= inst.sg.statemem.targetpos.x or
								inst.sg.statemem.startingpos.z ~= inst.sg.statemem.targetpos.z then
								inst.leapvelocity = math.sqrt(GLOBAL.distsq(inst.sg.statemem.startingpos.x, inst.sg.statemem.startingpos.z,
									inst.sg.statemem.targetpos.x, inst.sg.statemem.targetpos.z)) / (12 * FRAMES)
							end
							if HasSkill(inst,"rampage_1") then
								target:AddTag("wixieshoved")
								target:DoTaskInTime(1,function(target) target:RemoveTag("wixieshoved") end)
							end
						end
					end
					inst.SoundEmitter:PlaySound("turnoftides/common/together/boat/jump")
				end),


				TimeEvent(12 * FRAMES, function(inst)
					inst.sg:RemoveStateTag("abouttoattack")
					inst.components.locomotor:Stop()
					inst.Physics:ClearMotorVelOverride()
					inst:PerformBufferedAction()
					inst.components.playercontroller:Enable(false)
					inst.components.locomotor:EnableGroundSpeedMultiplier(true)
					inst.sg:RemoveStateTag("busy")
					inst.Physics:CollidesWith(GLOBAL.COLLISION.OBSTACLES)
					inst.Physics:CollidesWith(GLOBAL.COLLISION.SMALLOBSTACLES)
				end),

				TimeEvent(14 * FRAMES, function(inst) -- this is when the target gets hit
					if inst:HasTag("amped") and not inst:HasTag("wearingheavyarmor") then
						inst.leapvelocity = 15
					elseif inst.components.adrenaline:GetPercent() > .24 and inst.components.adrenaline:GetPercent() < .51 and not inst:HasTag("wearingheavyarmor") then
						inst.leapvelocity = 7.5 -- originally 10, lets see how this goes.
					elseif inst.components.adrenaline:GetPercent() > .50 and inst.components.adrenaline:GetPercent() < .75 and not inst:HasTag("wearingheavyarmor") and HasSkill(inst,"amp_1") then
						inst.leapvelocity = 10 -- * (inst.components.adrenaline:GetPercent() + .5)
					elseif inst.components.adrenaline:GetPercent() > .74 and inst.components.adrenaline:GetPercent() < 1 and not inst:HasTag("wearingheavyarmor") and HasSkill(inst,"amp_2") then
						inst.leapvelocity = 12.5 -- this is used in between 75 and 100 (Amped).
					elseif inst.components.adrenaline:GetPercent() > .74 and inst.components.adrenaline:GetPercent() < 1 and not inst:HasTag("wearingheavyarmor") and HasSkill(inst,"amp_1") then
						inst.leapvelocity = 10
					elseif inst.components.adrenaline:GetPercent() > .24 then
						inst.leapvelocity = 7.5
					else
						inst.leapvelocity = 0 --Either Wathom has the "wearingheavyarmor" tag, is under 25 adrenaline (ie fatigued) or the game is somehow not reading the Adrenaline meter.
					end
					SpawnPrefab("dirt_puff").Transform:SetPosition(inst.Transform:GetWorldPosition())
					
					if HasSkill(inst,"rampage_1") then
						local buffaction = inst:GetBufferedAction()
						local target = buffaction ~= nil and buffaction.target or nil
						Check_Bowling(inst,target)
					end
				end),

				TimeEvent(19 * FRAMES, function(inst)
					SpawnPrefab("dirt_puff").Transform:SetPosition(inst.Transform:GetWorldPosition())
					if HasSkill(inst,"rampage_1") then
						local buffaction = inst:GetBufferedAction()
						local target = buffaction ~= nil and buffaction.target or nil
						Check_Bowling(inst,target)
					end
				end),

				TimeEvent(24 * FRAMES, function(inst)
					SpawnPrefab("dirt_puff").Transform:SetPosition(inst.Transform:GetWorldPosition())
					inst.sg:RemoveStateTag("busy")
					inst.sg:RemoveStateTag("attack")
					inst.sg:RemoveStateTag("nointerrupt")
					inst.sg:RemoveStateTag("pausepredict")
					inst.sg:AddStateTag("idle")
					inst.leapvelocity = 0                   -- Stops Wathom's sliding.
					inst.Physics:Stop()
					inst.Physics:CollidesWith(GLOBAL.COLLISION.CHARACTERS) -- Re-enabling Wathom's normal collision.
					inst.components.playercontroller:Enable(true)
					if HasSkill(inst,"rampage_1") then
						local buffaction = inst:GetBufferedAction()
						local target = buffaction ~= nil and buffaction.target or nil
						Check_Bowling(inst,target)
					end
				end),

			},
			onupdate = function(inst)
				if inst.leapvelocity then
					inst.Physics:SetMotorVel(inst.leapvelocity, 0, 0)
				end
			end,
			events =
			{
				EventHandler("animover", function(inst)
					inst.sg:GoToState("idle")
				end),
			},
		},
		
		GLOBAL.State {
			name = "cantbark",
			tags = { busy },

			onenter = function(inst)
				inst:ClearBufferedAction()

				--				inst.components.talker:Say("Can't... Breathe...", nil, true) -- I can't think of something cool for Wathom to say, so away this goes.

				inst.AnimState:PlayAnimation("sing_fail", false)

				inst.SoundEmitter:PlaySound("wathomcustomvoice/wathomvoiceevent/leap") -- maybe make something new later?
			end,
			timeline =
			{
				TimeEvent(12 * FRAMES, function(inst)
					inst.SoundEmitter:PlaySound("wathomcustomvoice/wathomvoiceevent/leap") --place your funky sounds here
				end),                                                       --bark twice.
			},
			events =
			{
				EventHandler("animover", function(inst)
					if inst.AnimState:AnimDone() then
						inst.sg:GoToState("idle")
						inst.sg:RemoveStateTag("busy")
						inst:ClearBufferedAction()
					end
				end),
			}
		},

		GLOBAL.State {
			name = "wathombite",
			tags = { "attack", "backstab", "busy", "notalking", "abouttoattack", "pausepredict", "nointerrupt" },

			onenter = function(inst, data)
				local buffaction = inst:GetBufferedAction()
				local target = buffaction ~= nil and buffaction.target or nil

				inst.components.combat:StartAttack()
				--            inst.components.health:SetInvincible(true) -- I wonder why Tiddler did this?
				--inst.AnimState:PlayAnimation("atk_leap_pre", false)
                inst.AnimState:PlayAnimation("feast_eat_pre_pre")
                inst.AnimState:PushAnimation("feast_eat_pre", false)
				inst.components.locomotor:Stop()
				inst.components.locomotor:EnableGroundSpeedMultiplier(false)

				inst.AnimState:SetDeltaTimeMultiplier(1.2)
			end,

			onexit = function(inst)
				inst.AnimState:SetDeltaTimeMultiplier(1)
			end,	

			timeline =
			{
				TimeEvent(8 * FRAMES, function(inst)
					inst.sg:RemoveStateTag("abouttoattack")
					inst.components.locomotor:Stop()
					local buffaction = inst:GetBufferedAction()
					local target = buffaction ~= nil and buffaction.target or nil
					inst:PerformBufferedAction()
					inst.components.locomotor:EnableGroundSpeedMultiplier(true)
					inst.AnimState:SetFrame(5)
					
					if target then
						MarkDontEatFoods(inst,target)
						inst:DoTaskInTime(.25,function(inst) CheckIfDead(inst,target) end)
					end
				end),
				TimeEvent(12 * FRAMES, function(inst)
					inst.sg:GoToState("idle")
				end),
			},
			events = -- if somehow he gets stuck
			{
				EventHandler("animqueueover", function(inst)
					inst.sg:GoToState("idle")
				end),
			},
		},
	}

	for k, v in pairs(states) do
		GLOBAL.assert(v:is_a(GLOBAL.State), "Non-state added in mod state table!")
		inst.states[v.name] = v
	end

	for k, v in pairs(actionhandlers) do
		GLOBAL.assert(v:is_a(GLOBAL.ActionHandler), "Non-action added in mod state table!")
		inst.actionhandlers[v.action] = v
	end
end)

--client. Uses a "pre" as this should only be used if there's lag.

AddStategraphPostInit("wilson_client", function(inst)
	local _RunOnEnter = inst.states["run_start"].onenter
	local function NewOnEnter(inst, ...)
		if (inst:HasTag("wathom") and inst:HasTag("wathomrun")) then
			inst.sg.mem.footsteps = 0
			inst.sg:GoToState("run_wathom")
			return
		else
			_RunOnEnter(inst, ...)
		end
	end

	inst.states["run_start"].onenter = NewOnEnter

	local actionhandlers =
	{
		ActionHandler(GLOBAL.ACTIONS.WATHOMBARK,
			function(inst, action)
				return "wathombark_pre"
			end),
	}
	local states = {

		GLOBAL.State {
			name = "run_wathom",
			tags = { "moving", "running", "canrotate" },

			onenter = function(inst)
				ConfigureRunState(inst)
				if inst.components.adrenaline and inst.components.adrenaline:GetPercent() > .75 then
					inst.components.locomotor.predictrunspeed = TUNING.WILSON_RUN_SPEED + TUNING.WONKEY_SPEED_BONUS
				end
				inst.components.locomotor:RunForward()
				if not inst.AnimState:IsCurrentAnimation("umrun") then
					inst.AnimState:PlayAnimation("umrun", true)
				end
				--V2C: adding half a frame time so it rounds up
				inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength() + .5 * FRAMES)
			end,

			timeline =
			{
				--[[TimeEvent(4*FRAMES, function(inst) PlayFootstep(inst, .5) end),
            TimeEvent(5*FRAMES, function(inst) PlayFootstep(inst, .5) DoFoleySounds(inst) end),
            TimeEvent(10*FRAMES, function(inst) PlayFootstep(inst, .5) end),
            TimeEvent(11*FRAMES, function(inst) PlayFootstep(inst, .5) end),]]
			},

			onupdate = function(inst)
				if not inst:HasTag("wathomrun") then
					inst.sg:GoToState("run")
					return
				end
				inst.components.locomotor:RunForward()
			end,

			--[[events =
        {
            EventHandler("gogglevision", function(inst, data)
                if not data.enabled and inst:GetStormLevel() >= TUNING.SANDSTORM_FULL_LEVEL then
                    inst.sg:GoToState("run")
                end
            end),
            EventHandler("sandstormlevel", function(inst, data)
                if data.level >= TUNING.SANDSTORM_FULL_LEVEL and not inst.components.playervision:HasGoggleVision() then
                    inst.sg:GoToState("run")
                end
            end),
            EventHandler("carefulwalking", function(inst, data)
                if data.careful then
                    inst.sg:GoToState("run")
                end
            end),
        },]]

			ontimeout = function(inst)
				inst.sg.statemem.funkyrunning = true
				inst.sg:GoToState("run_wathom")
			end,

			onexit = function(inst)
				if not inst.sg.statemem.funkyrunning then
					inst.components.locomotor.predictrunspeed = nil
					inst.Transform:ClearPredictedFacingModel()
				end

			end,
		},

		
		GLOBAL.State {
			name = "wathomleap_pre",
			tags = { "busy" },

			onenter = function(inst)
				inst.components.locomotor:Stop()

				inst.AnimState:PlayAnimation("atk_leap_pre", false)
				inst.AnimState:PushAnimation("atk_leap_lag", false)

				local buffaction = inst:GetBufferedAction()
				if buffaction ~= nil then
					inst:PerformPreviewBufferedAction()

					if buffaction.pos ~= nil then
						inst:ForceFacePoint(buffaction:GetActionPoint():Get())
					end
				end

				inst.sg:SetTimeout(2)
			end,

			onupdate = function(inst)
				if inst:HasTag("busy") then
					if inst.entity:FlattenMovementPrediction() then
						inst.AnimState:PlayAnimation("atk_leap_lag", false)
					end
				elseif inst.bufferedaction == nil then
					inst.sg:GoToState("idle")
				end
			end,

			ontimeout = function(inst)
				inst:ClearBufferedAction()
				inst.sg:GoToState("idle")
			end,
		},

		GLOBAL.State {
			name = "wathombite",
			tags = { "attack", "backstab", "busy", "notalking", "abouttoattack", "pausepredict", "nointerrupt" },

			onenter = function(inst, data)
				inst.components.locomotor:Stop()

				inst.AnimState:PlayAnimation("feast_eat_pre_pre", false)
				inst.AnimState:PushAnimation("feast_eat_pre", false)

				local buffaction = inst:GetBufferedAction()
				if buffaction ~= nil then
					inst:PerformPreviewBufferedAction()

					if buffaction.pos ~= nil then
						inst:ForceFacePoint(buffaction:GetActionPoint():Get())
					end
				end

				inst.sg:SetTimeout(2)
			end,

			--[[onexit = function(inst)
			
			end,]]

			ontimeout = function(inst)
				inst:ClearBufferedAction()
				inst.sg:GoToState("idle")
			end,
		},
		GLOBAL.State {
			name = "wathombark_pre",
			tags = { "busy" },

			onenter = function(inst)
				inst.components.locomotor:Stop()

				inst.AnimState:PlayAnimation("idle", false)

				local buffaction = inst:GetBufferedAction()
				if buffaction ~= nil then
					inst:PerformPreviewBufferedAction()

					if buffaction.pos ~= nil then
						inst:ForceFacePoint(buffaction:GetActionPoint():Get())
					end
				end

				inst.sg:SetTimeout(0)
				inst.AnimState:PushAnimation("idle", true)
			end,

			onupdate = function(inst)
				if inst:HasTag("busy") then
					if inst.entity:FlattenMovementPrediction() then
						inst.sg:GoToState("idle", "noanim")
					end
				elseif inst.bufferedaction == nil then
					inst.sg:GoToState("idle")
				end
			end,

			ontimeout = function(inst)
				inst:ClearBufferedAction()
				inst.sg:GoToState("idle")
			end,
		}
	}

	for k, v in pairs(states) do
		GLOBAL.assert(v:is_a(GLOBAL.State), "Non-state added in mod state table!")
		inst.states[v.name] = v
	end

	for k, v in pairs(actionhandlers) do
		GLOBAL.assert(v:is_a(GLOBAL.ActionHandler), "Non-action added in mod state table!")
		inst.actionhandlers[v.action] = v
	end
end)

-----------------------------------------------------------------------------------------------------

STRINGS.ACTIONS.WATHOMBARK = "Bark"

local wathombark = AddAction(
	"WATHOMBARK",
	STRINGS.ACTIONS.WATHOMBARK,
	function(act)
		local inst = act.doer
		if HasSkill(inst,"wathom_friends_2") then
			SurvivorBarkEffect(inst)
		end
		if HasSkill(inst,"bark_mastery") then
			SpreadGoo(inst,1)
		end
		if act.doer ~= nil and act.doer.components.adrenaline ~= nil then -- previously act.target
			local inst = act.doer
			inst.AnimState:AddOverrideBuild("emote_angry")
			inst.components.adrenaline:DoDelta(inst:HasTag("amped") and 8 or -25, 2)
			--		inst.SoundEmitter:PlaySound("wathomcustomvoice/wathomvoiceevent/bark") Commented out for now since it already plays the sound before this code is performed

			local act_pos = act:GetActionPoint()
			local ents = GLOBAL.TheSim:FindEntities(act_pos.x, act_pos.y, act_pos.z, 10, { "_combat" },
				{ "companion", "INLIMBO", "notarget", "noattack", "player", "playerghost", "wall", "abigail", "shadow", "shadowminion"}) --added playertags because of the taunt.
			for i, v in ipairs(ents) do
				if v.components.hauntable ~= nil and v.components.hauntable.panicable and not
					(
						v.components.follower ~= nil and v.components.follower:GetLeader() and
						v.components.follower:GetLeader():HasTag("player")) then
					v.components.hauntable:Panic(10) -- Fallback to TUNING.BATTLESONG_PANIC_TIME (6 seconds) if needed
					if HasSkill(inst,"wathom_friends_1") then
						v:AddTag("wathom_really_spooking_me")
						v:DoTaskInTime(10,function(v) v:RemoveTag("wathom_really_spooking_me") end)
					end
					AddEnemyDebuffFx("battlesong_instant_panic_fx", v)
				end
				if v.components.hauntable == nil or
					v.components.hauntable ~= nil and not v.components.hauntable.panicable and not (
						v.components.follower ~= nil and v.components.follower:GetLeader() and
						v.components.follower:GetLeader():HasTag("player")) then
					if not v:HasTag("bird") and v.components.combat then
						v.components.combat:SetTarget(act.doer)
						AddEnemyDebuffFx("battlesong_instant_taunt_fx", v)
					end
				end
			end
			--also scare enemies near wathom, at a smaller radius
			local x, y, z = act.doer.Transform:GetWorldPosition()
			ents = GLOBAL.TheSim:FindEntities(x, y, z, 4, { "_combat" },
				{ "companion", "INLIMBO", "notarget", "noattack", "player", "playerghost", "wall", "abigail", "shadow", "shadowminion", "trap" }) --added playertags because of the taunt.
			for i, v in ipairs(ents) do
				if v.components.hauntable ~= nil and v.components.hauntable.panicable and not
					(
						v.components.follower ~= nil and v.components.follower:GetLeader() and
						v.components.follower:GetLeader():HasTag("player")) then
					v.components.hauntable:Panic(8) -- Fallback to TUNING.BATTLESONG_PANIC_TIME (6 seconds) if needed
					if HasSkill(inst,"wathom_friends_1") then
						v:AddTag("wathom_really_spooking_me")
						v:DoTaskInTime(8,function(v) v:RemoveTag("wathom_really_spooking_me") end)
					end
				end
				if v.components.hauntable == nil or
					v.components.hauntable ~= nil and not v.components.hauntable.panicable and not (
						v.components.follower ~= nil and v.components.follower:GetLeader() and
						v.components.follower:GetLeader():HasTag("player")) and not v:HasTag("player") then
					if not v:HasTag("bird") and v.components.combat then
						v.components.combat:SetTarget(act.doer)
					end
				end
			end
			return true
		else
			return false
		end
	end
)

wathombark.priority = HIGH_ACTION_PRIORITY
wathombark.rmb = true
wathombark.distance = 36
wathombark.mount_valid = false

STRINGS.ACTIONS.WATHOMBARK = "Bark"

-- STRINGS.ACTIONS.AMPUP = "Amp Up!"

---------------------------------------------

local KnownModIndex = GLOBAL.KnownModIndex
local Text = require "widgets/text"
local Image = require "widgets/image"
local NUMBERFONT = GLOBAL.NUMBERFONT

local function GetModName(modname) -- modinfo's modname and internal modname is different.
	for _, knownmodname in ipairs(KnownModIndex:GetModsToLoad()) do
		if KnownModIndex:GetModInfo(knownmodname).name == modname then
			return knownmodname
		end
	end
end

local function GetModOptionValue(knownmodname, known_option_name)
	local modinfo = KnownModIndex:GetModInfo(knownmodname)
	for _, option in pairs(modinfo.configuration_options) do
		if option.name == known_option_name then
			return option.saved
		end
	end
end

local DEERCLOPS_TIMERNAME = "deerclops_timetoattack"
local MOTHERGOOSE_TIMERNAME = "mothergoose_timetoattack"
local MOCKFLY_TIMERNAME = "mockfly_timetoattack"
local BEARGER_TIMERNAME = "bearger_timetospawn"

local function Say(inst,text)
	inst.components.talker:Say(text)
end

local function WathomWarnsEarly(inst, threattype, stage)
	if threattype == "megafauna" then
		if stage == 1 then
			Say(inst,"Distant Roar. Awoken, megafauna. Far away, still.")
		else
			Say(inst,"Distant Megafauna. Time for preparation.")
		end
	elseif threattype == "dogs" then
		if GLOBAL.TheWorld:HasTag("cave") then
			if stage == 1 then
				Say(inst,"Vocalizations, depth worms. Hunt began. Far away, still.")
			else
				Say(inst,"Worms. Our footsteps, felt. Soon, attack.")
			end
		else
			if stage == 1 then
				Say(inst,"Howling, distant dogs. Hunt began. Far away, still.")
			else
				Say(inst,"Dogs. Our footsteps, felt. Soon, attack.")
			end		
		end
	end
end

local function HoundTask(inst)
	local _worldsettingstimer = GLOBAL.TheWorld.components.worldsettingstimer
	if GLOBAL.TheWorld.components.hounded then
		local houndtime = GLOBAL.TheWorld.components.hounded:GetTimeToAttack() / 60
		if houndtime < 8.5 and houndtime > 7.5 then
			WathomWarnsEarly(inst, "dogs", 1)
		end
		if houndtime < 4.5 and houndtime > 3.5 then
			WathomWarnsEarly(inst, "dogs", 2)
		end
	end
	
	
	if _worldsettingstimer then
		if _worldsettingstimer:GetTimeLeft(DEERCLOPS_TIMERNAME) then
			local timeleft = _worldsettingstimer:GetTimeLeft(DEERCLOPS_TIMERNAME)
			if timeleft < 8.5 and timeleft > 7.5 then
				WathomWarnsEarly(inst,"megafauna",1)
			end
			if timeleft < 4.5 and timeleft > 3.5 then
				WathomWarnsEarly(inst,"megafauna",2)
			end
		end
		if _worldsettingstimer:GetTimeLeft(MOTHERGOOSE_TIMERNAME) then
			local timeleft = _worldsettingstimer:GetTimeLeft(MOTHERGOOSE_TIMERNAME)
			if timeleft > 8.5 and timeleft > 7.5 then
				WathomWarnsEarly(inst,"megafauna",1)
			end
			if timeleft < 4.5 and timeleft > 3.5 then
				WathomWarnsEarly(inst,"megafauna",2)
			end
		end
		if _worldsettingstimer:GetTimeLeft(MOCKFLY_TIMERNAME) then
			local timeleft = _worldsettingstimer:GetTimeLeft(MOCKFLY_TIMERNAME)
			if timeleft < 8.5 and timeleft > 7.5 then
				WathomWarnsEarly(inst,"megafauna",1)
			end
			if timeleft < 4.5 and timeleft > 3.5 then
				WathomWarnsEarly(inst,"megafauna",2)
			end
		end
		if _worldsettingstimer:GetTimeLeft(BEARGER_TIMERNAME) then
			local timeleft = _worldsettingstimer:GetTimeLeft(BEARGER_TIMERNAME)
			if timeleft < 8.5 and timeleft > 7.5 then
				WathomWarnsEarly(inst,"megafauna",1)
			end
			if timeleft < 4.5 and timeleft > 3.5 then
				WathomWarnsEarly(inst,"megafauna",2)
			end
		end
	end
end

AddPlayerPostInit(function(inst)
	if inst:HasTag("wathom") then
		inst.counter_max = GLOBAL.net_shortint(inst.GUID, "counter_max", "counter_maxdirty")
		inst.counter_current = GLOBAL.net_shortint(inst.GUID, "counter_current", "counter_currentdirty")
	
		
		if GLOBAL.TheWorld.ismastersim then
			inst.HoundTask = HoundTask
			inst:AddComponent("adrenaline")	
		end
		inst:ListenForEvent("onattackother", AttackOther)
	end
end)

local function AmpbadgeDisplays(self)
	if self.owner:HasTag("wathom") then
		local ampbadge = require "widgets/ampbadge"

		self.combinedmod = GetModName("Combined Status")

		self.adrenaline = self:AddChild(ampbadge(self.owner))

		if self.combinedmod ~= nil then
			self.brain:SetPosition(0, 35, 0)
			self.stomach:SetPosition(-62, 35, 0)
			self.heart:SetPosition(62, 35, 0)

			self.adrenaline:SetScale(.9, .9, .9)
			self.adrenaline:SetPosition(-62, -50, 0)
			self.adrenaline.combinedmod = true
			self.adrenaline.showmaxonnumbers = GetModOptionValue(self.combinedmod, "SHOWMAXONNUMBERS")

			self.adrenaline.bg = self.adrenaline:AddChild(Image("images/status_bgs.xml", "status_bgs.tex"))
			self.adrenaline.bg:SetScale(.4, .43, 0)
			self.adrenaline.bg:SetPosition(-.5, -40, 0)

			if self.boatmeter then
				self.boatmeter:SetPosition(-124, -52)
			end

			self.adrenaline.num:SetFont(NUMBERFONT)
			self.adrenaline.num:SetSize(28)
			self.adrenaline.num:SetPosition(3.5, -40.5, 0)
			self.adrenaline.num:SetScale(1, .78, 1)

			self.adrenaline.num:MoveToFront()
			self.adrenaline.num:Show()

			self.adrenaline.maxnum = self.adrenaline:AddChild(Text(NUMBERFONT, self.adrenaline.showmaxonnumbers and 25 or 33))
			self.adrenaline.maxnum:SetPosition(6, 0, 0)
			self.adrenaline.maxnum:MoveToFront()
			self.adrenaline.maxnum:Hide()
		else
			self.adrenaline:SetPosition(self.column3, -130, 0)
			self.moisturemeter:SetPosition(self.column1, -130, 0)
			--self.brain:SetPosition(40, -50, 0)
			--self.stomach:SetPosition(-40, 17, 0)
		end

		--self.inst:ListenForEvent("adrenalinedelta", function(inst, data) self.adrenaline:SetPercent(data.newpercent, self.owner.components.pestilencecounter:Max()) end, self.owner)

		local _SetGhostMode = self.SetGhostMode
		function self:SetGhostMode(ghostmode)
			if not self.isghostmode == not ghostmode then --force boolean
				return
			end

			_SetGhostMode(self, ghostmode)
			if ghostmode then
				self.adrenaline:Hide()
			else
				self.adrenaline:Show()
			end
		end
	end
end

AddClassPostConstruct("widgets/statusdisplays", AmpbadgeDisplays)

-- New code for Wathom's echolocation! Needs to be controls so it doesnt screw with player hud!
AddClassPostConstruct( "widgets/controls", function(self, inst)
	local ownr = self.owner
	if ownr == nil then return end
	
	if self.owner:HasTag("wathom") then
		local Wathom_Sonar = require "widgets/wathom_sonar"
		self.wathom_sonar = self:AddChild( Wathom_Sonar(self.owner) )
		self.wathom_sonar:MoveToBack()
	end
end)


GLOBAL.FOODTYPE.LICHEN = "LICHEN"
table.insert(GLOBAL.FOODGROUP.OMNI.types,GLOBAL.FOODTYPE.LICHEN)

AddPrefabPostInit("cutlichen", function(inst)
	if not GLOBAL.TheWorld.ismastersim then
		return
	end
	
	inst:AddComponent("edible")
	inst.components.edible.secondaryfoodtype = GLOBAL.FOODTYPE.LICHEN
	
end)

local function ruinshat_fxanim(inst)
	inst._fx.AnimState:PlayAnimation("hit")
	inst._fx.AnimState:PushAnimation("idle_loop")
end

local function ruinshat_oncooldown(inst)
	inst._task = nil
end

local function ruinshat_unproc(inst)
	if inst:HasTag("forcefield") then
		inst:RemoveTag("forcefield")
		if inst._fx ~= nil then
			inst._fx:kill_fx()
			inst._fx = nil
		end
		inst:RemoveEventCallback("armordamaged", ruinshat_fxanim)

		inst.components.armor:SetAbsorption(GLOBAL.TUNING.ARMOR_RUINSHAT_ABSORPTION)
		inst.components.armor.ontakedamage = nil

		if inst._task ~= nil then
			inst._task:Cancel()
		end
		inst._task = inst:DoTaskInTime(GLOBAL.TUNING.ARMOR_RUINSHAT_COOLDOWN, ruinshat_oncooldown)
	end
end

local function ruinshat_proc(inst, owner)
	inst:AddTag("forcefield")
	if inst._fx ~= nil then
		inst._fx:kill_fx()
	end
	inst._fx = GLOBAL.SpawnPrefab("forcefieldfx")
	inst._fx.entity:SetParent(owner.entity)
	inst._fx.Transform:SetPosition(0, .2, 0)
	inst:ListenForEvent("armordamaged", ruinshat_fxanim)

	inst.components.armor:SetAbsorption(GLOBAL.TUNING.FULL_ABSORPTION)
	inst.components.armor.ontakedamage = function(inst, damage_amount)
		if owner ~= nil and owner.components.sanity ~= nil then
			owner.components.sanity:DoDelta(-damage_amount * GLOBAL.TUNING.ARMOR_RUINSHAT_DMG_AS_SANITY, false)
		end
	end

	if inst._task ~= nil then
		inst._task:Cancel()
	end
	inst._task = inst:DoTaskInTime(GLOBAL.TUNING.ARMOR_RUINSHAT_DURATION, ruinshat_unproc)
end

local function tryproc(inst, owner, data) -- Wathom with ancient allegiance almost always procs
	if inst._task == nil and
		(data and not data.redirected) or not data and
		math.random() < .7 then
		ruinshat_proc(inst, owner)
	end
end
	
AddPrefabPostInit("ruinshat", function(inst)
	if not GLOBAL.TheWorld.ismastersim then
		return
	end
	
	inst._umoldproc = inst.procfn
	local _OnUnEquip = inst.components.equippable.onunequipfn
	local _OnEquip = inst.components.equippable.onequipfn
	
	local function OnEquip(inst, owner)
		if HasSkill(owner,"ancient_kinship_2") then
			if inst.procfn then
				inst.procfn = nil
			end
			inst.procfn = function(owner, data) tryproc(inst, owner, data) end
		end
		if HasSkill(owner,"ancient_kinship_3") then
			inst:AddComponent("planardefense")
			inst.components.planardefense:SetBaseDefense(10)
		end
		
		_OnEquip(inst,owner)
	end
	
	local function OnUnEquip(inst, owner)
		inst.procfn = inst._umoldproc
		if inst.components.planardefense then
			inst:RemoveComponent("planardefense")
		end
		inst.ondetach()
		_OnUnEquip(inst,owner)
	end
	
	inst.components.equippable:SetOnEquip(OnEquip)
	inst.components.equippable:SetOnUnequip(OnUnEquip)
end)

AddPrefabPostInit("armorruins", function(inst)
	if not GLOBAL.TheWorld.ismastersim then
		return
	end
	local _OnUnEquip = inst.components.equippable.onunequipfn
	local _OnEquip = inst.components.equippable.onequipfn		
	local function OnEquip(inst, owner)
		if HasSkill(owner,"ancient_kinship_3") then
			inst:AddComponent("planardefense")
			inst.components.planardefense:SetBaseDefense(10)
		end
		
		_OnEquip(inst,owner)
	end
	
	local function OnUnEquip(inst, owner)
		if inst.components.planardefense then
			inst:RemoveComponent("planardefense")
		end
		_OnUnEquip(inst,owner)
	end
	inst.components.equippable:SetOnEquip(OnEquip)
	inst.components.equippable:SetOnUnequip(OnUnEquip)	
end)

AddPrefabPostInit("ruins_bat", function(inst)
	if not GLOBAL.TheWorld.ismastersim then
		return
	end
	local _OnUnEquip = inst.components.equippable.onunequipfn
	local _OnEquip = inst.components.equippable.onequipfn		
	local function OnEquip(inst, owner)
		if HasSkill(owner,"ancient_kinship_3") then
			inst:AddComponent("planardamage")
			inst.components.planardamage:SetBaseDamage(20)
		end
		
		_OnEquip(inst,owner)
	end
	
	local function OnUnEquip(inst, owner)
		if inst.components.planardefense then
			inst:RemoveComponent("planardefense")
		end
		_OnUnEquip(inst,owner)
	end
	inst.components.equippable:SetOnEquip(OnEquip)
	inst.components.equippable:SetOnUnequip(OnUnEquip)	
end)

AddPrefabPostInit("ancient_altar", function(inst)
	if not GLOBAL.TheWorld.ismastersim then
		return
	end
	
	local _complete_onturnon = inst.components.prototyper.onturnon

	local function TurnOn(inst)
		local x,y,z = inst.Transform:GetWorldPosition()
		local players = TheSim:FindEntities(x,y,z,16,{"player"})
		for i,player in ipairs(players) do
			if HasSkill(player,"wathom_allegiance_neutral") and not player.found_station then
				player.found_station = true

				player:AddComponent("prototyper")
				player.components.prototyper.trees = TUNING.PROTOTYPER_TREES.ANCIENTALTAR_HIGH
				player.components.talker:Say("Hmm... understand now.")
				
				-- player.components.builder:UnlockRecipesForTech({ANCIENT = 4})
			end
		end
		_complete_onturnon(inst)
	end
	inst.components.prototyper.onturnon = TurnOn 
end)

-- AddPrefabPostInit("shadow_battleaxe", function(inst)
	-- if not GLOBAL.TheWorld.ismastersim then
		-- return
	-- end
	
	-- local _attack = inst.components.weapon.onattack
	
	-- local function OnAttack(inst, owner, target) -- Basically trigger the restoration component twice
		-- _attack(inst,owner,target)

		-- if target.components.health ~= nil and target.components.health:IsDead() then
			-- inst.components.hunger:DoDelta(GLOBAL.TUNING.SHADOW_BATTLEAXE.HUNGER_GAIN_ONKILL, false)

			-- if inst._trackedentities[target] == nil then -- The tracking will give us the kill stack.
				-- local is_epic = inst:CheckForEpicCreatureKilled(target)

				-- if owner ~= nil and not is_epic then
					-- inst:SayRegularChatLine("creature_killed", owner)
				-- end
			-- end

		-- elseif inst:IsEpicCreature(target) and
			-- inst.epic_kill_count < GLOBAL.TUNING.SHADOW_BATTLEAXE.LEVEL_THRESHOLDS[#GLOBAL.TUNING.SHADOW_BATTLEAXE.LEVEL_THRESHOLDS]
		-- then
			-- inst:TrackTarget(target)
		-- end	
	-- end
	
	-- inst.components.weapon:SetOnAttack(OnAttack)
-- end)

-------------------------------------------------------
-- The character select screen lines
STRINGS.CHARACTER_TITLES.wathom = "The Forgotten Parody"
STRINGS.CHARACTER_NAMES.wathom = "Wathom"
STRINGS.CHARACTER_DESCRIPTIONS.wathom = "*Apex Predator\n*Gets amped up with adrenaline\n*Causes animals to panic\n*The faster he goes, the harder he falls"
STRINGS.CHARACTER_QUOTES.wathom = "\"Cruel, the abyss.\""
STRINGS.CHARACTER_SURVIVABILITY.wathom = "Slim"

-- Custom speech strings
STRINGS.CHARACTERS.WATHOM = require "speech_wathom"

-- The character's name as appears in-game
STRINGS.NAMES.WATHOM = "Wathom"
STRINGS.SKIN_NAMES.wathom_none = "Wathom"

-- The skins shown in the cycle view window on the character select screen.
-- A good place to see what you can put in here is in skinutils.lua, in the function GetSkinModes
local skin_modes = {
	{
		type = "ghost_skin",
		anim_bank = "ghost",
		idle_anim = "idle",
		scale = .75,
		offset = { 0, -25 }
	},
}

-- Add mod character to mod character list. Also specify a gender. Possible genders are MALE, FEMALE, ROBOT, NEUTRAL, and PLURAL.
if GetModConfigData("holy fucking shit it's wathom") then
	AddModCharacter("wathom", "MALE", skin_modes)
end

--skincolor
for k, v in pairs(GLOBAL.CLOTHING) do
	if v and v.symbol_overrides_by_character and v.symbol_overrides_by_character.wortox then
		GLOBAL.CLOTHING[k].symbol_overrides_by_character.wathom = v.symbol_overrides_by_character.wortox
	end
end


--[[Keeping this here for standalone mod but this is causing issues with postinit/components/health
--Refuse to die Edit this not to include you
local function MayKill(self, amount)
	if self.currenthealth + amount <= 0 then
		return true
	end
end

local function HasLLA(self)
	if self.inst.components.inventory then
		local item = self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
		if item and item.prefab == "amulet" then
			return true
		end
	end
end

AddComponentPostInit("health", function(self)
	if not GLOBAL.TheWorld.ismastersim then return end

	local _DoDelta = self.DoDelta
	function self:DoDelta(amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)

	end
end)
]]

local PREFAB_SKINS = GLOBAL.PREFAB_SKINS
local PREFAB_SKINS_IDS = GLOBAL.PREFAB_SKINS_IDS
local SKIN_AFFINITY_INFO = GLOBAL.require("skin_affinity_info")

-- Modded Skin API
--[[
modimport("skins_api")

SKIN_AFFINITY_INFO.wathom = {
    "wathom_triumphant", --Hornet: These skins will show up for the character when the Survivor filter is enabled
}

PREFAB_SKINS["wathom"] = {"wathom_none", "wathom_triumphant",}

PREFAB_SKINS_IDS = {} --Make sure this is after you  change the PREFAB_SKINS["character"] table
for prefab,skins in pairs(PREFAB_SKINS) do
    PREFAB_SKINS_IDS[prefab] = {}
    for k,v in pairs(skins) do
          PREFAB_SKINS_IDS[prefab][v] = k
    end
end
AddSkinnableCharacter("wathom")]]


STRINGS.SKIN_NAMES.wathom_none = "Wathom"
STRINGS.SKIN_NAMES.wathom_triumphant = "The Archaic"

STRINGS.SKIN_QUOTES.wathom_none = "\"Cruel, the abyss.\""
STRINGS.SKIN_QUOTES.wathom_triumphant = "\"Pursuit of knowledge; A thousand deaths, will endure.\""

STRINGS.SKIN_DESCRIPTIONS.wathom_none = "A crude recreation of those who came before him."
STRINGS.SKIN_DESCRIPTIONS.wathom_triumphant = "Donned with military attire, Wathom acknowledges and accepts his fate when tracing the Ancients' footsteps. He was born for this."