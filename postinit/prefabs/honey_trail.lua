--[[
	Add washable compatibility with honey 
]]

local honeys = {"honey_trail"}
if GLOBAL.KnownModIndex:IsModEnabled("workshop-1289779251") then
    table.insert(honeys,"cherry_honey_trail")
end

for _,honey in ipairs(honeys) do
    AddPrefabPostInit(honey, function(inst)
        inst:AddTag("um_washable_goo")
        if inst:HasTag("FX") then
            inst:RemoveTag("FX")
        end
        if not TheWorld.ismastersim then return inst end
    end)
end