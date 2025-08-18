--[[
Documentation: KoreanWaffles

This code fixes a crash related to the Silken Sack when switching from a separated backpack layout
to an integrated one. Read further for a breakdown of the crash.

In scripts/widgets/containerwidget.lua, the "Open" function sets a listener for self.button that 
listens for a "continuefrompause" event which then calls self.button:Show() or self.button:Hide().

In scripts/screens/playerhud.lua, the "RefreshControllers" function is also triggered by a 
"continuefrompause" event, which calls the "Close" function in containerwidget.lua when switching
from a separated backpack layout to an integrated layout.

The "Close" function calls self.button:Kill() in containerwidget.lua and sets it to nil.

When the player switches from a separated backpack layout to an integrated layout while wearing a
backpack with a button (e.g. Silken Sack), the following scenario occurs:

1. The player first entered the settings screen to change backpack layouts, triggering a
"continuefrompause" event.
2. "continuefrompause" triggers "RefreshControllers" which kills the button in containerwidget.lua.
3. "continuefrompause" also causes self.button in containerwidget.lua to call either
self.button:Show() or self.button:Hide().
4. A client-side crash occurs because self.button is nil from step 2 (indexing a nil value).

The solution used here is to make sure the button is not nil after the "Close" function is run.

Refer to postinit/widgets/inventorybar.lua for more information regarding integrated layout support
for the Silken Sack.
]]

local env = env
GLOBAL.setfenv(1, GLOBAL)

local ImageButton = require("widgets/imagebutton")

env.AddClassPostConstruct("widgets/containerwidget", function(self, owner)
    local _Close = self.Close
    function self:Close()
        _Close(self)
        if not self.isopen and self.button == nil then
            self.button = self:AddChild(ImageButton(
                "images/ui.xml", "button_small.tex", "button_small_over.tex", 
                "button_small_disabled.tex", nil, nil, {1,1}, {0,0})
            )
            self.button:Hide()
        end
    end
end)
