local function UpdateRippleFXTransform(inst)
    local ripples = inst.replica.umripples
    local front_fx, back_fx = ripples.front_fx, ripples.back_fx
    local xscale, yscale, zscale = ripples.xscale and ripples.xscale:value() and tonumber(ripples.xscale:value()), ripples.yscale and ripples.yscale:value() and tonumber(ripples.yscale:value()), ripples.zscale and ripples.zscale:value() and tonumber(ripples.zscale:value())
    if front_fx then
        front_fx.Transform:SetScale(xscale, yscale, zscale)
    end
    if back_fx then
        back_fx.Transform:SetScale(xscale, yscale, zscale)
    end
    local vert_offset = ripples.vert_offset and ripples.vert_offset:value() and tonumber(ripples.vert_offset:value())
    if vert_offset then
        if front_fx then
            front_fx.Transform:SetPosition(0, vert_offset, 0)
        end
        if back_fx then
            back_fx.Transform:SetPosition(0, vert_offset, 0)
        end
    end
end

local Umripples = Class(function(self, inst)
    self.inst = inst

    self.xscale = net_string(inst.GUID, "umripples.xscale")
    self.yscale = net_string(inst.GUID, "umripples.yscale")
    self.zscale = net_string(inst.GUID, "umripples.zscale")
    self.vert_offset = net_string(inst.GUID, "umripples.vert_offset")
    self.bob_percent = net_string(inst.GUID, "umripples.bob_percent")
    self.size = net_string(inst.GUID, "umripples.size")
    self.should_parent_effect = net_bool(inst.GUID, "umripples.should_parent_effect")
    self._is_landed = net_bool(inst.GUID, "umripples._is_landed", "landeddirty")
    self.update_ripples = net_event(inst.GUID, "umripples.update_ripples")

    self.ismastersim = TheNet:GetIsMasterSimulation()

    if not TheNet:IsDedicated() then
        self.inst:ListenForEvent("landeddirty", function()
            if self._is_landed:value() then
                self:OnLandedClient()
            else
                self:OnNoLongerLandedClient()
            end
        end)
        self.inst:ListenForEvent("umripples.update_ripples", UpdateRippleFXTransform)
    end

    self.showing_effect = false
end)

function Umripples:IsLanded(islanded)
    self._is_landed:set(islanded)
end

function Umripples:SetIsObstacle(bool)
    self.is_obstable = bool ~= false
end

--small/med/large
function Umripples:SetSize(size)
    self.size = size
end

function Umripples:SetVerticalOffset(offset)
    self.vert_offset:set(offset)
    self.update_ripples:push()
    --UpdateRippleFXTransform(self)
end

function Umripples:SetXScale(scale)
    self.xscale:set(scale)
    self.update_ripples:push()
    --UpdateRippleFXTransform(self)
end

function Umripples:SetYScale(scale)
    self.yscale:set(scale)
    self.update_ripples:push()
    --UpdateRippleFXTransform(self)
end

function Umripples:SetZScale(scale)
    self.zscale:set(scale)
    self.update_ripples:push()
    --UpdateRippleFXTransform(self)
end

function Umripples:AttachEffect(effect)
    if self.should_parent_effect and self.should_parent_effect:value() then
        effect.entity:SetParent(self.inst.entity)
        effect.Transform:SetPosition(0, self.vert_offset and self.vert_offset:value() and tonumber(self.vert_offset:value()) or 0, 0)
    else
        local my_x, my_y, my_z = self.inst.Transform:GetWorldPosition()
        effect.Transform:SetPosition(my_x, my_y + (self.vert_offset and self.vert_offset:value() and tonumber(self.vert_offset:value()) or 0), my_z)
    end

    effect.Transform:SetScale(self.xscale and self.xscale:value(), self.yscale and self.yscale:value(), self.zscale and self.zscale:value())
end

function Umripples:IsFloating()
    return self.showing_effect
end

function Umripples:OnLandedClient()
    self.showing_effect = true
    if self.front_fx == nil then
        self.front_fx = SpawnPrefab("float_fx_front")
        self:AttachEffect(self.front_fx)
        self.front_fx.AnimState:PlayAnimation("idle_front_" .. (self.size and self.size:value() or "small"), true)
    end

    if self.back_fx == nil then
        self.back_fx = SpawnPrefab("float_fx_back")
        self:AttachEffect(self.back_fx)
        self.back_fx.AnimState:PlayAnimation("idle_back_" .. (self.size and self.size:value() or "small"), true)
    end

    self.inst.AnimState:SetFloatParams(-.05, 1.0, self.bob_percent and self.bob_percent:value() and tonumber(self.bob_percent:value()) or 0)
end

function Umripples:OnNoLongerLandedClient()
    self.showing_effect = false
    self.inst.AnimState:SetFloatParams(0, 0, 0)

    if self.front_fx ~= nil and self.front_fx:IsValid() then
        self.front_fx:Remove()
        self.front_fx = nil
    end
    if self.back_fx ~= nil and self.back_fx:IsValid() then
        self.back_fx:Remove()
        self.back_fx = nil
    end
end

return Umripples