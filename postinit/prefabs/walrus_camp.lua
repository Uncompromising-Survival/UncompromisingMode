local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local WALRUS_MUST = {"walrus"}
local function OnMegaFlare(inst, data)
    inst:DoTaskInTime(5 + (math.random() * 20), function()
        if data.sourcept and TheWorld.Map:IsVisualGroundAtPoint(data.sourcept.x,data.sourcept.y,data.sourcept.z) then
            
            local party_active = nil
            local engaged = nil
            local spawnpoint = nil

            -- ARE THE HUNTERS ENGAGED ALREADY?
            if inst.data.children then
                for k in pairs(inst.data.children) do
                    if k:IsValid() then
                        party_active = true

                        local x,y,z = k.Transform:GetWorldPosition()
                        local players = FindPlayersInRange(x,y,z, 35)
                        if #players > 0 then
                            engaged = true
                        end

                        if k.components.combat.target then
                            engaged = true
                        end
                    end
                end
            end
            -- GET A PLAYER NEAR THE BURST
            if not engaged and party_active then
                local players = FindPlayersInRange(data.sourcept.x, data.sourcept.y, data.sourcept.z, 35)

                --find a spot outside player vision of that player 
                if #players > 0 then
                    local offset = FindValidPositionByFan(math.random()*TWOPI, 40, 32, function(testoffset)
                        local newpt = data.sourcept + testoffset

                        if TheWorld.Map:IsAboveGroundAtPoint(newpt.x, newpt.y, newpt.z) then
                            local testplayers = FindPlayersInRange(newpt.x, newpt.y, newpt.z, 35)
                            if #testplayers == 0 then
                                return true
                            end
                        end
                    end)

                    if offset then
                        spawnpoint = data.sourcept + offset
                    end
                end
            end

            --ARE THERE OTHER WALRUS NEARBY ALREADY?
            if spawnpoint then
                local ents = TheSim:FindEntities(data.sourcept.x,0,data.sourcept.z, 70, WALRUS_MUST)
                if #ents > 0 then
                    spawnpoint = nil
                end
            end

            -- SPAWN THEM IN
            if party_active and spawnpoint and not engaged then
                for k in pairs(inst.data.children) do
                    local players = FindPlayersInRange(spawnpoint.x,spawnpoint.y,spawnpoint.z, 40)
                    k.Transform:SetPosition(spawnpoint.x,spawnpoint.y,spawnpoint.z)
                    k.components.combat:SuggestTarget(players[1])
                    k:AddTag("flare_summoned")
                end
            end
        end
    end)
end

env.AddPrefabPostInit("walrus_camp", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	
    inst:ListenForEvent("megaflare_detonated", function(src,data) OnMegaFlare(inst,data) end, TheWorld)	
end)
