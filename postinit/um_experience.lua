--decided to keep all skilltree experience changes centered here for easier access of all parts. - Atoba
--GOD this is a mess.
--TODO: UNMESS THIS

local function ResetSkills(prefab)
    print("Hello! RESET THE FUCKING SKILL TREES DAMNIT")
    if ThePlayer ~= nil then
        GLOBAL.TheSkillTree:RespecSkills(GLOBAL.ThePlayer.prefab)
        GLOBAL.TheSkillTree.skillxp[GLOBAL.ThePlayer.prefab] = GLOBAL.TheWorld.state.cycles --reset skillpoints.
    else
        GLOBAL.TheSkillTree:RespecSkills(prefab)
        GLOBAL.TheSkillTree.skillxp[prefab] = GLOBAL.TheWorld.state.cycles --reset skillpoints.
    end

    GLOBAL.TheGenericKV:SetKV("wathgrithr_instantsong_uses", "0")
    GLOBAL.TheGenericKV:SetKV("wathgrithr_container_unlocked", "0")
    GLOBAL.TheGenericKV:SetKV("wathgrithr_horn_played", "0")
    GLOBAL.TheGenericKV:SetKV("celestialchampion_killed", "0")
    GLOBAL.TheGenericKV:SetKV("fuelweaver_killed", "0")
end



AddClientModRPCHandler("UncompromisingSurvival", "ResetSkills", ResetSkills)

local env = env
GLOBAL.setfenv(1, GLOBAL)




env.AddComponentPostInit("skilltreeupdater", function(self)
    self.skip_validation = true
end)



local TheSkillTree = require("skilltreedata")()
local function ResetSkilltree(character)
    if TheSkillTree ~= nil then
        TheSkillTree.save_enabled = false
    end
    print(character.hasresetskills)
    print(character)
    print(character.userid) --nil??
    if character.hasresetskills ~= true then
        print("DO THE FUCKIN' THING")
        SendModRPCToClient(GetClientModRPC("UncompromisingSurvival", "ResetSkills"), ThePlayer ~= nil and ThePlayer.userid or character.userid, character.prefab)

        print("TASK")
        local skilltreeupdater = character.components.skilltreeupdater

        if skilltreeupdater ~= nil and skilltreeupdater:GetActivatedSkills() ~= nil then
            for k, v in pairs(skilltreeupdater:GetActivatedSkills()) do
                print(k, v)

                skilltreeupdater:DeactivateSkill(k)
            end
        end


        print('\n')

        if skilltreeupdater ~= nil then
            print("skilltreeupdater ~= nil")
            skilltreeupdater.skilltree.skillxp[character.prefab] = TheWorld.state.cycles --reset skillpoints.
        end
        character.hasresetskills = true
    end
end

env.AddPrefabPostInit("world", function(inst)
    TheWorld:ListenForEvent("ms_newplayercharacterspawned", function(inst, data)
        print("ms_newplayercharacterspawned")
        if data ~= nil and data.mode ~= nil and data.player ~= nil then
            print("data stuff not nil")
            print(data.mode)
            print(data.player)
            if data.mode ~= "Load" then
                print("reset damnit")
                ResetSkilltree(data.player)
            end
        end
    end)
end)

env.AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end

    inst:ListenForEvent("boss_defeated", function(inst, boss)
        if inst.bosses_defeated == nil then inst.bosses_defeated = {} end
        if not inst.bosses_defeated[boss] then
            inst.bosses_defeated[boss] = true
            inst.components.skilltreeupdater:AddSkillXP(10)
        end
    end)


    local _OnSave = inst.OnSave

    inst.OnSave = function(inst, data, ...)
        data.bosses_defeated = inst.bosses_defeated
        data.hasresetskills = inst.hasresetskills
        if _OnSave ~= nil then
            return _OnSave(inst, data, ...)
        end
    end

    local _OnLoad = inst.OnLoad

    inst.OnLoad = function(inst, data, ...)
        if data then
            if data.bosses_defeated then
                inst.bosses_defeated = data.bosses_defeated
            end
            if data.hasresetskills then
                inst.hasresetskills = data.hasresetskills
                if not inst.hasresetskills then
                    ResetSkilltree(inst)
                end
            end
        end

        if _OnLoad ~= nil then
            return _OnLoad(inst, data, ...)
        end
    end
end)

env.AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return end
    if inst ~= nil and inst:HasTag("epic") then
        inst:ListenForEvent("death", function(inst)
            for k, v in pairs(AllPlayers) do
                v:PushEvent("boss_defeated", inst.prefab)
            end
        end)
    end
end)
