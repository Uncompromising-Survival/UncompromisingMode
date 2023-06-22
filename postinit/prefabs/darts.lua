local env = env
GLOBAL.setfenv(1, GLOBAL)


env.AddPrefabPostInit("blowdart_fire", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	local _attackfn = inst.components.weapon.onattack -- Store the old function.
	
	SetSharedLootTable('um_firedart_splash_fires',
	{
		{ 'houndfire', 1.0 },
		{ 'houndfire', 0.5 }
	})
	
	local function fireattack(inst, attacker, target)
		local groundfire = SpawnPrefab("houndfire")
		groundfire.Transform:SetPosition(target.Transform:GetWorldPosition())
		groundfire.Transform:SetScale(1.5, 1.5, 1.5)
		
		inst.components.lootdropper:DropLoot(inst:GetPosition())
		
		if attacker:HasTag("pyromaniac") then
			inst.components.lootdropper:DropLoot(inst:GetPosition())
			inst.components.lootdropper:DropLoot(inst:GetPosition())
		end
		
		-- If the target is already on fire, do extra stuff.
		if target ~= nil and target.components.burnable ~= nil and target.components.burnable:IsBurning() then
			SpawnPrefab("magmafire").Transform:SetPosition(target.Transform:GetWorldPosition())
			SpawnPrefab("explode_small").Transform:SetPosition(target.Transform:GetWorldPosition())
			inst.SoundEmitter:PlaySound("dontstarve/common/balloon_pop")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/hound/firehound_explo")
	
			-- Instantly damages anything within a radius.
			local x, y, z = target.Transform:GetWorldPosition()
			local ents = TheSim:FindEntities(x, y, z, 3, nil, { "INLIMBO", "invisible", "noattack" })
			if #ents > 0 then
				for i, v in pairs(ents) do
					if v.components.burnable ~= nil then
						v.components.burnable:Ignite()
					end
					if v.components.combat ~= nil then
						v.components.combat:GetAttacked(attacker, 50, nil, "fire")
						if attacker:HasTag("pyromaniac") then
							v.components.combat:GetAttacked(attacker, 25, nil, "fire")
						end
					end
				end
			end
		end
		
		_attackfn(inst, attacker, target) -- Run the old function.
	end
	
	inst.entity:AddSoundEmitter()
	
	inst.components.weapon:SetDamage(20)
	inst.components.weapon:SetOnAttack(fireattack)
	
	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("um_firedart_splash_fires")
end)


env.AddPrefabPostInit("blowdart_yellow", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	local _attackfn = inst.components.weapon.onattack
	
	local function yellowattack(inst, attacker, target)
		if target:IsValid() and (target:HasTag("chess") or target:HasTag("uncompromising_pawn") or target:HasTag("twinofterror") and not target:HasTag("fleshyeye")) then
			if not target.components.debuffable then
				target:AddComponent("debuffable")
			end
			target.components.debuffable:AddDebuff("shockstundebuff", "shockstundebuff")
			
		end

		_attackfn(inst, attacker, target)
	end
	inst.components.weapon:SetOnAttack(yellowattack)
end)
