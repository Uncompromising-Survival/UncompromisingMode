local function onequip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("equipskinneditem", inst:GetSkinName())
        owner.AnimState:OverrideItemSkinSymbol("swap_object", skin_build, "swap_axe", inst.GUID, "swap_axe")
    else
        owner.AnimState:OverrideSymbol("swap_object", "swap_axe", "swap_axe")
    end
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end
end

local function common_fn(bank, build)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("sharp")

    --tool (from tool component) added to pristine state for optimization
    inst:AddTag("tool")

    if TheNet:GetServerGameMode() ~= "quagmire" then
        --weapon (from weapon component) added to pristine state for optimization
        inst:AddTag("weapon")
    end

    MakeInventoryFloatable(inst, "small", 0.05, {1.2, 0.75, 1.2})

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventoryitem")
    -----
    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.CHOP, 1)

    if TheNet:GetServerGameMode() ~= "quagmire" then
        -------
        inst:AddComponent("finiteuses")
        inst.components.finiteuses:SetMaxUses(TUNING.AXE_USES)
        inst.components.finiteuses:SetUses(TUNING.AXE_USES)
        inst.components.finiteuses:SetOnFinished(inst.Remove)
        inst.components.finiteuses:SetConsumption(ACTIONS.CHOP, 1)

        -------
        inst:AddComponent("weapon")
        inst.components.weapon:SetDamage(TUNING.AXE_DAMAGE)
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("equippable")

    inst.components.equippable:SetOnEquip(onequip)

    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)

    return inst
end



local function TryToAddToTable(inst,target)
	for i,v in ipairs(inst.targettable) do
		if v == target then
			return
		end
	end
	table.insert(inst.targettable,target)
end

local function SendWilson(inst,attacker,target)
	if target:IsValid() then
		if attacker:GetDistanceSqToInst(target) > 50^2 and attacker.components.sanity then --Long ways away, it's taking from your mind to send swilsons there
			if target.components.combat then
				attacker.components.sanity:DoDelta(-5) --If using for combat, be significantly more expensive
			end
		end
		local swilson = SpawnPrefab("swilson_labotomized")
		local angle = math.random(0,614)/200
		local x,y,z = target.Transform:GetWorldPosition()
		swilson.Transform:SetPosition(x+1.5*math.cos(angle),y,z+1.5*math.sin(angle))
		if attacker.prefab == "wilson" then
			swilson.attack = 34
			swilson.work = 1.5
			swilson.Transform:SetScale(0.8,0.8,0.8)
		end
		if target.components.health then
			swilson.LabAttack(swilson,attacker,target)
		elseif target.components.workable then
			swilson.LabWork(swilson,attacker,target)
		end
	end
end

local function CleanTable(inst,attacker)
	for i,v in ipairs(inst.targettable) do
		if v:IsValid() and (v:HasTag("stump") or v.components.health and v.components.health:IsDead() or (attacker:GetDistanceSqToInst(v) > 100^2 and v.components.combat)) then -- Far enough away? Remove it from the table
			table.remove(inst.targettable,i)
			return CleanTable(inst,attacker)
		end
	end
end

local function WilsonTriesAgain(inst,attacker,target)
	for i,v in ipairs(inst.targettable) do
		if not v:HasTag("stump") then
			SendWilson(inst,attacker,v)
			if attacker.prefab == "wilson" then --Wilson sends a second Swilson that does a bit less damage
				SendWilson(inst,attacker,v)
			end
		end
	end
	CleanTable(inst,attacker)
end

local function onequip_shadow(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_axe", "swap_axe")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
	owner.AnimState:SetSymbolMultColour("swap_object", 0, 0, 0, .6)
end

local function onunequip_shadow(inst, owner)
	owner.AnimState:SetSymbolMultColour("swap_object", 1, 1, 1, 1)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end
end

local function onattack_shadow(inst, attacker, target)
	TryToAddToTable(inst,target)
	WilsonTriesAgain(inst,attacker,target)
end



local function shadow()
    local inst = common_fn("axe", "axe")

    if not TheWorld.ismastersim then
        return inst
    end
    inst:AddTag("shadow_item")
    inst:AddTag("shadow")
    inst:AddTag("sharp")

    --weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")

	--shadowlevel (from shadowlevel component) added to pristine state for optimization
	inst:AddTag("shadowlevel")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/um_shadow_axe.xml"
    inst.components.tool:SetAction(ACTIONS.CHOP, 2)

	if inst.components.finiteuses ~= nil then
	    inst.components.finiteuses:SetConsumption(ACTIONS.CHOP, 1/4)
	end
	if inst.components.weapon ~= nil then
		inst.components.weapon:SetDamage(51)
		inst.components.weapon:SetOnAttack(onattack_shadow)
	end
    inst.components.equippable:SetOnEquip(onequip_shadow)
	inst.components.equippable:SetOnUnequip(onunequip_shadow)
    inst.components.equippable.dapperness = TUNING.CRAZINESS_MED --Same Insanity as Dsword
    inst.components.equippable.is_magic_dapperness = true
    local swap_data = {sym_build = "swap_axe", bank = "axe"}
    inst.components.floater:SetBankSwapOnFloat(true, -11, swap_data)
	inst.AnimState:SetMultColour(0, 0, 0, 0.6)
	inst.targettable = {}
	inst.WorkEffect = onattack_shadow
    return inst
end

return Prefab("um_shadow_axe", shadow)
