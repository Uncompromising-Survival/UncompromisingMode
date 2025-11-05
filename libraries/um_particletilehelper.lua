local UMENV = env
GLOBAL.setfenv(1, GLOBAL)

UM_ParticleTileTextureBuilder = Class(function(self, index_width, index_height)
    local primary_index
    local index_x, index_y
    local mask_to_index
    local next_mask

    local function GetNextMask()
        local mask = next_mask
        next_mask = bit.lshift(next_mask, 1)
        return mask
    end

    local function UpdateNextIndex()
        index_x = index_x + 1
        if index_x == index_width then
            index_x = 0
            index_y = index_y - 1
        end
    end

    local function GetTextureIndex()
        return (index_y * index_width + index_x) + 1
    end

    local function BuildTextureIndexForMask(required, ...)
        local optionals = {...}
        local optional_count = #optionals

        local index = GetTextureIndex()

        mask_to_index[required] = index

        if optional_count == 1 then
            local o1 = optionals[1]
            mask_to_index[required+o1] = index
        elseif optional_count == 2 then
            local o1 = optionals[1]
            local o2 = optionals[2]
            mask_to_index[required+o1] = index
            mask_to_index[required+o2] = index
            mask_to_index[required+o1+o2] = index
        elseif optional_count == 3 then
            local o1 = optionals[1]
            local o2 = optionals[2]
            local o3 = optionals[3]
            mask_to_index[required+o1] = index
            mask_to_index[required+o2] = index
            mask_to_index[required+o3] = index
            mask_to_index[required+o1+o2] = index
            mask_to_index[required+o1+o3] = index
            mask_to_index[required+o2+o3] = index
            mask_to_index[required+o1+o2+o3] = index
        elseif optional_count == 4 then
            local o1 = optionals[1]
            local o2 = optionals[2]
            local o3 = optionals[3]
            local o4 = optionals[4]
            mask_to_index[required+o1] = index
            mask_to_index[required+o2] = index
            mask_to_index[required+o3] = index
            mask_to_index[required+o4] = index
            mask_to_index[required+o1+o2] = index
            mask_to_index[required+o1+o3] = index
            mask_to_index[required+o1+o4] = index
            mask_to_index[required+o2+o3] = index
            mask_to_index[required+o2+o4] = index
            mask_to_index[required+o3+o4] = index
            mask_to_index[required+o1+o2+o3] = index
            mask_to_index[required+o1+o2+o4] = index
            mask_to_index[required+o1+o3+o4] = index
            mask_to_index[required+o2+o3+o4] = index
            mask_to_index[required+o1+o2+o3+o4] = index
        end

        UpdateNextIndex()
    end

    local function Reset()
        index_x, index_y = 0, index_height - 1
        mask_to_index = {}
        next_mask = 0x01
        primary_index = GetTextureIndex()
        UpdateNextIndex()
    end

    local function Finish()
        local _mask_to_index = mask_to_index
        Reset()
        return _mask_to_index
    end

    Reset()

    function self:GetPrimaryIndex()
        return primary_index
    end

    function self:GetNextMask()
        return GetNextMask()
    end

    function self:GetCurrentIndex()
        return GetTextureIndex()
    end

    function self:SkipIndex()
        UpdateNextIndex()
    end

    function self:BuildTextureIndexForMask(...)
        BuildTextureIndexForMask(...)
    end

    function self:Finish()
        return Finish()
    end

    function self:Reset()
        return Reset()
    end
end)
