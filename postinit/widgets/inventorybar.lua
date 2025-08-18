--[[
Documentation: KoreanWaffles

Klei does not support buttons or unique inventory slot backgrounds for integrated backpacks. This
code adds support for both these features which is used for the Silken Sack. Previously, players
could not use the bundling feature of the Silken Sack if they were using an integrated backpack
layout. The button to wrap a bundle would be absent and the unique backgrounds for the bundle
and silk slots would be missing as well.

Refer to postinit/widgets/containerwidget.lua for details regarding a crash related to integrated
backpack layouts.
]]

local env = env
GLOBAL.setfenv(1, GLOBAL)

local UpvalueHacker = require("tools/upvaluehacker")
local ImageButton = require("widgets/imagebutton")
local ItemTile = require("widgets/itemtile")

env.AddClassPostConstruct("widgets/inventorybar", function(self, owner)
    -- This function is used to highlight or grey out the backpack's button when it is valid to
    -- press. For example, the Silken Sack's wrap button will be greyed out when there is not
    -- Silk in its Silk slot or there are no valid items to bundle.
    function self:RefreshOverflowButton()
        local inventory = self.owner.replica.inventory
        local overflow = inventory:GetOverflowContainer()
        overflow = (overflow ~= nil and overflow:IsOpenedBy(self.owner)) and overflow or nil
        if not overflow then
            return
        end
        local container = overflow.inst
        local widget = overflow:GetWidget()
        if self.overflow_button ~= nil then
            if widget and widget.buttoninfo.validfn ~= nil then
                if widget.buttoninfo.validfn(container) then
                    self.overflow_button:Enable()
                else
                    self.overflow_button:Disable()
                end
            end
        end
    end

    self.inst:ListenForEvent("itemget", function(inst, data) self:RefreshOverflowButton() end, self.owner)
    self.inst:ListenForEvent("itemlose", function(inst, data) self:RefreshOverflowButton() end, self.owner)
    self.inst:ListenForEvent("refreshinventory", function(inst, data) self:RefreshOverflowButton() end, self.owner)

    -- Make sure to initially update the backpack's button when it is equipped, dropped, or its UI
    -- is refreshed.
    local _BackpackGet = UpvalueHacker.GetUpvalue(self.Rebuild, "RebuildLayout", "BackpackGet")
    local _BackpackLose = UpvalueHacker.GetUpvalue(self.Rebuild, "RebuildLayout", "BackpackLose")
    local _BackpackRefresh = UpvalueHacker.GetUpvalue(self.Rebuild, "RebuildLayout", "BackpackRefresh")

    local function BackpackGet(inst, data)
        local owner = ThePlayer
        if owner ~= nil and owner.HUD ~= nil and owner.replica.inventory:IsHolding(inst) then
            local inv = owner.HUD.controls.inv
            if inv ~= nil then
                inv:RefreshOverflowButton()
            end
        end
        return _BackpackGet(inst, data)
    end

    local function BackpackLose(inst, data)
        local owner = ThePlayer
        if owner ~= nil and owner.HUD ~= nil and owner.replica.inventory:IsHolding(inst) then
            local inv = owner.HUD.controls.inv
            if inv ~= nil then
                inv:RefreshOverflowButton()
            end
        end
        return _BackpackLose(inst, data)
    end

    local function BackpackRefresh(inst)
        local owner = ThePlayer
        local inventory = owner and owner.HUD and owner.replica.inventory or nil
        local overflow = inventory and inventory:GetOverflowContainer() or nil
        if overflow and overflow.inst == inst then
            local inv = owner.HUD.controls.inv
            if inv then
                inv:RefreshOverflowButton()
            end
        end
        return _BackpackRefresh(inst)
    end

    UpvalueHacker.SetUpvalue(self.Rebuild, BackpackGet, "RebuildLayout", "BackpackGet")
    UpvalueHacker.SetUpvalue(self.Rebuild, BackpackLose, "RebuildLayout", "BackpackLose")
    UpvalueHacker.SetUpvalue(self.Rebuild, BackpackRefresh, "RebuildLayout", "BackpackRefresh")

    -- RebuildLayout refeshes the visual components of the backpack. This includes creating all the
    -- inventory icons, positioning them, and in the case of the Silken Sack, creating the button.
    local _RebuildLayout = UpvalueHacker.GetUpvalue(self.Rebuild, "RebuildLayout")

    local function RebuildLayout(self, inventory, overflow, do_integrated_backpack, do_self_inspect)
        -- Call _RebuildLayout first to make sure widget elements are properly defined before we
        -- start modifying them.
        _RebuildLayout(self, inventory, overflow, do_integrated_backpack, do_self_inspect)
        local W = 68
        local INTERSEP = 28
        if do_integrated_backpack then
            
            local widget = overflow:GetWidget()
            -- Here we create the button for the Silken Sack. We want to position it to the right
            -- of the integrated layout arrow, right-flush with the head slot.
            if widget.buttoninfo ~= nil then
                local doer = self.owner
                local container = overflow.inst
    
                if doer ~= nil and doer.components.playeractionpicker ~= nil then
                    doer.components.playeractionpicker:RegisterContainer(container)
                end
        
                self.overflow_button = self.bottomrow:AddChild(ImageButton(
                    "images/ui.xml", "button_small.tex", "button_small_over.tex", 
                    "button_small_disabled.tex", nil, nil, {1,1}, {0,0})
                )
                self.overflow_button.image:SetScale(1.07)
                self.overflow_button.text:SetPosition(2,-2)
                self.overflow_button:SetPosition(self.inv[#self.inv]:GetPosition().x + W * 0.5 + INTERSEP + 181, 8)
                self.overflow_button:SetText(widget.buttoninfo.text)
                if widget.buttoninfo.fn ~= nil then
                    self.overflow_button:SetOnClick(function()
                        if doer ~= nil then
                            if doer:HasTag("busy") then
                                --Ignore button click when doer is busy
                                return
                            elseif doer.components.playercontroller ~= nil then
                                local iscontrolsenabled, ishudblocking = doer.components.playercontroller:IsEnabled()
                                if not (iscontrolsenabled or ishudblocking) then
                                    --Ignore button click when controls are disabled
                                    --but not just because of the HUD blocking input
                                    return
                                end
                            end
                        end
                        widget.buttoninfo.fn(container, doer)
                        self:RefreshOverflowButton()
                    end)
                end
                self.overflow_button:SetFont(BUTTONFONT)
                self.overflow_button:SetDisabledFont(BUTTONFONT)
                self.overflow_button:SetTextSize(33)
                self.overflow_button.text:SetVAlign(ANCHOR_MIDDLE)
                self.overflow_button.text:SetColour(0, 0, 0, 1)
                self.overflow_button:Show()
                self:RefreshOverflowButton()
        
                if TheInput:ControllerAttached() then
                    self.overflow_button:Hide()
                end
        
                self.overflow_button.inst:ListenForEvent("continuefrompause", function()
                    if TheInput:ControllerAttached() then
                        self.overflow_button:Hide()
                    else
                        self.overflow_button:Show()
                    end
                end, TheWorld)
            end

            -- If the container has custom inventory icon backgrounds, then override the default
            -- icons with the custom ones.
            for k = 1, #self.backpackinv do
                local bgoverride = widget.slotbg ~= nil and widget.slotbg[k] or nil
                local slot = self.backpackinv[k]
                if bgoverride ~= nil then
                    slot.bgimage = slot:AddChild(Image(bgoverride.atlas, bgoverride.image))
                end
                local item = overflow:GetItemInSlot(k)
                if item ~= nil then
                    slot:SetTile(ItemTile(item))
                end
            end
        end
    end
    
    UpvalueHacker.SetUpvalue(self.Rebuild, RebuildLayout, "RebuildLayout")
end)
