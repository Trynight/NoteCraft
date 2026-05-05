# Changelog

All notable changes to NoteCraft are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-05-05

### Added

#### Core tracking
- Automatic player discovery via `GROUP_ROSTER_UPDATE` (throttled, deduped per group session).
- Mythic+ outcome tracking via `CHALLENGE_MODE_START` / `CHALLENGE_MODE_COMPLETED` /
  `CHALLENGE_MODE_RESET`, plus a `ZONE_CHANGED_NEW_AREA` fallback for surrendered keys.
- Per-player role counts (Tank / Healer / DPS) accumulated from each shared run.
- Per-player M+ run history (date, dungeon, key level, role, in-time / depleted).

#### Notes & tags
- Free-text notes with optional short title.
- Built-in color tags: `GOOD`, `BAD`, `CAUTION`, `NEUTRAL`.
- Custom tags: add / edit / delete tags with a color picker from the options panel.

#### UI integrations (RaiderIO-style reach)
- Tooltip injection on player hover via `TooltipDataProcessor`.
- LFG applicant decoration (colored border + inline note + M+ counts).
- LFG search-entry tooltip extension (shows note / tag / M+ record for known leaders).
- Friends-list, Who-list, Guild-roster, Communities-list tooltip injection.
- Chat hyperlink right-click menu (modern `Menu.ModifyMenu` + legacy
  `LibDropDownExtension` fallback for current WoW chat).
- `/who` chat-output decoration with tag and note.
- Mythic+ end-of-run banner overlay listing tagged party members.
- Alert (chat warning + raid-warning frame + sound) when a player tagged BAD or
  CAUTION joins your group.

#### Main window
- Mini-window (`/nc` or `/nc list`) with two tabs: **Players** and **Stats**.
- Player list with search, tag filter, outcome filter, realm filter.
- Click modifiers per row: open NoteDialog / Ctrl-whisper / Shift-link / Alt-history.
- Per-player **History** dialog (M+ runs, date, dungeon, role, outcome).
- Aggregate **Stats** tab (totals, role distribution, top-by-encounters,
  top-by-runs, class distribution, most-run dungeons).

#### Quality-of-life
- Minimap button (`LibDBIcon`) — left-click toggles main window, right-click opens options.
- Post-M+ run popup that lets you quickly tag and note every party member at once
  (toggle in options if you don't want it).
- 4 keybindings: toggle main window, toggle minimap button, open options,
  add/edit note for current target.
- Slash command `/nc` / `/notecraft` with full sub-command dispatch
  (`add`, `tag`, `tags`, `show`, `list`, `export`, `import`, `config`).
- Export / Import via compressed Base64 string (`LibSerialize` + `LibDeflate`).
- Account-wide `SavedVariables` with schema versioning and migrations
  (v1 → v2 → v3).

### Privacy
- 100% local: no network sync, no addon broadcast, no internet reads.
