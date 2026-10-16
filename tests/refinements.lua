local SC,P=SoloCompass,SoloCompass.Progress
local total=0
local function test(name,fn) fn(); total=total+1; print('PASS '..name) end
local oldAfter=C_Timer.After
local pending={}
C_Timer.After=function(_,fn) pending[#pending+1]=fn end
local function drain() local n=0; while #pending>0 do table.remove(pending,1)(); n=n+1; assert(n<3000) end end
local function collect(method) local list={}; P[method](P,function(s) list[#list+1]=s end); return list end
SC:ClearGoal(); SC.UI:Hide(); SoloCompassCharDB.interests={professions=true}; P.caches={}; P.ownedHouses=nil
local originalGetProfessions,originalGetProfessionInfo=GetProfessions,GetProfessionInfo
GetProfessions=function() return 1,2,nil,4,5 end
GetProfessionInfo=function(index)
 local data={[1]={'Mining','mining-icon',186},[2]={'Blacksmithing','smith-icon',164},[4]={'Fishing','fish-icon',356},[5]={'Cooking','cook-icon',185}}
 local row=data[index]; return row[1],row[2],300,800,0,0,row[3]
end
local infos={
 [186]={professionID=186,professionName='Mining',expansionName='Unknown',skillLevel=300,maxSkillLevel=800},
 [164]={professionID=164,professionName='Blacksmithing',expansionName='Unknown',skillLevel=300,maxSkillLevel=800},
 [1001]={professionID=1001,parentProfessionID=164,professionName='Kul Tiran Blacksmithing',expansionName='Kul Tiran',skillLevel=8,maxSkillLevel=175},
 [1002]={professionID=1002,parentProfessionID=356,professionName='Classic Fishing',expansionName='Classic',skillLevel=20,maxSkillLevel=300},
 [1003]={professionID=1003,parentProfessionID=185,professionName='Classic Cooking',expansionName='Classic',skillLevel=60,maxSkillLevel=300}}
C_TradeSkillUI={GetAllProfessionTradeSkillLines=function() return {186,164,1001,1002,1003} end,GetProfessionInfoBySkillLineID=function(id) return infos[id] end}
test('profession parent totals are excluded while Cooking and Fishing use their own icons',function()
 local items=collect('Professions'); assert(#items==3)
 for _,s in ipairs(items) do assert(s.targetID~=164 and s.targetID~=186 and not s.detail:find('Unknown')); assert(s.icon~='Interface\\Icons\\Trade_BlackSmithing') end
end)
test('secondary professions offer distinct preparation when expansion data is not loaded',function()
 C_TradeSkillUI.GetAllProfessionTradeSkillLines=function() return {} end
 local items=collect('Professions'); assert(#items==2 and items[1].id~=items[2].id)
 for _,s in ipairs(items) do assert(s.targetID==185 or s.targetID==356) end
end)
GetProfessions,GetProfessionInfo=nil,nil
C_TradeSkillUI={GetFilteredRecipeIDs=function() return {501,502,503} end,
 GetRecipeInfo=function(id) return {name='Decor '..id,learned=id~=502,disabled=false,icon=12} end,
 GetRecipeOutputItemData=function(id) return {itemID=id,icon=12} end,
 GetCraftableCount=function() return 1 end}
C_HousingCatalog={GetCatalogEntryInfoByItem=function(id) if id==501 then return {name='A chair'} end end}
test('decor ideas require a learned recipe with a housing catalog output',function()
 P.caches={}; collect('DecorRecipes'); drain(); local items=collect('DecorRecipes')
 assert(#items==1 and items[1].targetID==501 and items[1].action=='decorrecipe')
 SC:SetGoal(items[1]); assert(not P:IsFinished(items[1].id))
 P:OnEvent('UNIT_SPELLCAST_SUCCEEDED','player','cast',503); assert(not P:IsFinished(items[1].id))
 P:OnEvent('UNIT_SPELLCAST_SUCCEEDED','player','cast',501); assert(P:IsFinished(items[1].id))
end)
SC:ClearGoal()
test('a repeat decor goal starts from the new craft count',function()
 local items=collect('DecorRecipes'); assert(#items==1 and items[1].progressTarget==2)
end)
test('lumber planning is offered for a confirmed house owner',function()
 P.ownedHouses={{houseGUID='test'}}; local items=collect('Professions'); local found=false
 for _,s in ipairs(items) do if s.id=='prepare:lumber' then found=true end end
 assert(found); P.ownedHouses=nil
end)
local watched,opened
C_Reputation={SetWatchedFactionByID=function(id) watched=id end,GetFactionDataByID=function() return {nextReactionThreshold=3000,currentStanding=2000} end}
test('tracking a reputation selects the watched bar and shows live remaining progress',function()
 local goal={id='reputation:72',action='reputation',category='reputation',targetID=72,progressKind='reputation',progressTarget=3000,title='Stormwind',detail='Reputation'}
 SC:SetGoal(goal); assert(watched==72 and P:ObjectiveLines(goal)[1]:find('1000'))
end)
ToggleCharacter=function(tab,onlyShow) opened=tab; assert(onlyShow) end
ToggleMajorFactionRenown=function(id) opened=id end
test('reputation details open legacy and Renown panels',function()
 SC.UI:HandleCardClick({action='reputation',targetID=72}); assert(opened=='ReputationFrame')
 MajorFactionRenownFrame={IsShown=function() return false end}
 SC.UI:HandleCardClick({action='reputation',targetID=2507,progressKind='renown'}); assert(opened==2507)
 MajorFactionRenownFrame=nil
 ToggleMajorFactionRenown=function() error('Must not toggle a nil Renown frame') end
 SC.UI:HandleCardClick({action='reputation',targetID=2696,progressKind='renown'}); assert(opened=='ReputationFrame')
end)
C_ResearchInfo={GetDigSitesForMap=function(id) return id==13 and {{name='Active site',position={GetXY=function() return .4,.5 end}}} or {} end}
test('Archaeology navigation resolves an active digsite rather than opening the journal',function()
 local id,x,y=P:ArchaeologyDestination(); assert(id==13 and x==.4 and y==.5)
 local map,px,py=SC.Navigation:Destination({action='archaeology'}); assert(map==13 and px==.4 and py==.5)
end)
test('Archaeology details can open an existing frame without the old show helper',function()
 ArchaeologyFrame={}; local oldShow=ShowUIPanel; ShowUIPanel=function(frame) assert(frame==ArchaeologyFrame); opened='archaeology' end
 SC.UI:HandleCardClick({action='archaeology'}); assert(opened=='archaeology')
 ShowUIPanel=oldShow; ArchaeologyFrame=nil
end)
SC:ClearGoal(); C_Timer.After=oldAfter; GetProfessions,GetProfessionInfo=originalGetProfessions,originalGetProfessionInfo
print(total..' profession and activity refinement tests passed')
