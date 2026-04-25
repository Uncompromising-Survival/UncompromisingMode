-- ADD ALL THE SKILL THREE BACKGROUND IMAGES HERE

local OldGetSkilltreeBG = GLOBAL.GetSkilltreeBG
function GLOBAL.GetSkilltreeBG(imagename, ...)
    if imagename == "wathgrithr_background.tex" and TUNING.DSTU.WATHGRITHR_REWORK == 1 then
        return "images/wathgrithr_rework_skilltree.xml"

    elseif imagename == "wolfgang_background.tex" and GetModConfigData("wolfgang") then
        return "images/wolfgang_rework_skilltree.xml"
        
    --ADD OTHER CHARACTERS HERE
    
    else
        return OldGetSkilltreeBG(imagename, ...)
    end
end

-- IMPORT ALTERNATE ICONS HERE
-- RegisterSkilltreeIconsAtlas("name_of_the_atlas", "name_of_the_skill")

-- Wortox
RegisterSkilltreeIconsAtlas("images/wortox_lunar_stealer.xml", "wortox_lunar_stealer.tex")
RegisterSkilltreeIconsAtlas("images/wortox_lunar_summoner.xml", "wortox_lunar_summoner.tex")
RegisterSkilltreeIconsAtlas("images/wortox_shadow_weaver.xml", "wortox_shadow_weaver.tex")

-- Wigfrid
RegisterSkilltreeIconsAtlas("images/wathgrithr_rework_skilltree.xml", "wathgrithr_arsenal_shield_2.tex")
RegisterSkilltreeIconsAtlas("images/wathgrithr_rework_skilltree.xml", "wathgrithr_allegiance_shadow.tex")
RegisterSkilltreeIconsAtlas("images/wathgrithr_rework_skilltree.xml", "wathgrithr_arsenal_spear_1.tex")
RegisterSkilltreeIconsAtlas("images/wathgrithr_rework_skilltree.xml", "wathgrithr_arsenal_spear_2.tex")

-- Wormwood
RegisterSkilltreeIconsAtlas("images/wormwood_flytrap.xml", "wormwood_flytrap.tex")
RegisterSkilltreeIconsAtlas("images/wormwood_originator.xml", "wormwood_originator.tex")
RegisterSkilltreeIconsAtlas("images/wormwood_sympathetic_blooming.xml", "wormwood_sympathetic_blooming.tex")
RegisterSkilltreeIconsAtlas("images/wormwood_resilient_crops1.xml", "wormwood_resilient_crops1.tex")
RegisterSkilltreeIconsAtlas("images/wormwood_resilient_crops2.xml", "wormwood_resilient_crops2.tex")
RegisterSkilltreeIconsAtlas("images/wormwood_resilient_crops3.xml", "wormwood_resilient_crops3.tex")
RegisterSkilltreeIconsAtlas("images/wormwood_prick_adept.xml", "wormwood_prick_adept.tex")
RegisterSkilltreeIconsAtlas("images/wormwood_armor_bramble2.xml", "wormwood_armor_bramble2.tex")
RegisterSkilltreeIconsAtlas("images/wormwood_eqex.xml", "wormwood_eqex.tex")
RegisterSkilltreeIconsAtlas("images/wormwood_mutations.xml", "wormwood_mutations.tex")