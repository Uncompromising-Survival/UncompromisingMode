local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------


local colors = {"red","green","blue"}

local function UpdateFX(owner,color,helm)
	if helm.charge == 0 and helm.fx then
		helm.fx:Remove()
	else
		if not owner then -- Can't Pass it from the Timer CD....
			owner = helm.owner
		end
		-- Initialize FX
		if helm.fx == nil or not helm.fx:IsValid() then 
			helm.fx = SpawnPrefab("umdebuff_pyre_toxin_fx")
			if owner.components.combat ~= nil then
				helm.fx.entity:AddFollower():FollowSymbol(owner.GUID, owner.components.combat.hiteffectsymbol, 0, -100, 0)
			else
				helm.fx.entity:SetParent(owner.entity)
			end
		end 
		
		-- Color FX
		if color then -- If the CD comes from the timer, it's not important to color the fx
			if color == "red" then
				helm.fx.AnimState:SetMultColour(1,0.2,0.2,1)
			elseif color == "green" then
				helm.fx.AnimState:SetMultColour(0.2,1,0.2,1)
			elseif color == "blue" then
				helm.fx.AnimState:SetMultColour(0.2,0.5,1,1)	
			end
		end
		
		-- Scale FX
		if helm.charge > 6 and helm.charge ~= 12 then
			helm.fx.Transform:SetScale(2, 2, 2)
		elseif helm.charge == 12 then
			helm.fx.Transform:SetScale(3, 3, 3)
		elseif helm.charge == 1 then
			helm.fx.Transform:SetScale(1, 1, 1)
		else
			helm.fx.Transform:SetScale(1.5, 1.5, 1.5)
		end
	end
end

local function FindColor(inst)
	local color
	if inst.prefab == "red_mushroomhat" then
		color = "red"
	elseif inst.prefab == "green_mushroomhat" then
		color = "green"
	elseif inst.prefab == "blue_mushroomhat" then
		color = "blue"
	end
	return color
end

local function CDDone(inst)
	inst.charge = inst.charge - 1
	if inst.charge > 0 then
		if inst.charge > 6 then
			inst.components.timer:StartTimer("lose_charge",40)
		else
			inst.components.timer:StartTimer("lose_charge",120)
		end	
	end
	if inst.charge > 10 then
		inst.owner.components.talker:Say("If I don't find more "..FindColor(inst).." caps I will surely starve!") -- temp
	elseif inst.charge > 6 then
		inst.owner.components.talker:Say("I need to find some "..FindColor(inst).." caps quick. I do not feel right.") -- temp
	else
		inst.owner.components.talker:Say("I would like more "..FindColor(inst).." mushrooms.") -- temp
	end
	UpdateFX(nil,nil,inst)
end


local function RemoveBuff(owner,color,helm)
	if owner.components.combat and owner.components.locomotor then
		if color == "red" then
			owner.components.combat.externaldamagemultipliers:RemoveModifier(helm)
		elseif color == "green" then
			owner.components.locomotor:RemoveExternalSpeedMultiplier(owner, "green_mushroomhat")
		elseif color == "blue" then -- Handled elsewhere....
			--owner:RemoveTag("bluemush_builder")
		end
	end
end

local function DecideNewDmgMod(inst)
	local mod
	if inst.charge == 12 then -- stage 3
		mod = 2
	elseif inst.charge < 12 and inst.charge > 6 then -- stage 2
		mod = 1.4
	elseif inst.charge >= 1 then -- stage 1
		mod = 1.2
	end
	
	return mod
end

local function DecideNewSpeedMod(inst)
	local mod = 1
	if inst.charge == 12 then -- stage 3
		mod = 2
	elseif inst.charge < 12 and inst.charge > 6 then -- stage 2
		mod = 1.4
	elseif inst.charge >= 1 then -- stage 1
		mod = 1.2
	end
	return mod
end


local function UpdateBuff(owner,color,helm)
	if color == "red" then
		local mod = DecideNewDmgMod(helm)
		owner.components.combat.externaldamagemultipliers:RemoveModifier(helm)
		owner.components.combat.externaldamagemultipliers:SetModifier(helm, mod)
	elseif color == "green" then
		local mod = DecideNewSpeedMod(helm)
		owner.components.locomotor:SetExternalSpeedMultiplier(owner,"green_mushroomhat", mod)
	elseif color == "blue" then -- Handled elsewhere....
	
	end
end



local function ShouldBond(owner,helm)
	if helm.charge > 6 and not helm.bonded then
		owner.components.talker:Say("What was that crunching noise..?") -- temporary
		helm.bonded = true
	elseif not helm.bonded and math.random() > 0.75 then
		owner.components.talker:Say("What was that crunching noise..?") -- temporary
		helm.bonded = true
	end
end


local function OnEat(owner, data)
	if owner.components.inventory and owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) and 
	(owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD).prefab == "red_mushroomhat" or owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD).prefab == "green_mushroomhat" 
	or owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD).prefab == "blue_mushroomhat") then
		local helm = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
		local color = FindColor(helm)
		if data.food.prefab == color.."_cap" then
			if helm.charge ~= 12 then
				helm.charge = helm.charge + 1
			end
			helm.components.timer:StopTimer("lose_charge")
			if helm.charge > 6 then
				helm.components.timer:StartTimer("lose_charge",30)
			else
				helm.components.timer:StartTimer("lose_charge",60)
			end
			

			if math.random() > 0.75 or helm.charge == 12 then -- only sometimes say these lines, unless you hit the cap.
				if helm.charge == 12 then
					owner.components.talker:Say("I feel satisfied now.") -- temp
				elseif helm.charge > 6 then
					owner.components.talker:Say("Yes! More "..FindColor(helm).." caps!") -- temp
				else
					owner.components.talker:Say("That's the tastiest mushroom I've ever had.") -- temp
				end
			end
			ShouldBond(owner,helm)
			UpdateBuff(owner,color,helm)
			UpdateFX(owner,color,helm)
			helm.components.perishable:AddTime(60*4) -- Restore half-day durability
		end
	else
		owner:RemoveEventCallback("oneat",OnEat)
	end
end

local function _base_onequip(inst, owner, symbol_override, swap_hat_override)
	local skin_build = inst:GetSkinBuild()
	if skin_build ~= nil then
		owner:PushEvent("equipskinneditem", inst:GetSkinName())
		owner.AnimState:OverrideItemSkinSymbol(swap_hat_override or "swap_hat", skin_build, symbol_override or "swap_hat", inst.GUID, owner.fname_temp)
	else
		owner.AnimState:OverrideSymbol(swap_hat_override or "swap_hat", owner.fname_temp, symbol_override or "swap_hat")
	end

	if inst.components.fueled ~= nil then
		inst.components.fueled:StartConsuming()
	end

	if inst.skin_equip_sound and owner.SoundEmitter then
		owner.SoundEmitter:PlaySound(inst.skin_equip_sound)
	end
end
	
local function _onequip(inst, owner, symbol_override, headbase_hat_override)
	_base_onequip(inst, owner, symbol_override)

	owner.AnimState:ClearOverrideSymbol("headbase_hat") --clear out previous overrides
	if headbase_hat_override ~= nil then
		local skin_build = owner.AnimState:GetSkinBuild()
		if skin_build ~= "" then
			owner.AnimState:OverrideSkinSymbol("headbase_hat", skin_build, headbase_hat_override )
		else 
			local build = owner.AnimState:GetBuild()
			owner.AnimState:OverrideSymbol("headbase_hat", build, headbase_hat_override)
		end
	end

	owner.AnimState:Show("HAT")
	owner.AnimState:Show("HAIR_HAT")
	owner.AnimState:Hide("HAIR_NOHAT")
	owner.AnimState:Hide("HAIR")

	if owner:HasTag("player") then
		owner.AnimState:Hide("HEAD")
		owner.AnimState:Show("HEAD_HAT")
		owner.AnimState:Show("HEAD_HAT_NOHELM")
		owner.AnimState:Hide("HEAD_HAT_HELM")
	end
end

local function _onunequip(inst, owner)
	local skin_build = inst:GetSkinBuild()
	if skin_build ~= nil then
		owner:PushEvent("unequipskinneditem", inst:GetSkinName())
	end

	owner.AnimState:ClearOverrideSymbol("headbase_hat") --it might have been overriden by _onequip
	if owner.components.skinner ~= nil then
		owner.components.skinner.base_change_cb = owner.old_base_change_cb
	end

	owner.AnimState:ClearOverrideSymbol("swap_hat")
	owner.AnimState:Hide("HAT")
	owner.AnimState:Hide("HAIR_HAT")
	owner.AnimState:Show("HAIR_NOHAT")
	owner.AnimState:Show("HAIR")

	if owner:HasTag("player") then
		owner.AnimState:Show("HEAD")
		owner.AnimState:Hide("HEAD_HAT")
		owner.AnimState:Hide("HEAD_HAT_NOHELM")
		owner.AnimState:Hide("HEAD_HAT_HELM")
	end

	if inst.components.fueled ~= nil then
		inst.components.fueled:StopConsuming()
	end
end
	
local function ShowHat(owner)
	local helm = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
	_onequip(helm, owner)
end

local function HideHat(owner)
	local helm = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
	_onunequip(helm, owner)
end

local function InfestHost(inst, owner, color)
	owner:ListenForEvent("oneat",OnEat)
	inst.owner = owner
	if owner:HasTag("player") then
		owner.components.talker:Say("I'm suddenly craving "..FindColor(inst).." caps.")
	end
	if owner.prefab == "woodie" then -- hide hat if that!
		owner:ListenForEvent("startwereplayer",HideHat)
		owner:ListenForEvent("stopwereplayer",ShowHat)
		owner.fname_temp = "hat_"..color.."_mushroom"
	end
end

local function TryKillHost(inst,owner)
	-- Death is the only way out.
	owner.components.health:DoDelta(-20)
	inst:DoTaskInTime(0,function(inst) 
		if inst.owner and inst.owner.components.health and not inst.owner.components.health:IsDead() then
			local owner = inst.owner
			inst.owner = nil
			owner.components.inventory:Equip(inst)
			owner.sg:GoToState("soundstun")
			owner.components.talker:Say("OW! I can't take it off!")
			inst.bonded = true
		end
	end)
end


for i,color in ipairs(colors) do

	env.AddPrefabPostInit(color.."_mushroomhat", function(inst)
		if not TheWorld.ismastersim then
			return
		end
		
		local _onequip = inst.components.equippable.onequipfn
		local _onunequip = inst.components.equippable.onunequipfn
		
		local function OnEquip(inst, owner)
			InfestHost(inst, owner, color)
			_onequip(inst, owner)
		end

		local function OnUnequip(inst, owner)
			if inst.bonded then
				TryKillHost(inst,owner)
			end
			local color = FindColor(inst)
			RemoveBuff(owner,color,inst)
			owner:RemoveEventCallback("oneat",OnEat)
			inst.bonded = nil
			inst.charge = 0
			if inst.fx then
				inst.fx:Remove()
			end
			if inst.components.timer:TimerExists("lose_charge") then
				inst.components.timer:StopTimer("lose_charge")
			end
			
			if owner.prefab == "woodie" then
				inst:RemoveEventCallback("startwereplayer",HideHat)
				inst:RemoveEventCallback("stopwereplayer",ShowHat)	
				owner.fname_temp = nil
			end	

			_onunequip(inst, owner)
		end
						
		inst.components.equippable:SetOnEquip(OnEquip)
		inst.components.equippable:SetOnUnequip(OnUnequip)
		
		
		
		-- Robust Save/Load inclusion.
		if inst.OnSave then
			local _OnSave = inst.OnSave
			inst.OnSave = function(inst,data)
				data.charge = inst.charge
				if inst.bonded then
					data.bonded = inst.bonded
				end
				return _OnSave(inst,data)
			end
		else
			inst.OnSave = function(inst,data)
				data.charge = inst.charge
				if inst.bonded then
					data.bonded = inst.bonded
				end
			end
		end
		
		if inst.OnLoad then
			local _OnLoad = inst.OnLoad
			inst.OnLoad = function(inst,data)
				if data and data.charge then
					inst.charge = data.charge
				end
				if data and data.bonded then
					inst.bonded = data.bonded
				end				
				return _OnLoad(inst,data)
			end
		else
			inst.OnLoad = function(inst,data)
				if data and data.charge then
					inst.charge = data.charge
				end
				if data and data.bonded then
					inst.bonded = data.bonded
				end		
			end
		end
		
		inst:DoTaskInTime(0,function(inst)
			if not inst.charge then
				inst.charge = 0
			end
		end)
		
		inst:AddComponent("timer")
		inst:ListenForEvent("timerdone",CDDone)
		
		inst:AddTag("backpack") -- Added just so wereforms don't take it off...
	end)
	

end