-- A small starter catalog. Collection names/icons are resolved by the client.
SoloCompass.Data = {}
local D = SoloCompass.Data
D.Categories = {
    { key = "quests", label = "Quest cleanup", icon = "INV_Misc_Scroll_05" },
    { key = "mounts", label = "Mount collection", icon = "Ability_Mount_Wyvern_01" },
    { key = "pets", label = "Battle pets", icon = "INV_Box_PetCarrier_01" },
    { key = "toys", label = "Toy collection", icon = "INV_Misc_Toy_10" },
    { key = "raids", label = "Legacy raids", icon = "INV_Helmet_03" },
    { key = "delves", label = "Delves", icon = "INV_Misc_Map_01" },
    { key = "lfr", label = "Raid Finder", icon = "INV_Misc_GroupLooking" },
    { key = "housing", label = "Housing", icon = "INV_Misc_House_01" },
}
-- Item IDs fix the original catalog's mismatched mount-journal IDs.
-- Estimates exclude travel and repeated attempts. Drops are never guaranteed.
D.Mounts = {
    { itemID = 13335, minutes = 30, minLevel = 50, mapID = 23,
        source = "Stratholme", step = "Use the service entrance and defeat Lord Aurius Rivendare." },
    { itemID = 32768, minutes = 30, minLevel = 50, mapID = 108, instanceID = 556, difficultyID = 2,
        source = "Sethekk Halls (Heroic)", step = "Set dungeon difficulty to Heroic and defeat Anzu." },
    { itemID = 32458, minutes = 30, minLevel = 50, mapID = 109, instanceID = 550,
        source = "Tempest Keep: The Eye", step = "Defeat Kael'thas Sunstrider for a chance at Ashes of Al'ar." },
    { itemID = 30480, minutes = 30, minLevel = 50, mapID = 42, instanceID = 532,
        source = "Karazhan (original raid)", step = "Enter the original raid and defeat Attumen the Huntsman." },
}
-- Introductory species; acquisition instructions come from the live Pet Journal.
D.Pets = { { speciesID = 39, minutes = 15 }, { speciesID = 40, minutes = 15 },
    { speciesID = 72, minutes = 15 }, { speciesID = 138, minutes = 15 } }
D.Toys = {
    { itemID = 86589, name = "Ai-Li's Skymirror", minutes = 30, minLevel = 50, mapID = 422,
        step = "Look for Ai-Li Skymirror in Dread Wastes. Her rare drop is a toy; respawn time varies." },
    { itemID = 86571, name = "Kang's Bindstone", minutes = 30, minLevel = 50, mapID = 390,
        step = "Look for Kang the Soul Thief in the Vale of Eternal Blossoms. Phase and respawn time can affect access." },
}
D.Raids = {
    { id = 532, mapID = 42, title = "Revisit Karazhan", minutes = 30, minLevel = 50,
        detail = "Enter the original raid in Deadwind Pass. Pick an appearance from its loot before you go." },
    { id = 550, mapID = 109, title = "Revisit Tempest Keep", minutes = 30, minLevel = 50,
        detail = "Visit The Eye in Netherstorm for legacy appearances and a chance at Ashes of Al'ar." },
    { id = 631, mapID = 118, title = "Clear Icecrown Citadel", minutes = 60, minLevel = 50,
        detail = "Choose a difficulty, then enter the raid in Icecrown for a longer legacy collection run." },
}
