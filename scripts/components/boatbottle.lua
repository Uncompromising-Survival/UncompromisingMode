local function OnBoatChange(self, data)
    self.inst.replica.boatbottle:SetIsFull(self.boat ~= nil or (self.boat_data ~= nil and #self.boat_data > 1))
    self.isfull = self.boat ~= nil or (self.boat_data ~= nil and #self.boat_data > 1)
    if self.isfull then
        self.inst:AddTag("filled_boat_bottle")
    else
        self.inst:RemoveTag("filled_boat_bottle")
    end

    self.inst.AnimState:PlayAnimation(self.isfull and "idleboat2" or "idle2")

    if self.isfull then
        self.inst.AnimState:HideSymbol("boat")
        self.inst.AnimState:SetSymbolBloom("antennae")
        self.inst.AnimState:SetSymbolLightOverride("antennae", 0.5)
    else
        self.inst.AnimState:ClearSymbolBloom("antennae")
        self.inst.AnimState:SetSymbolLightOverride("antennae", 0)
    end
end

local function OnBoatPrefabChange(self, data)
    self.inst.replica.boatbottle:SetBoatPrefab(self.boat_prefab)
end

local BoatBottle = Class(function(self, inst)
    assert(TheWorld.ismastersim, "BoatBottle should not exist on client!")

    self.inst = inst

    self.boat = nil
    self.boat_data = {}
    self.isfull = false
    self.boat_prefab = nil
    self.inst:AddTag("boatbottle")
end, nil, {
    boat        = OnBoatChange,
    boat_data   = OnBoatChange,
    boat_prefab = OnBoatPrefabChange
})


--[[
    Using save records because entities are a pain in the ass to actually save.
    This way we can copy just what's neccessary, and not copy actual entities, but just enough to replicate them.
]]

--Checks if it has a boat already
function BoatBottle:HasBoat()
    return self.boat ~= nil or self.boat_data ~= {}
end

--Sets self.boat as the boat save record
function BoatBottle:RecordBoat(boat)
    self.boat_prefab = boat.prefab
    self.boat = boat:GetSaveRecord()
    return self.boat
end

--gets the self.boat save record
function BoatBottle:GetBoat()
    return self.boat
end

--sets the self.boat_data as all the save records of everything* on the boat, with the relative coordinates of the things on it.
function BoatBottle:RecordBoatData(boat)
    local x, y, z = boat.Transform:GetWorldPosition()

    local ents = boat.components.walkableplatform:GetEntitiesOnPlatform()

    for v in pairs(ents) do
        local data = v:GetSaveRecord()

        local _x, _y, _z = v.Transform:GetWorldPosition()

        local px, py, pz = _x - x, _y - y, _z - z

        if v.components.savedrotation then
            local rot = v.Transform:GetRotation()
            data.rotation = rot
        end

        table.insert(self.boat_data, { data = data, relative_pos = { x = px, y = py, z = pz } })
    end
    return self.boat_data
end

--returns boat_data
function BoatBottle:GetBoatData()
    return self.boat_data
end

--Spawns in the boat from the save record at pt
function BoatBottle:RetrieveBoat(pt)
    local x, y, z = pt.x, pt.y, pt.z
    local boat = SpawnSaveRecord(self.boat)

    if boat ~= nil then
        boat.Transform:SetPosition(x, y, z)
    end
    return boat
end

--spawns on boat all the save records from the boat data.
function BoatBottle:RetrieveBoatData(boat)
    local x, y, z = boat.Transform:GetWorldPosition()
    local ents = {}
    for k, v in pairs(self.boat_data) do
        local ent = SpawnSaveRecord(v.data)
        if ent ~= nil then
            ent.Transform:SetPosition(x + v.relative_pos.x, y + v.relative_pos.y, z + v.relative_pos.z)
            table.insert(ents, ent)
        end

        if v.data.rot then
            v.Transform:SetRotation(v.data.rot)
        end
    end
    return ents
end

--Full handler for recording all boat stuff
function BoatBottle:DoFullRecord(boat)
    self:RecordBoat(boat)
    self:RecordBoatData(boat)

    return { boat = self.boat, boat_data = self.boat_data }
end

--Full handler for retrieving and removing boat stuff
function BoatBottle:DoFullRetrieval(pt)
    local boat = self:RetrieveBoat(pt)
    self:RetrieveBoatData(boat)
    return boat
end

function BoatBottle:ClearBoatData()
    self.boat = nil
    self.boat_data = {}
end

--standard save/load functions
function BoatBottle:OnSave()
    local data =
    {
        boat = self.boat,
        boat_data = self.boat_data,
    }

    return data
end

function BoatBottle:OnLoad(data)
    self.boat = data.boat
    self.boat_data = data.boat_data
end

return BoatBottle
