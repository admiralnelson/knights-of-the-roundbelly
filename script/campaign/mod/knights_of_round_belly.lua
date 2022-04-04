---SCRIPT WORKING.
local VERSION = "0.2.0"
local json = require("libsneedio_json");
local var_dump = require("var_dump");

local print = function (x)
  out("admiralnelson: "..tostring(x));
  print2(tostring(x).."\n");
end;

print("Running Knights of Round Belly mod version "..VERSION);

local DEBUG  = false;
local PError = PrintError or print;
local PWarn  = PrintWarning or print;
local core = core;
local cm = cm;
local find_uicomponent = find_uicomponent;
local CampaignUI = CampaignUI;
local Is_Bretonnian = Is_Bretonnian;
local CalculateChivalryTraitsForFaction = CalculateChivalryTraitsForFaction;
local Remove_Economy_Penalty = Remove_Economy_Penalty;
local Show_Peasant_Warning = Show_Peasant_Warning;
local throw = error;

local bInited = false;

local PrintError = function (x)
  if(PError) then PError(tostring(x).."\n"); else print("ERROR "..x); end
  --print("ERROR "..x);
end

local PrintWarning = function (x)
  if(PWarn) then PWarn(tostring(x).."\n"); else print("WARN "..x); end
  --print("WARN "..x);
end

if(json) then PrintWarning("json existed"); end

local IsElementInArray = function (el, arr)
    for index, value in pairs(arr) do
        if(value == el) then return true; end
    end
    return false;
end

local DelayedCall = function (func, time)
    if(func == nil) then
        return;
    end
    time = time or 0.5;

    cm:callback(function()
        func();
    end, time);
end

local SplitStr = function (inputstr, sep)
    if sep == nil then
        sep = "%s";
    end
    local t={};
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str);
    end
    return t;
end

local ConcatArray = function (a, b)
    for _, v in ipairs(b) do
        table.insert(a, v)
    end
end

local POSITIVE_PEASANT_ECON_PIC_URL = "ui\\skins\\default\\peasant_economy_top_positive.png";
local NEGATIVE_PEASANT_ECON_PIC_URL = "ui\\skins\\default\\peasant_economy_top_negative.png";

local ADMIRALNELSON_GRAIL_OGRE_VERSION = "ADMIRALNELSON_GRAIL_OGRE_VERSION";
local ADMIRALNELSON_SAVED_PEASANT_TABLE = "ADMIRALNELSON_SAVED_PEASANT_TABLE";
local ADMIRALNELSON_SAVED_OGRE_SPAWNED_MARKER_TABLE = "ADMIRALNELSON_SAVED_OGRE_SPAWNED_MARKER_TABLE";
local ADMIRALNELSON_SAVED_RANDOM_OGRE_TABLE = "ADMIRALNELSON_SAVED_RANDOM_OGRE_TABLE";
local ADMIRALNELSON_SAVED_LOUIS_LE_GROS_GOT_WEAPON = "ADMIRALNELSON_SAVED_LOUIS_LE_GROS_GOT_WEAPON";
local GRAIL_OGRE_VERSION = VERSION;

local DELAYED_UPDATE_FOR_LABEL = 0.7;

local HUMAN_DICE_SIDES = 10;
local HUMAN_DICE_ROLL = 4;
local DICE_THRESHOLD_WHEN_CAPTURING_SETTLEMENT = 22;
local DICE_THRESHOLD_AFTER_BATTLE = 31;

local BOT_DICE_SIDES = 10;
local BOT_DICE_ROLL = 4;
local DICE_THRESHOLD_EACH_TURN_FOR_BOT = 27;

--spawn: ok, localisation: ok, skill set: untested, weapon: untested, peasant slot reduction: untested
local LOUIS_LE_GROS_AGENT_KEY = "admnelson_bret_ogre_louis_le_gros_agent_key";
--spawn: ok, localisation: ok, skill set: untested, weapon: no weapon, peasant slot reduction: untested
local CLAUDIN_AGENT_KEY       = "admnelson_bret_ogre_claudin_agent_key";
--spawn: ok, localisation: ok, skill set: untested, weapon: no weapon, peasant slot reduction: untested
local GARRAVAIN_D_ESTRANGOT_AGENT_KEY = "admnelson_bret_ogre_garravain_d_estrangot_agent_key";
--spawn: ok, localisation: ok, skill set: untested, weapon: no weapon, peasant slot reduction: untested
local HECTOR_DE_MARIS_AGENT_KEY     = "admnelson_bret_ogre_hector_de_maris_agent_key";
--spawn: ok, localisation: ok, skill set: untested, weapon: no weapon, peasant slot reduction: untested
local YVAIN_LE_BATARD_AGENT_KEY     = "admnelson_bret_ogre_yvain_le_batard_agent_key";
--spawn: ok, localisation: ?, skill set: untested, weapon: no weapon, peasant slot reduction: untested
local GORNEMANT_DE_GOORT_AGENT_KEY  = "admnelson_bret_ogre_gornemant_de_goort_agent_key"
--spawn: ok, localisation: ?, skill set: untested, weapon: no weapon, peasant slot reduction: untested
local LUCANT_LE_BOUTELLIER_AGENT_KEY = "admnelson_bret_ogre_lucant_le_boutellier_agent_key";

-- louise le gros weapon skill key
local LOUIS_LE_GROS_WEAPON_SKILL_KEY = "admiralnelson_ogre_archduke_grand_mace_characther_skills_key_lane_2";

local DILLEMA_LOIS_LE_GROS_RECRUITMENT = "admiralnelson_archduke_recruitment_at_massif_orcal_dilemma_key";
local DILLEMA_LOIS_LE_GROS_RECRUITMENT_AT_ARABY = "admiralnelson_archduke_recruitment_at_araby_dilemma_key";
local DILLEMA_HECTOR_DE_MARIS_RECRUITMENT = "admiralnelson_hector_recruitment_at_skavenblight_dilemma_key";
local DILLEMA_YVAIN_RECRUITMENT = "admiralnelson_ogre_recruitment_at_norscan_region_dilemma_key";
local DILLEMA_GORNEMANT_RECRUITMENT = "admiralnelson_ogre_recruitment_at_empire_marienberg_region_dilemma_key";
local DILLEMA_GARRAVAIN_RECRUITMENT = "admiralnelson_ogre_recruitment_at_badlands_dilemma_key";
local DILLEMA_LUCANT_RECRUITMENT = "admiralnelson_ogre_recruitment_at_border_princes_and_slyvania_dilemma_key";
local DILLEMA_CLAUDIN_RECRUITMENT = "admiralnelson_ogre_recruitment_at_woodelves_region_dilemma_key";
local DILLEMA_OTHER_GRAIL_OGRE_DUE_TO_OGRE_UNIT_RECRUITMENT = "admiralnelson_ogre_recruitment_because_army_has_ogre_merc_dilemma_key";

-- faction for ogre: type faction object
local DESIGNATED_FACTION = nil;
local IS_PLAYED_BY_HUMAN = false;

PrintError("first tick was executed here!");
var_dump(json);
var_dump(Bretonnia_Peasant_Units);

if CHIVALRY_SKILLS then
    local ogreChivalrySkills = {
        -- background skills
        {
            skill = "admiralnelson_ogre_being_is_generally_unchivalrous_and_savage_skills_key_background_skill_scripted",
            value = -30
        },
        -- upgrade skills
        {
            skill = "admiralnelson_ogre_civilised_characther_skills_key_lane_2",
            value = 10
        },
        {
            skill = "admiralnelson_ogre_anger_management_characther_skills_key_lane_2",
            value = 10
        },
        {
            skill = "admiralnelson_ogre_knightly_manner_characther_skills_key_lane_2",
            value = 10
        },
        {
            skill = "admiralnelson_ogre_archduke_the_role_model_characther_skills_key_lane_2",
            value = 10
        },
        {
            skill = "admiralnelson_ogre_archduke_incorruptible_characther_skills_key_lane_2",
            value = 30
        }
    };

    ConcatArray(CHIVALRY_SKILLS, ogreChivalrySkills);
    var_dump(CHIVALRY_SKILLS);
end

local OGRE_MERC_UNIT_KEYS = {
  "wh2_twa05_ogr_cav_mournfang_cavalry_0",
  "wh2_twa05_ogr_inf_maneaters_2",
  "wh2_twa05_ogr_inf_maneaters_3",
  "wh2_twa05_ogr_inf_ogres_0",
  "wh2_twa05_ogr_inf_ogres_1"
};

local BretonnianFactions = {
    "wh_main_brt_bretonnia",
    "wh_main_brt_carcassonne",
    "wh_main_brt_bordeleaux",
    "wh2_dlc14_brt_chevaliers_de_lyonesse"
};

local PeasantSlotReductionSkills = {

  ["admiralnelson_ogre_being_is_generally_unchivalrous_and_savage_skills_key_background_skill_scripted"] = 6,
  -- for the archduke
  ["admiralnelson_ogre_archduke_the_role_model_characther_skills_key_lane_2"] = -1,
  ["admiralnelson_ogre_archduke_incorruptible_characther_skills_key_lane_2"] = -1,

  -- for others....
  ["admiralnelson_ogre_civilised_characther_skills_key_lane_2"] = -1,
  ["admiralnelson_ogre_anger_management_characther_skills_key_lane_2"] = -1,
  ["admiralnelson_ogre_knightly_manner_characther_skills_key_lane_2"] = -1,
  ["admiralnelson_ogre_great_deeds_characther_skills_key_lane_2"] = -1,
  ["admiralnelson_ogre_giant_paladins_characther_skills_key_lane_2"] = -1,
};

local InitialGrailKnightOgrePeasantResevationSlots = {
  ["admnelson_bret_ogre_louis_le_gros_main_unit_key"] = 18,
  ["admnelson_bret_ogre_yvain_le_batard_main_unit_key"] = 18,
};

local GrailOgreRecruitmentDilemmas = {
  [DILLEMA_LOIS_LE_GROS_RECRUITMENT] = LOUIS_LE_GROS_AGENT_KEY,
  [DILLEMA_LOIS_LE_GROS_RECRUITMENT_AT_ARABY] = LOUIS_LE_GROS_AGENT_KEY,
  [DILLEMA_HECTOR_DE_MARIS_RECRUITMENT] = HECTOR_DE_MARIS_AGENT_KEY,
  [DILLEMA_YVAIN_RECRUITMENT] = YVAIN_LE_BATARD_AGENT_KEY,
  [DILLEMA_GORNEMANT_RECRUITMENT] = GORNEMANT_DE_GOORT_AGENT_KEY,
  [DILLEMA_GARRAVAIN_RECRUITMENT] = GARRAVAIN_D_ESTRANGOT_AGENT_KEY,
  [DILLEMA_LUCANT_RECRUITMENT] = LUCANT_LE_BOUTELLIER_AGENT_KEY,
  [DILLEMA_CLAUDIN_RECRUITMENT] = CLAUDIN_AGENT_KEY,
  [DILLEMA_OTHER_GRAIL_OGRE_DUE_TO_OGRE_UNIT_RECRUITMENT] = "RANDOM"
};

local GrailOgreSpawnLocation = {
  -- only in massive orcal admiralnelson_archduke_recruitment_at_massif_orcal_dilemma_key LOCALISATION OK
  ["wh_main_massif_orcal_massif_orcal"] = LOUIS_LE_GROS_AGENT_KEY,
  -- when in araby admiralnelson_archduke_recruitment_at_araby_dilemma_key x
  ["wh2_main_great_desert_of_araby_pools_of_despair"] = LOUIS_LE_GROS_AGENT_KEY,

  -- near west empire and near mareienburg admiralnelson_ogre_recruitment_at_empire_marienberg_region_dilemma_key working, LOCALISATION OK
  ["wh2_main_misty_hills_the_black_pit"] = GORNEMANT_DE_GOORT_AGENT_KEY,
  ["wh_main_middenland_weismund"] = GORNEMANT_DE_GOORT_AGENT_KEY,
  ["wh2_main_laurelorn_forest_laurelorn_forest"] = GORNEMANT_DE_GOORT_AGENT_KEY,
  ["wh_main_middenland_middenstag"] = GORNEMANT_DE_GOORT_AGENT_KEY,
  ["wh2_main_misty_hills_wreckers_point"] = GORNEMANT_DE_GOORT_AGENT_KEY,
  ["wh_main_hochland_brass_keep"] = GORNEMANT_DE_GOORT_AGENT_KEY,

  -- only in skavenblight admiralnelson_hector_recruitment_at_skavenblight_dilemma_key working, LOCALISATION OK
  ["wh2_main_skavenblight_skavenblight"] = HECTOR_DE_MARIS_AGENT_KEY,

  -- spawn at tilea or estalia or wood elves working, description was blank  LOCALISATION OK
  ["wh_main_southern_grey_mountains_karak_azgaraz"] = CLAUDIN_AGENT_KEY,
  ["wh_main_athel_loren_waterfall_palace"] = CLAUDIN_AGENT_KEY,
  ["wh_main_athel_loren_vauls_anvil"] = CLAUDIN_AGENT_KEY,
  ["wh2_main_old_world_glade"] = CLAUDIN_AGENT_KEY,
  ["wh_main_estalia_bilbali"] = CLAUDIN_AGENT_KEY,
  ["wh_main_estalia_magritta"] = CLAUDIN_AGENT_KEY,
  ["wh_main_tilea_miragliano"] = CLAUDIN_AGENT_KEY,
  ["wh_main_tilea_luccini"] = CLAUDIN_AGENT_KEY,
  ["wh2_main_sartosa_sartosa"] = CLAUDIN_AGENT_KEY,
  ["wh2_main_vor_sartosa_sartosa"] = CLAUDIN_AGENT_KEY,

  -- spawn at norscan regions admiralnelson_ogre_recruitment_at_norscan_region_dilemma_key working, perhaps add bonus for him against norsca? LOCALISATION OK
  ["wh2_main_albion_isle_of_wights"] = YVAIN_LE_BATARD_AGENT_KEY,
  ["wh_main_vanaheim_mountains_pack_ice_bay"] = YVAIN_LE_BATARD_AGENT_KEY,
  ["wh2_main_vor_albion_pack_ice_bay"] = YVAIN_LE_BATARD_AGENT_KEY,
  ["wh2_main_albion_citadel_of_lead"] = YVAIN_LE_BATARD_AGENT_KEY,
  ["wh2_main_albion_albion"] = YVAIN_LE_BATARD_AGENT_KEY,
  ["wh_main_ice_tooth_mountains_longship_graveyard"] = YVAIN_LE_BATARD_AGENT_KEY,
  ["wh_main_ice_tooth_mountains_icedrake_fjord"] = YVAIN_LE_BATARD_AGENT_KEY,
  ["wh_main_vanaheim_mountains_bjornlings_gathering"] = YVAIN_LE_BATARD_AGENT_KEY,
  ["wh_main_vanaheim_mountains_troll_fjord"] = YVAIN_LE_BATARD_AGENT_KEY,

  --spawn in the badlands admiralnelson_ogre_recruitment_at_badlands_dilemma_key x working, perhaps add bonus when in badland? against greenskins? LOCALISATION OK
  ["wh_main_western_badlands_bitterstone_mine"] = GARRAVAIN_D_ESTRANGOT_AGENT_KEY,
  ["wh_main_western_badlands_dragonhorn_mines"] = GARRAVAIN_D_ESTRANGOT_AGENT_KEY,
  ["wh_main_western_badlands_ekrund"] = GARRAVAIN_D_ESTRANGOT_AGENT_KEY,
  ["wh_main_western_badlands_stonemine_tower"] = GARRAVAIN_D_ESTRANGOT_AGENT_KEY,
  ["wh_main_blood_river_valley_barag_dawazbag"] = GARRAVAIN_D_ESTRANGOT_AGENT_KEY,
  ["wh2_main_land_of_the_dead_zandri"] = GARRAVAIN_D_ESTRANGOT_AGENT_KEY,

  --spawn in slyvania and border princes admiralnelson_ogre_recruitment_at_border_princes_and_slyvania_dilemma_key x working, LOCALISATION OK
  ["wh_main_western_border_princes_myrmidens"] = LUCANT_LE_BOUTELLIER_AGENT_KEY,
  ["wh_main_eastern_border_princes_akendorf"] = LUCANT_LE_BOUTELLIER_AGENT_KEY,
  ["wh_main_eastern_border_princes_matorca"] = LUCANT_LE_BOUTELLIER_AGENT_KEY,
  ["wh_main_western_border_princes_zvorak"] = LUCANT_LE_BOUTELLIER_AGENT_KEY,
  ["wh_main_western_sylvania_schwartzhafen"] = LUCANT_LE_BOUTELLIER_AGENT_KEY,
  ["wh_main_eastern_sylvania_eschen"] = LUCANT_LE_BOUTELLIER_AGENT_KEY,
  ["wh_main_ostermark_mordheim"] = LUCANT_LE_BOUTELLIER_AGENT_KEY,
  ["wh_main_eastern_sylvania_castle_drakenhof"] = LUCANT_LE_BOUTELLIER_AGENT_KEY,
  ["wh_main_western_sylvania_castle_templehof"] = LUCANT_LE_BOUTELLIER_AGENT_KEY,

};

local GrailOgreSpawned = {
  [LOUIS_LE_GROS_AGENT_KEY] = false,
  [YVAIN_LE_BATARD_AGENT_KEY] = false,
  [GORNEMANT_DE_GOORT_AGENT_KEY] = false,
  [HECTOR_DE_MARIS_AGENT_KEY] = false,
  [CLAUDIN_AGENT_KEY] = false,
  [GARRAVAIN_D_ESTRANGOT_AGENT_KEY] = false,
  [LUCANT_LE_BOUTELLIER_AGENT_KEY] = false
};

local RandomGrailOgres = {};

local CachedPeasant = {
    ["wh_main_brt_bretonnia"] = {
        Free = 0,
        Used = 0,
    },
    ["wh_main_brt_carcassonne"] = {
        Free = 0,
        Used = 0,
    },
    ["wh_main_brt_bordeleaux"] = {
        Free = 0,
        Used = 0,
    },
    ["wh2_dlc14_brt_chevaliers_de_lyonesse"] = {
        Free = 0,
        Used = 0,
    },
};

local OgreDillemaToCallbacks = {};

local ForEach = function (array, pred)
  for key, value in pairs(array) do
    pred(value, key);
  end
end

local GetSavedValue = function (key)
  return cm:get_saved_value(key);
end

local SetSavedValue = function (key, val)
  val = ((type(val) == "table") and json.encode(val) or val);
  cm:set_saved_value(key, val);
end

local SaveData = function ()
  var_dump(json.encode(CachedPeasant));
  var_dump(json.encode(GrailOgreSpawned));
  var_dump(json.encode(RandomGrailOgres));
  SetSavedValue(ADMIRALNELSON_SAVED_PEASANT_TABLE, json.encode(CachedPeasant));
  SetSavedValue(ADMIRALNELSON_SAVED_OGRE_SPAWNED_MARKER_TABLE, json.encode(GrailOgreSpawned));
  SetSavedValue(ADMIRALNELSON_SAVED_RANDOM_OGRE_TABLE, json.encode(RandomGrailOgres));
  PrintWarning("data saved");
end

local LoadData = function ()
  print("load data...");
  if(not GetSavedValue(ADMIRALNELSON_GRAIL_OGRE_VERSION)) then
    PrintError("failed "..ADMIRALNELSON_GRAIL_OGRE_VERSION.." variable is not found on save file");
    return false;
  end
  GRAIL_OGRE_VERSION = GetSavedValue(ADMIRALNELSON_GRAIL_OGRE_VERSION);
  PrintWarning("version loaded! admiral nelson grail ogre ver "..GRAIL_OGRE_VERSION);

  if(not GetSavedValue(ADMIRALNELSON_SAVED_PEASANT_TABLE))then
    PrintError("failed! "..ADMIRALNELSON_SAVED_PEASANT_TABLE.." variable is not found on save file");
    return false;
  end
  CachedPeasant = json.decode(GetSavedValue(ADMIRALNELSON_SAVED_PEASANT_TABLE));
  PrintWarning("cached peasant loaded!");

  if(not GetSavedValue(ADMIRALNELSON_SAVED_OGRE_SPAWNED_MARKER_TABLE))then
    PrintError("failed! "..ADMIRALNELSON_SAVED_OGRE_SPAWNED_MARKER_TABLE.." variable is not found on save file");
    return false;
  end
  print(GetSavedValue(ADMIRALNELSON_SAVED_OGRE_SPAWNED_MARKER_TABLE));
  GrailOgreSpawned = json.decode(GetSavedValue(ADMIRALNELSON_SAVED_OGRE_SPAWNED_MARKER_TABLE));
  PrintWarning("spawned ogre marker loaded!");

  if(not GetSavedValue(ADMIRALNELSON_SAVED_RANDOM_OGRE_TABLE))then
    PrintError("failed! "..ADMIRALNELSON_SAVED_RANDOM_OGRE_TABLE.." variable is not found on save file");
    return false;
  end
  print(GetSavedValue(ADMIRALNELSON_SAVED_RANDOM_OGRE_TABLE));
  RandomGrailOgres = json.decode(GetSavedValue(ADMIRALNELSON_SAVED_RANDOM_OGRE_TABLE));
  PrintWarning("random grail ogre loaded!");

  print("load data OK");
  return true;
end

local IsOgreDukeAgentKey = function (grailOgreAgentKey) return grailOgreAgentKey == LOUIS_LE_GROS_AGENT_KEY; end

local IsFactionAllowedToSpawnGrailOgre = function (faction)
  return faction == DESIGNATED_FACTION;
end

-- Human, faction must be alive
local IsBretonnianHuman = function (faction)
  return faction ~= nil and
         faction:is_null_interface() == false and
         faction:is_dead() == false and
         faction:is_human() == true and
         Is_Bretonnian(faction:name());
end

-- bots and Human, faction must be alive
local IsBretonnian = function (faction)
  return faction ~= nil and
         faction:is_null_interface() == false and
         faction:is_dead() == false and
         Is_Bretonnian(faction:name());
end

-- only true for bots, faction must be alive
local IsBretonnianBot = function (faction)
  return IsBretonnian(faction) and not faction:is_human();
end

local IsFactionAlive = function (faction)
  return faction ~= nil and
         faction:is_null_interface() == false and
         faction:is_dead() == false;
end

local IsRecruitmentOgreDillemas = function (dillemaKey)
  return GrailOgreRecruitmentDilemmas[dillemaKey] ~= nil;
end

local IsGrailOgreHasSpawnedBefore = function (agentKey)
  return GrailOgreSpawned[agentKey] == true;
end

local IsGrailOgre = function (mainUnitKey)
  return mainUnitKey ~= nil and InitialGrailKnightOgrePeasantResevationSlots[mainUnitKey] ~= nil;
end

local IsFoundLockedOgre = function ()
  return #RandomGrailOgres > 0;
end

local DiceRoll = function (numberofDices, numberOfSides)
  numberOfSides = numberOfSides or 6;
  numberofDices = numberofDices or 1;
  local total = 0;
  for i = 1, numberofDices, 1 do
    total = total + cm:random_number(numberOfSides, 1);
  end
  return total;
end

local IsDiceRollSuccess = function (threshold, numberOfDices, numberOfSides)
  return DiceRoll(numberOfDices, numberOfSides) >= threshold;
end

local RandomNumber = function (stop)
  stop = stop or 1;
  return cm:random_number(stop);
end

local GetFactionName = function (faction)
  return (faction ~= nil and
          faction:is_null_interface() == false and
          faction:is_dead() == false and
          faction:name() or error("faction was invalid!"));
end

-- factionkeys : string or array
-- if string, get a single faction Instance otherwise, an array of faction instances returned
local GetFactionByIds = function (factionKeys)
  if(factionKeys == nil) then return; end
  if(type(factionKeys) == "string") then return cm:model():world():faction_by_key(factionKeys); end
  if(type(factionKeys) == "table") then
    local ret = {};
    ForEach(factionKeys, function (el)
      local faction = cm:model():world():faction_by_key(el);
      table.insert(ret, faction);
    end);
    return ret;
  end
end

local FindHumanBretonnianFactions = function ()
  local ret = {}
  ForEach(BretonnianFactions, function (el)
    local BretonnianFaction = GetFactionByIds(el);
    if(IsBretonnianHuman(BretonnianFaction)) then table.insert(ret, BretonnianFaction); end
  end);
  return ret;
end

local FindReferenceToLouisLeGros = function ()
  local bretonniaFac = DESIGNATED_FACTION;
  if(bretonniaFac == nil) then
    PrintError("DESIGNATED_FACTION is nil");
    print(debug.traceback());
    return nil;
  end
  local characterList = bretonniaFac:character_list();
  for i = 0, characterList:num_items() - 1 do
    local character = characterList:item_at(i);
    if(character:character_subtype_key() == LOUIS_LE_GROS_AGENT_KEY) then
      return character;
    end
  end
  PrintError("Could not find reference to Louis Le Gros");
  PrintWarning("It is possible that he may died");
  print(debug.traceback());
  return nil;
end

local GetOgreSpawnSettlements = function (agentkey)
  local accumulator = {};
  ForEach(GrailOgreSpawnLocation, function (agent, settlementKey)
    if(agentkey == agent) then table.insert(accumulator, settlementKey); end
  end);
  return accumulator;
end

local GetWhichOgresCannotBeSpawnedFromSettlement = function ()
  local accumulator = {};
  if(DESIGNATED_FACTION == nil) then return accumulator; end
  if(not IsBretonnian(DESIGNATED_FACTION)) then return accumulator; end

  print("GetWhichOgresCannotBeSpawnedFromSettlement");
  var_dump(GrailOgreSpawned);
  ForEach(GrailOgreSpawned, function (_, ogreKey)
    print("\t"..ogreKey);
    local SettlementOfOgre = GetOgreSpawnSettlements(ogreKey);
    print("settlement of ogre..."..ogreKey)
    var_dump(SettlementOfOgre);
    local regionList = DESIGNATED_FACTION:region_list();
    for i = 0, regionList:num_items() - 1, 1 do
      local Region = regionList:item_at(i);
      print("region "..Region:name());
      if(IsElementInArray(Region:name(), SettlementOfOgre) and
         not IsElementInArray(ogreKey, accumulator)) then
          table.insert(accumulator, ogreKey);
        end
    end

  end);
  return accumulator;
end

local GetAvailableGrailOgreRandomly = function ()
  if(#RandomGrailOgres == 0) then return nil; end
  local random = RandomNumber(#RandomGrailOgres);
  print("GetAvailableGrailOgreRandomly: picked random "..tostring(random).." max length "..tostring(#RandomGrailOgres));
  local ogreKey = RandomGrailOgres[random];
  return ogreKey;
end

local GetOgreMercenariesCountForArmy = function (armyIndex)
  local armyObject = cm:get_military_force_by_cqi(armyIndex);
  local units = armyObject:unit_list();
  local count = 0;
  for j = 0, units:num_items() - 1 do
    local unit = units:item_at(j);
    local key = unit:unit_key();
    if(IsElementInArray(key, OGRE_MERC_UNIT_KEYS)) then
      count = count + 1;
    end
    PrintWarning("\t"..key.."");
  end
  print("mercs ogre count "..count);
  return count;
end

local ResetOgreStates = function ()
  GrailOgreSpawned = {
    [LOUIS_LE_GROS_AGENT_KEY] = false,
    [YVAIN_LE_BATARD_AGENT_KEY] = false,
    [GORNEMANT_DE_GOORT_AGENT_KEY] = false,
    [HECTOR_DE_MARIS_AGENT_KEY] = false,
    [CLAUDIN_AGENT_KEY] = false,
    [GARRAVAIN_D_ESTRANGOT_AGENT_KEY] = false,
    [LUCANT_LE_BOUTELLIER_AGENT_KEY] = false
  };
  if(not IS_PLAYED_BY_HUMAN) then
    RandomGrailOgres = {
      LOUIS_LE_GROS_AGENT_KEY,
      YVAIN_LE_BATARD_AGENT_KEY,
      GORNEMANT_DE_GOORT_AGENT_KEY,
      HECTOR_DE_MARIS_AGENT_KEY,
      CLAUDIN_AGENT_KEY,
      GARRAVAIN_D_ESTRANGOT_AGENT_KEY,
      LUCANT_LE_BOUTELLIER_AGENT_KEY
    };
  else
    RandomGrailOgres = {};
  end
  PrintError("OGRE STATE WAS RESET!");
  SaveData();
end

local PickWhichFactionIsAllowedToSpawnOgre = function ()
  -- follow this prio:
  -- louen > fay > alberic > repanse
  local TargetFaction = nil;
  local Brets = GetFactionByIds(BretonnianFactions);
  local HumanBrets = FindHumanBretonnianFactions();

  if(#HumanBrets == 0) then -- all brets are AI
    ForEach(Brets, function (faction)
      if(TargetFaction == GetFactionByIds(BretonnianFactions[1])) then return; end -- louen
      if(TargetFaction == GetFactionByIds(BretonnianFactions[2])) then return; end -- fay
      if(TargetFaction == GetFactionByIds(BretonnianFactions[3])) then return; end -- alberic
      if(TargetFaction == GetFactionByIds(BretonnianFactions[4])) then return; end -- repanse
      if(IsBretonnian(faction)) then TargetFaction = faction; end
    end);
    IS_PLAYED_BY_HUMAN = TargetFaction:is_human();
    return TargetFaction;
  end

  -- follow this prio:
  -- if there are(or is) human player pick based on this pref
  -- louen > fay > alberic > repanse

  ForEach(HumanBrets, function (faction)
      if(TargetFaction == GetFactionByIds(BretonnianFactions[1])) then return; end -- louen
      if(TargetFaction == GetFactionByIds(BretonnianFactions[2])) then return; end -- fay
      if(TargetFaction == GetFactionByIds(BretonnianFactions[3])) then return; end -- alberic
      if(TargetFaction == GetFactionByIds(BretonnianFactions[4])) then return; end -- repanse
      if(IsBretonnianHuman(faction)) then TargetFaction = faction; end
  end);
  IS_PLAYED_BY_HUMAN = TargetFaction:is_human();
  return TargetFaction;

end

local SetOgreHasSpawned = function (agentKey)
  GrailOgreSpawned[agentKey] = true;
  SaveData();
end

local GetGrailOgreDillemaFromAgentKey = function (agentKey)
  for key, value in pairs(GrailOgreRecruitmentDilemmas) do
    if(value == agentKey) then return key; end
  end
  return nil;
end

local SetPeasantsCountForcefully = function (faction, peasantsAmount)
    if not IsBretonnianHuman(faction) then
        PrintError("SetPeasantsCountForcefully: NOT A HUMAN BRETONNIAN faction");
        return;
    end

    local region_count = faction:region_list():num_items();

    if cm:is_multiplayer() == false then
        if PEASANTS_WARNING_COOLDOWN > 0 then
            PEASANTS_WARNING_COOLDOWN = PEASANTS_WARNING_COOLDOWN - 1;
        end
    end

    PrintError("\tPeasants: "..peasantsAmount);
    Remove_Economy_Penalty(faction);

    local peasants_per_region_fac = PEASANTS_PER_REGION;
    local peasants_base_amount_fac = PEASANTS_BASE_AMOUNT;

    -- Peasants Per Region Modifiers
    if faction:name() == "wh_main_brt_carcassonne" then
        peasants_base_amount_fac = peasants_base_amount_fac + 5;
    end
    if faction:has_technology("tech_dlc07_brt_economy_farm_4") then
        peasants_per_region_fac = peasants_per_region_fac + 1;
    end
    if faction:has_technology("tech_dlc07_brt_heraldry_unification") then
        peasants_base_amount_fac = peasants_base_amount_fac + 10;
    end
    if faction:has_technology("tech_dlc14_brt_rally_the_peasants") then
        peasants_base_amount_fac = peasants_base_amount_fac + 15;
    end

    -- Make sure player has regions
    if faction:region_list():num_items() < 1 then
        peasants_base_amount_fac = 0;
    end

    local free_peasants = (region_count * peasants_per_region_fac) + peasants_base_amount_fac;
    free_peasants = math.max(1, free_peasants);
    PrintWarning("Free Peasants: "..free_peasants);
    local peasant_percent = (peasantsAmount / free_peasants) * 100;
    PrintWarning("Peasant Percent: "..peasant_percent.."%");
    peasant_percent = RoundUp(peasant_percent);
    PrintWarning("Peasant Percent Rounded: "..peasant_percent.."%");
    peasant_percent = math.min(peasant_percent, 200);
    PrintWarning("Peasant Percent Clamped: "..peasant_percent.."%");

    if peasant_percent > 100 then
        peasant_percent = peasant_percent - 100;
        PrintWarning("Peasant Percent Final: "..peasant_percent);
        cm:apply_effect_bundle(PEASANTS_EFFECT_PREFIX..peasant_percent, faction:name(), 0);

        if cm:get_saved_value("ScriptEventNegativePeasantEconomy") ~= true and faction:is_human() then
            core:trigger_event("ScriptEventNegativePeasantEconomy");
            cm:set_saved_value("ScriptEventNegativePeasantEconomy", true);
        end

        if cm:is_multiplayer() == false then
            if PEASANTS_RATIO_POSITIVE == true and PEASANTS_WARNING_COOLDOWN < 1 then
                Show_Peasant_Warning(faction:name());
                PEASANTS_WARNING_COOLDOWN = 25;
            end
        end

        PEASANTS_RATIO_POSITIVE = false;
    else
        PrintWarning("Peasant Percent Final: 0");
        cm:apply_effect_bundle(PEASANTS_EFFECT_PREFIX.."0", faction:name(), 0);

        if cm:get_saved_value("ScriptEventNegativePeasantEconomy") == true and cm:get_saved_value("ScriptEventPositivePeasantEconomy") ~= true and faction:is_human() then
            core:trigger_event("ScriptEventPositivePeasantEconomy");
            cm:set_saved_value("ScriptEventPositivePeasantEconomy", true);
        end
        PEASANTS_RATIO_POSITIVE = true;
    end

    PrintError("forcefully set the peasant count!");
    CachedPeasant[faction:name()].Used = peasantsAmount;
    CachedPeasant[faction:name()].Free = free_peasants;
    SaveData();
end

local CalculatePeasants = function (faction)
    if not (IsBretonnianHuman(faction))  then
        PrintError("not bretonnian!");
        return -1;
    end

    local peasant_count = 0;
    local force_list = faction:military_force_list();

    for i = 0, force_list:num_items() - 1 do
        local force = force_list:item_at(i);

        -- Make sure this isn't a garrison!
        if force:is_armed_citizenry() == false and
           force:has_general() == true then
            local unit_list = force:unit_list();

            for j = 0, unit_list:num_items() - 1 do
                local unit = unit_list:item_at(j);
                local key = unit:unit_key();
                local val = Bretonnia_Peasant_Units[key] or 0;

                PrintWarning("\t"..key.." - "..val);
                peasant_count = peasant_count + val;
            end
        end
    end

    return peasant_count;
end

local CalculateOgres = function (faction)
  if not (IsBretonnianHuman(faction))  then
    PrintError("not bretonnian!");
    return -1;
  end

  local charList = faction:character_list();
  local ret = 0;
  for i = 0, charList:num_items() - 1, 1 do
    local character = faction:character_list():item_at(i);
    local key = character:character_subtype_key();
    local newValue = 0;
    for skill, value in pairs(PeasantSlotReductionSkills) do
      newValue = newValue + (character:has_skill(skill) and
                                value
                             or 0);
      if(character:has_skill(skill)) then
        print("yes..skill was "..skill);
      end
    end
    ret = ret + newValue;
    print("characther id is: "..key);
    print("total reduction skill is now "..tostring(newValue));
  end
  PrintError("---------------------------------------------");
  PrintError("total ogre reseved peasants.."..tostring(ret));
  return ret;
end

local CheckForLockedOgres = function ()
  PrintWarning("===========CHECKING FOR LOCKED OGRES....==========");
  if(DESIGNATED_FACTION == nil) then
    PrintError("DESIGNATED FACTION is null");
    error("designeated faction null reference");
    return;
  end
  local LockedOgres = GetWhichOgresCannotBeSpawnedFromSettlement();
  RandomGrailOgres = LockedOgres;
  print("CheckForLockedOgres")
  var_dump(RandomGrailOgres);
end


-- TODO: keep track of OGRES COUNT! MANUALLY
-- THEN calculate the total before being passed to UpdatePeasantSlotUI

local UpdateOgrePeasantResevationSlots = function (faction)
    if not (IsBretonnianHuman(faction))  then
        PrintError("not bretonnian!");
        return;
    end

    local totalUsedPeasants = CalculatePeasants(faction) + CalculateOgres(faction);
    SetPeasantsCountForcefully(faction, totalUsedPeasants);
end

-- Change the picture TOO!

local UpdatePeasantSlotUI = function (factionKey)
    --"root > layout > resources_bar > right spacer_bretonnia > dy_peasants"
    local root = core:get_ui_root();
    local counterLabel = find_uicomponent(root, "layout", "resources_bar", "right spacer_bretonnia", "dy_peasants");

    if(counterLabel == false) then
        return;
    end

    PrintError("current text is "..counterLabel:GetStateText());
    --extract A/B
    local split = SplitStr(counterLabel:GetStateText(), "/");
    local A = CachedPeasant[factionKey].Used;
    local B = CachedPeasant[factionKey].Free;

    local newLabelText = tostring(A).."/"..B;
    PrintWarning(newLabelText);
    counterLabel:SetStateText(tostring(newLabelText));
    PrintError("has been set");
    PrintError("set picture");
    for i = 0, counterLabel:NumImages(), 1 do
        PrintWarning(tostring(counterLabel:GetImagePath(i)));
    end
    PrintError("dumped image pathes");
    B = tonumber(B);
    if(A >= B) then
        PrintError("set image to negative peasant :(");
        counterLabel:SetImagePath(NEGATIVE_PEASANT_ECON_PIC_URL, 0);
    else
        PrintError("set image to positive peasant :)");
        counterLabel:SetImagePath(POSITIVE_PEASANT_ECON_PIC_URL, 0);
    end
    PrintError("set new picture");
end

local UpdateInternalState = function ()
    for _, faction in ipairs(BretonnianFactions) do
        local bretonnianFaction = GetFactionByIds(faction);
        UpdateOgrePeasantResevationSlots(bretonnianFaction);
        CalculateChivalryTraitsForFaction(bretonnianFaction);
        --Calculate_Economy_Penalty(bretonnianFaction);
    end
end

local UpdateStateAndUI = function ()
  if(not IS_PLAYED_BY_HUMAN) then return; end
  -- State
  DelayedCall(function ()
      UpdateInternalState();
      PrintWarning("calculate OK?");
  end);

  -- UI
  DelayedCall(function ()
      UpdatePeasantSlotUI(cm:get_local_faction_name(true));
      PrintWarning("update OK?");
  end, DELAYED_UPDATE_FOR_LABEL);

end

local ProcessOgreDillemaOnAccept = function (context)
  local dilemma = context:dilemma();
  local choice  = context:choice();
  local faction = context:faction();
  if(not IsRecruitmentOgreDillemas(dilemma)) then return; end
  if(not IsBretonnianHuman(faction)) then return; end

  PrintWarning("processing ogre dillema ... "..dilemma);
  print("player chose "..choice);
  if(choice == 0) then
    return (OgreDillemaToCallbacks[dilemma] ~= nil and OgreDillemaToCallbacks[dilemma]());
  end
end

local SpawnOgrePaladin = function (factionIdx, grailOgreAgentKey, lordCommandIndex)

  local HasOgrePaladinSpawnedBefore = function(ogreKey)
    if(DESIGNATED_FACTION == nil) then return; end
    local characterList = DESIGNATED_FACTION:character_list();
    for i = 0, characterList:num_items() - 1, 1 do
      local char = characterList:item_at(i);
      local key = char:character_subtype_key();
      print("HasOgrePaladinSpawnedBefore "..key);
      if(key == ogreKey) then return true; end
    end
    return false;
  end

  if(IsOgreDukeAgentKey(grailOgreAgentKey)) then
    PrintError("are you spawning ogre duke???");
    return;
  end
  PrintWarning("attempting to spawn "..grailOgreAgentKey);
  cm:spawn_unique_agent_at_character(factionIdx, grailOgreAgentKey, lordCommandIndex, false);
  if(HasOgrePaladinSpawnedBefore(grailOgreAgentKey)) then
    SetOgreHasSpawned(grailOgreAgentKey);
  end
  SaveData();
end

local SpawnOgreDuke = function (lordCommandIndex, onSpawnCallback)
  local actualLord = cm:get_character_by_cqi(lordCommandIndex);
  local lordX   = actualLord:logical_position_x();
  local lordY   = actualLord:logical_position_y();
  local lordKey = actualLord:character_subtype_key();
  local regionKey = actualLord:region():name();
  local faction = actualLord:faction();
  if(IsGrailOgreHasSpawnedBefore(LOUIS_LE_GROS_AGENT_KEY)) then return; end
  cm:create_force_with_general(
      GetFactionName(faction),
      "",
      regionKey,
      lordX,
      lordY,
      "general",
      LOUIS_LE_GROS_AGENT_KEY,
      "names_name_11382017",
      "",
      "names_name_11382018",
      "",
      false,
      function (cqi)
        PrintWarning("spawn duke success "..tostring(cqi));
        if(onSpawnCallback) then onSpawnCallback(cqi); end
      end
  );
  SetOgreHasSpawned(LOUIS_LE_GROS_AGENT_KEY);
  SaveData();
end

local SpawnGrailOgreRandomlyForBotIfPossible = function (faction)
  if(not IsBretonnianBot(faction)) then return; end -- bot only!
  if(not IsDiceRollSuccess(DICE_THRESHOLD_EACH_TURN_FOR_BOT,
                           BOT_DICE_ROLL,
                           BOT_DICE_SIDES)) then -- roll 4d10 and only if reached 26!
    print("unfortunately bot failed to dice roll");
    return;
  end
  local characters = {};
  local force_list = faction:military_force_list();
  for i = 0, force_list:num_items() - 1 do
    local force = force_list:item_at(i);
    -- Make sure this isn't a garrison!
    if(not force:is_armed_citizenry() and
       force:has_general()) then
      if(not force:general_character():is_null_interface()) then
        table.insert(characters, force:general_character());
      end
    end
  end
  local ogreKey = GetAvailableGrailOgreRandomly();
  if(ogreKey == nil) then
    PrintError("ERROR, OGREKEY WAS NULL!\a\a\a\a\a");
    print("available ogre list");
    var_dump(RandomGrailOgres);
    return;
  end
  var_dump(characters);
  local SelectedLord = characters[RandomNumber(#characters)];
  if(SelectedLord == nil) then
    PrintError("ERROR, SELECTED LORD WAS NULL!\a\a\a");
    return;
  end
  local SelectedLordX = SelectedLord:logical_position_x();
  local SelectedLordY = SelectedLord:logical_position_y();
  local factionIdx = faction:command_queue_index();
  local SelectedLordIdx = SelectedLord:command_queue_index();
  PrintWarning("attempting to spawn grail ogre as AI");
  print("ogre key "..ogreKey);
  print("ogre has spawned before "..tostring(IsGrailOgreHasSpawnedBefore(ogreKey)));
  print("lord is "..SelectedLord:character_subtype_key());
  print("pos x "..tostring(SelectedLordX).. " y "..tostring(SelectedLordY));
  if(IsOgreDukeAgentKey(ogreKey)) then
    if(IsGrailOgreHasSpawnedBefore(ogreKey)) then return; end
    SpawnOgreDuke(SelectedLordIdx, function (cqi)
      PrintWarning("FIXME: TODO unlocks all the bonus after spawn for bot user? cqi was "..tostring(cqi));
      -- todo?
      -- unlocks all the bonus after spawn?
    end);
    PrintWarning("DUKE has spawned \a\a");
    return;
  end
  if(IsGrailOgreHasSpawnedBefore(ogreKey)) then return; end
  SpawnOgrePaladin(factionIdx, ogreKey, SelectedLordIdx);
  PrintWarning("Paladin has spawned \a\a");
end

local SpawnGrailOgreOnArmyIfPossible = function (lordCommandIndex, armyIndex)
  if(not IsFoundLockedOgre()) then return; end
  print("SpawnGrailOgreOnArmyIfPossible");
  local lord = cm:get_character_by_cqi(lordCommandIndex)
  local factionIdx = lord:faction():command_queue_index();
  local factionKey = GetFactionName(lord:faction());
  local ogreKey = GetAvailableGrailOgreRandomly();
  local totalOgreMercs = GetOgreMercenariesCountForArmy(armyIndex);
  if(totalOgreMercs == 0) then
    print("army has no ogres (after battle)");
    return;
  end
  if(not IsDiceRollSuccess(DICE_THRESHOLD_AFTER_BATTLE - totalOgreMercs, HUMAN_DICE_ROLL, HUMAN_DICE_SIDES)) then
    print("unfortunately failed to roll (after battle)");
    return;
  end
  if(ogreKey == nil) then return; end
    OgreDillemaToCallbacks[DILLEMA_OTHER_GRAIL_OGRE_DUE_TO_OGRE_UNIT_RECRUITMENT] = function ()
      if(IsOgreDukeAgentKey(ogreKey)) then
        SpawnOgreDuke(lordCommandIndex);
        return;
      end
      SpawnOgrePaladin(factionIdx, ogreKey, lordCommandIndex);
    end
  cm:trigger_dilemma(factionKey, DILLEMA_OTHER_GRAIL_OGRE_DUE_TO_OGRE_UNIT_RECRUITMENT);
end

local SpawnGrailOgreOnOccupiedSettlementIfPossible = function(regionKey, lordCommandIndex)
  if(GrailOgreSpawnLocation[regionKey] == nil) then return; end

  local grailOgreAgentKey = GrailOgreSpawnLocation[regionKey];
  PrintWarning("Process ogre spawning at "..regionKey);
  PrintWarning("Ogre type that will be spawned in "..grailOgreAgentKey);
  local actualLord = cm:get_character_by_cqi(lordCommandIndex);
  local factionKey = actualLord:faction():name();
  local factionIdx = actualLord:faction():command_queue_index();
  print("faction is "..factionKey);

  if(IsGrailOgreHasSpawnedBefore(grailOgreAgentKey)) then
    print(grailOgreAgentKey.." already spawned previously. if he died, then RIP i guess");
      return;
    end

  -- for duke himself
  if(IsOgreDukeAgentKey(grailOgreAgentKey)) then
    OgreDillemaToCallbacks[DILLEMA_LOIS_LE_GROS_RECRUITMENT] = function ()
      SpawnOgreDuke(lordCommandIndex);
    end
    cm:trigger_dilemma  (factionKey, DILLEMA_LOIS_LE_GROS_RECRUITMENT);
    return;
  end

  -- for hector
  if(grailOgreAgentKey == HECTOR_DE_MARIS_AGENT_KEY) then
    local dillema = GetGrailOgreDillemaFromAgentKey(grailOgreAgentKey);
    print("dillema type is hector "..dillema);
    OgreDillemaToCallbacks[dillema] = function ()
      SpawnOgrePaladin(factionIdx, grailOgreAgentKey, lordCommandIndex);
    end
    cm:trigger_dilemma(factionKey, dillema);
    return;
  end
  if(not IsDiceRollSuccess(DICE_THRESHOLD_WHEN_CAPTURING_SETTLEMENT,
                           HUMAN_DICE_ROLL,
                           HUMAN_DICE_SIDES)) then
    print("unfornutately, diceroll failed");
    return;
  end

  local dillema = GetGrailOgreDillemaFromAgentKey(grailOgreAgentKey);
  print("dillema type "..dillema);
  OgreDillemaToCallbacks[dillema] = function ()
    SpawnOgrePaladin(factionIdx, grailOgreAgentKey, lordCommandIndex);
  end
  cm:trigger_dilemma(factionKey, dillema);

end

local ProcessSettlementPostSiege = function (context)
  local faction = context:character():faction();
  if(not IsBretonnianHuman(faction)) then return; end
  if(not IsFactionAllowedToSpawnGrailOgre(faction)) then return; end

  local lordAttackerIndex, _, _ = cm:pending_battle_cache_get_attacker(1);
  local actualLord = cm:get_character_by_cqi(lordAttackerIndex);
  local lordX   = actualLord:logical_position_x();
  local lordY   = actualLord:logical_position_y();
  local lordKey = actualLord:character_subtype_key();
  local region  = context:garrison_residence():region();
  local regionKey = region:name();
  PrintWarning("===============");
  PrintError("Captured: "..regionKey);
  PrintError("Lord attacker was: "..lordKey);
  PrintWarning("Position at: x "..tostring(lordX).." y "..tostring(lordY));
  PrintWarning("===============");
  DelayedCall(function ()
    SpawnGrailOgreOnOccupiedSettlementIfPossible(regionKey, lordAttackerIndex);
  end, 0.7);
end


local GiveLouisLeGrosHisWeaponIfPossible = function ()
  -- print("GiveLouisLeGrosHisWeaponIfPossible");
  -- if 1 then return; end
  -- local lord = FindReferenceToLouisLeGros();
  -- if(lord == nil) then return; end
  -- local flagHasTheWeaponAlready = GetSavedValue(ADMIRALNELSON_SAVED_LOUIS_LE_GROS_GOT_WEAPON);
  -- if(flagHasTheWeaponAlready == true) then
  --   PrintWarning("Louis Le Gros already got his weapon");
  --   return;
  -- end
  -- if(lord:has_skill(LOUIS_LE_GROS_WEAPON_SKILL_KEY)) then
  --   cm:force_add_ancillary(lord, LOUIS_LE_GROS_WEAPON_SKILL_KEY, false);
  --   PrintWarning("Louis le Gros just got his weapon");
  --   SetSavedValue(ADMIRALNELSON_SAVED_LOUIS_LE_GROS_GOT_WEAPON, true);
  -- else
  --   PrintWarning("Louis Le Gros does not have weapon skill");
  -- end
end

local ProcessEventPostBattle = function (context)
  local faction = context:character():faction();
  if(not IsBretonnianHuman(faction)) then return; end
  if(not IsFactionAllowedToSpawnGrailOgre(faction)) then return; end
  CheckForLockedOgres();
  GiveLouisLeGrosHisWeaponIfPossible();

  local actualLord = context:character();
  local army    = actualLord:military_force();
  local lordX   = actualLord:logical_position_x();
  local lordY   = actualLord:logical_position_y();
  local lordKey = actualLord:character_subtype_key();
  if(actualLord:region():is_null_interface()) then
    PrintWarning("===============");
    PrintError("No region for lord "..lordKey);
    PrintError("Position at: x "..tostring(lordX).." y "..tostring(lordY));
    print(debug.traceback());
    PrintWarning("===============");
    return;
  end
  local regionKey = actualLord:region():name();
  PrintWarning("===============");
  PrintError("battle at: "..regionKey);
  PrintError("Lord attacker was: "..lordKey);
  PrintWarning("Position at: x "..tostring(lordX).." y "..tostring(lordY));
  PrintWarning("cqi lord "..tostring(actualLord:command_queue_index()).." army cqi "..tostring(army:command_queue_index()));
  PrintWarning("===============");
  var_dump(RandomGrailOgres);
  DelayedCall(function ()
    SpawnGrailOgreOnArmyIfPossible(actualLord:command_queue_index(), army:command_queue_index());
  end, 0.7);
end

local ConfigureTheMod = function ()
  PrintWarning("starting...");
  DESIGNATED_FACTION = PickWhichFactionIsAllowedToSpawnOgre();
  PrintWarning("designated faction is now "..GetFactionName(DESIGNATED_FACTION));
  PrintWarning("is designated faction human? "..tostring(IS_PLAYED_BY_HUMAN));
  if (not GetSavedValue(ADMIRALNELSON_GRAIL_OGRE_VERSION)) then
    PrintWarning("mod never loaded...");
    SetSavedValue(ADMIRALNELSON_GRAIL_OGRE_VERSION, GRAIL_OGRE_VERSION); -- save the version!
    ResetOgreStates();
    SaveData();
  else
    PrintWarning("loading existing mod");
    LoadData();
    CheckForLockedOgres();
  end
  print("available random ogres:");
  var_dump(RandomGrailOgres);
end

local CheckIfDesignatedFactionDie = function ()
  if(IS_PLAYED_BY_HUMAN) then return; end

  local FactionList = cm:model():world():faction_list();
  for i = 0, FactionList:num_items() - 1 do
    local CurrentFaction = FactionList:item_at(i);
    if(DESIGNATED_FACTION == CurrentFaction) then
      if(not IsFactionAlive(DESIGNATED_FACTION)) then
        PrintError("faction "..GetFactionName(DESIGNATED_FACTION).." WAS dead");
        PrintWarning("reconfiguring");
        ResetOgreStates();
        DESIGNATED_FACTION = PickWhichFactionIsAllowedToSpawnOgre();
        return DESIGNATED_FACTION;
      end
      --print("faction " ..GetFactionName(CurrentFaction).." is alive and well");
      return DESIGNATED_FACTION;
    end
  end
  DESIGNATED_FACTION = nil;
  return DESIGNATED_FACTION;
end

local OnBretTurns = function ()
  GiveLouisLeGrosHisWeaponIfPossible();
  if(IS_PLAYED_BY_HUMAN) then
    CheckForLockedOgres();
    return;
  end
  if(DESIGNATED_FACTION == nil) then
    PrintWarning("all bretonnian factions are dead. Long Live the King and Lady :^(");
    return;
  end
  SpawnGrailOgreRandomlyForBotIfPossible(DESIGNATED_FACTION);
end

local RPCSyncVariable = function ()
  UpdateStateAndUI();
  PrintWarning("RPC RPCSyncVariable done");
end

DelayedCall(function ()

  core:add_listener(
    "admiralnelson_Ogre_UnitDisbanded",
    "UnitDisbanded",
    function (context)
        local faction = context:unit():faction();
        return IsBretonnianHuman(faction);
    end,
    function(context)
        PrintWarning("unit was disbanded ");
        var_dump(context);

        DelayedCall(function ()
            UpdateStateAndUI();
            PrintWarning("update OK?");
        end, DELAYED_UPDATE_FOR_LABEL);
    end,
    true
  );

  core:add_listener(
    "admiralnelson_refresh_peasant_econ",
    "ScriptEventRaiseForceButtonClicked",
    true,
    function ()
        PrintWarning("new lord has been created?");
        UpdateStateAndUI();
    end,
    true
  );

  -- -- todo: bretonnian only
  -- cm:add_faction_turn_start_listener_by_name(
  --     "admiralnelson_refresh_peasant_econ",
  --     "wh_main_brt_bretonnia",
  --     function (context) UpdateStateAndUI(); end,
  --     true
  -- );

  core:add_listener(
    "admiralnelson_refresh_peasant_econ_on_char_screen",
    "ComponentLClickUp",
    function(context) return context.string == "button_ok" end,
    function() UpdateStateAndUI() end,
    true
  );

  core:add_listener(
    "admiralnelson_refresh_peasant_econ_on_start_turn",
    "FactionTurnStart",
    function (context) return IsBretonnianHuman(context:faction()); end,
    function () UpdateStateAndUI(); end,
    true
  );

  core:add_listener(
    "admiralnelson_remote_procedure_call",
    "UITrigger",
    function(context) return context:trigger() == "admRPC_RefreshOgres"; end,
    function() RPCSyncVariable(); end,
    true
  );

  core:add_listener(
    "admiralnelson_refresh_peasant_econ_on_end_turn",
    "FactionTurnEnd",
    function (context) return IsBretonnianHuman(context:faction()); end,
    function ()
      PrintError("on end turn called");
      CampaignUI.TriggerCampaignScriptEvent(0, "admRPC_RefreshOgres");
      UpdateStateAndUI();
    end,
    true
  );

  core:add_listener(
    "admiralnelson_check_for_bretonnia_faction_alive",
    "FactionTurnEnd",
    true,
    function ()
      CheckIfDesignatedFactionDie();
    end,
    true
  );

  core:add_listener(
    "admiralnelson_check_ogre_state_on_end_turn",
    "FactionTurnEnd",
    function (context) return IsBretonnian(context:faction()); end,
    function (context)
      if(IS_PLAYED_BY_HUMAN) then
        CampaignUI.TriggerCampaignScriptEvent(0, "admRPC_RefreshOgres");
        return;
      end
      if(context:faction() == DESIGNATED_FACTION) then
        PrintError("on end turn called for AIs...");
        OnBretTurns();
      end
    end,
    true
  );

  core:add_listener(
    "admiralnelson_detect_for_paladin_spawn",
    "UniqueAgentSpawned",
    function (context)
      PrintError("================Unique agent spawned ==============");
      var_dump(context);
      var_dump(context:unique_agent_details():character());
      var_dump(context:unique_agent_details():character():character_subtype_key());
      return IsGrailOgre(not context:unique_agent_details():character():is_null_interface() and
                            context:unique_agent_details():character():character_subtype_key()
                          or nil);
    end,
    function (context)
      PrintError("saved context to variable");
      local characterKey = context:unique_agent_details():character():character_subtype_key();
      PrintError(characterKey);
      UpdateStateAndUI();
    end,
    true
  );

  core:add_listener(
    "admiralnelson_detect_for_agent_killed_or_disband_bot",
    "UniqueAgentDespawned",
    function (context)
      if(not IS_PLAYED_BY_HUMAN) then return false; end
      local character = context:unique_agent_details():character();
      return not character:is_null_interface() and IsBretonnianBot(character:faction());
    end,
    function (context)
      local character = context:unique_agent_details():character();
      local characterKey = context:unique_agent_details():character():character_subtype_key();
      print("BOT disbanded char is "..tostring(characterKey).."\a\a");
    end
  )

  core:add_listener(
    "admiralnelson_detect_for_agent_disband",
    "UniqueAgentDespawned",
    function(context)
      local character = context:unique_agent_details():character();
      return not character:is_null_interface() and IsBretonnianHuman(character:faction());
    end,
    function (context)
      local character = context:unique_agent_details():character();
      local characterKey = context:unique_agent_details():character():character_subtype_key();
      print("disbanded char is "..tostring(characterKey));
      UpdateStateAndUI();
    end,
    true
  );

  core:add_listener(
    "admiralnelson_detect_for_agent_attach_or_detached",
    "CharacterSelected",
    true,
    function (context)
      print("selected char is "..tostring(context:character():character_subtype_key()));
      UpdateStateAndUI();
    end,
    true
  );

--------- battle monitors

  core:add_listener(
    "admiralnelson_monitor_for_battle_aftermath",
    "CharacterCompletedBattle",
    function() return cm:model():pending_battle():has_been_fought() end,
    function(context)
      PrintWarning("battle has been fought");
      ProcessEventPostBattle(context);
    end,
    true
  );

  core:add_listener(
    "admiralnelson_monitor_for_ongoing_battle",
    "PendingBattle",
    true,
    function (context)
      PrintWarning("battle is pending...");
      local pendingBattle = context:pending_battle();
    end
  )

  core:add_listener(
    "admiralnelson_monitor_for_settlement_siege_aftermath_takeover",
    "GarrisonOccupiedEvent",
    true,
    function(context)
      PrintWarning("siege has been fought: take over");
      ProcessSettlementPostSiege(context);
    end,
    true
  );

  core:add_listener(
    "admiralnelson_monitor_for_settlement_siege_aftermath_sacked",
    "CharacterSackedSettlement",
    true,
    function(context)
      PrintWarning("siege has been fought: sack");
      ProcessSettlementPostSiege(context);
    end,
    true
  );

  core:add_listener(
    "admiralnelson_monitor_for_settlement_siege_raze",
    "CharacterRazedSettlement",
    true,
    function(context)
      PrintWarning("siege has been fought: raze");
      ProcessSettlementPostSiege(context);
    end,
    true
  );

-------- dillema monitor

  core:add_listener(
    "admirealnelson_check_for_dillema_multiple_choices",
    "DilemmaChoiceMadeEvent",
    true,
    function (context)
      ProcessOgreDillemaOnAccept(context);
    end,
    true
  );

end, 0.1);

-- away we go!;
ConfigureTheMod();

DEBUG = false;

PrintError("FUCK");

if DEBUG then
  if not cm:get_saved_value("knights_of_round_belly_TEST") then
      cm:set_saved_value("knights_of_round_belly_TEST", true)
      cm:spawn_character_to_pool("wh_main_brt_bretonnia",
                                 "names_name_11382017",
                                 "names_name_11382018", "", "", 90, true, "general", "admnelson_bret_ogre_louis_le_gros_agent_key", false, "");
      DelayedCall(function ()
        local bret = FindHumanBretonnianFactions()[1];
        local factionCommandIdx = bret ~= nil and
                                    bret:command_queue_index()
                                  or -1;

        local cityCommandIdx = bret ~= nil and
                                bret:home_region():cqi()
                              or -1;

        if (factionCommandIdx == -1 or cityCommandIdx == -1) then
            print("fac command "..tostring(factionCommandIdx).." city command"..tostring(cityCommandIdx));
            return;
        end
        PrintError(factionCommandIdx);
        PrintError(cityCommandIdx);
        cm:spawn_unique_agent_at_region(
            factionCommandIdx,
            "admnelson_bret_ogre_yvain_le_batard_agent_key",
            cityCommandIdx,
            true
        );
        cm:spawn_unique_agent_at_region(
            factionCommandIdx,
            "admnelson_bret_ogre_claudin_agent_key",
            cityCommandIdx,
            true
        );
        cm:spawn_unique_agent_at_region(
          factionCommandIdx,
          "admnelson_bret_ogre_garravain_d_estrangot_agent_key",
          cityCommandIdx,
          true
        );
        cm:spawn_unique_agent_at_region(
          factionCommandIdx,
          "admnelson_bret_ogre_lucant_le_boutellier_agent_key",
          cityCommandIdx,
          true
        );
        cm:spawn_unique_agent_at_region(
          factionCommandIdx,
          "admnelson_bret_ogre_gornemant_de_goort_agent_key",
          cityCommandIdx,
          true
        );
        cm:spawn_unique_agent_at_region(
          factionCommandIdx,
          "admnelson_bret_ogre_hector_de_maris_agent_key",
          cityCommandIdx,
          true
        );
        PrintWarning("spawned!");
      end);
    else
      LoadData();
      UpdateStateAndUI();
  end
end

PrintWarning("completed");