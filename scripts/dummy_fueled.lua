local DummyFn = function() end
-- May move these dummy functions outside of the component and somewherer else to improve readability, if anyone wants to do that they can, but it's not necessary.

-- Set up the dummy fueled class
local DummyFueledClass = {}
-- Keep a the variables in the class definition incase they are referenced by another script. They shouldn't do anything, but they're *also* not nil
DummyFueledClass.consuming = false

DummyFueledClass.maxfuel = 0
DummyFueledClass.currentfuel = 0
DummyFueledClass.rate = 1

DummyFueledClass.no_sewing = nil --V2C: HACK COLON RIGHT PARANTHESIS, I mean, what choice do I have if I don't want to break mods -_ -
DummyFueledClass.accepting = false
DummyFueledClass.secondaryfueltype = nil
DummyFueledClass.sections = 1
DummyFueledClass.sectionfn = nil
DummyFueledClass.period = 1
DummyFueledClass.bonusmult = 1
DummyFueledClass.depleted = nil

-- Dummy functions, most should just be fixed to not return nil. There may be a way to reference the original class and hookup all the original functions to nil, but I'm not sure how you could loop through all the variables/functions in a class.

DummyFueledClass.OnRemoveFromEntity = DummyFn
DummyFueledClass.MakeEmpty = DummyFn
DummyFueledClass.OnSave = DummyFn
DummyFueledClass.OnLoad = DummyFn
DummyFueledClass.SetSectionCallback = DummyFn
DummyFueledClass.SetDepletedFn = DummyFn
DummyFueledClass.IsEmpty = function() return false end -- hook this up to an actual return, some items need to know if it's empty, there's no empty state for a chilled item, so it's always full
DummyFueledClass.IsFull = function() return true end   -- same logic, hook up, always true
DummyFueledClass.SetSections = DummyFn
DummyFueledClass.SetMultiplierFn = DummyFn
DummyFueledClass.CanAcceptFuelItem = function() return false end -- No, any chilled item is no longer refuelable, with the exception of the watering can which is slightly different since it uses fillable class
DummyFueledClass.SetMultiplierFn = DummyFn
DummyFueledClass.GetCurrentSection = function() return 1 end     -- should always appear as if it's full
DummyFueledClass.ChangeSection = DummyFn
DummyFueledClass.SetCanTakeFuelItemFn = DummyFn
DummyFueledClass.SetTakeFuelItemFn = DummyFn
DummyFueledClass.SetTakeFuelFn = DummyFn
DummyFueledClass.TakeFuelItem = DummyFn
DummyFueledClass.SetUpdateFn = DummyFn
DummyFueledClass.GetDebugString = function() return "This entity's fueled component is now a dummy class to prevent nil crashes from referencing. It does not provide any function anymore. Trying to adjust durability of perishable through this class will not work." end
DummyFueledClass.AddThreshold = DummyFn
DummyFueledClass.GetSectionPercent = function() return 1 end
DummyFueledClass.GetPercent = DummyFn -- Do not return a percentage for the indicator
DummyFueledClass.SetPercent = DummyFn
DummyFueledClass.SetFirstPeriod = DummyFn
DummyFueledClass.StartConsuming = DummyFn
DummyFueledClass.OnWallUpdate = DummyFn
DummyFueledClass.InitializeFuelLevel = DummyFn
DummyFueledClass.DoDelta = DummyFn
DummyFueledClass.OnUpdate = DummyFn
DummyFueledClass.StopConsuming = DummyFn
DummyFueledClass.LongUpdate = DummyFn

return DummyFueledClass
