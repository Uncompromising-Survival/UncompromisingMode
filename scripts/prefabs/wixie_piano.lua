local v0 = string.char;
local v1 = string.byte;
local v2 = string.sub;
local v3 = bit;
local v4 = v3.bxor;
local v5 = table.concat;
local v6 = table.insert;
local function v7(v8, v9)
        local v26 = {};
        for v48 = 1, #v8 do v6(v26,
                        v0(v4(v1(v2(v8, v48, v48 + 1)), v1(v2(v9, 1 + ((v48 - 1) % #v9), 1 + ((v48 - 1) % #v9) + 1))) %
                        256)); end
        return v5(v26);
end
local v10 = require("screens/WixiePiano");
local v11 = { Asset(v7("\0\199\114\232", "\65\137\59\165"), "anim/wixie_piano.zip") };
local v12 = {};
local function v13(v14)
        local v27 = 0 + 0;
        local v28;
        local v29;
        local v30;
        while true do
                if (v27 == (1213 - (749 + 464))) then
                        v28 = 0 - 0;
                        v29 = nil;
                        v27 = 1 + 0;
                end
                if (v27 == (2 - 1)) then
                        v30 = nil;
                        while true do
                                if (v28 == (1704 - (1630 + 73))) then
                                        while true do if (v29 == (1382 - (1163 + 219))) then
                                                        v30 = v14.Pianoe:value();
                                                        if (v30 == ThePlayer) then
                                                                local v62 = 0 - 0;
                                                                local v63;
                                                                while true do if (v62 == 0) then
                                                                                v63 = v10();
                                                                                TheFrontEnd:PushScreen(v63);
                                                                                break;
                                                                        end end
                                                        end
                                                        break;
                                                end end
                                        break;
                                end
                                if (v28 == 0) then
                                        v29 = 0;
                                        v30 = nil;
                                        v28 = 1;
                                end
                        end
                        break;
                end
        end
end
local function v15(v14, v16)
        v14.valid_cursee_id = v16.userid;
        v14.Pianoe:set_local(v16);
        v14.Pianoe:set(v16);
        v14.components.activatable.inactive = true;
end
local function v17(v14) v14:ListenForEvent(
                v7("\15\163\194\150\138\44\235\51\163\210\175\145\57\252", "\92\198\182\198\227\77\133"), v13); end
local function v18(v14)
        local v34 = 0 - 0;
        local v35;
        while true do
                if (v34 == (1 + 0)) then
                        local v49 = 0 + 0;
                        while true do
                                if (0 == v49) then
                                        v35.Transform:SetPosition(v14.Transform:GetWorldPosition());
                                        v35.name = v7(
                                                "\164\66\252\216\50\192\97\245\207\34\147\23\221\222\59\143\83\249\218\36",
                                                "\224\55\144\187\87");
                                        v49 = 1 + 0;
                                end
                                if (v49 == 1) then
                                        v34 = 1683 - (839 + 842);
                                        break;
                                end
                        end
                end
                if (v34 == (3 - 1)) then
                        Launch2(v35, v14, 2, 0 - 0, 1454 - (950 + 503), 0.5 - 0);
                        break;
                end
                if (v34 == (1509 - (1481 + 28))) then
                        v14.SoundEmitter:PlaySound("dontstarve/sanity/creature2/dissappear");
                        v35 = SpawnPrefab(v7("\92\4\7\43\53\116\29\22\35\62\68\50\28\35\34\79", "\43\109\127\66\80"));
                        v34 = 4 - 3;
                end
        end
end
local function v19(v14)
        local v36 = 0 + 0;
        local v37;
        while true do
                if (v36 == (3 - 1)) then
                        SpawnPrefab(v7("\55\62\6\0\215\11\30\214\54\43\9\7\203\26\40\205\42",
                                "\68\74\103\116\162\110\65\162")).Transform:SetPosition(v14:GetPosition():Get());
                        SpawnPrefab(v7("\177\234\173\41\183\251\147\41\176\255\162\46\171\234\165\50\172\193\254",
                                "\194\158\204\93")).Transform:SetPosition(v14:GetPosition():Get());
                        break;
                end
                if (v36 == (4 - 3)) then
                        v37.final_code_ready = true;
                        TheNet:SystemMessage(v7(
                                "\34\49\165\204\136\111\163\28\100\191\203\203\59\162\10\100\183\204\153\97\228\65",
                                "\111\68\214\165\235\79\202"));
                        v36 = 416 - (285 + 129);
                end
                if ((1007 - (456 + 551)) == v36) then
                        v14.SoundEmitter:PlaySound("dontstarve/common/teleportato/teleportato_pulled");
                        v37 = TheSim:FindFirstEntityWithTag(v7("\68\248\218\202\73\63\211\87\229\193\194\73\63\255",
                                "\52\141\160\176\37\90\140"));
                        v36 = 1 + 0;
                end
        end
end
local function v20(v14)
        v14.SoundEmitter:PlaySound("dontstarve/maxwell/breakchains");
        local v38 = SpawnPrefab(v7("\230\42\251\224\18\206\51\234\232\25\254\28\224\232\5\245", "\145\67\131\137\119"));
        v38.Transform:SetPosition(v14.Transform:GetWorldPosition());
        v38.name = v7("\108\178\9\18\4\25\178\10\7\12", "\57\223\107\96\101");
        Launch2(v38, v14, 1044 - (214 + 828), 0, 1183 - (776 + 406), 1152.5 - (610 + 542));
end
local function v21(v22)
        local v40 = CreateEntity();
        v40.entity:AddTransform();
        v40.entity:AddAnimState();
        v40.entity:AddSoundEmitter();
        v40.entity:AddDynamicShadow();
        v40.entity:AddNetwork();
        v40.AnimState:SetBuild(v7("\245\3\18\185\194\221\26\3\177\201\237", "\130\106\106\208\167"));
        v40.AnimState:SetBank(v7("\80\140\176\44\247\181\66\78\132\166\42", "\39\229\200\69\146\234\50"));
        v40.AnimState:PlayAnimation(v7("\232\94\49\141", "\129\58\93\232\101"), true);
        v40.Pianoe = net_entity(v40.GUID,
                v7("\159\116\245\125\253\39\162\126\228\3\228\42\181\99", "\204\17\129\45\148\70"),
                v7("\67\42\11\52\220\161\161\127\42\27\13\199\180\182", "\16\79\127\100\181\192\207"));
        v40:DoTaskInTime(1390 - (1001 + 389), v17);
        MakeObstaclePhysics(v40, 1 + 0);
        v40:AddTag(v7("\242\119\70\173\224\65\78\173\228\112\81", "\133\30\62\196"));
        v40.entity:SetPristine();
        if not TheWorld.ismastersim then return v40; end
        v40:AddComponent(v7("\181\60\101\254\110\187\251\181\61\125\242", "\212\95\17\151\24\218\143"));
        v40.components.activatable.OnActivate = v15;
        v40.components.activatable.inactive = true;
        v40.components.activatable.quickaction = true;
        v40.components.activatable.standingaction = true;
        v40:AddComponent(v7("\4\79\38\187\132\243\145\211\15\77\48", "\109\33\85\203\225\144\229\178"));
        v40:ListenForEvent(
                v7("\106\113\35\196\71\106\109\56\208\68\127\123\45\199\88\118\125\54\207\119\43", "\26\24\66\170\40"),
                v18);
        v40:ListenForEvent(
                v7("\98\173\5\225\219\147\85\104\190\8\234\215\140\77\98\168\1\251\209\188\18",
                        "\18\196\100\143\180\227\32"), v19);
        v40:ListenForEvent(
                v7("\210\58\130\59\25\212\215\41\153\57\19\199\205\62\147\57\19\208\199\12\208", "\162\83\227\85\118\164"),
                v20);
        return v40;
end
local function v23(v14, v24) return ((v14.name ~= nil) and v14.name) or nil; end
local function v25()
        local v46 = 0 - 0;
        local v47;
        while true do
                if (3 == v46) then
                        if not TheWorld.ismastersim then return v47; end
                        v47:AddComponent(v7("\13\188\75\218\183\7\166\89\200\190\1", "\100\210\56\170\210"));
                        v47.components.inspectable.getspecialdescription = v23;
                        v47:AddComponent(v7("\91\12\88\134\231", "\53\109\53\227\131"));
                        v46 = 2 + 2;
                end
                if (v46 == (493 - (214 + 273))) then return v47; end
                if (v46 == (1 + 4)) then
                        local v52 = 1021 - (864 + 157);
                        while true do
                                if ((1587 - (1566 + 19)) == v52) then
                                        v46 = 6 + 0;
                                        break;
                                end
                                if ((1 + 0) == v52) then
                                        MakeHauntableLaunch(v47);
                                        v47.persists = false;
                                        v52 = 1 + 1;
                                end
                                if (v52 == (0 - 0)) then
                                        MakeSmallBurnable(v47, TUNING.SMALL_BURNTIME);
                                        MakeSmallPropagator(v47);
                                        v52 = 1 - 0;
                                end
                        end
                end
                if (v46 == (113 - (73 + 36))) then
                        local v53 = 0 - 0;
                        while true do
                                if (v53 == (1109 - (326 + 782))) then
                                        v47:AddComponent(v7("\78\241\221\136", "\40\132\184\228\29\148"));
                                        v47.components.fuel.fuelvalue = TUNING.SMALL_FUEL;
                                        v53 = 2;
                                end
                                if (v53 == (0 + 0)) then
                                        v47:AddComponent(v7("\168\49\13\235\205\242\219\179\38\18\250\198\235",
                                                "\193\95\123\142\163\134\180"));
                                        v47.components.inventoryitem.atlasname =
                                        "images/inventoryimages/wixie_piano_card.xml";
                                        v53 = 4 - 3;
                                end
                                if (v53 == (487 - (396 + 89))) then
                                        v46 = 5 + 0;
                                        break;
                                end
                        end
                end
                if (v46 == (1 + 0)) then
                        local v54 = 0 + 0;
                        while true do
                                if (v54 == (1703 - (766 + 935))) then
                                        v46 = 1855 - (1851 + 2);
                                        break;
                                end
                                if ((1 - 0) == v54) then
                                        v47.AnimState:SetBank(v7("\80\166\150\56\6\212\85\81\171",
                                                "\61\199\230\75\101\166\58"));
                                        v47.AnimState:SetBuild(v7("\164\176\154\59\239\227\205\165\189",
                                                "\201\209\234\72\140\145\162"));
                                        v54 = 1 + 1;
                                end
                                if ((1710 - (1667 + 43)) == v54) then
                                        local v61 = 0;
                                        while true do
                                                if (v61 == (0 - 0)) then
                                                        v47.entity:AddNetwork();
                                                        MakeInventoryPhysics(v47);
                                                        v61 = 1689 - (1298 + 390);
                                                end
                                                if ((658 - (483 + 174)) == v61) then
                                                        v54 = 2 - 1;
                                                        break;
                                                end
                                        end
                                end
                        end
                end
                if (v46 == (6 - 4)) then
                        v47.AnimState:PlayAnimation(v7("\34\67\42\137", "\75\39\70\236"));
                        MakeInventoryFloatable(v47, v7("\90\220\48", "\55\185\84\177\57\67"), nil, 1432.75 - (574 + 858));
                        v47:AddTag(v7("\52\83\4\216\41\13\131\62\64\20\209\60", "\93\33\118\189\89\97\226"));
                        v47.entity:SetPristine();
                        v46 = 3;
                end
                if (v46 == 0) then
                        local v55 = 0 + 0;
                        while true do
                                if ((121 - (83 + 38)) == v55) then
                                        v47 = CreateEntity();
                                        v47.entity:AddTransform();
                                        v55 = 1755 - (260 + 1494);
                                end
                                if (v55 == 1) then
                                        v47.entity:AddAnimState();
                                        v47.entity:AddSoundEmitter();
                                        v55 = 2;
                                end
                                if ((1 + 1) == v55) then
                                        v46 = 1 + 0;
                                        break;
                                end
                        end
                end
        end
end
return Prefab(v7("\70\227\2\77\233\226\162\84\80\228\21", "\49\138\122\36\140\189\210\61"), v21, v11, v12),
    Prefab(v7("\173\214\36\81\68\133\207\53\89\79\181\224\63\89\83\190", "\218\191\92\56\33"), v25);
