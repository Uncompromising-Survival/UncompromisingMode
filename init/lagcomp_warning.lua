--[[Credit: https://gitlab.com/IslandAdventures/ia-core/-/blob/6fc110ed7de1080effd9c2b6df772637471bbefb/postinit/prefabs/world.lua]]

local env = env
GLOBAL.setfenv(1, GLOBAL)

STRINGS.UI.UM_LAG_COMPENSATION_WARNING = {
    TITLE = "Warning",
    TEXT = "Lag Compensation causes issues some of Uncompromising Mode's features and characters.\nContinue with it enabled at your own risk!",
    IGNORE = "Keep it on",
    DISABLE = "Turn it off",
}



------------------------------------

local PopupDialogScreen = require("screens/redux/popupdialog")
local Widget = require("widgets/widget")
local ImageButton = require("widgets/imagebutton")
local Text = require("widgets/text")

local function LagCompensationWarning()
    if Profile:GetMovementPredictionEnabled() and TheSim:GetSetting("misc", "lagcompwarning") ~= "false" then
        local checkbox_parent = Widget("checkbox_parent")
        local checkbox = checkbox_parent:AddChild(ImageButton("images/ui.xml", "checkbox_off.tex", "checkbox_off_highlight.tex", "checkbox_off_disabled.tex", nil, nil, {1,1}, {0,0}))
        local text = checkbox_parent:AddChild(Text(CHATFONT, 30, STRINGS.UI.SERVERLISTINGSCREEN.SHOW_MOD_WARNING))
        local textW, textH = text:GetRegionSize()
        local imageW, imageH = checkbox:GetSize()
        text:SetVAlign(ANCHOR_LEFT)
        text:SetColour(0,0,0,1)
        local checkbox_x = -textW/2 - (imageW*2)
        local region = 600
        checkbox:SetPosition(checkbox_x, 0)
        text:SetRegionSize(region,50)
        text:SetPosition(checkbox_x + textW/2 + imageW/1.5, -10)
        local bg = checkbox_parent:AddChild(Image("images/ui.xml", "single_option_bg.tex"))
        bg:MoveToBack()
        bg:SetClickable(false)
        bg:ScaleToSize(textW + imageW + 40, 50)
        bg:SetPosition(-75,2)
        checkbox_parent.do_warning = true
        checkbox_parent.focus_forward = checkbox
        checkbox:SetOnClick(function()
            checkbox_parent.do_warning = not checkbox_parent.do_warning
            if checkbox_parent.do_warning then
                checkbox:SetTextures("images/ui.xml", "checkbox_off.tex", "checkbox_off_highlight.tex", "checkbox_off_disabled.tex", nil, nil, {1,1}, {0,0})
            else
                checkbox:SetTextures("images/ui.xml", "checkbox_on.tex", "checkbox_on_highlight.tex", "checkbox_on_disabled.tex", nil, nil, {1,1}, {0,0})
            end
        end)
        local menuitems =
        {
            {widget=checkbox_parent, offset=Vector3(250,70,0)},
            {text=STRINGS.UI.UM_LAG_COMPENSATION_WARNING.IGNORE,
                cb = function()
                    TheSim:SetSetting("misc", "lagcompwarning", tostring(checkbox_parent.do_warning))
                    TheFrontEnd:PopScreen()
                end, offset=Vector3(-90,0,0)},
            {text=STRINGS.UI.UM_LAG_COMPENSATION_WARNING.DISABLE,
                cb = function()
                    Profile:SetMovementPredictionEnabled(false) ThePlayer:EnableMovementPrediction(false) TheFrontEnd:PopScreen()
                end, offset=Vector3(-90,0,0)}
        }

        local lag_comp_warning = PopupDialogScreen(STRINGS.UI.UM_LAG_COMPENSATION_WARNING.TITLE, STRINGS.UI.UM_LAG_COMPENSATION_WARNING.TEXT, menuitems)
        lag_comp_warning.dialog.actions.items[1]:SetScale(1)
        lag_comp_warning.dialog.body:SetScale(0.8)
        lag_comp_warning.dialog.body:SetPosition(0, 40, 0)
        lag_comp_warning.dialog.actions.items[1]:SetFocusChangeDir(MOVE_DOWN, lag_comp_warning.dialog.actions.items[2])
        lag_comp_warning.dialog.actions.items[1]:SetFocusChangeDir(MOVE_RIGHT, nil)
        lag_comp_warning.dialog.actions.items[2]:SetFocusChangeDir(MOVE_LEFT, nil)
        lag_comp_warning.dialog.actions.items[2]:SetFocusChangeDir(MOVE_RIGHT, lag_comp_warning.dialog.actions.items[3])
        lag_comp_warning.dialog.actions.items[2]:SetFocusChangeDir(MOVE_UP, lag_comp_warning.dialog.actions.items[1])
        lag_comp_warning.dialog.actions.items[3]:SetFocusChangeDir(MOVE_LEFT, lag_comp_warning.dialog.actions.items[2])
        lag_comp_warning.dialog.actions.items[3]:SetFocusChangeDir(MOVE_UP, lag_comp_warning.dialog.actions.items[1])
        lag_comp_warning.dialog.actions.items[1]:SetPosition(305,55,0)
        lag_comp_warning.dialog.actions.items[2]:SetPosition(105,-10,0)
        lag_comp_warning.dialog.actions.items[3]:SetPosition(355,-10,0)

        TheFrontEnd:PushScreen(lag_comp_warning)
    end
end

env.AddPrefabPostInit("world", function(inst)
    if not inst.ismastersim then
        inst:ListenForEvent("playeractivated", LagCompensationWarning)
        return
    end
end)