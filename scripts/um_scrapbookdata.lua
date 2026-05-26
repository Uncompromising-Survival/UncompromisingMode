--for reference of what kind of data goes here, take a look at vanilla scripts/screens/redux/scrapbookdata

return {
    --some examples. Does not include every field.
    --[[
    alterguardian_phase4_lunarrift = {name="alterguardian_phase4_lunarrift", tex="alterguardian_phase4_lunarrift.tex", subcat="gestalt", type="giant", prefab="alterguardian_phase4_lunarrift", sanityaura=1.6666666666667, health=16000, damage=168.75, planardamage=35, build="wagboss_lunar", bank="wagboss_lunar", anim="scrapbook", symbolcolours={{"lb_glow", "1", "1", "1", "0.375"}}, deps={"gears", "lunar_seed", "purebrilliance", "sketch", "trinket_6", "wagstaff_item_1", "wagstaff_item_2"}, notes={lunar_aligned=true}},
    alterguardianhat = {name="alterguardianhat", tex="alterguardianhat.tex", subcat="hat", type="item", prefab="alterguardianhat", build="hat_alterguardian", bank="alterguardianhat", anim="anim", dapperness=0.16666666666667, snowmandecor=true, deps={"alterguardianhatshard"}},
    alterguardianhatshard = {name="alterguardianhatshard", tex="alterguardianhatshard.tex", type="item", prefab="alterguardianhatshard", build="alterguardianhatshard", bank="alterguardianhatshard", anim="idle"},
    amulet = {name="amulet", tex="amulet.tex", subcat="clothing", type="item", prefab="amulet", finiteuses=20, build="amulets", bank="amulets", anim="redamulet", dapperness=0.033333333333333, deps={"goldnugget", "nightmarefuel", "redgem"}, specialinfo="REDAMULET"},
    anchor = {name="anchor", tex="anchor.tex", subcat="seafaring", type="thing", prefab="anchor", build="boat_anchor", bank="boat_anchor", anim="untethered_idle_loop", workable="HAMMER", burnable=true, deps={"anchor_item", "boards", "cutstone", "rope"}},
    anchor_item = {name="anchor_item", tex="anchor_item.tex", subcat="seafaring", type="item", prefab="anchor_item", build="seafarer_anchor", bank="seafarer_anchor", anim="idle", fueltype="BURNABLE", fuelvalue=180, burnable=true, deps={"anchor", "boards", "cutstone", "rope"}},
    battlesong_shadowaligned = {name="battlesong_shadowaligned", tex="battlesong_shadowaligned.tex", subcat="battlesong", type="item", prefab="battlesong_shadowaligned", build="battlesongs", bank="battlesongs", anim="battlesong_shadowaligned", fueltype="BURNABLE", fuelvalue=15, burnable=true, craftingprefab="wathgrithr", deps={"featherpencil", "horrorfuel", "papyrus"}},
    ]]
    cursed_antler = {name="cursed_antler", tex="cursed_antler.tex", subcat="veteranscurse", type="item", prefab="cursed_antler", weapondamage=34, build="cursed_antler", bank="cursed_antler", anim="idle", deps={"boneshard", "deerclops"}, specialinfo="CURSED_ANTLER"},


    um_bee_moon = {name="um_bee_moon", tex="um_bee_moon.tex", subcat="insect", type="creature", prefab="um_bee_moon", health=100, damage=10, stacksize=20, build="bee_angry_build", bank="bee", anim="idle", animoffsety=150, perishable=960, workable="NET", deps={"um_meathoney", "houndstooth"}},
}
