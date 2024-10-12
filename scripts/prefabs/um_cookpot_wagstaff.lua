require "prefabutil"

local cooking = require("cooking")

local assets =
{
    Asset("ANIM", "anim/cook_pot.zip"),
    Asset("ANIM", "anim/cook_pot_food.zip"),
    Asset("ANIM", "anim/ui_cookpot_1x4.zip"),
	Asset("ANIM", "anim/um_cookpot_wagstaff.zip"),
	Asset("ANIM", "anim/um_cookpot_wagstaff_display.zip"),
	Asset("ANIM", "anim/um_cookpot_wagstaff_lever.zip"),
}

local prefabs =
{
    "collapse_small",
	"um_cookpot_wagstaff_display",
}


for k, v in pairs(cooking.recipes.cookpot) do
    table.insert(prefabs, v.name)

	if v.overridebuild then
        table.insert(assets, Asset("ANIM", "anim/"..v.overridebuild..".zip"))
	end
end



local function onhammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    if not inst:HasTag("burnt") and inst.components.stewer_wagstaff.product ~= nil and inst.components.stewer_wagstaff:IsDone() then
        inst.components.stewer_wagstaff:Harvest()
    end
    if inst.components.container ~= nil then
        inst.components.container:DropEverything()
    end
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("metal")
    inst:Remove()
end

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then
        if inst.components.stewer_wagstaff:IsCooking() then
            inst.AnimState:PlayAnimation("hit_cooking")
            inst.AnimState:PushAnimation("cooking_loop", true)
            inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_close")
        elseif inst.components.stewer_wagstaff:IsDone() then
            inst.AnimState:PlayAnimation("hit_full")
            inst.AnimState:PushAnimation("idle_full", false)
        else
            if inst.components.container ~= nil and inst.components.container:IsOpen() then
                inst.components.container:Close()
                --onclose will trigger sfx already
            else
                inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_close")
            end
            inst.AnimState:PlayAnimation("hit_empty")
            inst.AnimState:PushAnimation("idle_empty", false)
        end
    end
end

--anim and sound callbacks

local function startcookfn(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("cooking_loop", true)
        inst.SoundEmitter:KillSound("snd")
        inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_rattle", "snd")
        inst.Light:Enable(true)
    end
end

local function onopen(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("cooking_pre_loop")
        inst.SoundEmitter:KillSound("snd")
        inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_open")
        inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot", "snd")
    end
end

local function onclose(inst)
    if not inst:HasTag("burnt") then
        if not inst.components.stewer_wagstaff:IsCooking() then
            inst.AnimState:PlayAnimation("idle_empty")
            inst.SoundEmitter:KillSound("snd")
        end
        inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_close")
    end
end

local function SetProductSymbol(inst, product, overridebuild)
    local recipe = cooking.GetRecipe(inst.prefab, product)
    local potlevel = recipe ~= nil and recipe.potlevel or nil
    local build = (recipe ~= nil and recipe.overridebuild ~= nil and recipe.overridebuild) or "cook_pot_food"
    local overridesymbol = (recipe ~= nil and recipe.overridesymbolname) or product

    if potlevel == "high" then
        inst.AnimState:Show("swap_high")
        inst.AnimState:Hide("swap_mid")
        inst.AnimState:Hide("swap_low")
    elseif potlevel == "low" then
        inst.AnimState:Hide("swap_high")
        inst.AnimState:Hide("swap_mid")
        inst.AnimState:Show("swap_low")
    else
        inst.AnimState:Hide("swap_high")
        inst.AnimState:Show("swap_mid")
        inst.AnimState:Hide("swap_low")
    end
    inst.AnimState:OverrideSymbol("swap_cooked", build, overridesymbol)
end

local function spoilfn(inst)
    if not inst:HasTag("burnt") then
        inst.components.stewer_wagstaff.product = inst.components.stewer_wagstaff.spoiledproduct
        SetProductSymbol(inst, inst.components.stewer_wagstaff.product)
    end
end

local function ShowProduct(inst)
    if not inst:HasTag("burnt") then
        local product = inst.components.stewer_wagstaff.product
        SetProductSymbol(inst, product, IsModCookingProduct(inst.prefab, product) and product or nil)
    end
end

local function donecookfn(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("cooking_pst")
        inst.AnimState:PushAnimation("idle_full", false)
        ShowProduct(inst)
        inst.SoundEmitter:KillSound("snd")
        inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_finish")
        inst.Light:Enable(false)
    end
end

local function continuedonefn(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("idle_full")
        ShowProduct(inst)
    end
end

local function continuecookfn(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("cooking_loop", true)
        inst.Light:Enable(true)
        inst.SoundEmitter:KillSound("snd")
        inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_rattle", "snd")
    end
end

local function harvestfn(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("idle_empty")
        inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_close")
    end
end

local function getstatus(inst)
    return (inst:HasTag("burnt") and "BURNT")
        or (inst.components.stewer_wagstaff:IsDone() and "DONE")
        or (not inst.components.stewer_wagstaff:IsCooking() and "EMPTY")
        or (inst.components.stewer_wagstaff:GetTimeToCook() > 15 and "COOKING_LONG")
        or "COOKING_SHORT"
end

local function MakeHologram(hologram,inst,scale)
	hologram:AddTag("FX")
	hologram:AddTag("NOCLICK")
	hologram.Transform:SetPosition(inst.Transform:GetWorldPosition())
	hologram.Physics:Stop()
	hologram:RemoveComponent("edible")
	hologram:RemoveComponent("inventoryitem")
	hologram.persists = false	
	hologram.AnimState:SetErosionParams(0, -0.2, -1.0)
	hologram.Transform:SetScale(scale,scale,scale)
	hologram:RemoveComponent("inspectable")
	hologram:DoTaskInTime(1,function(hologram) hologram:WatchWorldState("startday", function(hologram) hologram:Remove() end) end) -- need a delay, bc the "startday" command sometimes gets heard
	hologram:RemoveComponent("burnable")
	hologram:RemoveComponent("perishable")
end

	-- Spawn Dish Hologram
local function DishHologram(inst,dish)
	local hologram = SpawnPrefab(dish)
	hologram.entity:AddFollower()
	hologram.Follower:FollowSymbol(inst.display.GUID, "swap_maindish", 0, 45, 0)
	MakeHologram(hologram,inst,0.35)
	table.insert(inst.display.holograms,hologram)
	-- inst.display.AnimState:ClearOverrideSymbol("swap_maindish")
	-- inst.display.AnimState:OverrideSymbol("swap_maindish", GetInventoryItemAtlas(dish..".tex"), dish..".tex")
end



	-- Spawn Hologram
local function Hologram(inst,ingredient,i)
	local hologram = SpawnPrefab(ingredient)
	hologram.entity:AddFollower()
	hologram.Follower:FollowSymbol(inst.display.GUID, "swap_bulb"..i, 0, 80, 0)
	local scale = 0.45
	if ingredient == "giant_blueberry" then
		scale = 0.3
	end

	MakeHologram(hologram,inst,scale)
	table.insert(inst.display.holograms,hologram)
	
	-- Couldn't get minisign approach to work for items with a nonstandard inventory atlas
	-- local ingredient_atlas = GetInventoryItemAtlas(ingredient..".tex") 
	-- if ingredient == "giant_blueberry" then
		-- local temp = SpawnPrefab("giant_blueberry")
		-- ingredient_atlas = temp.replica.inventoryitem:GetAtlas()
		-- temp:Remove()
	-- end

	-- -- for i,v in ipairs(um_foods) do
		-- -- if ingredient == v then
			-- -- ingredient_name = nil
		-- -- end
	-- -- end
	-- inst.display.AnimState:ClearOverrideSymbol("swap_bulb"..i)
	-- inst.display.AnimState:OverrideSymbol("swap_bulb"..i, ingredient_atlas, ingredient..".tex")
end

local function MakeDisplay(inst)
	if not inst.displayx then
		local minim = 1
		local maxim = 2
		inst.displayx = math.random() > 0.5 and math.random(minim,maxim) or math.random(-maxim,-minim)
		inst.displayz = math.random() > 0.5 and math.random(minim,maxim) or math.random(-maxim,-minim)
	end
	local x,y,z = inst.Transform:GetWorldPosition()
	inst.display = SpawnPrefab("um_cookpot_wagstaff_display")
	inst.display.pot = inst
	inst.display.Transform:SetPosition(x+inst.displayx,0,z+inst.displayz)
	inst.display.AnimState:HideSymbol("lever")
end

local function onsave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end
	if data and inst.todays_dish then
		data.todays_dish = inst.todays_dish
		data.todays_ingredients = inst.todays_ingredients
	end
	if data and inst.displayx then
		data.displayx = inst.displayx
		data.displayz = inst.displayz
	end
	if inst.lever_ready then
		data.lever_ready = true
	end	
	if inst.display.lever then
		data.lever = true
	end
end

local function onload(inst, data)
    if data ~= nil and data.burnt then
        inst.components.burnable.onburnt(inst)
        inst.Light:Enable(false)
    end

	if data.displayx and data.todays_dish then
		inst.displayx = data.displayx
		inst.displayz = data.displayz
		inst.todays_dish = data.todays_dish
		inst.todays_ingredients = data.todays_ingredients
		MakeDisplay(inst)
		inst.display.holograms = {}
		DishHologram(inst,inst.todays_dish)
		
		for i = 1,4 do
			Hologram(inst,inst.todays_ingredients[i],i)
		end
		if data.lever_ready then
			inst.lever_ready = true
			inst.display.ReadyTheLever(inst.display)
			
		end	
		if data.lever then
			inst.display.lever = true
			inst.display.components.trader.enabled = false
			inst.display.AnimState:ShowSymbol("lever")
			if not data.lever_ready then
				inst.display.AnimState:PlayAnimation("pull",false)
			end
		end
	end

end

local function onloadpostpass(inst, newents, data)
    if data and data.additems and inst.components.container then
        for i, itemname in ipairs(data.additems)do
            local ent = SpawnPrefab(itemname)
            inst.components.container:GiveItem( ent )
        end
    end
end

local function cookpot_common(inst)
    inst.AnimState:SetBank("cook_pot")
    inst.AnimState:SetBuild("um_cookpot_wagstaff")
    inst.AnimState:PlayAnimation("idle_empty")
    inst.scrapbook_anim = "idle_empty"
    inst.MiniMapEntity:SetIcon("cookpot.png")
end

local function cookpot_common_master(inst)
    inst.components.container:WidgetSetup("um_cookpot_wagstaff")
end

local dishes = {
	"barnaclinguine",
	"barnaclesushi",
	"californiaroll",
	"dragonpie",
	"figatoni",
	"koalefig_trunk",
	"fishtacos",
	"waffles",
	"pumpkincookie",
	"pepperpopper",
	"lobsterdinner",
	
	-- UM Specific
	"theatercorn",
	"viperjam",
	"zaspberryparfait",
	"devilsfruitcake",
	"snotroast",
	"stuffed_peeper_poppers",
}

local effect_dishes = {
	"dragonpie",
	"waffles",
	"pepperpopper",
	"lobsterdinner",
	"devilsfruitcake",
	-- Buffer dishes, still decent, only if not wortox though
	
	-- Effect Dishes
	"theatercorn",
	"viperjam",
	"zaspberryparfait",
	"snotroast",
	"stuffed_peeper_poppers",
}

local function RedoTodays(inst,bias_to_effects)
	inst.todays_ingredients = {}
	inst.display.holograms = {}
	for i = 1,4 do
		local chnce = math.random(1,186)
		local ingredient = "berries" -- failsafe
		if chnce < 25 then -- smallmeat
			chnce = math.random()
			if chnce < 0.2 then
				ingredient = "monstersmallmeat"
			elseif chnce < 0.3 then
				ingredient = "froglegs"
			elseif chnce < 0.4 then
				ingredient = "drumstick"
			elseif chnce < 0.5 then
				ingredient = "batwing"
			else
				ingredient = "smallmeat"
			end
		elseif chnce < 75 then -- bigmeat
			chnce = math.random()
			if chnce < 0.2 then
				ingredient = "monstermeat"
			else
				ingredient = "meat"
			end		
		elseif chnce < 90 then -- small veggies
			chnce = math.random()
			if chnce < 0.33 then
				ingredient = "red_cap"
			elseif chnce < 0.66 then
				ingredient = "green_cap"
			else
				ingredient = "blue_cap"
			end			
		elseif chnce < 115 then -- large veggies
			chnce = math.random()
			if chnce < 0.33 then
				ingredient = "cactus_meat"
			else
				ingredient = "carrot"
			end				
		elseif chnce < 150 then -- ice and small fruits
			if TheWorld.state.iswinter or TheWorld.state.isspring then
				ingredient = "ice"
			else
				chnce = math.random()
				if chnce < 0.33 then
					ingredient = "berries"
				elseif chnce < 0.66 then
					ingredient = "acorn"
				else 
					ingredient = "honey"
				end				
			end
		elseif chnce < 175 then -- eggs
			chnce = math.random()
			if chnce < 0.33 then
				ingredient = "um_monsteregg"
			else
				ingredient = "bird_egg"
			end		
		else -- only viable large fruit
			ingredient = "giant_blueberry"	
		end
		table.insert(inst.todays_ingredients,ingredient)
		inst:DoTaskInTime(0,function(inst) Hologram(inst,ingredient,i) end)
	end
	local dish = dishes[math.random(#dishes)]
	if bias_to_effects then
		dish = effect_dishes[math.random(#effect_dishes)]
	end
	
	inst.todays_dish = dish
	inst:DoTaskInTime(0,function(inst) DishHologram(inst,dish) end)
end

local function LeverReady(inst)
	inst:AddComponent("activatable")
    inst.components.activatable.OnActivate = function(inst)
		inst:RemoveComponent("activatable")
		inst.AnimState:PlayAnimation("pull",false)
		for i,v in ipairs(inst.holograms) do
			v:Remove()
		end
		RedoTodays(inst.pot,true)

		inst.pot.lever_ready = nil
	end
    inst.components.activatable.inactive = true
	inst.components.activatable.quickaction = false
end

local function MakeCookPot(name, common_postinit, master_postinit, assets, prefabs)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddLight()
        inst.entity:AddNetwork()

		inst:SetDeploySmartRadius(1) --recipe min_spacing/2
        MakeObstaclePhysics(inst, .5)

        inst.Light:Enable(false)
        inst.Light:SetRadius(.6)
        inst.Light:SetFalloff(1)
        inst.Light:SetIntensity(.5)
        inst.Light:SetColour(60/255,200/255,200/255)
        --inst.Light:SetColour(1,0,0)

        inst:AddTag("structure")

        --stewer (from stewer component) added to pristine state for optimization
        inst:AddTag("stewer")

        if common_postinit ~= nil then
            common_postinit(inst)
        end

        MakeSnowCoveredPristine(inst)

        inst.scrapbook_specialinfo = "CROCKPOT"

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("stewer_wagstaff")
        inst.components.stewer_wagstaff.onstartcooking = startcookfn
        inst.components.stewer_wagstaff.oncontinuecooking = continuecookfn
        inst.components.stewer_wagstaff.oncontinuedone = continuedonefn
        inst.components.stewer_wagstaff.ondonecooking = donecookfn
        inst.components.stewer_wagstaff.onharvest = harvestfn
        inst.components.stewer_wagstaff.onspoil = spoilfn

        inst:AddComponent("container")
        --inst.components.container:WidgetSetup("cookpot")
        inst.components.container.onopenfn = onopen
        inst.components.container.onclosefn = onclose
        inst.components.container.skipclosesnd = true
        inst.components.container.skipopensnd = true

        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = getstatus

        inst:AddComponent("lootdropper")

        inst:AddComponent("hauntable")
        inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)
        --inst.components.hauntable:SetOnHauntFn(OnHaunt)

        MakeSnowCovered(inst)

        MakeSmallPropagator(inst)

        inst.OnSave = onsave
        inst.OnLoad = onload
        inst.OnLoadPostPass = onloadpostpass
		
        if master_postinit ~= nil then
            master_postinit(inst)
        end

		RemovePhysicsColliders(inst)
	
		inst:DoTaskInTime(0,function(inst)
			if not inst.displayx then
				MakeDisplay(inst)
			end
			if not inst.todays_dish then
				inst:DoTaskInTime(0,RedoTodays)
			end
		end)
		
		inst:WatchWorldState("startday",function(inst)
				if inst.display and inst.display.lever and not inst.lever_ready then
					inst.display.AnimState:PlayAnimation("ready",false)
					inst.display.AnimState:PushAnimation("idle",true)
					inst.display:ReadyTheLever(inst.display)
				end
			RedoTodays(inst)
		end)
		
        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

local function fndisplay()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddMiniMapEntity()
	inst.entity:AddLight()
	inst.entity:AddNetwork()

	inst:SetDeploySmartRadius(1) --recipe min_spacing/2
	--MakeObstaclePhysics(inst, .5)

	inst.Light:Enable(true)
	inst.Light:SetRadius(.6)
	inst.Light:SetFalloff(1)
	inst.Light:SetIntensity(.5)
	inst.Light:SetColour(60/255,200/255,200/255)

	inst:AddTag("structure")

    inst.AnimState:SetBank("um_cookpot_wagstaff_display")
    inst.AnimState:SetBuild("um_cookpot_wagstaff_display")
   
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end
	
	inst.AnimState:PlayAnimation("idle",true)
	inst:AddComponent("inspectable")

	inst.persists = false
	inst.ReadyTheLever = LeverReady
	
	--RemovePhysicsColliders(inst)
	MakeSmallPropagator(inst)
	
	inst:AddComponent("trader")
	inst.components.trader.test = function(inst, item)
		return item.prefab == "um_cookpot_wagstaff_lever"
	end
	inst.components.trader.enabled = true
    inst.components.trader.onaccept =
        function(inst, giver, item)
			inst.AnimState:ShowSymbol("lever")
            inst.AnimState:PlayAnimation("ready",false)
			inst.AnimState:PushAnimation("idle",true)
			LeverReady(inst)
			inst.lever = true
			inst.components.trader.enabled = false
        end	
	
	return inst
end
	
local function fnlever()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()



    inst.AnimState:SetBank("um_cookpot_wagstaff_lever")
    inst.AnimState:SetBuild("um_cookpot_wagstaff_lever")
   
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end
	inst.AnimState:PlayAnimation("idle",true)
	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/um_cookpot_wagstaff_lever.xml"

	inst:AddComponent("tradable")
	return inst
end

return MakeCookPot("um_cookpot_wagstaff", cookpot_common, cookpot_common_master,assets),
Prefab("um_cookpot_wagstaff_display",fndisplay),
Prefab("um_cookpot_wagstaff_lever",fnlever)
