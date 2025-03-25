

local skills = {

}

if SkillTreeDefs.SKILLTREE_DEFS["wormwood"] ~= nil then --in case another mod turns it nil beforehand (disabling skill tree)
    SkillTreeDefs.SKILLTREE_DEFS["wormwood"] = {}
    SkillTreeDefs.CreateSkillTreeFor("wormwood", skills)
    SkillTreeDefs.SKILLTREE_ORDERS["wormwood"] = ORDERS
end
