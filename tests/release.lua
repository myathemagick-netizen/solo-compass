local SC,P=SoloCompass,SoloCompass.Progress
local n=0
local function test(name,fn) fn(); n=n+1; print('PASS '..name) end
local function collect(method) local result={}; SC.Suggestions[method](SC.Suggestions,function(s) result[#result+1]=s end); return result end
local oldLocked=SC.Suggestions.IsLocked
SC.Suggestions.IsLocked=function(_,id) return id==550 end
GetServerExpansionLevel=function() return 11 end
UnitLevel=function() return 90 end
C_EncounterJournal={GetInstanceForGameMap=function(id) return id end}
EJ_GetInstanceInfo=function(id) return 'Native raid '..id,'description',0,'raid-icon-'..id end
GetAchievementInfo=function(id) return id,'An achievement',0,false,0,0,0,'',0,'achievement-icon-'..id end
test('raid catalog covers Classic through Dragonflight, with native icons and known lockouts',function()
 local list=collect('BuildRaids'); assert(#SC.Data.Raids==51 and #list==50)
 local found={}; for _,s in ipairs(list) do found[s.instanceID]=s; assert(s.icon and s.detail:find('Soloability')) end
 assert(found[409] and found[469] and found[2522] and found[2569] and found[2549] and not found[550])
 assert(found[409].icon=='raid-icon-409')
end)
test('raid level and expansion gates exclude newer difficult content for a lower character',function()
 UnitLevel=function() return 60 end
 for _,s in ipairs(collect('BuildRaids')) do assert(s.instanceID~=2522 and s.instanceID~=1712) end
 UnitLevel=function() return 90 end; GetServerExpansionLevel=function() return 10 end
 for _,s in ipairs(collect('BuildRaids')) do assert(s.instanceID~=2522) end
 GetServerExpansionLevel=function() return 11 end
end)
SC.Suggestions.IsLocked=oldLocked
local defaultCalls,searchCalls,refilters=0,0,0
local visible={}
C_ToyBoxInfo={SetDefaultFilters=function() defaultCalls=defaultCalls+1 end}
C_ToyBox={SetFilterString=function(text) assert(text==''); searchCalls=searchCalls+1 end,
 SetAllSourceTypeFilters=function(value) assert(value) end,SetAllExpansionTypeFilters=function(value) assert(value) end,
 SetCollectedShown=function(value) assert(value) end,SetUncollectedShown=function(value) assert(value) end,
 ForceToyRefilter=function() refilters=refilters+1; visible={101,102,103} end,
 GetNumFilteredToys=function() return #visible end,GetToyFromIndex=function(i) return visible[i] end,
 GetToyInfo=function(id) return id,'Toy '..id,'toy-icon' end}
PlayerHasToy=function(id) return id==102 end
local queued={}; C_Timer.After=function(_,fn) queued[#queued+1]=fn end
local function drain() local i=0; while #queued>0 do table.remove(queued,1)(); i=i+1; assert(i<3000) end end
SoloCompassCharDB.interests={toys=true}; P.caches={}; P.toyIDs=nil
local function toys() local list={}; P:Toys(function(s) list[#list+1]=s end); return list end
test('toy scan clears filters, captures full IDs, and avoids resetting filters on ordinary redraws',function()
 toys(); drain(); local list=toys(); assert(#list==2 and defaultCalls==1 and searchCalls==1 and refilters==1)
 visible={}; toys(); assert(defaultCalls==1 and #P.toyIDs==3)
 P:RefreshCaches(); toys(); drain(); toys(); assert(defaultCalls==2)
end)
C_Texture={GetAtlasInfo=function(name) return name:find('goblin') or name:find('testfaction') end}
test('reputation artwork uses native Renown and goblin atlases and faction-specific PvP icons',function()
 local _,atlas=P:ReputationIcon(2696,{textureKit='testfaction'}); assert(atlas=='majorfactions_icons_testfaction512')
 local _,goblin=P:ReputationIcon(21,{}); assert(goblin=='raceicon128-goblin-male')
 assert(P:ReputationIcon(730,{}):find('Achievement_PVP_A_01'))
 assert(P:ReputationIcon(729,{}):find('Achievement_PVP_H_01'))
end)
GetAchievementInfo=function(id) return id,'The Argent Crusade',0,false,0,0,0,'',0,'argent-icon' end
test('legacy reputation achievement icons are accepted only for matching faction names',function()
 assert(P:ReputationIcon(1106,{name='The Argent Crusade'})=='argent-icon')
 assert(P:ReputationIcon(1106,{name='Different faction'})~='argent-icon')
end)
print(n..' release refinement tests passed')
