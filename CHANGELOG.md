# Changelog

## [2.2.6]
### Fixed
- **Config tabs now scroll** (mouse wheel). Tab content was drawn on plain frames sized to the 
window: anything past the bottom edge spilled outside the panel — the TrashCD tab's last controls 
("Growth direction", "Show icon") rendered over the game world. Pages are now proper scroll 
children whose height follows the real content; the Custom tab keeps its full-height layout.
- **Ghost central ring**: the RingProgress could stay on screen after its deadline (the cooldown 
edge remains visible once the swipe ends). A watchdog now hides the ring shortly after expiry no 
matter what — the pre-2.2.3 looping `Stop()` used to mask this leak.
- Dropdown popups are reparented to UIParent (anchored to their button, effective scale synced): 
they can no longer be clipped by the new scrolling pages.
- "Spell on you" section made more compact (single description); minor locale wording tightened.
- **Blizzard Timeline tab**: the 4-line masked-identity note only reserved 2 lines of height and 
overlapped the section below it; reserved heights of multi-line descriptions fixed across tabs.

## [2.2.5]
### New
- **5 off-season Midnight dungeons** (17 bosses, 74 events): Altar of Fangs, Den of Nalorakk, 
Murder Row, The Blinding Vale, Voidscar Arena. Duration-based identification for the Blizzard 
timeline module — bars and callouts work anywhere the server timeline is active (Normal/Heroic/M0).
- `DungeonMaps` extended with the 5 new instanceMapIDs (2813, 2825, 2859, 2923, 2993).

### Notes
- *Matching* data only (generated from LittleWigs duration branches, Mythic / Normal-Heroic modes 
merged): no prediction series — pointless where the server already provides the timeline. Roles, 
voices and severities are defaults to refine in game; the few durations shared between two abilities 
are documented with `-- AMBIGU` comments in each file.

## [2.2.4]
### New
- **"Spell on you" alert (trash packs)**: if the mob's target during a tracked cast appears to be you, 
the big central ring closes over the cast duration, with a "*Spell* → on YOU!" flash and the "Target on 
you" voice callout. The target is **re-checked throughout the cast**: a mob turning to you mid-cast 
triggers the alert (the most reliable signal — the aggro target is not necessarily the spell's target), 
a mob looking away cancels it.
- "**Only when the mob turns to you**" option (off by default): no alert at cast start if you are tanking 
that mob (readable threat) — but a mid-cast retarget onto you always alerts, tanks included. Cuts the 
noise without depriving tanks of their warnings.
- Masked values (Midnight secretvalues) = silence: no false positives possible; unreadable threat in 
"turns to you" mode = alert anyway (better one warning too many).
- **RingProgress: priorities.** An "on you" alert (high priority) can no longer be overwritten or 
stopped by the boss timeline tracker; the latter automatically takes over again once the alert ends. 
New owner-scoped stop (`StopOwner`).
- 3 settings in the Packs tab (enable / "turns to you" mode / voice), fr + en locales.

## [2.2.3]
### New
- **Timeline bridge**: TrashCD predictions (`first`/`cd` series) are published to the 
**official Blizzard timeline** (`C_EncounterTimeline.AddScriptEvent`). They show up in the 
native UI — and in AbilityTimeline if the player uses it — and **resync on every real cast**. 
Automatic cancellation on mob death, at combat end and on zone change; configurable horizon 
(30–120 s, default 90); per-spell and global caps; feedback-loop guard (our own events are 
ignored by the BlizzTimeline module) and clean self-disable if the API returns no usable identifier.
- **TrashCD: 3-level spell identification** — readable spellID → live cast name compared against 
names resolved from the data → cast duration (only when a single candidate fits). Cooldown series 
become usable **even when Midnight masks the spellID**.
- **Hardened BlizzTimeline module**: full server state machine (Active / Paused / Finished / Canceled 
— bars hidden while paused, resumed on active), rejection of events added already paused and of 
"placeholder" bars (> 120 s), hidden/indeterminate track filtering (`GetEventTrack`/`GetTrackType`), 
states read straight from event arguments, and **automatic enabling of the `encounterTimelineEnabled` 
CVar** if it was off (without it, no timeline event ever reaches addons).

### Fixed
- The predictive engine's auto-start only worked **once per session**: `Stop()` unregistered 
the permanent boss-cast watch. The watch now survives combat end.
- **Ghost rings after a wipe**: `Stop()` only cleaned up bars, not rings.
- **Custom boss entries created mid-session** are now recognized by the Blizzard timeline 
without a `/reload` (match index invalidation).
- Possible **duplicate bars** when the predictive engine and the Blizzard timeline ran in 
parallel on the same boss: the predictive engine now stands down when the server timeline is 
available.
- TrashCD: **pure channels** (Torrent of Misery, Plungegrip…) could have their bar killed 
instantly by `UNIT_SPELLCAST_SUCCEEDED` depending on event order.
- Voice: a callout whose file cannot be found no longer consumes the anti-duplicate window.
- `OnStateChanged` wrote to the global `_`; the fallback icon dropped the event's original one.

### Performance
- The predictive engine no longer redraws every bar at ~20 Hz: rendering only on cycle change 
and resync (styling, sorting and layout were not needed every tick).
- BlizzTimeline: early exit of the ticker when no event is active (no more looping ring-stop 
calls out of combat).

## [2.2.2]
### Fixed
- Options window now opens on the **first** `/tmb` (or first minimap-icon click) instead of
  requiring two — the frame was created shown and immediately toggled off.

## [2.2.1]
### Fixed
- The central ring's **move handle** stays visible in unlock/edit mode (the timeline engine was
  hiding the anchor every tick while idle).

## [2.2.0]
### Added
- **Central progress ring** — a large ring around your character that *closes* as the next
  ability approaches (full circle = impact). Movable (`/tmb unlock`), resizable, colour-coded by
  severity. Uses a Cooldown frame with a ring swipe texture and reverse fill.

## [2.1.1]
### Fixed
- **Announcement/timer drift on long fights.** Timing is now continuously re-synced to the server
  timeline (`GetEventTimeRemaining`) instead of being frozen at add time. Identity matching
  (ability duration) and fire timing are now handled separately, and callouts fire with a proper
  lead (respects the "Announcement lead" slider and each ability's pre-alert).

## [2.1.0]
### Added
- **Blizzard-timeline-driven engine** (`C_EncounterTimeline`). Under Midnight, boss abilities are
  only exposed through the server timeline. TomoBoss now consumes it and **identifies each event
  by its duration** against built-in data (`firstSeenSec` / `cdSeriesSec`, 0.75 s tolerance),
  then uses its own spellID for readable names/icons, localized voice and severity. Unmatched
  events fall back to `spellName` / a generic label. On by default in covered dungeons.
- **`instanceMapID` -> encounters** lookup to detect the active boss without `ENCOUNTER_START`.

### Changed
- The boss engine no longer relies on `ENCOUNTER_START` or `UNIT_SPELLCAST` for boss abilities
  (neither reaches addons for boss mechanics on Midnight).

## [2.0.2]
### Added
- **`/tmb debug`** command and on-screen diagnostic traces.
- Optional **generic beep** for timeline abilities that cannot be identified.

### Fixed
- "loop in gettable" warning on French clients (self-referential locale fallback).

## [2.0.1]
### Fixed
- **"Secret value" (taint) errors** with the Blizzard timeline. Midnight hides ability data;
  all timeline values (severity, duration, time-remaining, icon, id) are guarded with
  `SafeNumber` before any comparison, and `Theme:Severity` is hardened.

## [2.0.0]
### Added
- **English voice pack** (185 lines) and a **multi-language voice system**: choose *French* or
  *English* in the Voice tab, or *Auto* to follow the client locale. Automatic fallback to French
  when a line is missing. Voice packs live in `Media/Voice/<locale>/`.

## Earlier (1.x)
Major features introduced before 2.0.0:
- Boss timers with French voice for the 8 Season 1 dungeons; live re-sync and phase handling.
- Interrupt tracker (who interrupted, your own cooldown, Mythic+ kick tally via `/tmb kicks`).
- TrashCD: cast bars for important trash abilities, interruptible casts highlighted.
- Role-based progress rings (tank / healer / danger).
- Custom panel: create boss/trash alerts (bar / ring / sound) and share them with a
  WeakAura-style import/export string.
- Minimap button and group version check (`/tmbv`).
- Comfort options: bar window filter, minimum gap between callouts, callout volume boost
  (100–300%). Dark-and-mint themed options UI.
