local Widget = require "widgets/widget"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"
local easing = require "easing"

local function IsTerrorNearby(owner)
	local x, y, z = owner.Transform:GetWorldPosition()
	if #TheSim:FindEntities(x, y, z, 36, { "nightterror" }) > 0 then
		return true
	end
end

local function IsStrangerNearby(owner)
	local x, y, z = owner.Transform:GetWorldPosition()
	if #TheSim:FindEntities(x, y, z, 24, { "tiddlestranger" }) > 0 then
		return true
	end
end

local function CheckSurroundings(owner,self)
	if IsStrangerNearby(owner) then
		self.UpdateTracks(self,2)
	elseif IsTerrorNearby(owner) then
		self.UpdateTracks(self,1)
	elseif self.track ~= 0 then
		self.UpdateTracks(self,0)
	end
end

local function UpdateTracks(self,newtrack)
	if newtrack ~= self.track then
		self.track = newtrack
		TheFocalPoint.SoundEmitter:KillSound("fogfear")
		TheFocalPoint.SoundEmitter:KillSound("fogdanger")
		TheFocalPoint.SoundEmitter:KillSound("tiddlestranger")
		if self.track == 0 then
			TheFocalPoint.SoundEmitter:PlaySound("UCSounds/screecher/feer", "fogfear")
		end
		if self.track == 1 then
			TheFocalPoint.SoundEmitter:PlaySound("UMMusic/music/night_terrors", "fogdanger")
		end
		if self.track == 2 then
			TheFocalPoint.SoundEmitter:PlaySound("UMMusic/music/tiddlestranger", "tiddlestranger")
		end
	end
end

local FogOver = Class(Widget, function(self, owner)
    self.owner = owner
    Widget._ctor(self, "FogOver")
    self:SetClickable(false)

    self.bg2 = self:AddChild(Image("images/fx5.xml", "fog_over.tex"))
    self.bg2:SetVRegPoint(ANCHOR_MIDDLE)
    self.bg2:SetHRegPoint(ANCHOR_MIDDLE)
    self.bg2:SetVAnchor(ANCHOR_MIDDLE)
    self.bg2:SetHAnchor(ANCHOR_MIDDLE)
    self.bg2:SetScaleMode(SCALEMODE_FILLSCREEN)

    self.alpha = 0
    self.alphagoal = 0
    self.transitiontime = 2.0
    self.time = self.transitiontime
	self:StartUpdating()
    self:Hide()
	--self:Show()
	--self.bg2:SetTint(1, 1, 1, 0.6)
	self.track = 4
	
	self.owner:WatchWorldState("isday", function()
		self.owner:DoTaskInTime(0.1,
			function(inst) if TheWorld.state.isday then
				self.track = 4 -- No music
			end
		end)
	end, TheWorld)
	self.owner:WatchWorldState("iscaveday", function() 
		self.owner:DoTaskInTime(0.1,
			function(inst) if TheWorld.state.isday then
				self.track = 4 -- No music
			end
		end)
	end, TheWorld)
	
	self.terror = 1
	self.UpdateTracks = UpdateTracks
	
    owner:ListenForEvent("nightterrordirty",function(owner,data)
        self.terror = owner.nightterror:value()
		if self.terror == 0 then
			self.alpha = 0
			self.transitiontime = 2.0
			self.time = self.transitiontime
			self.bg2:SetTint(0.4, 0.4, 0.4, self.alpha)
			self.time = self.transitiontime
			self.alphagoal = 0
			self.alphareached = nil
			UpdateTracks(self,0) -- Standard NT ambiance

			TheFocalPoint.SoundEmitter:KillSound("busy")
			self.owner:DoPeriodicTask(3,function(owner)
				CheckSurroundings(owner,self)
			end)
		end
    end)   
	
end)

function FogOver:UpdateAlpha(dt)
    if self.alphagoal ~= self.alpha then
        if self.time > 0 then
            self.time = math.max(0, self.time - dt)
            if self.alphagoal < self.alpha then
                self.alpha = Remap(self.time, self.transitiontime, 0, 1, 0)
            else
                self.alpha = Remap(self.time, self.transitiontime, 0, 0, 1)
            end
        end
    end
end

function FogOver:OnUpdate(dt)
	self.bg2:SetTint(0.4, 0.4, 0.4, self.alpha)
	if self.alpha == 0 then
		self:Hide()
		--TheFocalPoint.SoundEmitter:KillSound("fogfear")
	end
	if self.terror < 1 then
		self:Show()
        self.time = self.transitiontime
        self.alphagoal = 1
		
		
	else
        self.time = self.transitiontime
        self.alphagoal = 0
		self.alphareached = nil
	end
	
	if (self.alphagoal + 0.1*math.sin(GetTime())) > self.alpha then
		self.alpha = self.alpha + 0.005
	else
		self.alphareached = true
	end
	if (self.alphagoal + 0.1*math.sin(GetTime())) < self.alpha then
		self.alpha = self.alpha - 0.005
	else
		self.alphareached = true
	end


end

return FogOver