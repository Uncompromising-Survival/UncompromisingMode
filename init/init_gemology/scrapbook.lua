local env = env
GLOBAL.setfenv(1, GLOBAL)

local GEM_DEFS = require("gemology_defs").GEM_DEFS
local scrapbook_prefabs = require("scrapbook_prefabs")
local dataset = require("screens/redux/scrapbookdata")
local UpvalueHacker = require("tools/upvaluehacker")
local ScrapbookScreen = require("screens/redux/scrapbookscreen")
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"
local Image = require "widgets/image"
local Widget = require "widgets/widget"
local UIAnim = require "widgets/uianim"

require("um_gemology_geode_defs")
require("simutil")

--strings todo: move this somewhere else?
STRINGS.SCRAPBOOK.CATS.GEMOLOGY = "Gemology"
STRINGS.SCRAPBOOK.SUBCATS.GEMOLOGYGEM = "Strange Gem"
STRINGS.SCRAPBOOK.SUBCATS.GEODE = "Geode"
STRINGS.SCRAPBOOK.SUBCATS.GEMOLOGY = "Gemology"

STRINGS.SCRAPBOOK.SPECIALINFO.GEMOLOGY_FORGE = "Can enchant tools and weapons with Strange Gems to amplify them with special effects.\n\nGem effects fade with usage."
STRINGS.SCRAPBOOK.SPECIALINFO.GEMOLOGY_GEM = "Can be used at a " .. STRINGS.NAMES.UM_GEMOLOGYFORGE .. " to apply a special effect to a Tool or Weapon."



--add gemology category
table.insert(SCRAPBOOK_CATS, "gemology")
local _MakeSideBar = ScrapbookScreen.MakeSideBar

function ScrapbookScreen:MakeSideBar(...)
    _MakeSideBar(self, ...)

    local buttonwidth = 252 / 2.2  --75
    local buttonheight = 112 / 2.2 --30
    local PANEL_WIDTH = 1000
    local PANEL_HEIGHT = 530
    local SEARCH_BOX_HEIGHT = 40
    local SEARCH_BOX_WIDTH = 300

    local FILLER = "zzzzzzz"
    local UNKNOWN = "unknown"

    local UK_TINT = { 0.5, 0.5, 0.5, 1 }

    -- PANEL_HEIGHT

    local totalheight = PANEL_HEIGHT - 100

    local MakeButton = function(idx, data)
        local y = totalheight / 2 - ((totalheight / 7) * idx - 1) + 50

        local buttonwidget = self.root:AddChild(Widget())

        local button = buttonwidget:AddChild(ImageButton("images/scrapbook.xml", "tab.tex"))
        button:ForceImageSize(buttonwidth, buttonheight)
        button.scale_on_focus = false
        button.basecolor = { data.color[1], data.color[2], data.color[3] }
        button:SetImageFocusColour(math.min(1, data.color[1] * 1.2), math.min(1, data.color[2] * 1.2), math.min(1, data.color[3] * 1.2), 1)
        button:SetImageNormalColour(data.color[1], data.color[2], data.color[3], 1)
        button:SetImageSelectedColour(data.color[1], data.color[2], data.color[3], 1)
        button:SetImageDisabledColour(data.color[1], data.color[2], data.color[3], 1)
        button:SetOnClick(function()
            self:SelectSideButton(data.filter)
            self.current_dataset = self:CollectType(dataset, data.filter)
            self.current_view_data = self:CollectType(dataset, data.filter)
            self:SetGrid()
        end)

        buttonwidget.focusimg = button:AddChild(Image("images/scrapbook.xml", "tab_over.tex"))
        buttonwidget.focusimg:ScaleToSize(buttonwidth, buttonheight)
        buttonwidget.focusimg:SetClickable(false)
        buttonwidget.focusimg:Hide()

        buttonwidget.selectimg = button:AddChild(Image("images/scrapbook.xml", "tab_selected.tex"))
        buttonwidget.selectimg:ScaleToSize(buttonwidth, buttonheight)
        buttonwidget.selectimg:SetClickable(false)
        buttonwidget.selectimg:Hide()

        buttonwidget:SetOnGainFocus(function()
            buttonwidget.focusimg:Show()
        end)
        buttonwidget:SetOnLoseFocus(function()
            buttonwidget.focusimg:Hide()
        end)

        local text = button:AddChild(Text(HEADERFONT, 12, STRINGS.SCRAPBOOK.CATS[string.upper(data.name)], UICOLOURS.WHITE))
        text:SetPosition(10, -8)
        buttonwidget:SetPosition(522 + buttonwidth / 2, y)

        local total = 0
        local count = 0
        for i, set in pairs(dataset) do
            if set.type == data.filter then
                total = total + 1
                if set.knownlevel > 0 then
                    count = count + 1
                end
            end
        end
        if total > 0 then
            local percent = (count / total) * 100
            if percent < 1 then
                percent = math.floor(percent * 100) / 100
            else
                percent = math.floor(percent)
            end

            local progress = buttonwidget:AddChild(Text(HEADERFONT, 18, percent .. "%", UICOLOURS.GOLD))
            progress:SetPosition(15, 17)
        end

        buttonwidget.newcreatures = {}

        buttonwidget.flash = buttonwidget:AddChild(UIAnim())
        buttonwidget.flash:GetAnimState():SetBank("cookbook_newrecipe")
        buttonwidget.flash:GetAnimState():SetBuild("cookbook_newrecipe")
        buttonwidget.flash:GetAnimState():PlayAnimation("anim", true)
        buttonwidget.flash:GetAnimState():SetDeltaTimeMultiplier(1.25)
        buttonwidget.flash:SetScale(.8, .8, .8)
        buttonwidget.flash:SetPosition(40, 0, 0)
        buttonwidget.flash:Hide()
        buttonwidget.flash:SetClickable(false)

        buttonwidget.filter = data.filter
        buttonwidget.focus_forward = button

        table.insert(self.menubuttons, buttonwidget)
    end

    MakeButton(7, { name = "gemology", filter = "gemology", color = { 146 / 255, 70 / 255, 120 / 255 } })
end

--data stuff
--gem forge
scrapbook_prefabs["um_gemologyforge"] = true
dataset["um_gemologyforge"] = {
    name = "um_gemologyforge",
    tex = "um_gemologyforge.tex",
    subcat = "gemology",
    type = "POI",
    prefab = "um_gemologyforge",
    build = "um_gemforge",
    bank = "um_gemforge",
    anim = "idle",
    deps = {},
    specialinfo = "GEMOLOGY_FORGE"
}

--gems
local function GetKnownNameFromGem(name)
    local color = "DEFAULT"

    if string.find(recipe_type, "um_gemology") ~= nil then --just UM has the color stuff idk if any addons will apply, so we'll use the default.
        color = string.upper(string.gsub(string.gsub(recipe_type, "um_gemology", ""), "gem%d", ""))
    end

    return TheMineralLogbook:IsGemKnown(name) and STRINGS.NAMES[name] or STRINGS.NAMES.UM_GEMOLOGYGEM_UNKNOWN[color]
end


local function CreateGemologyEntryFromDefs(name, defs)
    
    local data = {
        name = name,
        type = "gemology",
        prefab = name,
        tex = "um_gemology" .. defs.img,
        stacksize = 10,
        bank = defs.bank,
        build = defs.build,
        anim = defs.anim,
        special_info = "GEMOLOGY_GEM",
        subcat = "gemologygem",
        notes = { gemology_gem = true }, --this will handles wheter to dynamically adjust description/name based on the mineral logbook.
        deps = { "um_gemologyforge", "ancientfruit_gem" },
        workable = "HAMMER"
    }

    scrapbook_prefabs[name] = true

    printwrap("DATA FOR "..name, data)
    print()

    table.insert(dataset["ancientfruit_gem"].deps, name)
    table.insert(dataset["um_gemologyforge"].deps, name)

    for k, v in pairs(GetGeodeSourcesFromGem(name)) do
        --table.insert(data.deps, v)
    end

    return data
end

--DESPAIR DESPAIR DESPAIR


for name, defs in pairs(GEM_DEFS) do
    local data = CreateGemologyEntryFromDefs(name, defs)
    env.AddPrefabPostInit(name, function(inst)
        inst.scrapbook_thingtype = data.type
        inst.scrapbook_specialinfo = data.special_info

        if inst.scrapbook_adddeps == nil then
            inst.scrapbook_adddeps = {}
        end

        ConcatArrays(inst.scrapbook_adddeps, data.deps)
    end)

    dataset[name] = data
end

--geode sources
-- save that for

--geodes
local function CreateGeodeEntryFromLootTable(name, defs)
    local buildbank = string.gsub(name, "gemology", "")
    local data = {
        subcat = "geode",
        name = name,
        tex = name .. ".tex",
        anim = "idle",
        build = buildbank,
        bank = buildbank,
        type = "gemology",
        prefab = name,
        stacksize = 10,
        workable = "HAMMER"
    }

    local deps = {}
end
