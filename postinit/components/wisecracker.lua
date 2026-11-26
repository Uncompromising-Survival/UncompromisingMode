local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
env.AddComponentPostInit("wisecracker", function(self, inst)
    self.inst = inst

    inst:WatchWorldState("phase", function(inst, phase)
        if inst:HasTag("wormwood_vetcurse") and phase == "dusk" and not TheWorld:HasTag("cave") then
            inst.components.talker:Say(GetString(inst, "ANNOUNCE_DUSK"))
        end
    end)

    inst:ListenForEvent("onpresink_portable", function(inst, data)
        inst.components.talker:Say(GetString(inst, "ANNOUNCE_PORTABLEBOAT_SINK"))
    end)

    -- Hook up these to a string.
    inst:ListenForEvent("himalaya_dormant", function(inst, data)
		inst.components.talker:Say(GetString(inst, "ANNOUNCE_HIMALAYA_DORMANT"))
	end)

    inst:ListenForEvent("himalaya_shielded", function(inst, data)
		inst.components.talker:Say(GetString(inst, "ANNOUNCE_HIMALAYA_SHIELDED"))
	end)

    inst:ListenForEvent("himalaya_resetting", function(inst, data)
		inst.components.talker:Say(GetString(inst, "ANNOUNCE_HIMALAYA_RESETTING"))
	end)
end)
