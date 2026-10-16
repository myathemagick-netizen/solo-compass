# Solo Compass

**Choose one useful thing to do next.** Solo Compass gives solo players a short list of activities based on their interests and available time, rather than a wall of chores.

Targets WoW Retail: Midnight 12.1.5 (`120105`). Version 0.6.0 brings the session planner, Interests onboarding, live goal tracker and expanded activity suggestions together.

## Your session

1. Open `/sc`, `/solocompass`, or the minimap button.
2. On a new character, read the introduction on **Interests**, choose at least one interest, then click **Done - show my ideas**. You can change these choices at any time. Existing characters keep their choices and start on **Ideas**.
3. Browse up to three suggestions. Hover the small buttons: **Track** saves a goal and closes the dashboard so you can follow a compact tracker; **Navigate** opens a destination; **Details** opens the quest, journal, or activity panel; **Dismiss** offers three durations.
4. Drag the tracker to move it. Your goal and position survive reloads. Preferences can hide it or reset its position. The addon never queues you automatically.

**Ideas** is the main view: choose 15, 30 or 60 minutes, browse the shortlist, and see the current goal with its objectives. **Interests** shows all 18 choices together. **Preferences** contains the login popup, minimap, compact tracker and reset controls. Unfinished first-time setup resumes after reload without losing selections.

In addition to quest cleanup, mounts, pets, toys, legacy raids, Delves, LFR and housing, you can select Timewalking, appearance sets, professions, Archaeology, achievements, solo-queue PvP, heirlooms, Warband campsites, Renown/reputation and Legion appearances. New characters make their own selections; existing choices are preserved. LFR, Timewalking and PvP are solo-queue group activities, not solo instances.

## Small steps toward bigger rewards

The shortlist stays at three ideas. A card distinguishes a short preparation step, a measurable milestone, and a full outing. The session time is a planning allowance; the description and tooltip explain queue time, travel, random drops and long unlocks.

| Interest | What Solo Compass can check | Practical limits |
| --- | --- | --- |
| LFR | Named wings in the newest expansion represented in the current Raid Finder list, joinability, remaining bosses, equipped item level and minimum entry level | Does not compare raid loot against your equipment or guarantee an upgrade. A wing can take 30-60 minutes plus its queue. |
| Timewalking | Queues the client currently reports as Timewalking and joinable | No hardcoded schedule, weekly completion check or vendor-cost calculation. Inactive/restricted/loading queues get an explanation. |
| Appearance sets | Character-compatible, non-limited, partially collected sets and collected-piece counts; prefer sets closest to completion | First step is inspecting a missing piece's source. Drop availability, travel and soloability are not inferred. |
| Professions | Unfinished learned skill lines, including older expansions; targets of 1 / 5 / 10 points at 15 / 30 / 60 minutes | Skill gains and costs vary. The target does not move on refresh. Opening older profession sections may be needed to load data. |
| Archaeology | Learned profession, current race projects and base fragment totals; prioritize funded solves | No automatic solves/spending, keystone optimization, or race-specific digsite routing. |
| Achievements | Halfway-finished criteria progress in quest, exploration, profession and collection categories; display one unfinished criterion | Skip raid, PvP, legacy, feat and guild categories. A criterion's duration and soloability still need checking. |
| Heirlooms | Missing items and client source text in the existing journal view | Respect current class/spec/collection filters. Sources can cost gold/currency; no automatic purchases or upgrades. |
| Warband campsites | Missing backgrounds and live unlock-source descriptions | Sources can be long, seasonal, promotional or paid; availability is not assumed. |
| Renown / reputation | Unlocked unfinished Renown and visible neutral-or-better older reputation tracks; show progress to the next level | Does not invent a quest source or reputation rate. Expand older collapsed factions to include them. |
| Legion appearances | Locked, explicitly obtainable appearances from artifacts inspected at the class-hall forge; remember their IDs | Cannot inspect all class artifacts remotely. Visit the forge once per weapon. Unlocked and explicitly unobtainable appearances are excluded. |
| Solo-queue PvP | Honor level and a one-match/practice planning goal | Explicit opt-in. No automatic queue, War Mode change, rated eligibility check or promised win. |
| Housing Endeavors | Named unfinished tasks in the active neighborhood, live requirement text and repeat counters | Track one task once, not the whole shared Endeavor. Open Housing / Endeavors to load the active neighborhood if necessary. Completion is checked within the original neighborhood/cycle. |

Collection scans run only for selected interests, in batches of 25 entries, retaining at most 60 suggestions per catalog. Relevant events invalidate cached data with a one-minute throttle; explicit Refresh requests a new completed scan immediately. Disabling an interest stops its running scan. This does not scan files or run an external process.

Supported goals clear when the game confirms the target: a profession milestone, one additional appearance for a tracked partial set, a completed achievement/collectible, the next reputation/Renown level, or all bosses in a tracked LFR wing. Other planning/session goals remain until you clear them. The tracker can update while the dashboard is closed.

Quest tracking includes live objective text, completed-objective markers and a ready-to-turn-in state. An active quest remains selected even if a historical completion flag is set. Its actual turn-in event completes the goal. Housing task tracking similarly shows the live requirements and recognizes one completion of a repeatable task; moving to another neighborhood or Endeavor cycle cannot falsely complete the original goal. Up to six objective rows are visible; the tooltip contains all objectives.

**Other ideas** rotates categories and favors less recently shown collectibles, using saved history. **Dismiss** hides an idea for this session, for 24 hours, or permanently. **Reset skips** clears session skips; **Restore hidden ideas** in Preferences also clears timed/permanent dismissals. Preferences controls the login popup, minimap button, and tracker; `/sc settings` and right-clicking the minimap button also open it. Interests, history, dismissals, positions, and goal are saved per character. Minimap settings are account-wide.

Navigation uses the client's next quest waypoint or matching dungeon/raid entrance. When an exact source is unavailable it opens the known source zone, or the world map for general activities. It does not invent source coordinates or a travel route. Quest icons use the client's quest theme where supplied, otherwise a quest icon; expansion origin is not guessed from level or quest ID. Delves and housing use their native UI artwork when available.

## What it knows

- Prioritizes ready-to-turn-in quests, nearby quests (within about 500 yards when distance is available), and quests on the current map. Daily, weekly, task, hidden, and explicitly group-sized quests are excluded. It does not claim to know how long a quest has been abandoned or infer expansion from its scaled level.
- Combines detailed collection routes with journal scans for missing mounts, pets and toys. Owned targets are removed; source-planning cards distinguish investigation from an obtainable reward.
- Filters known saved lockouts for the curated legacy raids and Heroic Sethekk Halls. Raid entries are conservatively excluded if any active saved difficulty is found; partially cleared runs are not optimized. A request for updated lockout information is sent at login and on Refresh.
- Balances categories so mounts cannot consume all three slots when other interests have suggestions.
- Automatically clears a saved collectible/quest goal after verified completion. Other goals stay until you clear them. A saved goal remains visible if you change filters or its activity becomes temporarily unavailable.

Delve rewards/keys, weekly quest completion, housing unlocks, travel routes, vendor costs, source availability and exact loot upgrades are **not** fully tracked. Cards describe the checks they actually perform. Time estimates describe a session, not guaranteed completion or drops. This is not a complete database of WoW activities.

## Install and verify

Copy the addon files into `_retail_/Interface/AddOns/SoloCompass/` (the folder name must be `SoloCompass`). Keep the bundled `Libs` directory. Restart WoW or reload after installing.

Install `lupa` and run `python tests/run.py` for the full scenario, progress-provider and packaged-library startup suites. The base scenarios can also run with `lua tests/run.lua`. Checks cover migration, ranking/diversity, ownership, lockouts, time filtering, dismissals/history, goals, frame reuse, actions, background-scan bounds and progress updates. See [the in-game checklist](docs/TESTING.md) for checks that require the client.

Release tags matching `v*` trigger packaging and publication to GitHub Releases and CurseForge. Libraries are bundled in this repository so release packaging does not depend on fetching external library repositories.

### Battle pet ideas
Missing-pet suggestions inspect the current Pet Journal list; enable uncollected pets and Refresh to include them. Owned battle-pet training uses the unfiltered owned collection, chooses the highest-level copy per species, and skips species already at level 25. Training goals aim for one level and show live progress. Collection scans run in small batches; allow a few seconds after Refresh.

### Professions, reputation and Archaeology
Profession ideas exclude parent totals (such as a combined 300/800) and use expansion skill lines. Learned Cooking and Fishing are included; if expansion data is unavailable, open that secondary profession and Refresh. Icons come from the profession book or the client's profession texture.

Open a profession and Refresh to inspect known decor recipes in its current recipe view. Recipe filters are preserved. One-craft goals require a learned recipe with a housing catalog output; the player chooses materials and performs the craft. A successful cast of the tracked recipe completes the goal. Lumber is a planning step for a confirmed house owner, not a verified material count or tree waypoint.

Tracking a reputation selects it for the game's watched reputation bar. Renown uses its own details panel; legacy factions open Character > Reputation. Known source zones, expansion names and reputation groups provide context where available. Unknown vendor coordinates are not guessed.

Archaeology details open the native profession frame. Navigate chooses one active digsite reported by the client, preferring the current area before searching older continents. The map API does not identify fragment races, so this is a general active digsite rather than a guaranteed source for the tracked project's fragments.

### Expanded collections and named Delves
Mount ideas combine the detailed starter routes with a sliced scan of the complete mount ID list. The wider scan includes missing drop, quest, vendor, profession and achievement sources; it excludes hidden entries and unsupported source types. These broader entries are acquisition-source investigation goals, because the journal does not prove current obtainability, access or drop luck. Known starter routes retain their level/lockout checks. Toy scans reset Toy Box source/expansion/collection/search filters on their first scan and on explicit Refresh, capture the full ID list, and use client tooltip information. Subsequent redraws reuse that list without clearing filters again. Scans retain up to 60 candidates and yield between small batches.

Named Delves are discovered from current map POIs across world zones. Their native atlas is shown, Bountiful atlas markers are preferred, and the character's Restored Coffer Key currency is displayed with zero/unknown distinguished. Navigation pins the client-provided entrance. The game's reported minimum level is checked; comfortable tier selection, unlocks and final reward eligibility remain in-game checks. Delve goals currently stay selected until you clear them; completion is not inferred from entering or leaving an instance.

Renown helpers can exist while their frame is absent. The addon only calls the Renown toggle when that frame exists; otherwise it opens Character > Reputation. A reputation with no cataloged source zone opens the world map instead of calling the same details helper.

### Raid outings and reputation artwork
The raid catalog includes 51 live raid instances from Classic through Dragonflight. Character level, expansion distance and saved lockouts filter suggestions. Native Encounter Journal artwork and achievement icons identify raids. Older content is not a guarantee of an easy solo clear: difficulty, gear and encounter mechanics still matter. Removed Classic versions of raids are not listed as available content.

Reputation cards use the faction's native Renown emblem when available, matching reputation achievement artwork for cataloged older factions, distinct Alliance/Horde PvP icons, and a native goblin portrait for goblin factions. Unknown artwork falls back to a reputation icon.
