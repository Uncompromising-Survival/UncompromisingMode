-- Credit to the implementation of this to ClumsyPenny - From "Show Multiple Products" client mod
-- Client mod workshop link: https://steamcommunity.com/sharedfiles/filedetails/?id=2959976083

local G = GLOBAL
local Text = G.require("widgets/text")

local FONT = TUNING.DSTU.UI_SHOWMULTIPRODUCTS_FONT == "UIFONT" and G.UIFONT or TUNING.DSTU.UI_SHOWMULTIPRODUCTS_FONT == "TALKINGFONT" and G.TALKINGFONT or G.NUMBERFONT  --Changed font for bettter looks. -C
local FONTSIZE = 32
local TEXTCOLOUR = G.UICOLOURS.GOLD_UNIMPORTANT

-- Add the number to the recipes in the grid list
AddClassPostConstruct("widgets/redux/craftingmenu_widget", function(self, owner, crafting_hud, height)
    -- Give each cell a text widget
    for _,widget in pairs(self.recipe_grid.widgets_to_update) do
        widget.numtogive = widget.item_img:AddChild(Text(FONT, FONTSIZE, "", TEXTCOLOUR))
        widget.numtogive:SetPosition(30,-24)
        widget.numtogive:Hide()
    end

    -- Show and hide the text accordingly
    local _old_update_fn = self.recipe_grid.update_fn

    self.recipe_grid.update_fn = function(context, widget, data, index)
        _old_update_fn(context, widget, data, index)

        if data ~= nil and data.recipe ~= nil and data.meta ~= nil and data.recipe.numtogive ~= nil and data.recipe.numtogive > 1 then
            widget.numtogive:SetString(data.recipe.numtogive)
            widget.numtogive:Show()
        else
            widget.numtogive:SetString("")
            widget.numtogive:Hide()
        end
    end
end)

-- Add the number to the recipes in the pin bar
AddClassPostConstruct("widgets/redux/craftingmenu_pinslot", function(self, owner, craftingmenu, slot_num, pin_data)
    self.item_img.numtogive = self.item_img:AddChild(Text(FONT, FONTSIZE, "", TEXTCOLOUR))
    self.item_img.numtogive:SetPosition(30,-24)
    self.item_img.numtogive:Hide()

    local _old_refresh = self.Refresh

    -- Show and hide the text accordingly
    function self:Refresh(...)
        _old_refresh(self, ...)

        if not self.item_img.numtogive or not self.item_img.numtogive.inst:IsValid() then return end

        local data = self.craftingmenu:GetRecipeState(self.recipe_name) 
        if data ~= nil and data.recipe ~= nil and data.meta ~= nil and data.recipe.numtogive ~= nil and data.recipe.numtogive > 1 then
            self.item_img.numtogive:SetString(data.recipe.numtogive)
            self.item_img.numtogive:Show()
        else
            self.item_img.numtogive:SetString("")
            self.item_img.numtogive:Hide()
        end
    end
end)