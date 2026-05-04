local loot_table = {

    ["um_gemology_geode_red"] =
    {
        notgemloot = {
            red_cap = 1,
            rocks = 1,
            log = 0.5,
            spore_medium = 0.5,
        },
        gemloot = {
            um_gemologyredgem1 = 1,
            um_gemologyredgem2 = 1,
            um_gemologyorangegem1 = 0.5,
            redgem = 0.5,
        },
    },

    ["um_gemology_geode_green"] =
    {
        notgemloot = {
            green_cap = 1,
            rocks = 1,
            log = 0.5,
            spore_short = 0.5,
        },
        gemloot = {
            um_gemologygreengem1 = 1,
            um_gemologygreengem2 = 1,
            um_gemologypalegem1 = 0.5,
            greengem = 0.05,
        },
    },

    ["um_gemology_geode_blue"] =
    {
        notgemloot = {
            blue_cap = 1,
            rocks = 1,
            log = 0.5,
            spore_tall = 0.5,
        },
        gemloot = {
            um_gemologybluegem1 = 1,
            um_gemologybluegem2 = 1,
            um_gemologypurplegem2 = 0.5,
            bluegem = 0.5,
        },
    },
    ["um_gemology_geode_guano"] =
    {
        notgemloot = {
            guano = 1,
            rocks = 1,
            nitre = 0.5,
            flint = 0.5,
        },
        gemloot = {
            um_gemologyyellowgem2 = 1,
            um_gemologyredgem2 = 1,
            um_gemologypurplegem2 = 0.5,
            yellowgem = 0.1,
            redgem = 0.5,
        },
    },
    ["um_gemology_geode_lobster"] =
    {
        notgemloot = {
            smallmeat = 1,
            rocks = 1,
            nitre = 0.5,
            flint = 0.5,
        },
        gemloot = {
            um_gemologyyellowgem1 = 1,
            um_gemologypalegem2 = 1,
            um_gemologyorangegem2 = 1,
            um_gemologybluegem1 = 1,
            yellowgem = 0.1,
            redgem = 0.5,
        },
    },
    ["um_gemology_geode_glass"] =
    {
        notgemloot = {
            moonglass = 1,
        },
        gemloot = {
            um_gemologyyellowgem2 = 1,
            um_gemologypalegem1 = 1,
            um_gemologybluegem1 = 1,
            um_gemologygreengem1 = 1,
            yellowgem = 0.1,
            bluegem = 0.5,
        },
    },
    ["um_gemology_geode_slime"] =
    {
        notgemloot = {
            poop = 0.5,
            rocks = 0.5,
            cave_banana = 0.5,
        },
        gemloot = {
            um_gemologybluegem2 = 1,
            um_gemologyredgem1 = 1,
            um_gemologypalegem1 = 1,
            um_gemologypalegem2 = 1,
            bluegem = 0.5,
            redgem = 0.5,
        },
    },
    ["um_gemology_geode_ruins"] =
    {
        notgemloot = {
            gears = 1,
            trinket_6 = 1,
            trinket_1 = 1,
            thulecite = 0.25,
        },
        gemloot = {
            um_gemologygreengem1 = 1,
            um_gemologyyellowgem1 = 1,
            um_gemologypurplegem2 = 1,
            um_gemologypurplegem1 = 1,
            bluegem = 0.5,
            redgem = 0.5,
            purplegem = 0.5,
            orangegem = 0.25,
            yellowgem = 0.25,
            greengem = 0.25,
        },
    },
    ["um_gemology_geode_sink"] =
    {
        notgemloot = {
            rocks = 1,
            cutgrass = 1,
            twigs = 1,
            foliage = 1,
        },
        gemloot = {
            um_gemologygreengem1 = 1,
            um_gemologyyellowgem2 = 1,
            um_gemologyorangegem2 = 1,
            um_gemologyorangegem1 = 1,
            orangegem = 0.1,
            greengem = 0.05,
            yellowgemgem = 0.05,
        },
    },
    ["um_gemology_geode_vent"] =
    {
        notgemloot = {
            rocks = 2,
            nitre = 1,
        },
        gemloot = {
            um_gemologypurplegem2 = 1,
            um_gemologypurplegem1 = 1,
            um_gemologyorangegem2 = 1,
            purplegem = 0.1,
            orangegem = 0.05,
        },
    },
}
local function GetGeodeSourcesFromGem(gem_name)
    local sources = {}
    for geode,data in pairs(loot_table) do
        local gemloot = data.gemloot

        if gemloot[gem_name] then
            table.insert(sources, geode)
        end
    end
end

return loot_table, GetGeodeSourcesFromGem
