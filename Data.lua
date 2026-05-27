-- SoloCompass: curated data tables
-- Each entry is a collectible or activity with its source info.

SoloCompass.Data = {}
local D = SoloCompass.Data

-- Farmable mounts: { mountID, name, source, sourceType, sourceID }
-- sourceType: "dungeon" | "raid" | "rare" | "vendor" | "quest"
D.Mounts = {
    { id = 781,  name = "Rivendare's Deathcharger",  source = "Stratholme",          sourceType = "dungeon", sourceID = 329  },
    { id = 363,  name = "Raven Lord",                source = "Sethekk Halls (H)",   sourceType = "dungeon", sourceID = 269  },
    { id = 535,  name = "Vitreous Stone Drake",      source = "The Stonecore (H)",   sourceType = "dungeon", sourceID = 645  },
    { id = 534,  name = "Drake of the North Wind",   source = "Vortex Pinnacle (H)", sourceType = "dungeon", sourceID = 657  },
    { id = 925,  name = "Son of Galleon",            source = "Galleon (Rare)",      sourceType = "rare",    sourceID = 0    },
    { id = 1046, name = "Jade Primordial Direhorn",  source = "Zandalari Warbringer",sourceType = "rare",    sourceID = 0    },
}

-- Farmable pets: { speciesID, name, source, sourceType }
D.Pets = {
    { id = 40,   name = "Mechanical Squirrel",  source = "Engineering",        sourceType = "craft"   },
    { id = 283,  name = "Tiny Shale Spider",    source = "Jadefang (Rare)",    sourceType = "rare"    },
    { id = 1154, name = "Chromie",              source = "Timewalking Vendor",  sourceType = "vendor"  },
}

-- Farmable toys: { itemID, name, source, sourceType }
D.Toys = {
    { id = 88021,  name = "Foot Ball",           source = "Various drop",       sourceType = "dungeon" },
    { id = 118427, name = "Crashin' Thrashin' Cannon", source = "Winter Veil", sourceType = "seasonal"},
}

-- Housing nudge definitions
-- category: "visit" | "endeavor" | "decoration"
D.HousingNudges = {
    { id = "warband_visit",    category = "visit",    text = "Visit a neighbor's Warband house today for Warband XP." },
    { id = "neighborhood_end", category = "endeavor", text = "Check the Neighborhood board for daily endeavors." },
    { id = "deco_weekly",      category = "decoration",text = "You haven't placed any new decorations this week. Try browsing the catalog!" },
}

-- Questline stubs: chains we track for cleanup nudges
-- { chainID, name, startQuestID, endQuestID, expansionID }
D.QuestChains = {
    { chainID = "shadowlands_covenant", name = "Covenant Campaign",    startQuestID = 57878, endQuestID = 63994, expansionID = 9 },
    { chainID = "bfa_war_campaign",     name = "BfA War Campaign",     startQuestID = 47099, endQuestID = 56115, expansionID = 8 },
    { chainID = "legion_class_order",   name = "Legion Class Order",   startQuestID = 40519, endQuestID = 44701, expansionID = 7 },
}
