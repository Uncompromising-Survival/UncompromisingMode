-- From Craft Pot --

-- define or redefine global variable to store tag data
global("FOODTAGDEFINITIONS")
FOODTAGDEFINITIONS = FOODTAGDEFINITIONS or {}

--
-- A public API for ingredient tag management
-- This function should be used by modders to add info about food tags, specifically atlas
-- Function performs merge, so it is safe to call multiple times or with different data
--
-- So Far TagData only takes following keys: atlas, tex, name
global("AddFoodTag")
AddFoodTag = function(tag, data)
    local mergedData = FOODTAGDEFINITIONS[tag] or {}

    for k, v in pairs(data) do
        mergedData[k] = v
    end

    FOODTAGDEFINITIONS[tag] = mergedData
end

-- common tags
AddFoodTag('insectoid', { name= 'Insectoid', atlas="images/um_food_tags/insectoid.xml" })
AddFoodTag('foliage', { name= 'Foliage', atlas="images/um_food_tags/foliage.xml" })
AddFoodTag('lice', { name= 'Rice/Lice', atlas="images/um_food_tags/lice.xml" })
AddFoodTag('plantmeat', { name= 'Leafy Meats', atlas="images/um_food_tags/plantmeat.xml" })
AddFoodTag('seed', { name= 'Birchnuts', atlas="images/um_food_tags/seed.xml" })
FOODTAGDEFINITIONS['frozen'].atlas="images/um_food_tags/frozen.xml"
FOODTAGDEFINITIONS['monster'].atlas="images/um_food_tags/monster.xml"
FOODTAGDEFINITIONS['egg'].atlas="images/um_food_tags/egg.xml"
FOODTAGDEFINITIONS['inedible'].atlas="images/um_food_tags/inedible.xml"
FOODTAGDEFINITIONS['magic'].atlas="images/um_food_tags/magic.xml"
--AddFoodTag('frozen', { name="Ice", atlas="images/food_tags.xml" })