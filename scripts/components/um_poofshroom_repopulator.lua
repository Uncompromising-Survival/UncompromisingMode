return Class(function(self, inst)
    assert(TheWorld.ismastersim, "um_poofshroom_repopulator should not exist on client")
   
    self.init = false

    self.list_green = {}
    self.list_blue = {}
    self.list_red = {}

    function self:RepopulatePoofshrooms(list)
        local count = math.floor(0.2*#list) -- only let 1/10th of the poofshroom spawners activate
        for i,v in ipairs(shuffleArray(list)) do
            v.PlacePoofShrooms(v)
            if i > count then
                break
            end
        end
    end

    function self:RepopulatePoofshroomsRedTest()
        local list = self.list_red
        local count = math.floor(0.5*#list) -- only let 3/4 of the poofshroom spawners activate
        for i,v in ipairs(shuffleArray(list)) do
            v.PlacePoofShrooms(v)
            if i > count then
                break
            end
        end
    end
    function self:RepopulatePoofshroomsBlueTest()
        local list = self.list_blue
        local count = math.floor(0.5*#list) -- only let 3/4 of the poofshroom spawners activate
        for i,v in ipairs(shuffleArray(list)) do
            v.PlacePoofShrooms(v)
            if i > count then
                break
            end
        end
    end
    function self:RepopulatePoofshroomsGreenTest()
        local list = self.list_green
        local count = math.floor(0.5*#list) -- only let 3/4 of the poofshroom spawners activate
        for i,v in ipairs(shuffleArray(list)) do
            v.PlacePoofShrooms(v)
            if i > count then
                break
            end
        end
    end


    inst:WatchWorldState("isspring", function(inst, data)
        inst:DoTaskInTime(2,function(inst)
            if TheWorld.state.isspring then
                self:RepopulatePoofshrooms(self.list_green)
            end
        end)
    end)
    inst:WatchWorldState("iswinter", function(inst, data)
        inst:DoTaskInTime(2,function(inst)
            if TheWorld.state.iswinter then
                self:RepopulatePoofshrooms(self.list_blue)
            end
        end)
    end)
    inst:WatchWorldState("issummer", function(inst, data)
        inst:DoTaskInTime(2,function(inst)
            if TheWorld.state.isummer then
                self:RepopulatePoofshrooms(self.list_red)
            end
        end)
    end)

    function self:OnPostInit()
        inst:DoTaskInTime(1,function(inst)
            if not self.init then
                self:RepopulatePoofshrooms(self.list_green)
                self:RepopulatePoofshrooms(self.list_blue)
                self:RepopulatePoofshrooms(self.list_red)
                self.init = true
            end
        end)
    end

    function self:OnSave()
        local data = {}
        data.init = self.init
        return data
    end

    function self:OnLoad(data)
        if data and data.init then
            self.init = data.init
        end
    end

end)
