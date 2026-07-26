# Changelog

## [2.3.7]

Everything here is derived from a real capture (Emberdawn, 233 s, 92
observations) rather than from assumptions about what the server sends.

### Fixed

- **Re-added timeline events were misidentified.** When the server re-posts an
  already-scheduled event, `duration` no longer holds the interval — it holds the
  *remaining time*. The capture shows `fire=128.77` posted at 113.27 with
  `duration=15.50`, then re-posted at 118.13 with `duration=10.64`. Since
  `MatchDuration` identifies on `duration`, the second post resolved to a
  different ability or fell through to generic mode. A re-add is now detected
  before identification (same end time, reduced duration) and only updates the
  timing, keeping the original identity.
- **False positives in period detection.** Cluster tightness was judged by MAD,
  which tolerates up to 50% outliers. Folding on a cycle that is *half* the true
  one produces a bucket made of two clumps, the smaller weighing ~43% — just
  under the breakdown point. MAD reported 0.78 s on a bucket 19.67 s wide and the
  wrong cycle was accepted as "good". Tightness is now measured by a high
  quantile of deviations, so an ignored clump is seen.
- **First-seen anchoring.** A lost observation can only make the first occurrence
  appear *later*, never earlier, so the minimum is the correct estimator, not the
  median. The median drifted when several pulls missed the first cast, and the
  series came out right but rotated (`{20, 33, 12}` instead of `{12, 20, 33}`).
- Late resolution of boss identity: `ENCOUNTER_START` fires before boss units are
  populated, which is why captures showed `boss=nil npc=nil`.

### Changed

- **Inference is keyed on duration.** Confirmed by the capture: the timeline ADD
  timestamp *is* the cast start timestamp (18/18 within 0.01 s). It is not
  `fire`, which equals ADD + duration — the *next* occurrence. `info.duration` is
  the nominal cooldown and stays constant per ability.
- **Two-rule deduplication.** The capture holds 70 raw ADDs for 36 real events.
  Batch duplicates (same instant, same duration) and remaining-time rewrites are
  distinguished by recurrence: a nominal duration recurs (15.50 appears 9 times),
  a rewrite is unique (10.64 appears once). Deduplicating on `fire` alone made
  two *distinct* abilities cancel each other out.
- Series whose positions are all equal collapse to a single value: `{41.5, 41.9}`
  and `{41.5}` predict the same thing, and the latter is the correct form.
- Abilities with no timeline event get their own group. Emberdawn's 16 s
  channelled intermission appears nowhere in `C_EncounterTimeline` — the two
  streams are complementary, not redundant.
- `UnitGUID` is masked on boss units, so npcID is attempted but never relied on.

### Testing

- `Tools/test_infer.lua` now carries the real Emberdawn capture as a golden case
  alongside the synthetic ones, plus an assertion that a series which cannot be
  resolved is *declared* rather than asserted confidently. Across 13 seeds: 11
  fully clean, 2 with one degraded-but-flagged case, and no false positives even
  at 45% observation loss.

## [2.3.6]

### Fixed

- **The learning recorder was capturing the player's own spells.** Two causes,
  the first producing the second.
  1. `RegisterUnitEvent(..., "boss1", "boss2")` does not filter boss units: those
     tokens do not exist outside an encounter, so at `Init` time the filter
     cannot be established and the frame receives the event for *every* unit.
     `Engine/Timeline.lua` already avoided `RegisterUnitEvent` for this reason —
     unfiltered registration, then token matching in the handler. Same pattern
     applied to the recorder.
  2. `readCast` tested for an empty name by direct comparison. A secret value of
     string type answers `"string"` to `type()`, but any *comparison* on it
     raises a taint error — the very test meant to discard empty values was what
     crashed.
- Safety net: in M+ combat never drops between packs, so `PLAYER_REGEN_ENABLED`
  never fires. If `ENCOUNTER_END` was missed the pull stayed open and swallowed
  the trash. `INSTANCE_ENCOUNTER_ENGAGE_UNIT` with no living boss unit now closes
  the recording.

### Changed

- **Recorder v2 — measured, not asked.** `UnitCastingInfo` / `UnitChannelInfo`
  return nothing usable on hostile units under Midnight (name and spellID both
  masked), a finding already recorded in BossReminder's `TrashCD/Observation.lua`.
  Cast duration is now *measured* wall-clock between `UNIT_SPELLCAST_START` and
  `SUCCEEDED`, never read from the API. Instant and interrupted casts are kept as
  distinct identity classes.
- **Identity is now `(npcID, measured duration)`, not a spell name.** `UnitGUID`
  remains readable, so the caster is identified by npcID — far more robust than
  matching localized names against the Encounter Journal.
- **Data schema v2.** Every observation now carries its provenance (unit token,
  npcID) so a leaking filter is visible in the dump instead of inferred. v1
  captures are ignored on read rather than blended in: better no data than wrong
  data that looks right. `/tmb learn prune` removes them.
- Inference is deliberately gated behind the schema check while its grouping key
  (the spell name) is rebuilt around duration. The algorithm core — phase
  folding, cycle estimation, horizon guard — is unchanged and still covered by
  `Tools/test_infer.lua`.

### Added

- **`/tmb learn dump <key> [n]`** — raw capture, line by line, with per-type
  totals and an explicit verdict on which streams the server actually delivers.
  `/tmb learn dumpc` prints the same to chat.
- **`/tmb learn prune`** — drop captures from a stale schema.

## [2.3.5]

Two independent tracks: a learning system that builds encounter data from your
own pulls, and a render-path rewrite that removes the per-frame work the UI was
doing for nothing.

### Added

- **Learning system (`Learn/`).** Builds timing data from your own pulls, using
  three Blizzard sources exclusively — no third-party data:
  1. `C_EncounterTimeline` — the server's authoritative schedule,
  2. `UNIT_SPELLCAST_*` on `boss1`-`boss8` — the spell name, still readable in
     the clear under Midnight,
  3. the Encounter Journal (`EJ_*`) — spellID, icon, localized boss name.

  Crossing (1) and (2) yields what neither provides alone: the
  duration-to-ability mapping that `BlizzTimeline` needs. Six modules:
  `Store.lua` (SavedVariables schema, pull lifecycle, pruning), `Journal.lua`
  (name → spellID resolution, encounterID disambiguation when `ENCOUNTER_START`
  masks it), `Recorder.lua` (raw in-combat capture), `Infer.lua` (robust
  aggregation into `firstSeenSec` / `cdSeriesSec`), `Export.lua` (hot-apply via
  `MergeEncounter`, plus a paste-ready Lua block), `Slash.lua` (`/tmb learn`).
- **`/tmb learn`** — `on|off`, `show <key>`, `apply <key> [quality]`,
  `export <key> [quality]`, `rekey <key> <encounterID>`, `clear [key]`.
  `apply` merges the inferred definition into the live engine so a series can be
  tested on the very next pull, without a `/reload`.
- **`learn` profile settings** — `enabled`, `announce`, `pulls`.
- **`Tools/test_infer.lua`** — an out-of-game bench for the inference chain: five
  scenarios with measurement noise, missed observations and early wipes. Run with
  `lua5.1 Tools/test_infer.lua`. Not loaded by the TOC.

### Changed

- **Period detection works by phase folding, not by index.** Slicing observations
  as "index modulo p" desynchronizes the moment one is missing — the player dies,
  the boss walks out of range — and the whole series is destroyed from that point
  on. The cycle `T` is instead estimated from the median of sliding sums, then
  timestamps are folded modulo `T`: a missed observation only thins out a bucket,
  it never shifts anything. Tolerance is **absolute first** (0.6 s), because
  measurement noise does not scale with cycle length.
- **Inference uses robust statistics throughout** (median, MAD), never means, so
  a single bad pull cannot move the result. Quality is reported as
  `faible` / `moyen` / `bon`; a series observed over less than two full cycles is
  flagged as an extrapolation rather than an observation, and downgraded.
- **The timeline no longer re-renders on every tick.** Rendering was republished
  at 20 Hz per ability, and each republish triggered a full `styleBar`
  (`ClearAllPoints`, six `SetPoint`, two `SetFont`) plus a `table.sort` in
  `Layout()` — with no data having changed. `RenderOcc` is now called only on
  state change: start, rescheduling, and resync on a real cast. The visual
  countdown was already driven by the BarGroup ticker.
- **`Timeline` ticker lowered to 0.02 s.** It no longer renders, it only
  schedules. It must stay strictly below the BarGroup's recycling threshold
  (-0.05 s) so the next bar is published before the previous one returns to the
  pool.
- **`BarGroup`:** `styleBar` pulled out of `AddOrUpdate` behind a style
  generation counter bumped by `Restyle`; `Layout` runs only when the ordering
  can actually change (i.e. `endTime` moved); the spark is anchored once to the
  right edge of the fill so it follows `SetWidth` instead of being re-anchored
  every frame; time text, color, icon and name are all cached against their last
  applied value.
- **`RingGroup`:** `SetCooldown` is called only when the window really changes —
  it restarts the sweep animation, so calling it every frame made the ring
  stutter. Same caching for color, icon, name and time text.
- **`Theme:Font` memoizes font, size and color** and skips redundant `SetFont` /
  `SetTextColor` calls. A module that sets a color directly must clear
  `fs.__tmbColor` to have the next `Font()` reapply it; `BarGroup` and
  `RingGroup` do this on their danger/normal switch.
- **Both groups' `Tick` returns immediately when no bar or ring is active.**

### Fixed

- **Rings survived `ENCOUNTER_END` and wipes.** `Timeline:Stop()` called `Remove`
  on `TimerBars` only; it now goes through `RemoveOcc`, which clears bars **and**
  rings.
- **A live-read spell name was written to the shared event definition.** It is
  now stored on the occurrence instead, so a questionable resync — the
  duration-based fallback — can no longer corrupt the data for the rest of the
  session.
- **`Theme:Skin` was passed a boolean in `opts.border`,** which expects a color
  table.

### Notes

- The Recorder never touches the combat log (permanent taint under Midnight) and
  makes no `EJ_*` call in combat (`EJ_SelectEncounter` mutates global state).
- Observations are capped at 12 pulls per encounter and 400 entries per pull;
  pulls with fewer than 4 observations are discarded as unlearnable.
- When `ENCOUNTER_START` masks the encounterID, pulls are filed under a synthetic
  `i<instanceMapID>:<boss name>` key, which `/tmb learn rekey` can attach to the
  real encounterID afterwards.

## [2.3.0]

Cross-audit against BossReminder 2.8.0, then four batches of work. Data sources
were LittleWigs (duration branches) and BossReminder (event IDs,
roles, voices, severities, curated matching rules).

Encounter coverage grows from **29 encounters / 122 events** to
**67 encounters / 393 events**, 291 of which now carry an `eventID`.

### Added

- **EventBridge (`Modules/EventBridge.lua`).** Voice callouts are handed to the
  game itself through `C_EncounterEvents.SetEventSound`, so the client fires them
  at the exact moment: no Lua latency, no taint, and they keep working while
  encounter restrictions mask everything else. Registration is scoped to the
  current instance, batched to avoid a hitch on zone-in, and cleared on the way
  out. Timeline bars are also tinted by severity via `SetEventColor`.
  Diagnostics: `/tmb bridge`.
- **Timeline recorder (`Debug/TimelineRecorder.lua`).** Persists captures to a
  new `TomoBossRecorderDB` saved variable instead of printing volatile lines.
  Every `ENCOUNTER_TIMELINE_EVENT_ADDED` is annotated with the raw server
  duration, the matched event, **how** it was matched (sync / round-robin / rule
  / duration), and `srv:Y|N` — whether the game is already playing a server-side
  sound for it. That last flag is what makes duplicate callouts obvious at a
  glance. Commands: `/tmb rec on|off|list|show|export|clear`, with a copy/paste
  window for sharing captures.
- **Curated duration rules (`Data/DurationRules.lua`).** 264 duration-to-eventID
  rules across 41 encounters. They resolve what duration
  matching alone cannot: two abilities sharing the same duration inside one
  encounter (22 such collisions). Three mechanisms: `sync` rules consumed once
  inside a 10 s pull window, `sequenceGroup`/`sequenceOrder` round-robin on ties,
  and nearest-within-tolerance otherwise. 183 rules resolve against current data;
  the remaining 81 stay inert until their events exist.
- **Five off-season Midnight dungeons** — Murder Row, Den of Nalorakk, The
  Blinding Vale, Voidscar Arena, Altar of Fangs. 17 bosses / 74 events,
  regenerated from LittleWigs duration branches (Mythic and Normal/Heroic modes
  merged). This restores work announced in the 2.2.5 changelog that was never
  actually committed.
- **Three recycled Season 2 dungeons** — Temple of Sethraliss, Kings' Rest, Ruby
  Life Pools. 11 bosses / 47 events, same generation path. BossReminder carried
  no events at all for these.
- **Four raids** — Sporefall, The Voidspire, March on Quel'Danas, The Dreamrift.
  10 bosses / 150 events with event IDs, roles, voices and severities. They carry
  no timings, which does not matter: the EventBridge only needs an `eventID`.
- **`eventID` on 141 existing events**, including all 122 Season 1 events.
  Injected surgically by `spellID`; hand-tuned roles, voices and severities were
  left untouched.
- **`matchOnly` and `bridgeOnly` encounter flags.** `matchOnly` marks encounters
  whose durations identify timeline events but are not recurrence intervals;
  `bridgeOnly` marks encounters with no timing data at all. Without them
  `RegisterEncounter` would have filled in `cdSeriesSec = { 30 }` and fed
  `BuildMatchIndex` with invented durations.
- **Nameplate castbar glow (`Modules/NameplateGlow.lua`).** A pulsing border
  glow on a mob's nameplate castbar when its cast is dangerous. Two cumulative
  criteria: `C_Spell.IsSpellImportant(spellID)` (the game's own "important /
  lethal if not interrupted" flag) and, optionally, uninterruptible casts.
  Diagnostics: `/tmb glow`.
- **`eventBridge` and `recorder` settings** in the profile defaults.

### Changed

- **`BT:MatchDuration` now tries curated rules first** and only falls back to the
  historical nearest-duration index. Previously it took the smallest delta across
  every duration of every candidate encounter, with no memory, so it could not
  distinguish two abilities of equal duration.
- **The Lua voice path stays silent for bridged events.** `BT:Tick` checks
  `EventBridge:WillPlaySound(ev)` before announcing; without it the callout would
  fire twice. The severity-2 screen flash still fires — it is visual, not audio.
- **Bar tint and sound volume** now go through `EncounterEventSoundInfo.volume`
  on the bridge path, a real gain, rather than stacking `PlaySoundFile` calls.

### Fixed

- **Voice files never resolved.** `Core/Media.lua` registered
  `Media\Voice\<locale>\<file>` while the 185 `.ogg` files sat flat in
  `Media\Voice\`. `LSM:Fetch` does not check the disk, so it returned a valid
  path and `PlaySoundFile` failed silently. All 185 catalog entries now resolve
  in both `frFR` and `enUS`. *(Shipped in 2.2.7.)*
- **`DungeonMaps` was missing five map IDs** (2813, 2825, 2859, 2923, 2993)
  announced in 2.2.5, so those instances resolved no encounter candidates.

### Known issues

- `windrunner_spire.lua` encounter 3058 contains three strictly duplicated event
  lines.
- `maisara_caverns.lua` encounter 3213 lists spell 1251775 / eventID 688 twice —
  once with `voice = "kite-add"`, once with no voice at all.
- Voices and severities on the four raids and the off-season Midnight dungeons have not been
  verified in game; 14 events fall back to a default voice, flagged in comments.
- 42 event lines are marked `AMBIGU`: two abilities share a duration within
  0.75 s in the same encounter and no curated rule covers them.
- The bridge only covers events that carry an `eventID` (291 of 393). The other
  102, from the LittleWigs-derived off-season dungeons, stay on the Lua path.
- The bridge fires on trigger 2 (`OnTimelineEventHighlight`), hardwired to about
  5 seconds before the cast. The "announcement lead" slider and per-ability
  `preAlertSec` therefore have no effect on bridged events. Disabling
  `eventBridge` hands control back to the Lua path.

### Notes

Three defects were found in BossReminder while porting and are **not** reproduced
here: its `.toc` declares `Data\EncounterTriggers.lua` while the file lives at
`Engine\EncounterTriggers.lua`, so its entire curated matching layer is dead
code; it calls `SetEventColor(eventID, color)` where the real signature is
`SetEventColor(eventID, trigger, color)`; and its bridge registration iterates
every encounter instead of scoping to the current instance, which matters because
event IDs are not unique across instances (802 exists in both Den of Nalorakk and
The Voidspire).

The nameplate glow cannot know that a cast targets *you* — under Midnight
`UnitSpellTargetName` returns a secret, and `UnitIsUnit` rejects nameplate and
`targettarget` tokens. It keys on the game's importance flag instead, which is
itself a *secret boolean*: it is never tested in Lua but fed to
`Region:SetAlphaFromBoolean`, so the engine resolves it taint-free (glow alpha 1
when important, 0 otherwise).

BossReminder's comments also invert the sound trigger enum. Per Blizzard's
generated API documentation: 0 is `OnTextWarningShown`, 1 is
`OnTimelineEventFinished`, and 2 is `OnTimelineEventHighlight`.

## [2.2.7]
### Fixed
- **Minimap button now follows a square minimap.** The button was always placed on a circle of 
fixed radius around the minimap centre, so on a square minimap (TomoMod and similar) it floated 
inside the map near the corners and outside it near the edge midpoints. The angle is now projected 
onto the square border when `GetMinimapShape()` reports `SQUARE`, matching how LibDBIcon buttons 
behave. Round minimaps are unaffected.

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
