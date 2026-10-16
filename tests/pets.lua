local SC,P=SoloCompass,SoloCompass.Progress
local oldAPI,oldAfter=C_PetJournal,C_Timer.After
local queue={}
C_Timer.After=function(_,fn) queue[#queue+1]=fn end
local function drain() local n=0; while #queue>0 do table.remove(queue,1)(); n=n+1; assert(n<2000) end end
local levels={a=24,b=2,c=25}
C_PetJournal={GetOwnedPetIDs=function() return {'a','b','c'} end,
 GetPetInfoTableByPetID=function(id) return {speciesID=id=='a' and 100 or 101,petLevel=levels[id],name='Pet',icon=123,canBattle=true} end,
 GetPetInfoTableBySpeciesID=function() return {name='Missing pet',icon=123,sourceText='Wild',obtainable=true,canBattle=true,isWild=true} end,
 GetNumPets=function() return 2 end,GetPetInfoByIndex=function() return nil,9001 end,
 GetNumCollectedInfo=function(id) return id==9001 and 0 or 1 end,
 SetSearchFilter=function() error('Scanning changed filters') end}
SC:ClearGoal(); SC.UI:Hide(); SoloCompassCharDB.interests={pets=true}; SoloCompassCharDB.minutes=60
P.caches={}; SC.skipped={}; SoloCompassCharDB.dismissals={}
local function collect() local items={}; P:Pets(function(s) items[#items+1]=s end); return items end
assert(#collect()==0); drain(); local items=collect(); assert(#items==2)
local goal; for _,s in ipairs(items) do if s.action=='petlevel' then goal=s end end
assert(goal and goal.targetPetID=='a' and goal.progressTarget==25)
SC:SetGoal(goal); assert(SoloCompassCharDB.goalSnapshot.targetPetID=='a')
assert(P:ObjectiveLines(goal)[1]=='Level 24 / 25'); assert(not P:IsFinished(goal.id))
levels.a=25; assert(P:IsFinished(goal.id)); assert(#collect()==1)
print('PASS pet species deduplication and max-level copy exclusion')
print('PASS pet GUID snapshot and live level completion')
SC:ClearGoal(); levels.a=12; C_PetJournal.GetNumPets=function() return 0 end
P.caches={}; collect(); drain(); items=collect(); assert(#items==1 and items[1].targetPetID=='a')
print('PASS owned training goals survive journal filters hiding all entries')
C_PetJournal,C_Timer.After=oldAPI,oldAfter; P.caches={}
