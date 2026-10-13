# In-game checks before release

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
