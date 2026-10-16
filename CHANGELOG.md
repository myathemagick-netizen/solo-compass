## 0.6.0
- Release the redesigned Ideas / Interests / Preferences workflow with first-character onboarding and a movable, persistent goal tracker.
- Expand the raid catalog to 51 instances from Classic through Dragonflight, including Molten Core, Blackwing Lair, Ahn'Qiraj and all Dragonflight raids. Use native raid artwork and retain level/lockout filtering.
- Reset Toy Box filters on initial scan and explicit Refresh, then capture the full journal list so filtered views no longer hide missing-toy ideas.
- Add native Renown emblems, matching legacy reputation achievement icons, goblin portraits and faction-specific PvP artwork.
- Include the tested expanded collection, appearance-set, profession, Archaeology, achievement, housing-upgrade, Endeavor, named Delve, LFR, reputation and other progress providers from the development previews.
- Bundle all minimap dependencies and publish the same source/package through GitHub and CurseForge.

## 0.5.5
- Guard the actual Renown frame before calling its toggle helper; fall back to Character > Reputation when it is unavailable. Reputation navigation without a known zone opens the world map.
- Scan the full mount ID catalog for missing drop/quest/vendor/profession/achievement sources; retain detailed starter routes and known lockout checks.
- Scan uncollected toys in the current Toy Box view, using native icons and tooltip data. Journal filters are preserved.
- Discover named Delves from map POIs, use their native icons and entrance pins, prioritize Bountiful markers, and display live Restored Coffer Key counts.
- Use raid achievement icons for the legacy raid suggestions.

## 0.5.4
- Exclude misleading parent profession totals, use profession-specific icons, and include Cooking/Fishing expansion skills or preparation when their data is not loaded.
- Suggest known decor recipes from the loaded profession view and a lumber planning step for confirmed house owners. A tracked decor craft completes on that recipe's successful player cast.
- Track reputation with the native watched bar, show live remaining progress, and open legacy/Renown details. Add expansion/group context and source-zone navigation where cataloged; exact vendor pins are not supplied.
- Open the Archaeology frame directly and navigate to an active client-reported digsite. Digsite fragment types are not inferred.

## 0.5.3
- Check owned houses asynchronously for earned XP upgrades; show a ready upgrade first when Housing is selected.
- Keep house identities separate and clear tracked upgrades after a verified level increase.

## 0.5.2
- Check Raid Finder minimum character levels before recommending wings. Under-level characters get a friendly leveling step that opens the quest log.

## 0.5.1
- Expand pet ideas beyond four starter species: inspect missing pets in the visible journal and suggest one level for owned battle pets.
- Skip training species with a level-25 copy; preserve a fixed target and live tracker progress.
- Scan in small batches and preserve journal filters. Missing-pet acquisition times are estimates.

# Changelog

## 0.5.0 preview

- Split the dashboard into Ideas, Interests, and Preferences tabs.
- Show all 18 interests together in a three-column selection view, replacing the paged sidebar.
- Give new characters a short introduction and an explicit choose-interests / Done / Ideas flow; preserve unfinished setup across reloads.
- Preserve existing characters' settings and open their Ideas tab without onboarding.
- Show the current goal and live objectives on Ideas alongside the shortlist and session-time controls.
- Keep tab switches separate from goal selection and reuse existing frames.
- Remove duplicated Endeavor requirements from the goal tooltip.

## 0.4.1 preview

- Fix empty appearance-set suggestions: search the full set catalog instead of GetUsableSets, which only returns completed sets ready to apply.
- Preserve character compatibility, limited/hidden-set exclusions, partial collection counts, and bounded background scanning.
- Test with a completed-only usable-set API so this regression cannot be masked by a mock that returns incomplete sets.

## 0.4.0 preview

- Fix quest Track immediately clearing an active quest when historical completion is already recorded. Active quests remain selected until the real turn-in event.
- Add live quest objective rows and ready-to-turn-in state to the compact tracker, with extra objectives available in its tooltip.
- Suggest named tasks from the active Neighborhood Endeavor and track one completion, including requirements and repeat/cycle identity.
- Expand to 18 opt-in interests with three sidebar pages and eight reused checkbox rows.
- Replace the max-level/60-minute-only LFR prompt with named current-list wings, entry requirements, equipped item level, boss loot eligibility, and short preparation steps.
- Add currently joinable Timewalking queues without hardcoding an event calendar.
- Find partially collected usable appearance sets and nearly completed achievements in solo-oriented categories using bounded background scans.
- Add current and older learned profession skill milestones, Archaeology fragment/project suggestions, missing heirlooms and Warband backgrounds, Renown and older reputation tracks, solo-queue PvP, and inspected Legion artifact appearance requirements.
- Keep skill/appearance-piece targets fixed, recognize supported progress goals, and report a reached goal.
- Explain unavailable/loading data and provide an activity-panel action from empty states.
- Label preparation steps and longer projects explicitly; do not claim gear upgrades, reward availability, or completion times without evidence.

## 0.3.0 preview

- Add compact Track, Navigate, Details, and Dismiss icon buttons with tooltips.
- Show native themed quest, Delve, and housing icons with texture fallbacks.
- Track one saved goal in a movable compact widget, including updates while the dashboard is closed.
- Navigate using live quest waypoints and matching journal entrance pins; show zone maps when exact pins are unavailable.
- Explain quest proximity and separate activity estimates from travel, queue, and rare-drop uncertainty.
- Remember recently shown ideas and add session, 24-hour, and permanent dismissals with a restore control.
- Deduplicate quest IDs before ranking so repeated log entries cannot produce duplicate cards.

## 0.2.1

- Bundle and load CallbackHandler before the minimap libraries, fixing startup errors when no other addon provides it.
- Test the bundled libraries in TOC order in a fresh Lua environment.

## 0.2.0

- Rebuild Solo Compass around a three-idea shortlist and one saved next goal.
- Add separate interests for quest cleanup, mounts, battle pets, toys, legacy raids, Delves, Raid Finder, and housing.
- Add 15, 30, and 60 minute session choices, rotation, session skips, and editable preferences.
- Check collection ownership, quest status, and saved instance lockouts for the starter catalog.
- Replace the expanding dashboard with a teal and gold layout, reusable cards, and readable actions.
- Preserve existing character interests, split Collector into three preferences, and keep minimap settings.
- Remove unverified housing progress/reward claims and the outdated quest-level cutoff.
- Target Midnight 12.1.5 (interface 120105).
