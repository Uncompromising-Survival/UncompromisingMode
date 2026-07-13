--[[ AXE
	Buff webber's healing item to buff the max health of spiders instead of just healing them.
    Buffs are individual prefabs, many of UM's buffs are defined within uncompromising_foodbuffs.lua, search for spider_maxhealth there.
    The buff will need to be revised if webber or spiders are able to buff their max health through alternative means.
    There is no official "clean" way to do it (remember old max health values) that Klei has set up. So it's case-by-case for now.
    It would be ideal to do something akin to damage multiplier has a list of external modifiers.
]]
AddPrefabPostInit("spider_healer_item", function(inst)
    if not TheWorld.ismastersim then return end

    -- healer is already part of this item, no need for a check.
    local Healer = inst.components.healer
    local _onhealfn = Healer.onhealfn

    local function OnHealFn(inst, target, doer)
        _onhealfn(inst,target,doer)

        -- Buff Maximum Health of Webber and nearby Spiders
        if target:HasTag("spiderwhisperer") then
            target.components.debuffable:AddDebuff("buff_spider_maxhealth", "buff_spider_maxhealth")
        end

        local x,y,z = inst.Transform:GetWorldPosition()
        local other_spiders = TheSim:FindEntities(x, y, z, TUNING.SPIDER_HEALING_ITEM_RADIUS, SPIDER_TAGS, SPIDER_IGNORE_TAGS)

        for _, spider in ipairs(other_spiders) do
            if not spider.components.debuffable then
                spider:AddComponent("debuffable")
            end
            spider.components.debuffable:AddDebuff("buff_spider_maxhealth", "buff_spider_maxhealth")
        end

    end
    Healer:SetOnHealFn(OnHealFn)
end)
