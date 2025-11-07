local function OnLabelTextDirty(inst)
    inst.label:SetText(inst.label_text:value()) 
    inst.label:Enable(true)
end

local function OnLabelUIOffsetDirty(inst)
    inst.label:SetUIOffset(inst.label_uioffset.x:value(), inst.label_uioffset.y:value(), inst.label_uioffset.z:value())
end

local function OnLabelColourDirty(inst)
    inst.label:SetColour(inst.label_colour.r:value(), inst.label_colour.g:value(), inst.label_colour.b:value(), inst.label_colour.a:value())
end

local function RegisterNetListeners(inst)
    inst:ListenForEvent("label_textdirty", OnLabelTextDirty)
    inst:ListenForEvent("label_uioffsetdirty", OnLabelUIOffsetDirty)
    inst:ListenForEvent("label_colourdirty", OnLabelColourDirty)
    OnLabelTextDirty(inst)
    OnLabelUIOffsetDirty(inst)
    OnLabelColourDirty(inst)
end

local function OnSetText(inst, text)
    inst.label_text:set(text)
    OnLabelTextDirty(inst)
end

local function OnSetUIOffset(inst, x, y, z)
    inst.label_uioffset.x:set(x)
    inst.label_uioffset.y:set(y)
    inst.label_uioffset.z:set(z)
    OnLabelUIOffsetDirty(inst)
end

local function OnSetColour(inst, r, g, b, a)
    inst.label_colour.r:set(r)
    inst.label_colour.g:set(g)
    inst.label_colour.b:set(b)
    inst.label_colour.a:set(a)
    OnLabelColourDirty(inst)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()
    inst:AddTag("CLASSIFIED")

    inst.label = inst.entity:AddLabel()
    inst.label:SetWorldOffset(0, 1, 0)
    inst.label:SetFont(CHATFONT_OUTLINE)
    inst.label:SetFontSize(16)

    inst.label_text = net_string(inst.GUID, "um_debug_label.label_text", "label_textdirty")
    inst.label_text:set("")

    inst.label_uioffset = {
        x = net_float(inst.GUID, "um_debug_label.label_uioffset.x", "label_uioffsetdirty"),
        y = net_float(inst.GUID, "um_debug_label.label_uioffset.y", "label_uioffsetdirty"),
        z = net_float(inst.GUID, "um_debug_label.label_uioffset.z", "label_uioffsetdirty"),
    }
    inst.label_uioffset.x:set(0)
    inst.label_uioffset.y:set(0)
    inst.label_uioffset.z:set(0)

    inst.label_colour = {
        r = net_float(inst.GUID, "um_debug_label.label_colour.r", "label_colourdirty"),
        g = net_float(inst.GUID, "um_debug_label.label_colour.g", "label_colourdirty"),
        b = net_float(inst.GUID, "um_debug_label.label_colour.b", "label_colourdirty"),
        a = net_float(inst.GUID, "um_debug_label.label_colour.a", "label_colourdirty"),
    }
    inst.label_colour.r:set(PLAYERCOLOURS.CORAL[1])
    inst.label_colour.g:set(PLAYERCOLOURS.CORAL[2])
    inst.label_colour.b:set(PLAYERCOLOURS.CORAL[3])
    inst.label_colour.a:set(PLAYERCOLOURS.CORAL[4])

    inst.persists = false

    inst:DoStaticTaskInTime(0, RegisterNetListeners)

    inst.entity:SetPristine()

    inst.SetText = OnSetText
    inst.SetUIOffset = OnSetUIOffset
    inst.SetColour = OnSetColour

    return inst
end

return Prefab("um_debug_label", fn)
