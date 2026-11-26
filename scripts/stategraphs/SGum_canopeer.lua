local easing = require("easing")
require("stategraphs/commonstates")

-- Require hardwiring the electrical states because of how the animation calling works for this entity
local update_electrocute_recovery_delay = CommonHandlers.UpdateElectrocuteRecoveryDelay
local update_hit_recovery_delay = CommonHandlers.UpdateHitRecoveryDelay
local spawn_electrocute_fx = CommonHandlers.SpawnElectrocuteFx

local events=
{
	EventHandler("attacked", function(inst, data)
		if inst.components.health and not inst.components.health:IsDead() then
			if CommonHandlers.TryElectrocuteOnAttacked(inst, data) then
				return
			elseif not inst.sg:HasAnyStateTag("hit", "attack") then
                inst.sg:GoToState("hit")
			end
		end
	end),
    CommonHandlers.OnFreeze(),
	CommonHandlers.OnElectrocute(),

    EventHandler("death", function(inst,data)
        inst.sg:GoToState("death")
    end),
    EventHandler("freeze", function(inst,data)
        if inst.components.health and not inst.components.health:IsDead() then
            inst.sg:GoToState("frozen")
        end
    end),
}

local states=
{


    State{
        name = "idle",
		tags = { "idle"},
        onenter = function(inst)
            inst.AnimState:PushAnimation("canopeer"..inst.animtype[inst.type].."_idle",true)
        end,
    },

    State{
        name = "hit",
		tags = { "busy","hit"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("canopeer"..inst.animtype[inst.type].."_hit",false)
        end,
        events=
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },

    },

	State{
        name = "death",
        tags = {"busy","raised"},

        onenter = function(inst)
            inst.components.lootdropper:DropLoot()
            inst.AnimState:PlayAnimation("canopeer"..inst.animtype[inst.type].."_death",false)
            RemovePhysicsColliders(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/eyeplant/lure_die")
        end,
        timeline=
        {
            TimeEvent(11*FRAMES,function(inst) inst:DoPreDeath() end),
            TimeEvent(25*FRAMES,function(inst) inst:DoDeath() end),
        },
    },
    State{
        name = "frozen",
        tags = {"busy", "frozen","raised"},

        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("canopeer"..inst.animtype[inst.type].."_frozen")
            inst.SoundEmitter:PlaySound("dontstarve/common/freezecreature")
        end,

        events =
        {
            EventHandler("onthaw", function(inst) inst.sg:GoToState("thaw") end ),
        },
    },

    State{
        name = "thaw",
        tags = {"busy", "thawing","raised"},

        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("canopeer"..inst.animtype[inst.type].."_frozen_loop_pst",true)
            inst.SoundEmitter:PlaySound("dontstarve/common/freezethaw", "thawing")
        end,

        onexit = function(inst)
            inst.SoundEmitter:KillSound("thawing")
        end,
        events =
        {
            EventHandler("unfreeze", function(inst) inst.sg:GoToState("idle") end),
        },
    },
    State{
		name = "electrocute",
		tags = { "electrocute", "hit", "busy", "noelectrocute", "nosleep" },

		onenter = function(inst, data)
            if inst.components.freezable and inst.components.freezable:IsFrozen() then
                inst.components.freezable:Unfreeze()
            end
			inst.AnimState:PlayAnimation("canopeer"..inst.animtype[inst.type].."_shock_loop", true)

			local duration = CalcEntityElectrocuteDuration(inst, data and data.duration)

			update_electrocute_recovery_delay(inst)
            update_hit_recovery_delay(inst)
			inst.sg.statemem.fx = spawn_electrocute_fx(inst, data, duration)

			inst.sg:SetTimeout(duration)

			inst:PushEvent("startelectrocute")
		end,


		ontimeout = function(inst)
			inst.sg.statemem.not_interrupted = true
			inst.sg:GoToState("electrocute_pst")
		end,

		onexit = function(inst)
			if inst.sg.mem.burn_on_electrocute then
				local data = inst.sg.statemem.data
				if not (data and data.noburn) and inst.components.burnable and not inst.components.burnable:IsBurning() then
					local attackdata = data and data.attackdata or data
					inst.components.burnable:Ignite(nil, attackdata and (attackdata.weapon or attackdata.attacker), attackdata and attackdata.attacker)
				end
			end
		end,
	    },
    State{
		name = "electrocute_pst",
		tags = { "electrocute", "hit", "busy", "noelectrocute" },

		onenter = function(inst)
			if inst.components.locomotor then
				inst.components.locomotor:StopMoving()
			end

			inst.AnimState:PlayAnimation("canopeer"..inst.animtype[inst.type].."_shock_loop_pst")

		end,

		events =
		{
			EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
		},
	}

}
--CommonStates.AddFrozenStates(states) --AXE Not using common states because of the way the animations were named.

--[[local anims = {
    loop = "canopeer"..inst.animtype[inst.type].."_shock_loop",
    pst = "canopeer"..inst.animtype[inst.type].."_shock_loop_pst",
}]]
--[[CommonStates.AddElectrocuteStates(states, nil, anims, {
	onanimover = function(inst)
		if inst.AnimState:AnimDone() then
			inst.sg:GoToState("idle")
		end
	end,
})]] -- AXE We cannot use this method because the electric animations cannot pass inst for the "anim" field

CommonStates.AddInitState(states, "idle")
--CommonStates.AddCorpseStates(states)

return StateGraph("um_canopeer", states, events, "init")
