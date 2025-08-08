local env = env
GLOBAL.setfenv(1, GLOBAL)

local function OnCooldown(inst)
    inst._cdtask = nil
end

env.AddStategraphPostInit("shadowcreature", function(inst)


	local function TryDropTarget(inst)
		if inst.ShouldKeepTarget then --nightmarecreatures don't drop target
			local target = inst.components.combat.target
			if target and not inst:ShouldKeepTarget(target) and target:HasTag("player") then -- check for players
				inst.components.combat:DropTarget()
				return true
			end
		end
	end
		
	local _OldAttacked = inst.events["attacked"].fn -- crawling h/n have a special hit state
	inst.events["attacked"].fn = function(inst, data, ...)
        if not (inst.sg:HasStateTag("attack") or inst.sg:HasStateTag("hit") or inst.sg:HasStateTag("noattack") or inst.components.health:IsDead()) then
			if inst._cdtask == nil and inst:HasTag("crawlinghorror") then
				inst._cdtask = inst:DoTaskInTime(1, OnCooldown)
				inst.sg:GoToState("hit_goo")
			else
				_OldAttacked(inst, data, ...)
			end
		end
	end
	
	local _OldAttack = inst.events["doattack"].fn -- t/n beaks have a special attack state
	inst.events["doattack"].fn = function(inst, data, ...)
        if not (inst.sg:HasStateTag("attack") or inst.sg:HasStateTag("hit") or inst.sg:HasStateTag("noattack") or inst.components.health:IsDead()) then
			if inst.prefab == "nightmarebeak" or inst.prefab == "terrorbeak" then
				if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
					inst.sg:GoToState("attack", data.target)
				end				
			else
				_OldAttack(inst, data, ...)
			end
		end
	end	
	
	
local function FinishExtendedSound(inst, soundid)
    inst.SoundEmitter:KillSound("sound_"..tostring(soundid))
    inst.sg.mem.soundcache[soundid] = nil
    if inst.sg.statemem.readytoremove and next(inst.sg.mem.soundcache) == nil then
        inst:Remove()
    end
end

local function PlayExtendedSound(inst, soundname)
    if inst.sg.mem.soundcache == nil then
        inst.sg.mem.soundcache = {}
        inst.sg.mem.soundid = 0
    else
        inst.sg.mem.soundid = inst.sg.mem.soundid + 1
    end
    inst.sg.mem.soundcache[inst.sg.mem.soundid] = true
    inst.SoundEmitter:PlaySound(inst.sounds[soundname], "sound_"..tostring(inst.sg.mem.soundid))
    inst:DoTaskInTime(5, FinishExtendedSound, inst.sg.mem.soundid)
end

	-- stop taunting if wortox summoned
	local _OldTauntEnter = inst.states["taunt"].onenter
	inst.states["taunt"].onenter = function(inst,...)
		if inst.wortox_minion then
			inst.sg:GoToState("idle")
		else
			_OldTauntEnter(inst,...)
		end
	end

		
local states = {

	State{
        name = "hit_goo",
        tags = { "busy", "hit" },

        onenter = function(inst)
			
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("disappear")
        end,
		
		timeline =
        {   
            TimeEvent(FRAMES, function(inst)
				inst:LaunchProjectile()
            end),
            TimeEvent(2*FRAMES, function(inst)
				inst:LaunchProjectile()
            end),
            TimeEvent(4*FRAMES, function(inst)
				inst:LaunchProjectile()
            end),
			TimeEvent(6*FRAMES, function(inst)
				inst:LaunchProjectile()
            end),
			TimeEvent(8*FRAMES, function(inst)
				inst:LaunchProjectile()
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                local max_tries = 4
                for k = 1, max_tries do
                    local x, y, z = inst.Transform:GetWorldPosition()
                    local offset = 10
                    x = x + math.random(2 * offset) - offset
                    z = z + math.random(2 * offset) - offset
                    if TheWorld.Map:IsPassableAtPoint(x, y, z) then
                        inst.Physics:Teleport(x, y, z)
                        break
                    end
                end

                inst.sg:GoToState("appear")
            end),
        },
    },

	State{
        name = "attack",
        tags = { "attack", "busy" },

        onenter = function(inst, target)
            inst.sg.statemem.target = target 
			inst.Physics:Stop()
			
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk_pre")
            inst.AnimState:PushAnimation("atk", false)
            PlayExtendedSound(inst, "attack_grunt")
        end,

        timeline =
        {
            TimeEvent(14*FRAMES, function(inst) PlayExtendedSound(inst, "attack") 
				
			end),
            TimeEvent(16*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) 
			
			end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
				if math.random() < .333 then
					if inst:HasTag("terrorbeak") and inst.components.combat and inst.components.combat.target and inst.components.combat.target:HasTag("player") then --taunt teleporting is only really useful against a player
						inst.sg:GoToState("tauntport")
					else
						TryDropTarget(inst)
						inst.forceretarget = true --V2C: try to keep legacy behaviour; it used SetTarget(nil) here, which would always result in a retarget
						inst.sg:GoToState("taunt")
					end
				else
					inst.sg:GoToState("idle")
				end
            end),
        },
    },
	
	State{
        name = "tauntport",
        tags = { "busy" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
            PlayExtendedSound(inst, "taunt")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("taunttp") end),
        },
    },

    State{
        name = "taunttp",
        tags = { "busy", "hit" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("disappear")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                local max_tries = 4
				local target = inst.components.combat.target
				
				if target ~= nil then
					for k = 1, max_tries do
						local x, y, z = target.Transform:GetWorldPosition()
						local offset = 10
						x = x + math.random(2 * offset) - offset
						z = z + math.random(2 * offset) - offset
						if TheWorld.Map:IsPassableAtPoint(x, y, z) and #TheSim:FindEntities(x, y, z, 3, { "player" }) == 0 then
							inst.Physics:Teleport(x, y, z)
							break
						end
					end
				else
					for k = 1, max_tries do
						local x, y, z = inst.Transform:GetWorldPosition()
						local offset = 10
						x = x + math.random(2 * offset) - offset
						z = z + math.random(2 * offset) - offset
						if TheWorld.Map:IsPassableAtPoint(x, y, z) then
							inst.Physics:Teleport(x, y, z)
							break
						end
					end
				end

                inst.sg:GoToState("appear")
            end),
        },
    }
}

for k, v in pairs(states) do
    assert(v:is_a(State), "Non-state added in mod state table!")
    inst.states[v.name] = v
end

end)

