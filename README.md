# Solo Compass

**Choose one useful thing to do next.** Solo Compass gives solo players a short list of activities based on their interests and available time, rather than a wall of chores.

Targets WoW Retail: Midnight 12.1.5 (`120105`). Version 0.2.0 is a first development pass; test it in game before tagging a public release.

## Your session

1. Open `/sc`, `/solocompass`, or the minimap button.
2. Choose 15, 30, or 60 minutes and the parts of WoW you enjoy.
3. Browse up to three suggestions. **Make my goal** saves one for your next session.
4. Use the action button to open the relevant quest, collection journal, map, or Raid Finder. The addon never queues you automatically.

Interests include quest cleanup, mount collection, battle pets, toys, legacy raids, Delves, Raid Finder, and housing. LFR is optional matchmade group content; it starts disabled for new characters.

**Other ideas** rotates available suggestions. **Skip for now** hides one until a reload or **Reset skips**. **Preferences** controls the login popup and minimap button; `/sc settings` and right-clicking the minimap button also open it. Interests, time, position, and goal are saved per character. Minimap settings are account-wide.

## What it knows

- Prioritizes ready-to-turn-in quests, then ordinary quests already in your log. Daily, weekly, task, hidden, and explicitly group-sized quests are excluded. It does not claim to know how long a quest has been abandoned or infer expansion from its scaled level.
- Checks ownership of a small curated collection catalog. Mount IDs and localized names are resolved from mount items; pet acquisition text comes from the game's journal. Owned targets are removed.
- Filters known saved lockouts for the curated legacy raids and Heroic Sethekk Halls. Raid entries are conservatively excluded if any active saved difficulty is found; partially cleared runs are not optimized. A request for updated lockout information is sent at login and on Refresh.
- Balances categories so mounts cannot consume all three slots when other interests have suggestions.
- Automatically clears a saved collectible/quest goal after verified completion. Other goals stay until you clear them. A saved goal remains visible if you change filters or its activity becomes temporarily unavailable.

Delve rewards/keys, weekly completion, LFR eligibility/queues, housing unlocks, missing transmog, travel time, vendor costs, and seasonal availability are **not** fully tracked. Those activity cards are honest prompts to check in-game information. Time estimates describe a session, not guaranteed completion or drops. The small starter catalog is not a complete database of WoW activities.

## Install and verify

Copy the addon files into `_retail_/Interface/AddOns/SoloCompass/` (the folder name must be `SoloCompass`). Keep the bundled `Libs` directory. Restart WoW or reload after installing.

The Lua scenario suite can run from the repository root with `lua tests/run.lua`. Alternatively, install `lupa` and run `python tests/run.py`. It covers preference migration, ranking/diversity, ownership, lockouts, time filtering, skips, goals, frame reuse, actions, and debounced refresh. See [the in-game checklist](docs/TESTING.md) for checks that require the client.

Release tags matching `v*` trigger the CurseForge packager. Do not tag until in-game validation is complete.
