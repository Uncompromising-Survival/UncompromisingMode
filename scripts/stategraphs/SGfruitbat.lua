require("stategraphs/commonstates")

-- Copied from mine.lua to emulate its mine test.
local mine_test_fn = function(target, inst)
    return not (target.components.health ~= nil and target.components.health:IsDead())
            and (target.components.combat ~= nil and target.components.combat:CanBeAttacked(inst))
end

local mine_test_tags = { "monster", "character", "animal" }
local mine_must_tags = { "_combat" }
local mine_no_tags = { "notraptrigger", "flying", "ghost", "playerghost", "snapdragon" }

local function FxAppear(inst)
	SpawnPrefab("blueberryexplosion").Transform:SetPosition(inst.Transform:GetWorldPosition())
	SpawnPrefab("blueberrypuddle").Transform:SetPosition(inst.Transform:GetWorldPosition())
end

local function Explode(inst)
	inst.SoundEmitter:PlaySound("turnoftides/creatures/together/starfishtrap/trap")
	FxAppear(inst)
	
	local x,y,z = inst.Transform:GetWorldPosition()
	local target_ents = TheSim:FindEntities(x, y, z, 1.1*TUNING.STARFISH_TRAP_RADIUS, mine_must_tags, mine_no_tags, mine_test_tags)
	for i, target in ipairs(target_ents) do
		if target ~= inst and target.entity:IsVisible() and mine_test_fn(target, inst) then
			target.components.combat:GetAttacked(inst, TUNING.STARFISH_TRAP_DAMAGE)
		end
	end
	
	local otherbombs = TheSim:FindEntities(x, y, z, 3*TUNING.STARFISH_TRAP_RADIUS, {"blueberrybomb"}, mine_no_tags)
	for i, target in ipairs(otherbombs) do
		if target ~= inst and target.components.mine and not target.components.mine.issprung and not target.froze then
			target.components.mine:SetRadius(TUNING.STARFISH_TRAP_RADIUS*12)
		end
	end
end


local actionhandlers =
{
    ActionHandler(ACTIONS.GOHOME, "flybackup"),
    ActionHandler(ACTIONS.EAT, "eat_enter"),
    ActionHandler(ACTIONS.PICKUP, "eat_enter")
}

local events=
{
    EventHandler("fly_back", function(inst, data)
        inst.sg:GoToState("flyback")
    end),
    CommonHandlers.OnLocomote(false, true),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnAttack(),
    CommonHandlers.OnAttacked(),
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
    CommonHandlers.OnSleep(),
}

local states =
{
    State{
        
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst, playanim)
            inst.Physics:Stop()
            if playanim then
                inst.AnimState:PlayAnimation(playanim)
                inst.AnimState:PushAnimation("idle", true)
            else
                inst.AnimState:PlayAnimation("idle", true)
            end
        end,
        
        timeline = 
        {         
			TimeEvent(3*FRAMES, function(inst) inst:PushEvent("wingdown") end ),
            --TimeEvent(5*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/vampirebat/breath")  end ),
			TimeEvent(13*FRAMES, function(inst) inst:PushEvent("wingdown") end ),
        },
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        
        name = "action",
        onenter = function(inst, playanim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("fly_loop", true)
            inst:PerformBufferedAction()
        end,
        events=
        {
            EventHandler("animover", function (inst)
                inst.sg:GoToState("idle")
            end),
        }
    }, 

    State{
        name = "flyback",
        tags = {"flight", "busy"},
        onenter = function(inst)
            inst.Physics:Stop()

            inst.DynamicShadow:Enable(false)
            inst.components.health:SetInvincible(true)

            inst.AnimState:PlayAnimation("fly_back_loop",true)

            local x,y,z = inst.Transform:GetWorldPosition()
            inst.Transform:SetPosition(x,10,z)
            inst.Physics:SetMotorVel(0,-10+math.random()*2,0)
        end,

        onupdate= function(inst)
            inst.Physics:SetMotorVel(0,-10+math.random()*2,0)
            local pt = Point(inst.Transform:GetWorldPosition())
            if pt.y <= .1 or inst:IsAsleep() then
                pt.y = 0
                inst.Physics:Stop()
                inst.Physics:Teleport(pt.x,pt.y,pt.z)
                inst.DynamicShadow:Enable(true)
                inst.components.health:SetInvincible(false)
                inst.sg:GoToState("idle", "fly_back_pst")
            end
        end,

        timeline = {
            TimeEvent(3*FRAMES, function(inst) inst:PushEvent("wingdown") end ),
            TimeEvent(14*FRAMES, function(inst) inst:PushEvent("wingdown") end ),
            TimeEvent(24*FRAMES, function(inst) inst:PushEvent("wingdown") end ),
            TimeEvent(34*FRAMES, function(inst) inst:PushEvent("wingdown") end ),
            TimeEvent(41*FRAMES, function(inst) inst:PushEvent("wingdown") end ),
        },

    },

    State{
        name = "flybackup",
        tags = {"flight", "busy"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.DynamicShadow:Enable(false)
            inst.components.health:SetInvincible(true)
            inst.AnimState:PlayAnimation("fly_back_loop",true)
            inst.Physics:SetMotorVel(0,10+math.random()*2,0)
        end,

        onupdate= function(inst)
            inst.Physics:SetMotorVel(0,10+math.random()*2,0)
            local pt = Point(inst.Transform:GetWorldPosition())
			local home = inst.components.homeseeker ~= nil and inst.components.homeseeker.home or nil
            if pt.y >= 10 then
				
				if home ~= nil and home:IsValid() and home.components.lootdropper ~= nil then
				home:DoTaskInTime(1+math.random(), function(home)
				home.AnimState:PlayAnimation("spit")
				home.AnimState:PushAnimation("swinglong")
				home:DoTaskInTime(0.3, function(home) home.components.lootdropper:DropLoot(pt) end) --Drop loot only once every time it goes home.
				end)
				inst.bugcount = inst.bugcount - 3
				end
                inst:PerformBufferedAction()
            end
        end,

        timeline = {
            TimeEvent(3*FRAMES, function(inst) inst:PushEvent("wingdown") end ),
            TimeEvent(14*FRAMES, function(inst) inst:PushEvent("wingdown") end ),
            TimeEvent(24*FRAMES, function(inst) inst:PushEvent("wingdown") end ),
            TimeEvent(34*FRAMES, function(inst) inst:PushEvent("wingdown") end ),
            TimeEvent(41*FRAMES, function(inst) inst:PushEvent("wingdown") end ),
        },

    },
	
    State{
        name = "taunt",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
        end,

        timeline = 
        {
            TimeEvent(1*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/vampirebat/taunt") end ),
			TimeEvent(3*FRAMES, function(inst) inst:PushEvent("wingdown") end ),
            TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/vampirebat/breath")  end ),
			TimeEvent(14*FRAMES, function(inst) inst:PushEvent("wingdown") end ),
			TimeEvent(24*FRAMES, function(inst) inst:PushEvent("wingdown") end ),
			TimeEvent(41*FRAMES, function(inst) inst:PushEvent("wingdown") end ),
        },
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "eat",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
			inst:PerformBufferedAction()
            inst.AnimState:PlayAnimation("eat_pre", false)
			inst.AnimState:PushAnimation("eat",false)
        end,

        onexit = function(inst)

        end,

        timeline = 
        {
			TimeEvent(3*FRAMES, function(inst) inst:PushEvent("wingdown") end ),
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/vampirebat/bite") end),
			TimeEvent(14*FRAMES, function(inst) inst:PushEvent("wingdown") end ),
			TimeEvent(28*FRAMES, function(inst) inst:PushEvent("wingdown") end ),
			TimeEvent(42*FRAMES, function(inst) inst:PushEvent("wingdown") end ),
        },

        events = 
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end)
        },
    },

    State{
        name = "eat_loop",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("eat_loop", true)
            inst.sg:SetTimeout(1+math.random()*2)
        end,

        ontimeout= function(inst)
            inst.lastmeal = GetTime()
            inst:PerformBufferedAction()
            inst.sg:GoToState("idle")
        end,

        timeline = 
        {
			TimeEvent(7*FRAMES, function(inst) inst:PushEvent("wingdown") inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/chew") end ),
			TimeEvent(17*FRAMES, function(inst) inst:PushEvent("wingdown") inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/chew") end ),
        },

        events = 
        {
            EventHandler("attacked", function(inst) inst.components.inventory:DropEverything() inst.sg:GoToState("idle") end) --drop food
        },
    },

    State{
        name = "glide",
        tags = {"idle", "flying", "busy"},
        onenter= function(inst)
            inst.DynamicShadow:Enable(false)
            inst.AnimState:PlayAnimation("glide", true)
            inst.Physics:SetMotorVelOverride(0,-25,0)        
        end,
        
        onupdate= function(inst)
            inst.Physics:SetMotorVelOverride(0,-25,0)
            local pt = Point(inst.Transform:GetWorldPosition())            
            if pt.y <= .1 then
                inst.Physics:ClearMotorVelOverride()
                pt.y = 0
                inst.Physics:Stop()
                inst.Physics:Teleport(pt.x,pt.y,pt.z)
            --    inst.AnimState:PlayAnimation("land")
                inst.DynamicShadow:Enable(true)
              
             --   inst.sg:GoToState("idle")                
                inst.sg:GoToState("land")   
            end
        end,

        onexit = function(inst)
            if inst:GetPosition().y > 0 then
                local pos = inst:GetPosition()
                pos.y = 0
                inst.Transform:SetPosition(pos:Get())
            end
           -- inst.components.knownlocations:RememberLocation("landpoint", inst:GetPosition())
        end, 
    },     

    State{
        name = "land",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("land", false)
            --inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/vampire_bat/land")
        end,

        events = 
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end)
        },
    },

    State{
        name = "boop",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("boop", false)
            --inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/vampire_bat/land")
        end,

        events = 
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end)
        },
    },
    State{
        name = "death_true",
        tags = {"busy"},
        
        onenter = function(inst)
			--TheNet:Announce("Code Ran")
            inst.SoundEmitter:PlaySound("UCSounds/Scorpion/death")
			inst.Physics:Stop()
            inst.AnimState:PlayAnimation("death_pre")
			inst.AnimState:PushAnimation("death_loop")
        end,
		timeline = {
			TimeEvent(1*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/vampirebat/death") end),
			TimeEvent(4*FRAMES, function(inst) inst:PushEvent("wingdown")	end),
			TimeEvent(45*FRAMES, Explode),			
		},

    },	
}

local walkanims = 
{
    startwalk = "move_pre",
    walk = "move",
    stopwalk = "move_pst",
}

CommonStates.AddWalkStates(states,
{
    starttimeline =
    {
        TimeEvent(1*FRAMES, function(inst) inst:PushEvent("wingdown") end ),
    },

    walktimeline = 
    {
        TimeEvent(7*FRAMES, function(inst) inst:PushEvent("wingdown") end ),
        --TimeEvent(5*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/vampirebat/breath")  end ),
        TimeEvent(17*FRAMES, function(inst) inst:PushEvent("wingdown") end ),
    },

    endtimeline =
    {
        TimeEvent(1*FRAMES, function(inst) inst:PushEvent("wingdown") end ),
    },

},  walkanims, true)


CommonStates.AddSleepStates(states,
{
    starttimeline = 
    {
        TimeEvent(7*FRAMES, function(inst) inst:PushEvent("wingdown") end ),
        --TimeEvent(5*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/vampirebat/breath")  end ),
        TimeEvent(17*FRAMES, function(inst) inst:PushEvent("wingdown") end ),    
    },

    sleeptimeline = 
    {
        TimeEvent(23*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/vampirebat/breath") end),
    },

    endtimeline =
    {
        TimeEvent(13*FRAMES, function(inst) inst:PushEvent("wingdown") end ),
    },
})

CommonStates.AddCombatStates(states,
{
    attacktimeline = 
    {
        
        -- TimeEvent(7* FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/vampire_bat/bite") end),
        TimeEvent(7*FRAMES, function(inst) inst:PushEvent("wingdown") end),
        TimeEvent(8* FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/vampirebat/bite") end),
        TimeEvent(14*FRAMES, function(inst) 
        inst.components.combat:DoAttack()
        inst:PushEvent("wingdown")
        end),
    },

    hittimeline =
    {
        TimeEvent(1*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/vampirebat/hurt")	end),
        TimeEvent(3*FRAMES, function(inst) inst:PushEvent("wingdown")	end),
    },

    deathtimeline =
    {
        TimeEvent(0*FRAMES, function(inst) inst.sg:GoToState("death_true") end),
    },
})

CommonStates.AddFrozenStates(states)


return StateGraph("fruitbat", states, events, "boop", actionhandlers)