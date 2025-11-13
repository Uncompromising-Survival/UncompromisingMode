local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Grid = require "widgets/grid"
local Spinner = require "widgets/spinner"

local TEMPLATES = require "widgets/redux/templates"


require("util")

local base_size = 128
local cell_size = 73
local row_w = cell_size
local row_h = cell_size;
local reward_width = 80
local row_spacing = 5

local food_size = cell_size + 20
local icon_size = 20 / (cell_size / base_size)


local MineralLogbookWidget = Class(Widget, function(self, parent)
    Widget._ctor(self, "MineralLogbookWidget")

    self.root = self:AddChild(Widget("root"))

    local backdrop = self.root:AddChild(Image("images/quagmire_recipebook.xml", "quagmire_recipe_menu_bg.tex"))
    backdrop:ScaleToSize(900, 550)
end)

function MineralLogbookWidget:BuildLogbook()
   
end

return MineralLogbookWidget
