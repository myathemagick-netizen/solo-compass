local SC,P=SoloCompass,SoloCompass.Progress
local count=0
local function test(name,fn) fn(); count=count+1; print('PASS '..name) end
local pending={}; C_Timer.After=function(_,fn) pending[#pending+1]=fn end
local function drain() local n=0; while #pending>0 do table.remove(pending,1)(); n=n+1; assert(n<3000) end end
local function collect(method) local result={}; P[method](P,function(s) result[#result+1]=s end); return result end
SC:ClearGoal(); SC.UI:Hide(); SoloCompassCharDB.interests={mounts=true,toys=true,delves=true}; P.caches={}
local owned={}
C_MountJournal={GetMountIDs=function() return {8001,8002,8003,8004} end,
 GetMountInfoByID=function(id) return 'Mount '..id,0,'mount-icon',false,true,id==8003 and 8 or 1,false,false,nil,id==8004,owned[id]==true end,
 GetMountInfoExtraByID=function() return 0,'Description','Drop: A dungeon boss' end}
test('mount catalog scans beyond starter IDs and excludes owned, hidden and unsupported sources',function()
 owned[8002]=true; collect('Mounts'); drain(); local result=collect('Mounts')
 assert(#result==1 and result[1].targetID==8001 and result[1].detail:find('dungeon boss'))
 owned[8001]=true; assert(#collect('Mounts')==0)
end)
local toyOwned={}
C_ToyBox={GetNumFilteredToys=function() return 3 end,GetToyFromIndex=function(i) return 9000+i end,
 GetToyInfo=function(id) return id,'Toy '..id,'toy-icon' end,
 SetFilterString=function(text) assert(text=='') end}
PlayerHasToy=function(id) return toyOwned[id]==true end
C_TooltipInfo={GetToyByItemID=function() return {lines={{leftText='Source: A vendor'}}} end}
test('toy journal finds missing toys beyond starter IDs with client icons and tooltip data',function()
 toyOwned[9002]=true; collect('Toys'); drain(); local result=collect('Toys'); assert(#result==2)
 assert(result[1].icon=='toy-icon' and result[1].detail:find('vendor'))
end)
local keys=2
C_CurrencyInfo={GetCurrencyInfo=function() return {name='Restored Coffer Key',quantity=keys} end}
C_DelvesUI={GetDelvesMinRequiredLevel=function() return 70 end}
local mapReads=0
C_Map=C_Map or {}; C_Map.GetMapChildrenInfo=function() return {{mapID=100,mapType=3},{mapID=200,mapType=3}} end
local delveInfo={
 [7001]={name='Named normal delve',atlasName='delves',position={GetXY=function() return .2,.3 end}},
 [7002]={name='Named bountiful delve',atlasName='delves-bountiful',position={GetXY=function() return .4,.5 end}}}
C_AreaPoiInfo={GetDelvesForMap=function(id) mapReads=mapReads+1; return id==100 and {7001,7002} or {7002} end,
 GetAreaPOIInfo=function(_,id) return delveInfo[id] end}
test('delves scan in batches, deduplicate map entries, and rank named bountiful entrances with keys',function()
 assert(#collect('Delves')==0 and mapReads==0); drain(); local result=collect('Delves')
 assert(#result==2 and result[1].targetID==7002 and result[1].atlas=='delves-bountiful')
 assert(result[1].detail:find('2') and result[1].mapX==.4)
end)
test('delve key counts refresh without rebuilding map data and zero keys are explicit',function()
 keys=0; local result=collect('Delves'); assert(result[1].detail:find('No keys on hand'))
 keys=nil; result=collect('Delves'); assert(result[1].detail:find('unavailable'))
end)
test('delve navigation preserves the exact entrance waypoint in the saved goal',function()
 local goal=collect('Delves')[1]; SC:SetGoal(goal)
 assert(SoloCompassCharDB.goalSnapshot.mapX==.4)
 local map,x,y=SC.Navigation:Destination(goal); assert(map==100 and x==.4 and y==.5)
end)
test('a low-level character gets a leveling step instead of an inaccessible delve',function()
 local old=UnitLevel; UnitLevel=function() return 60 end
 local result=collect('Delves'); assert(#result==1 and result[1].action=='questlog')
 UnitLevel=old
end)
test('missing Renown frame safely falls back for both details and map actions',function()
 local opened
 MajorFactionRenownFrame=nil; MajorFactions_LoadUI=nil
 ToggleMajorFactionRenown=function() error('nil frame helper must never run') end
 ToggleCharacter=function(tab) opened=tab end
 SC.UI:HandleCardClick({action='reputation',progressKind='renown',targetID=2696}); assert(opened=='ReputationFrame')
 local old=SC.UI.OpenMap; SC.UI.OpenMap=function(_,map) opened='map' end
 SC.Navigation:Go({action='reputation',progressKind='renown',targetID=2710}); assert(opened=='map')
 SC.UI.OpenMap=old
end)
print(count..' collection, delve and nil-frame regression tests passed')

