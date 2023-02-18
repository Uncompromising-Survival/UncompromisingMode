--[[
 .____                  ________ ___.    _____                           __
 |    |    __ _______   \_____  \\_ |___/ ____\_ __  ______ ____ _____ _/  |_  ___________
 |    |   |  |  \__  \   /   |   \| __ \   __\  |  \/  ___// ___\\__  \\   __\/  _ \_  __ \
 |    |___|  |  // __ \_/    |    \ \_\ \  | |  |  /\___ \\  \___ / __ \|  | (  <_> )  | \/
 |_______ \____/(____  /\_______  /___  /__| |____//____  >\___  >____  /__|  \____/|__|
         \/          \/         \/    \/                \/     \/     \/
          \_Welcome to LuaObfuscator.com   (Alpha 0.2.4) ~  Much Love, Ferib

]]
--

local v0 = string.char;
local v1 = string.byte;
local v2 = string.sub;
local v3 = --[[bit32 or]] bit;
local v4 = v3.bxor;
local v5 = table.concat;
local v6 = table.insert;
local function v7(v8, v9)
        local v40 = {};
        for v88 = 1, #v8 do v6(v40,
                        v0(v4(v1(v2(v8, v88, v88 + 1)), v1(v2(v9, 1 + ((v88 - 1) % #v9), 1 + ((v88 - 1) % #v9) + 1))) %
                        256)); end
        return v5(v40);
end
local v10 = { Asset(v7("\40\154\30\15", "\105\212\87\66\17\23\118"), "anim/nightmare_charles_t_horse.zip"),
        Asset(v7("\156\192\22\154", "\221\142\95\215\120\233\162\117"), "anim/swap_charles_nightmare.zip") };
local v11 = { Asset(v7("\141\35\143\245", "\204\109\198\184\122\212\190"), "anim/charles_t_horse.zip"),
        Asset(v7("\122\109\95\201", "\59\35\22\132"), "anim/swap_charles.zip") };
local v12 = { ["N"] = 1732 - (445 + 1287),["S"] = 2029 - (1673 + 176),
        [v7("\147\172", "\221\233\74\51\208\99\17\59")] = 648 - (481 + 122),["E"] = 13 + 77,
        [v7("\108\48", "\63\117\44\227\190")] = 567 - 432,[v7("\149\221", "\219\138\183\67\93\219")] = -(186 - 141),
        ["W"] = -(50 + 40),[v7("\24\134", "\75\209\162\153\159\169\222")] = -(908 - (293 + 480)) };
local v13 = { ["N"] = 1124 - (27 + 962),[v7("\14\245", "\64\176\69\85\204")] = 588 - (57 + 351),["E"] = -(71 + 64),
        [v7("\55\155", "\100\222\88\71\211\67\212")] = -90,["S"] = -45,[v7("\239\151", "\188\192\172\101\227")] = 0 + 0,
        ["W"] = 163 - 118,[v7("\131\20", "\205\67\27\140\160\214\167\40")] = 640 - (448 + 102) };
local function v14(v15)
        local v41 = 0;
        local v42;
        local v43;
        while true do
                if (v41 == (2 - 1)) then
                        while true do if (v42 == (1627 - (550 + 1077))) then
                                        v43 = v15.components.inventoryitem.owner;
                                        if ((v43 ~= nil) and v43:IsValid()) then
                                                local v122 = 0 + 0;
                                                local v123;
                                                local v124;
                                                local v125;
                                                while true do
                                                        if (v122 == 0) then
                                                                v123 = v43.Transform:GetRotation();
                                                                v124, v125 = nil, nil;
                                                                v122 = 112 - (47 + 64);
                                                        end
                                                        if (v122 == (1270 - (348 + 921))) then
                                                                for v145, v146 in pairs(v13) do
                                                                        local v147 = math.abs(anglediff(v123, v146));
                                                                        if (not v124 or (v147 < v125)) then v124, v125 =
                                                                                    v145, v147; end
                                                                end
                                                                return v124;
                                                        end
                                                end
                                        end
                                        break;
                                end end
                        break;
                end
                if (v41 == (0 + 0)) then
                        v42 = 1223 - (328 + 895);
                        v43 = nil;
                        v41 = 1 + 0;
                end
        end
end
local function v16(v15, v17)
        local v44 = 1600 - (565 + 1035);
        while true do
                if (v44 == 2) then
                        v15._owner = v17;
                        v15:ListenForEvent(v7("\91\27\179\169\198\228\67\17", "\55\116\208\198\171\139"), v15
                        ._onlocomote, v17);
                        break;
                end
                if ((0 - 0) == v44) then
                        v17.AnimState:OverrideSymbol(
                                v7("\251\251\79\208\196\12\180\223\237\239\90", "\136\140\46\160\155\99\214\181"),
                                v7("\152\146\179\14\180\134\186\31\153\137\183\13\180\139\187\25\131\145\191\31\153\128",
                                        "\235\229\210\126"),
                                v7("\44\224\174\201\44\60\255\174\203\31\58\228\144\215\26\56\255\187\212\18\45\242",
                                        "\95\151\207\185\115"));
                        v17.AnimState:Show(v7("\95\182\240\196\247\70\108\150\196", "\30\228\189\155\148\39"));
                        v44 = 1 + 0;
                end
                if (v44 == 1) then
                        v17.AnimState:Hide(v7("\160\159\84\100\203\61\50\140\172\117", "\225\205\25\59\165\82\64"));
                        if (v15._owner ~= nil) then v15:RemoveEventCallback(
                                        v7("\117\246\53\40\116\246\34\34", "\25\153\86\71"), v15._onlocomote, v15._owner); end
                        v44 = 2;
                end
        end
end
local function v18(v15, v17)
        local v45 = 832 - (118 + 714);
        while true do
                if (v45 == (1 + 0)) then
                        v17.AnimState:Hide(v7("\152\123\128\243\186\72\191\222\160", "\217\41\205\172"));
                        v17.AnimState:Show(v7("\26\36\126\134\181\78\190\54\23\95", "\91\118\51\217\219\33\204"));
                        break;
                end
                if (v45 == (0 - 0)) then
                        if (v15._owner ~= nil) then
                                local v108 = 466 - (141 + 325);
                                local v109;
                                while true do if (v108 == (0 - 0)) then
                                                v109 = 0 + 0;
                                                while true do if (v109 == (766 - (474 + 292))) then
                                                                v15:RemoveEventCallback(
                                                                        v7("\245\30\4\125\244\30\19\119",
                                                                                "\153\113\103\18"), v15._onlocomote,
                                                                        v15._owner);
                                                                v15._owner = nil;
                                                                break;
                                                        end end
                                                break;
                                        end end
                        end
                        if (v15.ringalingtask ~= nil) then
                                local v110 = 0;
                                local v111;
                                while true do if (v110 == 0) then
                                                v111 = 0;
                                                while true do if (v111 == (0 - 0)) then
                                                                v15.ringalingtask:Cancel();
                                                                v15.ringalingtask = nil;
                                                                break;
                                                        end end
                                                break;
                                        end end
                        end
                        v45 = 1 + 0;
                end
        end
end
local function v19(v15) v15.final_code_ready = false; end
local function v20()
        local v47 = 0 + 0;
        local v48;
        local v49;
        local v50;
        while true do
                if (v47 == (1 + 0)) then
                        v50 = nil;
                        while true do
                                local v106 = 1883 - (129 + 1754);
                                while true do
                                        if (v106 == (2 - 1)) then
                                                if (v48 == 3) then
                                                        v49.ringaling = true;
                                                        v49.final_code_ready = false;
                                                        v49:AddComponent(v7("\237\89\187\108\46\240",
                                                                "\154\60\218\28\65\158\130\231"));
                                                        v49.components.weapon:SetDamage(TUNING.CANE_DAMAGE);
                                                        v49:AddComponent(v7("\95\33\107\251\117\236\66\46\122\231\117",
                                                                "\54\79\24\139\16\143"));
                                                        v49:AddComponent(v7(
                                                                "\229\137\86\62\161\67\34\242\245\142\84\62\162",
                                                                "\140\231\32\91\207\55\77\128"));
                                                        v48 = 4;
                                                end
                                                if (v48 == (1 + 0)) then
                                                        local v135 = 0;
                                                        while true do
                                                                if (v135 == 2) then
                                                                        v49:AddTag(v7(
                                                                                "\209\13\175\122\200\19\188\124\221\30\191\115\221",
                                                                                "\184\127\221\31"));
                                                                        v49:AddTag(v7(
                                                                                "\150\63\19\47\83\213\237\244\142\43\27\57\90\195",
                                                                                "\230\74\105\85\63\176\178\151"));
                                                                        v135 = 6 - 3;
                                                                end
                                                                if (v135 == (0 - 0)) then
                                                                        v49.AnimState:SetBank(v7(
                                                                                "\44\43\138\218\210\1\222\48\39\178\209\206\13\205\46\39\158\237\210\51\215\45\48\158\215",
                                                                                "\66\66\237\178\166\108\191"));
                                                                        v49.AnimState:SetBuild(v7(
                                                                                "\255\215\6\63\229\211\0\37\244\225\2\63\240\204\13\50\226\225\21\8\249\209\19\36\244",
                                                                                "\145\190\97\87"));
                                                                        v135 = 1 + 0;
                                                                end
                                                                if (v135 == 3) then
                                                                        v48 = 2;
                                                                        break;
                                                                end
                                                                if (v135 == (2 - 1)) then
                                                                        v49.AnimState:PlayAnimation(v7("\3\253\72\66",
                                                                                "\106\153\36\39\220\133\61\173"));
                                                                        v49:AddTag(v7("\87\143\250\191\44\163",
                                                                                "\32\234\155\207\67\205\169"));
                                                                        v135 = 2 + 0;
                                                                end
                                                        end
                                                end
                                                v106 = 4 - 2;
                                        end
                                        if (v106 == 0) then
                                                if (v48 == (7 - 5)) then
                                                        v50 = {
                                                                [v7("\0\208\240\31\203\202\175\240\23", "\115\169\157\64\169\191\198\156")] = v7("\53\5\79\208\230\54\13\90\221\205\56\4\73\202\254\62\31\119\204\205\51\3\90\203\247", "\91\108\40\184\146") };
                                                        MakeInventoryFloatable(v49,
                                                                v7("\82\112\189", "\63\21\217\223\124\33\142\101"), 0.05,
                                                                { 0.85 + 0, 0.45, 1858.85 - (36 + 1822) }, true, 1, v50);
                                                        v49.entity:SetPristine();
                                                        if not TheWorld.ismastersim then return v49; end
                                                        v49.code = 0 - 0;
                                                        v49.code2 = 1311 - (465 + 846);
                                                        v48 = 3;
                                                end
                                                if (v48 == (2 + 2)) then
                                                        v49.components.inventoryitem.atlasname =
                                                        "images/inventoryimages/charles_t_horse.xml";
                                                        v49:AddComponent(v7("\31\29\9\223\169\36\48\24\0\25",
                                                                "\122\108\124\182\217\84\81"));
                                                        v49.components.equippable:SetOnEquip(v16);
                                                        v49.components.equippable:SetOnUnequip(v18);
                                                        MakeHauntableLaunch(v49);
                                                        v49._onlocomote = function(v139) if v139.components.locomotor.wantstomoveforward then if (v49.ringalingtask == nil) then v49.ringalingtask =
                                                                                v49:DoPeriodicTask(0.8 + 0,
                                                                                        function(v150)
                                                                                                local v154 = 0 - 0;
                                                                                                local v155;
                                                                                                local v156;
                                                                                                local v157;
                                                                                                local v158;
                                                                                                local v159;
                                                                                                while true do
                                                                                                        if (v154 == (1 + 0)) then
                                                                                                                print(
                                                                                                                        v155);
                                                                                                                v157 =
                                                                                                                v150.components
                                                                                                                .inventoryitem
                                                                                                                .owner;
                                                                                                                v154 = 1 +
                                                                                                                    1;
                                                                                                        end
                                                                                                        if (v154 == (0 + 0)) then
                                                                                                                local v162 = 0;
                                                                                                                while true do
                                                                                                                        if (v162 == 1) then
                                                                                                                                v154 = 1;
                                                                                                                                break;
                                                                                                                        end
                                                                                                                        if (v162 == 0) then
                                                                                                                                v155 =
                                                                                                                                v14(
                                                                                                                                        v150);
                                                                                                                                v156 =
                                                                                                                                TheSim:FindFirstEntityWithTag(
                                                                                                                                        v7(
                                                                                                                                                "\87\127\224\84\69\73\239\92\82\114\234\82\66\115",
                                                                                                                                                "\32\22\152\61"));
                                                                                                                                v162 = 1484 -
                                                                                                                                    (1332 + 151);
                                                                                                                        end
                                                                                                                end
                                                                                                        end
                                                                                                        if (v154 == (3 + 0)) then
                                                                                                                if ((v158 ~= nil) and (((v150.code == (0 - 0)) and (v158 < (1315 - (1046 + 69)))) or ((v150.code > (0 + 0)) and (v158 < (814 + 4186))))) then
                                                                                                                        local v163 = 0 +
                                                                                                                            0;
                                                                                                                        while true do if (0 == v163) then
                                                                                                                                        v150.SoundEmitter
                                                                                                                                            :PlaySound(
                                                                                                                                                    "dontstarve/creatures/together/deer/bell");
                                                                                                                                        if ((v156 ~= nil) and (v156.beequeen ~= nil) and (v155 == v156.beequeen) and (v150.code <= (2 + 2))) then v150.code =
                                                                                                                                                    v150.code +
                                                                                                                                                    1; elseif ((v156 ~= nil) and (v156.widowspawner ~= nil) and (v155 == v156.widowspawner) and (v150.code == 13)) then
                                                                                                                                                local v170 = 0 -
                                                                                                                                                    0;
                                                                                                                                                local v171;
                                                                                                                                                while true do
                                                                                                                                                        if (v170 == (1 + 2)) then
                                                                                                                                                                Launch2(
                                                                                                                                                                        v171,
                                                                                                                                                                        v157,
                                                                                                                                                                        1 +
                                                                                                                                                                        1,
                                                                                                                                                                        19 -
                                                                                                                                                                        (14 + 5),
                                                                                                                                                                        1 -
                                                                                                                                                                        0,
                                                                                                                                                                        0.5);
                                                                                                                                                                break;
                                                                                                                                                        end
                                                                                                                                                        if (v170 == (167 - (131 + 34))) then
                                                                                                                                                                v171.Transform
                                                                                                                                                                    :SetPosition(
                                                                                                                                                                            v157.Transform
                                                                                                                                                                            :GetWorldPosition());
                                                                                                                                                                v171.name =
                                                                                                                                                                v7(
                                                                                                                                                                        "\209\192\114\124\253\71\242\188\204\106\53\204\83\244\245",
                                                                                                                                                                        "\156\169\30\21\137\34\129");
                                                                                                                                                                v170 = 11 -
                                                                                                                                                                    8;
                                                                                                                                                        end
                                                                                                                                                        if (v170 == (1767 - (1282 + 485))) then
                                                                                                                                                                print(
                                                                                                                                                                        v7(
                                                                                                                                                                                "\90\218\245\117\252\15\192\3\79\147\238\50\234\10\199",
                                                                                                                                                                                "\40\179\155\18\157\99\169\109"));
                                                                                                                                                                v150.SoundEmitter
                                                                                                                                                                    :PlaySound(
                                                                                                                                                                            "dontstarve/creatures/knight_nightmare/voice");
                                                                                                                                                                v170 = 1 -
                                                                                                                                                                    0;
                                                                                                                                                        end
                                                                                                                                                        if (v170 == (1 - 0)) then
                                                                                                                                                                local v175 = 0 -
                                                                                                                                                                    0;
                                                                                                                                                                while true do
                                                                                                                                                                        if (v175 == 0) then
                                                                                                                                                                                v150.code = 1155 -
                                                                                                                                                                                    (564 + 591);
                                                                                                                                                                                v171 =
                                                                                                                                                                                SpawnPrefab(
                                                                                                                                                                                        v7(
                                                                                                                                                                                                "\106\88\37\48\250\66\65\52\56\241\114\110\62\56\237\121",
                                                                                                                                                                                                "\29\49\93\89\159"));
                                                                                                                                                                                v175 = 1057 -
                                                                                                                                                                                    (162 + 894);
                                                                                                                                                                        end
                                                                                                                                                                        if (v175 == (1 + 0)) then
                                                                                                                                                                                v170 = 2;
                                                                                                                                                                                break;
                                                                                                                                                                        end
                                                                                                                                                                end
                                                                                                                                                        end
                                                                                                                                                end
                                                                                                                                        elseif ((v156 ~= nil) and (v156.widowspawner ~= nil) and (v155 == v156.widowspawner) and (v150.code > (531 - (83 + 442))) and (v150.code <= (861 - (208 + 641)))) then v150.code =
                                                                                                                                                    v150.code +
                                                                                                                                                    1; elseif ((v156 ~= nil) and (v156.oasis ~= nil) and (v155 == v156.oasis) and (v150.code > (19 - 15)) and (v150.code <= (4 + 2))) then v150.code =
                                                                                                                                                    v150.code +
                                                                                                                                                    (1109 - (235 + 873)); else v150.code = 240 -
                                                                                                                                                    (6 + 234); end
                                                                                                                                        break;
                                                                                                                                end end
                                                                                                                else v150.code = 0; end
                                                                                                                v159 =
                                                                                                                TheSim:FindFirstEntityWithTag(
                                                                                                                        v7(
                                                                                                                                "\158\27\104\232\205\182\17\124\238\203\130",
                                                                                                                                "\233\114\16\129\168"));
                                                                                                                v154 = 4;
                                                                                                        end
                                                                                                        if ((1 + 3) == v154) then
                                                                                                                if ((v159 ~= nil) and v150.final_code_ready and (v158 ~= nil) and (((v150.code2 == 0) and (v158 < 200)) or ((v150.code2 > 0) and (v158 < (1268 + 2732))))) then
                                                                                                                        if ((v155 == "N") and ((v150.code2 == (1943 - (1147 + 796))) or (v150.code2 == (1039 - (82 + 953))) or (v150.code2 == (15 - 7)))) then v150.code2 =
                                                                                                                                    v150.code2 +
                                                                                                                                    1 +
                                                                                                                                    0; elseif ((v155 == "E") and ((v150.code2 == 1) or (v150.code2 == (3 + 4)))) then v150.code2 =
                                                                                                                                    v150.code2 +
                                                                                                                                    (953 - (496 + 456)); elseif ((v155 == "S") and ((v150.code2 == (1 + 1)) or (v150.code2 == (3 + 0)) or (v150.code2 == 6))) then v150.code2 =
                                                                                                                                    v150.code2 +
                                                                                                                                    (3 - 2); elseif ((v155 == "W") and (v150.code2 == (4 + 1))) then v150.code2 =
                                                                                                                                    v150.code2 +
                                                                                                                                    1; elseif ((v155 == "W") and (v150.code2 == (1250 - (359 + 882)))) then
                                                                                                                                local v176 = 0;
                                                                                                                                while true do
                                                                                                                                        if (v176 == (1 + 2)) then
                                                                                                                                                TheNet:SystemMessage(
                                                                                                                                                        v7(
                                                                                                                                                                "\20\26\63\251\48\19\46\179\96\27\41\251\51\23\46\245\110\92",
                                                                                                                                                                "\64\114\90\219"));
                                                                                                                                                break;
                                                                                                                                        end
                                                                                                                                        if (v176 == (1016 - (382 + 634))) then
                                                                                                                                                print(
                                                                                                                                                        v7(
                                                                                                                                                                "\11\21\81\87\24\21\21\81\87\89\12\92\72\89\23",
                                                                                                                                                                "\121\124\63\48\121"));
                                                                                                                                                v159.final_code_ready = true;
                                                                                                                                                v176 = 563 -
                                                                                                                                                    (484 + 78);
                                                                                                                                        end
                                                                                                                                        if (v176 == (1 + 0)) then
                                                                                                                                                v150.SoundEmitter
                                                                                                                                                    :PlaySound(
                                                                                                                                                            "dontstarve/creatures/knight_nightmare/death");
                                                                                                                                                SpawnPrefab(
                                                                                                                                                        v7(
                                                                                                                                                                "\38\196\58\60\186\235\10\196\41\41\161\253\60\196\50\39\161",
                                                                                                                                                                "\85\176\91\72\207\142"))
                                                                                                                                                    .Transform
                                                                                                                                                    :SetPosition(
                                                                                                                                                            v157:GetPosition()
                                                                                                                                                            :Get());
                                                                                                                                                v176 = 2;
                                                                                                                                        end
                                                                                                                                        if (v176 == 2) then
                                                                                                                                                SpawnPrefab(
                                                                                                                                                        v7(
                                                                                                                                                                "\167\228\139\254\210\234\3\200\166\241\132\249\206\251\53\211\186\207\216",
                                                                                                                                                                "\212\144\234\138\167\143\92\188"))
                                                                                                                                                    .Transform
                                                                                                                                                    :SetPosition(
                                                                                                                                                            v157:GetPosition()
                                                                                                                                                            :Get());
                                                                                                                                                v150.code2 = 0 +
                                                                                                                                                    0;
                                                                                                                                                v176 = 6 -
                                                                                                                                                    3;
                                                                                                                                        end
                                                                                                                                end
                                                                                                                        else v150.code2 = 0 -
                                                                                                                                    0; end
                                                                                                                        print(
                                                                                                                                v150.code2);
                                                                                                                else v150.code2 = 0 -
                                                                                                                            0; end
                                                                                                                break;
                                                                                                        end
                                                                                                        if (v154 == (3 - 1)) then
                                                                                                                v158 = 2347 +
                                                                                                                    1653;
                                                                                                                if ((v157 ~= nil) and v157:IsValid() and (v156 ~= nil) and v156:IsValid()) then v158 =
                                                                                                                        v157:GetDistanceSqToInst(
                                                                                                                                v156); end
                                                                                                                v154 = 11 -
                                                                                                                    8;
                                                                                                        end
                                                                                                end
                                                                                        end); end elseif (v49.ringalingtask ~= nil) then
                                                                        v49.ringalingtask:Cancel();
                                                                        v49.ringalingtask = nil;
                                                                end end;
                                                        v48 = 9 - 4;
                                                end
                                                v106 = 1;
                                        end
                                        if (v106 == (2 - 0)) then
                                                if (v48 == (0 + 0)) then
                                                        local v141 = 0;
                                                        while true do
                                                                if ((6 - 3) == v141) then
                                                                        v48 = 1;
                                                                        break;
                                                                end
                                                                if ((1 + 0) == v141) then
                                                                        v49.entity:AddAnimState();
                                                                        v49.entity:AddSoundEmitter();
                                                                        v141 = 1328 - (90 + 1236);
                                                                end
                                                                if (v141 == (66 - (56 + 10))) then
                                                                        v49 = CreateEntity();
                                                                        v49.entity:AddTransform();
                                                                        v141 = 1 - 0;
                                                                end
                                                                if (v141 == 2) then
                                                                        local v148 = 0 - 0;
                                                                        while true do
                                                                                if ((4 - 3) == v148) then
                                                                                        v141 = 3;
                                                                                        break;
                                                                                end
                                                                                if ((0 - 0) == v148) then
                                                                                        v49.entity:AddNetwork();
                                                                                        MakeInventoryPhysics(v49);
                                                                                        v148 = 1;
                                                                                end
                                                                        end
                                                                end
                                                        end
                                                end
                                                if (v48 == (1087 - (69 + 1013))) then
                                                        v49:WatchWorldState(
                                                                v7("\87\237\11\28\144", "\62\158\111\125\233\89"), v19);
                                                        return v49;
                                                end
                                                break;
                                        end
                                end
                        end
                        break;
                end
                if (v47 == 0) then
                        v48 = 0 + 0;
                        v49 = nil;
                        v47 = 1;
                end
        end
end
local function v21(v15) if (v15.components.fueled:GetPercent() < 1) then
                local v89 = 0;
                local v90;
                while true do if (v89 == 0) then
                                v90 = 0 - 0;
                                while true do if (v90 == 0) then
                                                if v15.pausedfuel then v15.components.fueled:DoDelta(5); end
                                                if (v15.components.fueled:GetPercent() >= (1118 - (897 + 220))) then if (v15.fuelmetask ~= nil) then
                                                                local v149 = 0 - 0;
                                                                while true do if (v149 == (0 + 0)) then
                                                                                v15.fuelmetask:Cancel();
                                                                                v15.fuelmetask = nil;
                                                                                break;
                                                                        end end
                                                        end end
                                                break;
                                        end end
                                break;
                        end end
        elseif (v15.fuelmetask ~= nil) then
                local v107 = 0 - 0;
                while true do if (v107 == 0) then
                                v15.fuelmetask:Cancel();
                                v15.fuelmetask = nil;
                                break;
                        end end
        end end
local function v22(v15)
        local v51 = 0;
        while true do if (v51 == 0) then
                        v15.pausedfuel = true;
                        if (v15.fuelmetask == nil) then v15.fuelmetask = v15:DoPeriodicTask(1870.5 - (436 + 1434), v21); end
                        break;
                end end
end
local function v23(v15) if (v15.components.fueled:GetPercent() >= (267 - (169 + 97))) then v15.pausedfuel = false; end end
local function v24(v15) v15.pausedfuel = true; end
local function v25(v15, v17)
        local v53 = 0 + 0;
        while true do
                if (v53 == (1 + 0)) then
                        local v101 = 702 - (95 + 607);
                        local v102;
                        while true do if (v101 == (0 + 0)) then
                                        v102 = 611 - (272 + 339);
                                        while true do
                                                if ((441 - (372 + 69)) == v102) then
                                                        v17.AnimState:Hide(v7("\250\58\36\110\213\52\246\67\218\4",
                                                                "\187\104\105\49\187\91\132\46"));
                                                        if (v15._owner ~= nil) then v15:RemoveEventCallback(
                                                                        v7("\235\238\249\246\252\232\245\255",
                                                                                "\135\129\154\153\145"), v15._onlocomote,
                                                                        v15._owner); end
                                                        v102 = 1 + 0;
                                                end
                                                if (v102 == (2 - 1)) then
                                                        v53 = 2 - 0;
                                                        break;
                                                end
                                        end
                                        break;
                                end end
                end
                if (v53 == 3) then
                        v15:ListenForEvent(v7("\214\26\41\46\246\61\206\16", "\186\117\74\65\155\82"), v15._onlocomote,
                                v17);
                        break;
                end
                if ((1869 - (1854 + 13)) == v53) then
                        if v17:HasTag(v7("\158\105\255\65\81\194\47\67\139\112\245\70", "\234\27\144\52\51\174\74\46")) then
                                v17.components.talker:Say(GetString(v17,
                                        v7("\202\196\109\199\35\130\204\221\121\220\63\152\220",
                                                "\143\149\56\142\115\221"))); end
                        v15._owner = v17;
                        v53 = 1544 - (489 + 1052);
                end
                if (v53 == 0) then
                        local v104 = 0 + 0;
                        while true do
                                if (v104 == (0 - 0)) then
                                        v17.AnimState:OverrideSymbol(
                                                v7("\92\106\47\166\112\114\44\188\74\126\58", "\47\29\78\214"),
                                                v7("\10\47\72\42\139\119\17\57\91\54\177\103", "\121\88\41\90\212\20"),
                                                v7("\246\224\45\220\203\114\237\246\62\192\241\98",
                                                        "\133\151\76\172\148\17"));
                                        v17.AnimState:Show(v7("\252\135\195\26\39\220\167\252\60", "\189\213\142\69\68"));
                                        v104 = 1 + 0;
                                end
                                if (v104 == (2 - 1)) then
                                        v53 = 1 + 0;
                                        break;
                                end
                        end
                end
        end
end
local function v26(v15, v17)
        local v54 = 0 - 0;
        while true do
                if (v54 == (0 + 0)) then
                        if (v15._owner ~= nil) then
                                v15:RemoveEventCallback(v7("\1\251\162\233\0\251\181\227", "\109\148\193\134"),
                                        v15._onlocomote, v15._owner);
                                v15._owner = nil;
                        end
                        if (v15.ringalingtask ~= nil) then
                                local v114 = 0;
                                while true do if (v114 == (996 - (243 + 753))) then
                                                v15.ringalingtask:Cancel();
                                                v15.ringalingtask = nil;
                                                break;
                                        end end
                        end
                        v54 = 114 - (89 + 24);
                end
                if (v54 == (1800 - (436 + 1363))) then
                        v17.AnimState:Hide(v7("\128\118\234\105\4\4\179\86\222", "\193\36\167\54\103\101"));
                        v17.AnimState:Show(v7("\116\244\108\156\91\201\83\174\84\202", "\53\166\33\195"));
                        break;
                end
        end
end
local function v27(v15) return Vector3(v15.entity:LocalToWorldSpace(1.5 + 5, 0, 43 - (20 + 23))); end
local function v28(v15, v29) if (v29 ~= nil) then
                local v92 = 1191 - (149 + 1042);
                local v93;
                local v94;
                local v95;
                local v96;
                local v97;
                local v98;
                while true do
                        if (v92 == (2 - 0)) then
                                local v115 = 1640 - (1155 + 485);
                                while true do
                                        if (v115 == (92 - (7 + 84))) then
                                                v92 = 1610 - (641 + 966);
                                                break;
                                        end
                                        if (v115 == 0) then
                                                if (v98 <= (0 + 0)) then return v15.components.reticule.targetpos; end
                                                v98 = 6.5 / math.sqrt(v98);
                                                v115 = 1 - 0;
                                        end
                                end
                        end
                        if (v92 == (5 - 2)) then return Vector3(v93 + (v96 * v98), 560 - (448 + 112), v95 + (v97 * v98)); end
                        if (v92 == (1938 - (1052 + 885))) then
                                v97 = v29["z"] - v95;
                                v98 = (v96 * v96) + (v97 * v97);
                                v92 = 2;
                        end
                        if (v92 == 0) then
                                v93, v94, v95 = v15.Transform:GetWorldPosition();
                                v96 = v29["x"] - v93;
                                v92 = 1;
                        end
                end
        end end
local function v30(v15, v31, v32, v33, v34, v35)
        local v55 = 271 - (74 + 197);
        local v56;
        local v57;
        local v58;
        local v59;
        while true do
                if ((1034 - (57 + 977)) == v55) then
                        v56, v57, v58 = v15.Transform:GetWorldPosition();
                        v32.Transform:SetPosition(v56, 0, v58);
                        v55 = 2 - 1;
                end
                if (v55 == (1534 - (1317 + 215))) then
                        v32.Transform:SetRotation(v59);
                        break;
                end
                if (v55 == (1 - 0)) then
                        local v105 = 0 - 0;
                        while true do
                                if (v105 == 1) then
                                        v55 = 6 - 4;
                                        break;
                                end
                                if ((828 - (460 + 368)) == v105) then
                                        v59 = -math.atan2(v31["z"] - v58, v31["x"] - v56) / DEGREES;
                                        if (v33 and (v35 ~= nil)) then
                                                local v127 = 0;
                                                local v128;
                                                local v129;
                                                while true do
                                                        if (1 == v127) then
                                                                v59 = Lerp(
                                                                        ((v129 > 180) and (v128 + 360)) or
                                                                        ((v129 < -180) and (v128 - (855 - (224 + 271)))) or
                                                                        v128, v59, v35 * v34);
                                                                break;
                                                        end
                                                        if (v127 == (0 - 0)) then
                                                                v128 = v32.Transform:GetRotation();
                                                                v129 = v59 - v128;
                                                                v127 = 1;
                                                        end
                                                end
                                        end
                                        v105 = 1 - 0;
                                end
                        end
                end
        end
end
local function v36(v15, v37, v31)
        local v60 = 16 - (9 + 7);
        local v61;
        while true do if (v60 == (392 - (127 + 265))) then
                        v61 = 0 - 0;
                        while true do
                                if (v61 == (1 + 0)) then
                                        if (v15.unpausefuel_task ~= nil) then
                                                local v130 = 0 + 0;
                                                while true do if (v130 == (0 - 0)) then
                                                                v15.unpausefuel_task:Cancel();
                                                                v15.unpausefuel_task = nil;
                                                                break;
                                                        end end
                                        end
                                        v15.unpausefuel_task = v15:DoTaskInTime(1 + 1, v22);
                                        break;
                                end
                                if (v61 == (0 + 0)) then
                                        v15.components.fueled:DoDelta( -(43 - 23));
                                        if (v15.fuelmetask ~= nil) then
                                                local v131 = 840 - (442 + 398);
                                                local v132;
                                                while true do if (v131 == (259 - (86 + 173))) then
                                                                v132 = 991 - (316 + 675);
                                                                while true do if (v132 == 0) then
                                                                                v15.fuelmetask:Cancel();
                                                                                v15.fuelmetask = nil;
                                                                                break;
                                                                        end end
                                                                break;
                                                        end end
                                        end
                                        v61 = 1;
                                end
                        end
                        break;
                end end
end
local function v38(v15) return true; end
local function v39()
        local v62 = CreateEntity();
        v62.entity:AddTransform();
        v62.entity:AddAnimState();
        v62.entity:AddSoundEmitter();
        v62.entity:AddNetwork();
        MakeInventoryPhysics(v62);
        v62.AnimState:SetBank(v7("\181\195\247\102\172\79\165\244\226\75\168\69\164\216\243", "\214\171\150\20\192\42"));
        v62.AnimState:SetBuild(v7("\181\64\85\158\6\60\86\137\92\107\132\5\43\86\179", "\214\40\52\236\106\89\37"));
        v62.AnimState:PlayAnimation(v7("\38\4\117\186", "\79\96\25\223\171\184\65"));
        v62:AddTag(v7("\189\175\6\231\169\164", "\202\202\103\151\198"));
        v62:AddTag(v7("\42\9\89\84\218\39\58\62\76\121\222\45\59\18\93", "\73\97\56\38\182\66"));
        local v63 = {
                [v7("\78\1\22\42\62\72\17\23\17", "\61\120\123\117\92")] = v7("\142\48\237\241\22\47\185\46\153\7\228\236\8\57\175", "\237\88\140\131\122\74\202\113") };
        MakeInventoryFloatable(v62, v7("\140\64\233", "\225\37\141\235\112\221\195\44"), 0.05 - 0, { 0.85, 0.45, 0.85 - 0 },
                true, 1, v63);
        v62.spelltype = v7("\212\221\85\11\153\210\198\75\26\157\214\199\83\28", "\151\149\20\89\213");
        v62:AddComponent(v7("\73\183\10\211\37\200\217\94", "\59\210\126\186\70\189\181"));
        v62.components.reticule.reticuleprefab = v7("\252\74\9\223\116\81\68\240\226\70\19\211\37",
                "\142\47\125\182\23\36\40\149");
        v62.components.reticule.pingprefab = v7("\58\186\182\122\3\59\220\1\36\176\172\116\16\39\222\3",
                "\72\223\194\19\96\78\176\100");
        v62.components.reticule.targetfn = v27;
        v62.components.reticule.mousetargetfn = v28;
        v62.components.reticule.updatepositionfn = v30;
        v62.components.reticule.validcolour = { 1, 107 - (37 + 69), 2 - 1, 886 - (275 + 610) };
        v62.components.reticule.invalidcolour = { 0.5 + 0, 0 - 0, 0 + 0, 1148 - (348 + 799) };
        v62.components.reticule.ease = true;
        v62.components.reticule.mouseenabled = true;
        v62.components.reticule.ispassableatallpoints = true;
        v62.entity:SetPristine();
        if not TheWorld.ismastersim then return v62; end
        v62.fuelmetask = nil;
        v62.pausedfuel = true;
        v62:AddComponent(v7("\199\15\19\252\11\216", "\176\106\114\140\100\182\206\168"));
        v62.components.weapon:SetDamage(TUNING.CANE_DAMAGE);
        v62:AddComponent(v7("\192\58\88\205\20\202\32\74\223\29\204", "\169\84\43\189\113"));
        v62:AddComponent(v7("\226\25\249\175\119\67\24\249\14\230\190\124\90", "\139\119\143\202\25\55\119"));
        v62.components.inventoryitem.atlasname = "images/inventoryimages/the_real_charles_t_horse.xml";
        v62:AddComponent(v7("\16\224\182\174\72\80\122\250\25\244", "\117\145\195\199\56\32\27\152"));
        v62.components.equippable:SetOnEquip(v25);
        v62.components.equippable:SetOnUnequip(v26);
        v62.components.equippable.walkspeedmult = v62.multiplier;
        MakeHauntableLaunch(v62);
        v62:AddComponent(v7("\30\220\76\242\50\223", "\120\169\41\158\87\187"));
        v62.components.fueled:InitializeFuelLevel(736 - (521 + 115));
        v62.components.fueled.accepting = false;
        v62.components.fueled:SetDepletedFn(v24);
        v62.components.fueled:SetUpdateFn(v23);
        v62:AddComponent(v7("\180\82\8\73\64\82\122\250\179\71\31", "\199\34\109\37\44\49\27\137"));
        v62.components.spellcaster:SetSpellFn(v36);
        v62.components.spellcaster:SetCanCastFn(v38);
        v62.components.spellcaster.canuseontargets = true;
        v62.components.spellcaster.canuseondead = true;
        v62.components.spellcaster.canuseonpoint = true;
        v62.components.spellcaster.canuseonpoint_water = true;
        v62.components.spellcaster.canusefrominventory = false;
        v62.fuelmetask = v62:DoPeriodicTask(0.5 - 0, v21);
        v62._onlocomote = function(v86) if v86.components.locomotor.wantstomoveforward then if (v62.ringalingtask == nil) then v62.ringalingtask =
                                v62:DoPeriodicTask(0.5,
                                        function(v116) v116.SoundEmitter:PlaySound(
                                                        "dontstarve/creatures/together/deer/bell"); end); end elseif (v62.ringalingtask ~= nil) then
                        v62.ringalingtask:Cancel();
                        v62.ringalingtask = nil;
                end end;
        return v62;
end
return Prefab(v7("\194\204\232\111\81\248\225\254\208\214\117\82\239\225\196", "\161\164\137\29\61\157\146"), v20, v10),
    Prefab(
            v7("\72\162\87\154\101\229\32\164\99\169\90\164\101\236\36\187\99\190\109\173\120\242\50\173",
                    "\60\202\50\197\23\128\65\200"), v39, v11);
