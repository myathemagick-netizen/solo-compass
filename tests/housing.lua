local SC,P=SoloCompass,SoloCompass.Progress
local prior=C_Housing
C_Housing={GetPlayerOwnedHouses=function() end,GetCurrentHouseLevelFavor=function() end,
 GetMaxHouseLevel=function() return 10 end,GetHouseLevelFavorForLevel=function() return 100 end}
SC:ClearGoal(); SC.UI:Hide(); SoloCompassCharDB.interests={housing=true}; SoloCompassCharDB.minutes=30
SoloCompassCharDB.dismissals={}; SC.skipped={}; SC.rotation=7
P.houseRequestAt=nil
P:OnEvent('PLAYER_HOUSE_LIST_UPDATED',{{houseGUID='Alliance',houseName='Alliance house'},{houseGUID='Horde',houseName='Horde house'}})
P:OnEvent('HOUSE_LEVEL_FAVOR_UPDATED',{houseGUID='Alliance',houseLevel=3,houseFavor=100})
P:OnEvent('HOUSE_LEVEL_FAVOR_UPDATED',{houseGUID='Horde',houseLevel=3,houseFavor=99})
local items=SC.Suggestions:Build()
assert(items[1].id=='houseupgrade:Alliance' and items[1].priority)
local goal=items[1]; SC:SetGoal(goal)
assert(SoloCompassCharDB.goalSnapshot.houseGUID=='Alliance' and not P:IsFinished(goal.id))
P:OnEvent('HOUSE_LEVEL_FAVOR_UPDATED',{houseGUID='Horde',houseLevel=4,houseFavor=0})
assert(not P:IsFinished(goal.id))
P:OnEvent('HOUSE_LEVEL_FAVOR_UPDATED',{houseGUID='Alliance',houseLevel=4,houseFavor=0})
assert(P:IsFinished(goal.id))
items=SC.Suggestions:Build(); for _,s in ipairs(items) do assert(s.action~='houseupgrade') end
print('PASS house upgrade XP threshold, priority and house-specific completion')
P:OnEvent('HOUSE_LEVEL_FAVOR_UPDATED',{houseGUID='Alliance',houseLevel=10,houseFavor=100000})
local found=false; P:HouseUpgrades(function() found=true end); assert(not found)
print('PASS max-level houses never suggest coming-soon upgrades')
SC:ClearGoal(); C_Housing=prior; P.ownedHouses=nil; P.houseFavor=nil; P.houseRequestAt=nil
