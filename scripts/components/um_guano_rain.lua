return Class(function(self, inst)
    self.inst = inst
    assert(TheWorld.ismastersim, "um_guano_rain should not exist on client")
    --AXE This is essentially a big ol bat in the cave, pooping everywhere...

	self.guano_nodes = {} --AXE This is a list of hidden "nodes" in the world where the guano rain is handled.
	
	function self:EndRaining()
		for i,v in ipairs(self.guano_nodes) do
			v.Deactivate(v)
		end
		local time = math.random(8,12)*480 --AXE subsequent guano rain has a bigger gap
		self.inst.components.timer:StartTimer("begin_guano_rain", time)
	end
	function self:BeginRaining()
		for i,v in ipairs(self.guano_nodes) do
			v.Activate(v)
		end	
		local time = math.random(3,5)*480
		self.inst.components.timer:StartTimer("end_guano_rain", time)
	end
	
    function self:InitializeTimer()
		local time = math.random(3,5)*480 --AXE Start with a 3-5 day gap..? This only happens on worldgen, or at least it should.
		self.inst.components.timer:StartTimer("begin_guano_rain", time)
    end

    function self:OnPostInit()
        if not self.inst.components.timer:TimerExists("begin_guano_rain") then
            self:InitializeTimer()
        end
    end

    inst:ListenForEvent("timerdone", function(inst, data)
        if data then
            if data.name == "begin_guano_rain" then
				self:BeginRaining()
            end
            if data.name == "end_guano_rain" then
				self:EndRaining()
            end
        end
    end)
end)
