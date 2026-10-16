# In-game checks before release

- 0.5: On a configured character, `/sc` should open Ideas and preserve all settings and the selected goal. Ideas shows time choices, the shortlist, the current goal and live objectives; Interests and Preferences are separate views.
- On a character with no Solo Compass character settings, first open should show the welcome on Interests with no interests preselected. Done should guide an empty selection to choose one; choosing interests then Done opens Ideas. Reload before Done and verify partial choices persist and setup resumes.
- Show all 18 interests together, including on a smaller UI scale. Switch tabs repeatedly, use `/sc settings` and minimap right-click, and verify tab exclusivity, saved choices, current goal and objective refresh.
- Regression: select the previously failing Quest cleanup card using Track. The dashboard should close, the quest should remain the saved goal, and its live objectives should appear. Reopen `/sc` and reload to verify persistence. Completing objectives should show Ready to turn in, not clear the goal; the actual turn-in should clear it.
- Housing: open the active neighborhood's Endeavor tab once, then select a named task in Solo Compass. Check live requirement text while the dashboard is closed. Completing a repeatable task once should finish the chosen goal; an older completion count or a new neighborhood/cycle must not falsely finish it.
- Confirm all 18 interests remain selectable on Interests and changing tabs preserves every choice.
- With only LFR selected at 30 minutes, confirm a named available wing or a preparation card appears. Check equipped/minimum item level, remaining boss count, and the explicit queue-time warning. Fully looted wings must disappear. No upgrade claim should be made.
- Timewalking: verify a currently available queue appears and an inactive/ineligible week produces an explanation. Details should select the intended Dungeon Finder entry without queueing.
- Appearance sets / achievements: enable the interest, wait for background scanning, and compare a card with the client UI. Collected/limited/incompatible sets, completed achievements, raid/PvP/legacy/feat categories and unknown data should not be presented as missing solo unlocks. Inspect source availability manually.
- Professions: compare current and older expansion skill lines. At 15/30/60 minutes, targets should be +1/+5/+10, capped at maximum. Track a milestone, gain some skill, refresh/reload and verify the target stays fixed until reached.
- Archaeology: test an untrained character, a partial fragment project, and a funded solve. The panel action must not solve or spend automatically.
- Check heirloom and Warband campsite ownership/source text. Heirloom filters remain unchanged. A collected goal should clear on the corresponding event.
- Check an unfinished Renown track and an older neutral-or-better reputation. Expand a collapsed older faction and Refresh. Completed, locked and hostile tracks should be excluded.
- Legion: open an artifact's appearance tab at its class-hall forge, then open Solo Compass. Verify requirements, cache survival across reload, and exclusion of unlocked/unobtainable appearances. Without inspected data, the card should explain setup.
- PvP: explicitly enable it, verify Honor-level context and the preparation/one-match distinction. Details opens Honor / unranked options; no queue or War Mode changes occur.
- Hover Track, Navigate, Details, and Dismiss on each card; check icons and tooltip text. Check quest, Delve, and housing artwork. Client quest themes may not identify an expansion.
- Track a goal: dashboard closes and compact tracker appears. Drag it, reload, and verify the saved position. Close the dashboard with Escape and confirm the tracker returns. Hide/reset it in Preferences.
- Complete the tracked quest with the dashboard closed; the tracker should clear after the quest event. Combat must block navigation and panel-opening actions.
- Navigate to original Karazhan / The Eye / Sethekk Halls. Confirm any pin is the intended entrance. If the client has no matching entrance, confirm the source zone opens without a fabricated pin.
- Try session, 24-hour, and permanent dismissals. Reload: session skips clear, timed/permanent hides remain. Restore hidden ideas in Preferences and verify they return.
- Use Other ideas and relog to check variety; repeated Refresh should not churn history. At 15 minutes with only quests/housing enabled, verify a quest cannot occupy two cards.
- Install into a folder named `SoloCompass` on Retail 12.1.5. Enable Lua errors (`/console scriptErrors 1`), then `/reload`.
- Test first login, an existing 0.1.0 character, and `/sc` before opening the dashboard. Confirm no errors and preserved interests/minimap position.
- Select each interest and each time choice. Disable all interests and check the empty state. Cycle ideas, skip, reset skips, and refresh repeatedly.
- Choose a quest goal, reload, then complete/turn in the quest. Confirm the goal survives reload and clears on confirmed completion.
- Repeat with an unowned mount, pet, or toy if possible. Confirm already-owned starter collectibles never appear.
- Click a quest, mount, pet, toy, map, and LFR action. Journals should open to the intended category and search term; existing journal filters can still hide a target. No automatic queue or difficulty change should occur.
- Check original Karazhan / Tempest Keep and Heroic Sethekk Halls suggestions on characters with saved lockouts. Confirm Refresh removes locked targets after raid info updates.
- Open/close preferences, use Escape, drag the window, reload, and test a smaller display or larger UI scale. Text and card controls should fit.
- Hide the minimap button and recover the addon using `/sc settings`. Toggle the login popup and verify the next login.
- Enter combat and click an action: receive the wait-until-after-combat message without opening protected panels.
- Check localized Pet Journal acquisition text: card text may shorten it visually, but the full source must remain available in the hover tooltip.

The automated tests use mocked APIs and layout objects. They do not prove protected-frame behavior, actual journal filters, live client data, or visual rendering in WoW.

## 0.6.0 release checks
- Automated Lua 5.1 scenarios: 73 passing, including first-character onboarding, progress providers, nil Renown-frame fallback and packaging-library initialization.
- Verify Legacy raids shows Classic entries and all Dragonflight raids on a level-90 character; lower-level and saved entries must be filtered. Mechanics and difficulty can still prevent a solo clear.
- Apply restrictive Toy Box filters/search, enable Toys and Refresh: missing-toy suggestions should populate and journal filters should reset. Subsequent ordinary redraws should not keep resetting filters.
- Check native Renown, cataloged older reputation achievements, goblin and PvP faction artwork in game.
