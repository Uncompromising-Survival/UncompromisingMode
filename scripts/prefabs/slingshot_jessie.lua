local assets =
{
    Asset("ANIM", "anim/slingshot.zip"),
}

local prefabs =
{
	"slingshotammo_rock_proj",
}

local easing = require("easing")

local PROJECTILE_DELAY = 2 * FRAMES

local function Swap_Fire_Mode(inst)
	inst.firing_mode = inst.firing_mode + 1
	
	if inst.firing_mode > 3 then
		inst.firing_mode = 1
	end
	
	
	if inst.components.equippable:IsEquipped() then
		local owner = inst.components.inventoryitem.owner
		owner.AnimState:OverrideSymbol("swap_object", "swap_jessie_"..inst.firing_mode, "swap_jessie_"..inst.firing_mode)
		
		inst.SoundEmitter:PlaySound("wixie/characters/wixie/jessie_swap_"..inst.firing_mode)
	end
	
	inst.components.inventoryitem.atlasname = "images/inventoryimages/slingshot_jessie_"..inst.firing_mode..".xml"
	inst.components.inventoryitem:ChangeImageName("slingshot_jessie_"..inst.firing_mode.."")
end

local function OnEquip(inst, owner)
	if inst.firing_mode ~= nil then
		owner.AnimState:OverrideSymbol("swap_object", "swap_jessie_"..inst.firing_mode, "swap_jessie_"..inst.firing_mode)
	end
	
    inst:AddComponent("um_activatable_item")
    inst.components.um_activatable_item.act_fn = Swap_Fire_Mode
	
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    if inst.components.container ~= nil then
        inst.components.container:Open(owner)
    end
end

local function OnUnequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end
	
    inst:RemoveComponent("um_activatable_item")

    if inst.components.container ~= nil then
        inst.components.container:Close()
    end
end

local function OnProjectileLaunched(inst, attacker, target)
	if inst.components.container ~= nil then
		local ammo_stack = inst.components.container:GetItemInSlot(1)
		local item = inst.components.container:RemoveItem(ammo_stack, false)
		if item ~= nil then
			if item == ammo_stack then
				item:PushEvent("ammounloaded", {slingshot = inst})
			end

			item:Remove()
		end
	end
end

local function OnAmmoLoaded(inst, data)
	if inst.components.weapon ~= nil then
		if data ~= nil and data.item ~= nil then
			if data.slot == 1 then
				inst.loaded_projectile1 = data.item.prefab.."_proj"
			elseif data.slot == 2 then
				inst.loaded_projectile2 = data.item.prefab.."_proj"
			elseif data.slot == 3 then
				inst.loaded_projectile3 = data.item.prefab.."_proj"
			elseif data.slot == 4 then
				inst.loaded_projectile4 = data.item.prefab.."_proj"
			elseif data.slot == 5 then
				inst.loaded_projectile5 = data.item.prefab.."_proj"
			elseif data.slot == 6 then
				inst.loaded_projectile6 = data.item.prefab.."_proj"
			end
			
			local check_full = true
			
			if inst.components.container:IsFull() then
				inst.gun_is_empty = false
				inst.gun_is_full = true
				inst.can_take_ammo = false
				inst:RemoveTag("can_take_ammo")
				inst.shot_count = 1
			end
			
			inst.components.weapon:SetProjectile(data.item.prefab.."_proj")
			data.item:PushEvent("ammoloaded", {slingshot = inst})
		end
	end
end

local function OnAmmoUnloaded(inst, data)
	if inst.components.weapon ~= nil and data.slot ~= nil then
		if data.slot == 1 then
			inst.loaded_projectile1 = nil
		elseif data.slot == 2 then
			inst.loaded_projectile2 = nil
		elseif data.slot == 3 then
			inst.loaded_projectile3 = nil
		elseif data.slot == 4 then
			inst.loaded_projectile4 = nil
		elseif data.slot == 5 then
			inst.loaded_projectile5 = nil
		elseif data.slot == 6 then
			inst.loaded_projectile6 = nil
		end
		
		local check_empty = false
			
		if inst.components.container:IsEmpty() then
			inst.shot_count = 1
			inst.gun_is_full = false
			inst.can_take_ammo = true
			inst:AddTag("can_take_ammo")
		end
		
		if data ~= nil and data.prev_item ~= nil then
			data.prev_item:PushEvent("ammounloaded", {slingshot = inst})
		end
	end
end

local floater_swap_data = {sym_build = "swap_slingshot"}

local function ReticuleTargetFn(inst)
    return Vector3(inst.entity:LocalToWorldSpace(6.5, 0, 0))
end

local function ReticuleMouseTargetFn(inst, mousepos)
    if mousepos ~= nil then 
        local x, y, z = inst.Transform:GetWorldPosition()
        local dx = mousepos.x - x
        local dz = mousepos.z - z
        local l = dx * dx + dz * dz
		
		local dist = inst:GetDistanceSqToPoint(mousepos.x, 0, mousepos.z)
		
		inst.components.reticule.fadealpha = dist / 100
		
        if l <= 0 then
            return inst.components.reticule.targetpos
        end
        l = 6.5 / math.sqrt(l)
        return Vector3(x + dx * l, 0, z + dz * l)
    end
end

local function ReticuleUpdatePositionFn(inst, pos, reticule, ease, smoothing, dt)
    local x, y, z = inst.Transform:GetWorldPosition()
    reticule.Transform:SetPosition(x, 0, z)
    local rot = -math.atan2(pos.z - z, pos.x - x) / DEGREES
    if ease and dt ~= nil then
        local rot0 = reticule.Transform:GetRotation()
        local drot = rot - rot0
        rot = Lerp((drot > 180 and rot0 + 360) or (drot < -180 and rot0 - 360) or rot0, rot, dt * smoothing)
    end
    reticule.Transform:SetRotation(rot)
end

local function LaunchSpit(inst, caster, target, fixedpowerlevel, ammo)
	if caster ~= nil then
		local x, y, z = caster.Transform:GetWorldPosition()
		
		if ammo ~= nil then
			local targetpos = target:GetPosition()
			targetpos.y = 0.5

			local projectile = SpawnPrefab(ammo)
			projectile.Transform:SetPosition(x, y, z)
			projectile.powerlevel = fixedpowerlevel
				
			if projectile.components.complexprojectile ~= nil then
				local theta = caster.Transform:GetRotation()
				theta = theta*DEGREES
		
				local dx = targetpos.x - x
				local dz = targetpos.z - z
					
				--local rangesq = (dx * dx + dz * dz) / 1.2
				local rangesq = dx * dx + dz * dz
				local maxrange = TUNING.FIRE_DETECTOR_RANGE * 2
				--local speed = easing.linear(rangesq, 15, 3, maxrange * maxrange)
				local speed = easing.linear(rangesq, maxrange, 1, maxrange * maxrange)
				projectile.caster = caster
				projectile.components.complexprojectile.usehigharc = true
				projectile.components.complexprojectile:SetHorizontalSpeed(speed)
				projectile.components.complexprojectile:SetGravity(-45)
				projectile.components.complexprojectile:Launch(targetpos, caster, caster)
				projectile.components.complexprojectile:SetLaunchOffset(Vector3(1.5, 1.5, 0))
			else
				if ammo == "slingshotammo_moonglass_proj_secondary" then
					projectile.components.projectile:SetSpeed(20)
				else
					projectile.components.projectile:SetSpeed(10 + 10 * projectile.powerlevel)
				end
					
				projectile.components.projectile:Throw(caster, target, caster)
			end
			
			projectile.planar_ammo = true
			
			local fx = SpawnPrefab("slingshot_planar_fx_shadow")
            fx.entity:SetParent(projectile.entity)
            fx.entity:AddFollower()
            fx.Follower:FollowSymbol(projectile.GUID, "rock", 0, 0, 0)
		end
	end
end

local function getspawnlocation(inst, target)
    local x1, y1, z1 = inst.Transform:GetWorldPosition()
    local x2, y2, z2 = target.Transform:GetWorldPosition()
    return x1 + .15 * (x2 - x1), 0.5, z1 + .15 * (z2 - z1)
end

local function UnloadAmmo(inst)
	if inst.components.container ~= nil then
		local ammo_stack = inst.components.container:GetItemInSlot(inst.shot_count)
		
		if inst.shot_count == 1 then
			inst.loaded_projectile1 = nil
		elseif inst.shot_count == 2 then
			inst.loaded_projectile2 = nil
		elseif inst.shot_count == 3 then
			inst.loaded_projectile3 = nil
		elseif inst.shot_count == 4 then
			inst.loaded_projectile4 = nil
		elseif inst.shot_count == 5 then
			inst.loaded_projectile5 = nil
		elseif inst.shot_count == 6 then
			inst.loaded_projectile6 = nil
		end
		
		local item = inst.components.container:RemoveItem(ammo_stack, false)
		if item ~= nil then
			if item == ammo_stack then
				item:PushEvent("ammounloaded", {slingshot = inst})
			end
			
			inst.shot_count = inst.shot_count + 1
			inst.can_take_ammo = false
			inst:RemoveTag("can_take_ammo")
			
			if inst.shot_count > 6 or inst.components.container:IsEmpty() then
				inst.shot_count = 1
				inst.gun_is_full = false
				inst.can_take_ammo = true
				inst:AddTag("can_take_ammo")
			end

			item:Remove()
		end
	end
end

local function Proxy_Shoot(inst, owner, fixedpowerlevel, shotcount)
	--if caster.sg.currentstate.name == "slingshot_cast" then
	if inst.gun_is_full then
		local ammo = inst.shot_count == 1 and inst.loaded_projectile1 and inst.loaded_projectile1.."_secondary"
					or inst.shot_count == 2 and inst.loaded_projectile2 and inst.loaded_projectile2.."_secondary"
					or inst.shot_count == 3 and inst.loaded_projectile3 and inst.loaded_projectile3.."_secondary"
					or inst.shot_count == 4 and inst.loaded_projectile4 and inst.loaded_projectile4.."_secondary"
					or inst.shot_count == 5 and inst.loaded_projectile5 and inst.loaded_projectile5.."_secondary"
					or inst.shot_count == 6 and inst.loaded_projectile6 and inst.loaded_projectile6.."_secondary"
					or nil
		
		if ammo == nil then
			inst.shot_count = inst.shot_count + 1
			inst.can_take_ammo = false
			inst:RemoveTag("can_take_ammo")
			
			if inst.shot_count > 6 or inst.components.container:IsEmpty() then
				inst.shot_count = 1
				inst.gun_is_full = false
				inst.can_take_ammo = true
				inst:AddTag("can_take_ammo")
			end
		end

		local wx = nil
		local wz = nil
		
		if owner.wixiepointx ~= nil then
			wx = owner.wixiepointx
			wz = owner.wixiepointz
		end

		if wx then
			print("owner and wixiepoint")
			if ammo ~= nil then
				inst.SoundEmitter:PlaySound("wixie/characters/wixie/jessie_shoot")
				
				print("ammo ~= nil")
				if ammo == "slingshotammo_shadow_proj_secondary" then
					local xmod = owner.wixiepointx
					local zmod = owner.wixiepointz
				
					local pattern = false
						
					if math.random() > 0.5 then
						pattern = true
					end
					
					for i = 1, 2 * 2 do
						inst:DoTaskInTime(0.03 * i, function()
							local caster = inst.components.inventoryitem.owner
							local spittarget = SpawnPrefab("slingshot_target")
							
							local multipl = (pattern and -100 or 100) / 2
							
							local maxangle = multipl / 2
							
							local varangle = maxangle - multipl
							
							maxangle = maxangle - (varangle / 2)
							
							local theta = (inst:GetAngleToPoint(owner.wixiepointx, 0.5, owner.wixiepointz) + (maxangle + (varangle * (i-1)))) * DEGREES
									
							xmod = owner.wixiepointx + 15*math.cos(theta)
							zmod = owner.wixiepointz - 15*math.sin(theta)

							spittarget.Transform:SetPosition(xmod, 0.5, zmod)
							LaunchSpit(inst, caster, spittarget, fixedpowerlevel, ammo)
							spittarget:DoTaskInTime(.1, spittarget.Remove)
						end)
					end
				else
					local xmod = owner.wixiepointx
					local zmod = owner.wixiepointz
				
					local pattern = false
						
					if math.random() > 0.5 then
						pattern = true
					end
					
					local caster = inst.components.inventoryitem.owner
					local spittarget = SpawnPrefab("slingshot_target")

					if inst.firing_mode == 3 then
						local shotgun_pattern = 30 * (shotcount - 1) - 30
							
						local theta = (inst:GetAngleToPoint(owner.wixiepointx, 0.5, owner.wixiepointz) + shotgun_pattern) * DEGREES
	
						xmod = owner.wixiepointx + 15*math.cos(theta)
						zmod = owner.wixiepointz - 15*math.sin(theta)

						spittarget.Transform:SetPosition(xmod, 0.5, zmod)
						LaunchSpit(inst, caster, spittarget, fixedpowerlevel, ammo)
						spittarget:DoTaskInTime(0, spittarget.Remove)
					else
						local accuracymod = inst.firing_mode == 2 and 15 or 0
						local theta = (inst:GetAngleToPoint(owner.wixiepointx, 0.5, owner.wixiepointz) + math.random(-accuracymod, accuracymod)) * DEGREES

						wx = wx + 15*math.cos(theta)
						wz = wz - 15*math.sin(theta)
										
						spittarget.Transform:SetPosition(wx, 0.5, wz)

						spittarget.Transform:SetPosition(wx, 0.5, wz)
						LaunchSpit(inst, caster, spittarget, fixedpowerlevel, ammo)
						spittarget:DoTaskInTime(0, spittarget.Remove)
					end
				end
				
				UnloadAmmo(inst, inst.shot_count)
			end
		end
	end
end

local function createlight(inst, target, pos)
	local owner = inst.components.inventoryitem.owner
	local fixedpowerlevel = 2 - (inst.firing_mode / 4)

	for i = 1, inst.firing_mode do
		if inst.firing_mode == 2 then
			inst:DoTaskInTime((i / 10) - 0.1, function(inst)
				Proxy_Shoot(inst, owner, fixedpowerlevel, i)
			end)
		else
			Proxy_Shoot(inst, owner, fixedpowerlevel, i)
		end
	end
end

local function can_cast_fn(doer, target, pos)
	if doer:HasTag("troublemaker") then
		return true
	else
		return false
	end
end

local function OnSave(inst, data)
	if inst.gun_is_empty ~= nil then
		data.gun_is_empty = inst.gun_is_empty
	end
	
	if inst.can_take_ammo ~= nil then
		data.can_take_ammo = inst.can_take_ammo
	end
	
	if inst.shot_count ~= nil then
		data.shot_count = inst.shot_count
	end
end

local function OnLoad(inst, data)
    if data ~= nil and data.can_take_ammo ~= nil then
        inst.gun_is_empty = data.gun_is_empty
        inst.can_take_ammo = data.can_take_ammo
        inst.shot_count = data.shot_count
		--inst.firing_mode = data.firing_mode
		
		if inst.can_take_ammo then
			inst:AddTag("can_take_ammo")
		else
			inst:RemoveTag("can_take_ammo")
		end
    end
	
	if inst.components.container:IsEmpty() then
		inst.shot_count = 1
		inst.gun_is_full = false
		inst.can_take_ammo = true
		inst:AddTag("can_take_ammo")
	end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("swap_wixiegun")
    inst.AnimState:SetBuild("swap_wixiegun")
    inst.AnimState:PlayAnimation("BUILD")

    inst:AddTag("rangedweapon")
    inst:AddTag("wixie_weapon")
    inst:AddTag("wixiegun")
    inst:AddTag("veryquickcast")
    inst:AddTag("allow_action_on_impassable")

    --weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")
    inst:AddTag("donotautopick")
    --inst.projectiledelay = PROJECTILE_DELAY

    MakeInventoryFloatable(inst, "med", 0.075, {0.5, 0.4, 0.5}, true, -7, floater_swap_data)

    inst.spelltype = "SLINGSHOT"
    inst.actiontype = STRINGS.ACTIONS.UM_ACTIVATABLE_ITEM.MORPH
	

    inst:AddComponent("reticule")
    inst.components.reticule.reticuleprefab = "wixie_reticuleline"
    inst.components.reticule.pingprefab = "reticulelongping"
    --inst.components.reticule.reticuleprefab = "reticuleline2"
    --inst.components.reticule.pingprefab = "reticulelineping"
    inst.components.reticule.targetfn = ReticuleTargetFn
    inst.components.reticule.mousetargetfn = ReticuleMouseTargetFn
    inst.components.reticule.updatepositionfn = ReticuleUpdatePositionFn
    inst.components.reticule.validcolour = { 1, 1, 1, 1 }
    inst.components.reticule.invalidcolour = { .5, 0, 0, 1 }
    inst.components.reticule.ease = true
    inst.components.reticule.mouseenabled = true
    inst.components.reticule.ispassableatallpoints = true

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
		inst.OnEntityReplicated = function(inst) 
			if inst.replica.container ~= nil then
				inst.replica.container:WidgetSetup("jessie") 
			end
		end
        return inst
    end

	inst.firing_mode = 1
	
	inst.gun_is_empty = true
	inst.gun_is_full = false
	inst.can_take_ammo = true
	inst:AddTag("can_take_ammo")

	inst.loaded_projectile1 = nil
	inst.loaded_projectile2 = nil
	inst.loaded_projectile3 = nil
	inst.loaded_projectile4 = nil
	inst.loaded_projectile5 = nil
	inst.loaded_projectile6 = nil
	
	inst.shot_count = 1

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/slingshot_jessie_1.xml"
	inst.components.inventoryitem:ChangeImageName("slingshot_jessie_1")

    inst:AddComponent("equippable")
    inst.components.equippable.restrictedtag = "troublemaker"
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(10)
    inst.components.weapon:SetRange(0.5)
    inst.components.weapon:SetOnProjectileLaunched(OnProjectileLaunched)
    inst.components.weapon:SetProjectile(nil)
	inst.components.weapon:SetProjectileOffset(1)
	
    inst:AddComponent("spellcaster")
    inst.components.spellcaster:SetSpellFn(createlight)
    inst.components.spellcaster:SetCanCastFn(can_cast_fn)
    inst.components.spellcaster.veryquickcast = true
    inst.components.spellcaster.canuseontargets = true
    inst.components.spellcaster.canuseondead = true
    inst.components.spellcaster.canuseonpoint = true
    inst.components.spellcaster.canuseonpoint_water = true
    inst.components.spellcaster.canusefrominventory = false

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("jessie")
	inst.components.container.canbeopened = false
    inst:ListenForEvent("itemget", OnAmmoLoaded)
    inst:ListenForEvent("itemlose", OnAmmoUnloaded)

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)
    MakeHauntableLaunch(inst)
	
	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

    return inst
end

return Prefab("slingshot_jessie", fn, assets, prefabs)