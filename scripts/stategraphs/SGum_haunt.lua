require("stategraphs/commonstates")

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

local function OnAnimOverRemoveAfterSounds(inst)
    if inst.sg.mem.soundcache == nil or next(inst.sg.mem.soundcache) == nil then
        inst:Remove()
    else
        inst:Hide()
        inst.sg.statemem.readytoremove = true
    end
end

local events =
{
}

local function Dissappear_or_Death(inst)
	inst.disappear_count = inst.disappear_count + 1
	
	if inst.disappear_count >= 4 then
		inst.sg:GoToState("death")
	else
		inst.sg:GoToState("disappear")
	end
end

local function StartHaunting(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local targets = TheSim:FindEntities(x, y, z, 20, { "player" })
			
	for i, v in pairs(targets) do
		if v ~= nil then
			inst.queue_haunt = true
			
			if inst.haunt_target ~= nil and inst.haunt_target.components and inst.haunt_target.components.container ~= nil then
				local slots = inst.haunt_target.components.container.numslots
					
				for i = 1, slots do
					local item = inst.haunt_target.components.container:GetItemInSlot(i)
					if item ~= nil then
						return
					end
				end
			end
			
			inst:StartAttackingTarget(v)
				
			return
		end
	end
end

local states=
{
    State{
        name = "idle",
        tags = { "idle" },

        onenter = function(inst)
			inst.AnimState:PlayAnimation("idle")
        end,

        events=
        {
            EventHandler("animover", function(inst) 
				if inst.queue_disappear then
					Dissappear_or_Death(inst)
				elseif inst.queue_haunt then
					inst.sg:GoToState("haunt_pre")
				else
					inst.sg:GoToState("idle") 
				end
			end)
        },
    },
	
    State{
        name = "haunt_pre",
        tags = { "busy" },

        onenter = function(inst)
            PlayExtendedSound(inst, "taunt")
			inst.AnimState:PlayAnimation("haunt_pre")
        end,

        events=
        {
            EventHandler("animover", function(inst) 
				if inst.queue_disappear then
					inst.sg:GoToState("haunt_pst")
				else
					inst.sg:GoToState("haunt")
				end
			end)
        },
    },
	
    State{
        name = "haunt",
        tags = { "busy" },

        onenter = function(inst)
			if inst.haunt_target ~= nil then
				print("Haunt Target ~= nil "..inst.haunt_target.prefab)
				if inst.haunt_target.components and inst.haunt_target.components.container then
				print("inst.haunt_target.components.container")
					local slots = inst.haunt_target.components.container.numslots
					
					for i = 1, slots do
						local item = inst.haunt_target.components.container:GetItemInSlot(i)
						if item ~= nil then
							print("item ~= nil")
							inst.haunt_target.components.container:DropItemBySlot(i)
							Launch2(item, inst, 7, 3, 2, 1, 5)
							
							StartHaunting(inst)
							break
						end
					end
				end
			end
		
			inst.AnimState:PlayAnimation("haunt_idle")
        end,

        events=
        {
            EventHandler("animover", function(inst) 
				if inst.queue_disappear then
					inst.sg:GoToState("haunt_pst")
				elseif inst.stop_haunting then
					inst.sg:GoToState("haunt_pst")
				else
					inst.sg:GoToState("haunt")
				end
			end)
        },
    },
	
    State{
        name = "haunt_pst",
        tags = { "busy" },

        onenter = function(inst)
			inst.AnimState:PlayAnimation("haunt_pst")
			inst.queue_haunt = false
			inst.stop_haunting = false
        end,

        events=
        {
            EventHandler("animover", function(inst)
				if inst.queue_disappear then
					Dissappear_or_Death(inst)
				else
					inst.sg:GoToState("idle")
				end
			end)
        },
    },

    State{
        name = "appear",
        tags = { "busy" },

        onenter = function(inst)
			if inst.haunt_target == nil then
				local x, y, z = inst.Transform:GetWorldPosition()
				local structures = TheSim:FindEntities(x, y, z, 30, { "structure" })
					
				for i, v in ipairs(structures) do
					if v ~= nil then
						local x1, y1, z1 = v.Transform:GetWorldPosition()
						local players = TheSim:FindEntities(x1, y1, z1, 8, { "player" })
								
						if players == nil or #players == 0 then
							inst.haunt_target = v
							inst.Transform:SetPosition(x1, 0, z1)

							break
						end
					end
				end
			end

			inst.stop_haunting = false
			inst.queue_disappear = false
			
			if inst.haunt_task ~= nil then
				inst.haunt_task:Cancel()
			end
			
			inst.haunt_task = inst:DoPeriodicTask(10, StartHaunting)
		
            inst.AnimState:PlayAnimation("appear")
            inst.Physics:Stop()
            PlayExtendedSound(inst, "appear")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end)
        },
    },

    State{
        name = "disappear",
        tags = { "busy" },

        onenter = function(inst)
            PlayExtendedSound(inst, "disappear")
            inst.AnimState:PlayAnimation("disappear")
			
			inst.queue_disappear = false
			inst.queue_haunt = false
        end,

        events =
        {
            EventHandler("animover", function(inst)
				local x, y, z = inst.Transform:GetWorldPosition()
				local structures = TheSim:FindEntities(x, y, z, 30, { "structure" })
				
				for i, v in ipairs(structures) do
					if v ~= nil then
						local x1, y1, z1 = v.Transform:GetWorldPosition()
						local players = TheSim:FindEntities(x1, y1, z1, 8, { "player" })
							
						if players == nil or #players == 0 then
							inst.haunt_target = v
							inst.Transform:SetPosition(x1, 0, z1)
							
							break
						end
					end
				end
				
				inst.sg:GoToState("appear") 
			end)
        },
    },

    State{
        name = "death",
        tags = { "busy" },

        onenter = function(inst)
            PlayExtendedSound(inst, "death")
            inst.AnimState:PlayAnimation("disappear")
        end,

        events =
        {
            EventHandler("animover", OnAnimOverRemoveAfterSounds),
        },
    },
}

return StateGraph("um_haunt", states, events, "appear")