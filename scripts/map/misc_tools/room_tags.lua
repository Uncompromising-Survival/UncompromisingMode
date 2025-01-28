-----KoreanWaffle's Task/Room Tag Adding Code
-- In order to add new tags, this must run... Keeping it central to save space
local roomTags = { "hoodedcanopy", "rattygas", "ratkey1", "mosaic" }
AddGlobalClassPostConstruct("map/storygen", "Story", function(self)
    for k, v in pairs(roomTags) do
        self.map_tags.Tag[v] = function(tagdata) return "TAG", v end
    end
end)
