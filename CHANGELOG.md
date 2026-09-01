# Changelog

## 2.8.0-rc3 — Flicker-free display, evidence-gated Learn, observed Season 2 data

### Data & Provenance

- **All eight Season 2 dungeons regenerated from TomoBoss captures** — Murder Row, Den of Nalorakk, The Blinding Vale, Voidscar Arena, Altar of Fangs, Temple of Sethraliss, Kings' Rest and Ruby Life Pools now ship `provenance = "observed"`. 28 encounters, 121 events, every duration seen at least three times on `ENCOUNTER_TIMELINE_EVENT_ADDED` across 274 recorded pulls. No third-party timing data remains in the Season 2 dungeon pool.
- **Why raw captures were sufficient here** — These eight dungeons are `matchOnly`, so the predictive engine never starts on them and `cdSeriesSec` is consumed solely by `BT:BuildMatchIndex` as a bag of durations compared against `C_EncounterTimeline`. A duration there is an *identification key*, not a schedule: Blizzard supplies the timing. The accuracy bar is therefore "was this duration actually observed", which the capture log answers directly, with no inference in the path.
- **Spell identities and editorial metadata preserved** — `spellID`, `eventID`, `role`, `voice` and `severity` carry over unchanged. Those are Blizzard identifiers and TomoBoss authoring choices; only timings were replaced.
- **Duration collisions preserved rather than resolved** — 18 durations are shared by more than one ability. Each remains attached to every tied ability so the engine still detects the ambiguity and falls back to a generic alert. Silently narrowing a collision would turn a deliberate generic warning into a confident and possibly wrong callout; a neutral voice is better than the wrong one. Each case is listed in the export report for a future `DURATION_RULES` entry.
- **10 previously unknown mechanics recovered** — Durations observed repeatedly with no matching ability in the old dataset are emitted with a neutral voice and a `TODO identifier` marker instead of being discarded. The most frequent are a 99 s event on The Hoardmonger (3207) seen 24 times, a 45 s event on Lightwarden Ruia (3199) seen 27 times, and a 21 s event on 3201 seen 12 times — none present in the previous data.
- **5 unconfirmed entries removed** — Durations carried by the previous dataset but never observed in any capture were dropped rather than trusted. All five are on The Council of Tribes (2140), which has only 118 s of recorded combat across 4 pulls; they are more likely undersampled than wrong, and a single longer pull should settle it.

### Added

- **`Tools/export_observed.lua`** — Regenerates the eight Season 2 dungeon files from a SavedVariables capture. Replays the real engine to obtain effective definitions (base plus `Season2Corrections`), then attaches observed durations using the same 0.75 s tolerance as `BlizzTimeline`. Writes to `Build/`, never to `Engine/Encounters/`, and emits a report of confirmed, removed, orphan and ambiguous entries. Re-runnable as coverage grows.
- **Replay verification in the inference engine** — A series must now explain the intervals actually observed: each gap between two observations has to be a sum of *consecutive* series entries, with chaining positions. Multi-entry sums account for missed occurrences, which is normal under observation loss. A gap no sum can explain marks the series as contradicted. The test is local to each interval, so it is immune to accumulated drift, and independent of how the series was derived.
- **Evidence-based quality gating** — `quality` now requires a minimum number of observed intervals (8 for `good`, 4 for `medium`) on top of pull count, with a dedicated warning reporting the exact interval count when evidence is short.
- **New result fields** — `fit` (replay fidelity, 0–1) and `intervals` (usable interval count) are exposed on inference results and surfaced in `/tmb learn`.
- **`Tools/test_fit.lua`** — Locks the replay guard in both directions: clean data must not be downgraded, an imposed wrong cycle must be. A guard that is too strict is as harmful as none at all, since it would condemn correct data at export time.
- **`Tools/test_noblink.lua`** — Replays the timeline flicker scenario and asserts the card no longer toggles visibility at the NOW line.
- **`timeline.holdAtNow` profile setting** — Controls how long a card stays anchored on the NOW line past its deadline (default 1.5 s).

### Fixed

- **TomoTimeline flickered when an ability reached NOW** — `BT:Tick` rewrites `endTime` from the server countdown every 0.3 s, and that countdown pins to 0 as soon as the ability fires. Between two resyncs the local extrapolation went negative, the `-0.05` visibility threshold hid the card, and the next resync brought it back. At the 20 Hz render rate this produced 17 visibility flips over the 2.4 s between the deadline and the server `REMOVED`. Cards are now latched on the NOW line for a grace period; only producer removal or grace expiry hides them.
- **Cards jumped between rails** — The left/right side was re-arbitrated every tick, so a neighbour entering or leaving the window could flip a card from one side to the other 20 times a second. The side is now locked at first placement, with remaining collisions resolved vertically.
- **Urgent state oscillated at the threshold** — A remaining time hovering around the urgency threshold repainted the card repeatedly. Entry and exit now use a 0.5 s hysteresis band.
- **Ring flashed on completion** — `UI/RingGroup.lua` was the only `Cooldown` frame in the addon that never called `SetDrawBling(false)`, so `CooldownFrameTemplate` drew its white completion burst exactly when the ability landed.
- **Rings vanished and reappeared within the same second** — A ring reaching its deadline was removed at `-0.05` and reposted by the next `STATE_CHANGED`. Rings are now held at zero for a grace period, and `SetCooldown` is only re-issued when the timing change exceeds 0.15 s, which also removes the sweep stutter caused by resyncing on noise.
- **Central progress ring blinked between abilities** — `Stop()` hid the ring immediately and the next ability reopened it right after. Hiding is now deferred; an incoming `Track()` cancels it, turning the flicker into a continuous transition. The tracked ability also keeps focus briefly past its deadline so the ring closes fully instead of jumping.
- **Resync applied server noise as if it were drift** — `endTime` is no longer rewritten for changes under 0.15 s, nor during the last 0.75 s where the server value freezes and local extrapolation is smoother. Voice callout accuracy is unaffected, as its matching tolerance is 0.5 s.
- **Inference could assert a wrong cooldown series with full confidence** — Phase folding can produce perfectly tight clusters on a *wrong* cycle when observations are sparse: the clusters genuinely are tight, so no dispersion measure can detect it. The project's own "sure failure" regression assertion was red, with two of three abilities reporting a false series as `good` and no warning. Replay verification now catches this class and the assertion passes.
- **Quality was awarded on pull count rather than evidence** — With a 91 s median pull length across 274 recorded pulls, an ability on a 60 s cooldown yields a single interval per pull, so "4 pulls" could mean four intervals. Replay verification then abstained for lack of material, and absence of contradiction was being read as confirmation. Abilities rated `good` drop from 183 to 31, which is the honest count for the evidence on hand.
- **Inference trace crashed on an undefined variable** — `Learn/Infer.lua` referenced `span`, a leftover from the refactor that replaced the `c[#c] - c[1]` arc span with modulo unrolling. Trace-gated, so players never hit it, but it aborted the regression harness before it reached the assertions above.

## 2.8.0-rc2 — Flicker-free display, evidence-gated Learn, observed Season 2 data

### Data & Provenance

- **All eight Season 2 dungeons regenerated from TomoBoss captures** — Murder Row, Den of Nalorakk, The Blinding Vale, Voidscar Arena, Altar of Fangs, Temple of Sethraliss, Kings' Rest and Ruby Life Pools now ship `provenance = "observed"`. 28 encounters, 117 events, every duration seen at least three times on `ENCOUNTER_TIMELINE_EVENT_ADDED` in live runs. No third-party timing data remains in the Season 2 dungeon pool.
- **Why this was possible without a prediction-grade dataset** — These eight dungeons are `matchOnly`, so the predictive engine never starts on them and `cdSeriesSec` is consumed solely by `BT:BuildMatchIndex` as a bag of durations compared against `C_EncounterTimeline`. A duration there is an *identification key*, not a schedule: Blizzard supplies the timing. The accuracy bar is therefore "was this duration actually seen", which raw captures answer directly.
- **Spell identities and editorial metadata preserved** — `spellID`, `eventID`, `role`, `voice` and `severity` are carried over unchanged. Those are Blizzard identifiers and TomoBoss authoring choices; only the timings were replaced.
- **9 unconfirmed entries removed** — Durations present in the previous dataset but never observed in any capture were dropped rather than carried forward on trust. The heaviest concentration is on Ziekket (3202), where three entries disappear at once.
- **10 previously unknown mechanics recovered** — Durations observed repeatedly with no matching ability in the old dataset are now emitted with a neutral voice and a `TODO identifier` marker instead of being discarded. The most frequent is a 99 s event on The Hoardmonger (3207), seen 24 times and absent from the previous data entirely.
- **18 duration collisions flagged, none silently resolved** — Where two abilities share a duration, the generator refuses to pick, matching the engine's own behaviour of falling back to a generic alert rather than risking the wrong callout. Each case is listed for a `DURATION_RULES` entry.

### Added

- **`Tools/export_observed.lua`** — Regenerates the eight Season 2 dungeon files from a SavedVariables capture. Replays the real engine to obtain effective definitions (base plus `Season2Corrections`), then attaches observed durations using the same 0.75 s tolerance as `BlizzTimeline`. Writes to `Build/`, never to `Engine/Encounters/`. Emits a report covering confirmed, removed, orphan and ambiguous entries.
- **Replay verification in the inference engine** — A series must now explain the intervals actually observed: each gap between two observations has to be a sum of *consecutive* entries in the series, with chaining positions. Multi-entry sums account for missed occurrences, which is normal under observation loss. A gap no sum can explain marks the series as contradicted. The test is local to each interval, so it is immune to accumulated drift, and independent of how the series was derived.
- **Evidence-based quality gating** — `quality` now requires a minimum number of observed intervals (8 for `good`, 4 for `medium`) in addition to pull count, and a dedicated warning reports the exact interval count when evidence is short.
- **New result fields** — `fit` (replay fidelity, 0–1) and `intervals` (usable interval count) are exposed on inference results and surfaced in `/tmb learn`.
- **`Tools/test_fit.lua`** — Locks the replay guard in both directions: clean data must not be downgraded, an imposed wrong cycle must be. A guard that is too strict is as harmful as none at all, since it would condemn correct data at export time.
- **`Tools/test_noblink.lua`** — Replays the timeline flicker scenario and asserts the card no longer toggles visibility at the NOW line.
- **`timeline.holdAtNow` profile setting** — Controls how long a card stays anchored on the NOW line after its deadline (default 1.5 s).

### Fixed

- **TomoTimeline flickered when an ability reached NOW** — `BT:Tick` rewrites `endTime` from the server countdown every 0.3 s, and that countdown pins to 0 as soon as the ability fires. Between two resyncs the local extrapolation went negative, the `-0.05` visibility threshold hid the card, and the next resync brought it back. At the 20 Hz render rate this produced 17 visibility flips over the 2.4 s between the deadline and the server `REMOVED`. Cards are now latched on the NOW line for a grace period; only producer removal or grace expiry hides them.
- **Cards jumped between rails** — The left/right side was re-arbitrated on every tick, so a neighbour entering or leaving the window could flip a card from one side to the other 20 times a second. The side is now locked at first placement, with remaining collisions resolved vertically.
- **Urgent state oscillated at the threshold** — A remaining time hovering around the urgency threshold repainted the card repeatedly. Entry and exit now use a 0.5 s hysteresis band.
- **Ring flashed on completion** — `UI/RingGroup.lua` was the only `Cooldown` frame in the addon that did not call `SetDrawBling(false)`, so `CooldownFrameTemplate` drew its white completion burst exactly when the ability landed.
- **Rings vanished and reappeared within the same second** — A ring reaching its deadline was removed at `-0.05` and reposted by the next `STATE_CHANGED`. Rings are now held at zero for a grace period, and `SetCooldown` is only re-issued when the timing change exceeds 0.15 s, which also removes the sweep stutter caused by resyncing on noise.
- **Central progress ring blinked between abilities** — `Stop()` hid the ring immediately, and the next ability reopened it right after. Hiding is now deferred; an incoming `Track()` cancels it, turning the flicker into a continuous transition. The tracked ability also keeps focus briefly past its deadline so the ring closes fully instead of jumping.
- **Resync applied server noise as if it were drift** — `endTime` is no longer rewritten for changes under 0.15 s, nor during the last 0.75 s where the server value freezes and local extrapolation is smoother. Voice callout accuracy is unaffected, as its tolerance is 0.5 s.
- **Inference could assert a wrong cooldown series with full confidence** — Phase folding can produce perfectly tight clusters on a *wrong* cycle when observations are sparse: the clusters genuinely are tight, so no dispersion measure can detect it. The project's own "sure failure" regression assertion was red, with two of three abilities reporting a false series as `good` and no warning. Replay verification now catches this class, and the assertion passes.
- **Quality was awarded on pull count rather than evidence** — With a 91 s median pull length measured across 255 real pulls, an ability on a 60 s cooldown yields a single interval per pull, so "4 pulls" could mean four intervals. 81 of 129 abilities rated `good` rested on fewer than six intervals, and replay verification abstained precisely there for lack of material, so absence of contradiction was being read as confirmation. `good` now stands at 32 abilities, which is the honest count.
- **Inference trace crashed on an undefined variable** — `Learn/Infer.lua` referenced `span`, a leftover from the refactor that replaced the `c[#c] - c[1]` arc span with modulo unrolling. Trace-gated, so players never hit it, but it aborted the regression harness before it reached the assertions above.

### Known limitations

- The two Season 2 raids are out of scope. No encounter definitions exist yet for 3379, 3421, 3429, 3470 or 3492, and capture coverage is thin. Unlike the dungeons, raid timing feeds prediction, so it needs the full evidence bar.
- 10 recovered mechanics ship with a neutral voice pending in-game identification of role and severity.

## 2.8.0-rc1 — Release Candidate

### Release Candidate
- **Boss timer authority is now frozen for RC1** — Player-facing boss timers and voice decisions are produced by TomoBoss. Blizzard `C_EncounterTimeline` remains the native input feed; BigWigs/DBM remain audit-only and EXBossData/WeakAura remain reference-only.
- **No new boss-resolution rules** — RC1 intentionally freezes the validated Season 2 boss logic from beta5d2b for stabilization and player testing.
- **StateResolver runtime validation complete** — Guarded state-aware rules have now been validated in live dungeon runs for Adderis & Aspix (2124), Council of Tribes (2140), Mchimba the Embalmer (2142), and Lightwarden Ruia (3201), with specific resolutions observed and no guarded fallbacks in the validated runs.
- **Ruia Phase 3 runtime validation complete** — The native `2.5s` Phase 3 marker was observed and the `32s` cycle resolved `5/5` in the validated run, with the Learn gate armed and persistent evidence retained.
- **Adderis & Aspix runtime validation complete** — The observed death-state branch resolved `8` state-aware decisions with `0` guarded fallbacks.
- **Council runtime validation complete** — The validated run resolved `4` state-aware decisions with `0` guarded fallbacks and observed the expected state transition.
- **Mchimba runtime validation complete** — The validated run resolved `8` state-aware decisions with `0` guarded fallbacks and observed the expected Entomb state changes.

### Localization
- **RC1 GUI strings translated into every supported locale** — The stable-layout rework shipped its 38 new strings as a hardcoded English fallback injected into all twelve locale tables, so deDE, esES, esMX, itIT, ptBR, ruRU, koKR, zhCN and zhTW displayed the whole reorganized options panel in English. Each of those nine locales now has its own translation block; enGB keeps the English source.
- **Reorganized tab labels realigned across locales** — `TAB_BARS`, `BARS_TITLE` and `TAB_TRASH` were rewritten for frFR and enUS only, leaving other clients with labels describing the previous layout (a German player saw "Anzeige" over the boss alerts and "TrashCD" over the targeted-cast page). All twelve locales are now rewritten from a single table.
- Locale injection is now data-driven (`TRANSLATIONS` / `TABS`) instead of per-language `if` blocks, so adding a locale is one table entry.

### Trash Warnings
- **Secret-safe targeted cast ring** — Dungeon trash casts that target the player can now drive the central TomoBoss warning ring without inspecting the restricted target boolean in Lua.
- **Native secret-safe progress** — Enemy cast progress uses Blizzard `UnitCastingDuration()` / `UnitChannelDuration()` duration objects directly through `Cooldown:SetCooldownFromDurationObject()`. No enemy cast timestamps are converted to Lua numbers.
- **Validated cast correlation** — `castBarID` remains an opaque NeverSecret identity used only to correlate the current cast; it is never mapped back to a restricted spell identity.
- **No combat log dependency** — Trash warnings do not register `COMBAT_LOG_EVENT_UNFILTERED` and do not use `CombatLogGetCurrentEventInfo`.

### Timeline & Display
- Includes the beta5d2b TomoTimeline duplicate suppression and the native timeline overlap fix.
- Blizzard's native Encounter Timeline remains the source feed when available, while TomoBoss owns the player-facing Bars / Timeline / Hybrid rendering.
- Sentinel timeline values remain blocked from player-facing timers.
- One intentionally ambiguous Season 2 collision remains generic-safe rather than risking an incorrect mechanic callout.

### Diagnostics
- `/tmb doctor` now states the RC1 player-facing authority model explicitly.
- Doctor reports the secret-safe targeted Trash Warning Ring separately from the observation-only TrashCD research diagnostics.
- Legacy beta footer text is replaced by a concise RC1 stabilization summary.

### Release Policy
- **Player-facing boss output:** TomoBoss authority.
- **Blizzard `C_EncounterTimeline`:** native runtime input.
- **BigWigs / DBM:** audit only; never player-facing authority.
- **EXBossData / WeakAura:** reference only; never player-facing authority.
- **Learn / PhaseDetector / StateResolver:** TomoBoss-owned validation and guarded resolution layers.
- No Learn purge is required.

## 2.8.0-beta5d2b — TomoTimeline duplicate & native timeline overlap

### Fixed
- **Duplicated abilities on TomoTimeline** — When Blizzard re-posts the same encounter event under a new identifier and hides its `duration`, both existing anti-duplicate guards were inert, so a second timer was created. The classic bars stacked those two on top of each other and hid the problem; TomoTimeline spreads simultaneous entries to either side of the rail, so every ability showed up twice. `NS.BlizzTimeline` now falls back to the resolved name + icon at the same fire time as an identity, keeps the original entry, and aliases the new identifier so its REMOVED still cleans up.
- **Timeline render safety net** — TomoTimeline collapses two visible entries that share name, icon and fire time (within 0.35 s), so no producer can ever paint the same ability twice on the rail.

### Added
- **Timer feed kept armed while hiding** — `encounterWarningsEnabled` gates the whole encounter-warning system, so it also gates the `ENCOUNTER_TIMELINE_EVENT_*` source that feeds TomoTimeline and the bars: switching it off to get rid of the native frame would leave TomoTimeline empty. TomoBoss now restores it to 1 whenever "Enable Blizzard timeline" is checked — independently of EventBridge, which only did so while the bridge was enabled and the player was inside a party or raid — reacting to `CVAR_UPDATE`, world entry and encounter start, with a slow periodic check as a backstop. Unchecking "Enable Blizzard timeline" hands the CVar back to the player.
- **`/tmb doctor` timer-feed section** — Reports the CVar state, whether the timeline feature is available, how many Blizzard events are tracked, how many entries reached the shared model, the resolved display mode, and whether the native frame was located and hidden.
- **Hide Blizzard's native timeline** — New option on the Blizzard Timeline page (on by default). EventBridge has to keep `encounterWarningsEnabled` at 1 for the game to fire its own sound triggers, which also makes the native timeline appear next to TomoBoss's. The native frame is now made invisible and click-through instead of being hidden, so the client keeps running it and the ~5 s highlight trigger the sound bridge depends on still fires.
- Localized strings for the new option in all twelve supported client locales.

## 2.8.0-beta5d2a — Display Modes, TomoTimeline & Full Localization

### Added
- **TomoTimeline V1** — Added a native TomoBoss vertical timeline renderer driven by the same timer model as the classic boss bars.
- **Three timer display modes** — Players can choose **Bars**, **Timeline**, or **Hybrid** from the new Display page.
- **Display Engine** — Added the shared TimerModel / DisplayController layer so bars and TomoTimeline consume the same timer state instead of running separate timer engines.
- **Full interface localization** — Added complete UI translations for all current WoW client locales: `enUS`, `enGB`, `frFR`, `deDE`, `esES`, `esMX`, `itIT`, `ptBR`, `ruRU`, `koKR`, `zhCN`, and `zhTW`.

### Changed
- **UI Foundation** — Refreshed the visual system around the Obsidian + Jade theme, with stronger surface hierarchy and reusable modern UI components.
- **Boss Bars V2** — Boss timers now use the modern layered bar style with clearer icon framing, progress track, severity accents, and a dedicated urgency state.
- **Display options** — The former Bars page is now the Display page and explains each rendering mode before exposing its relevant settings.
- **Hybrid configuration** — Hybrid mode lets players switch between bar settings and TomoTimeline settings without crowding the options panel.

### Fixed
- **Dungeon TomoTimeline feed** — Blizzard Encounter Timeline events are now forwarded to the shared display layer even when the historical “show as bars” option is disabled, allowing TomoTimeline to receive dungeon boss timers correctly.
- Changing display mode during an active encounter republishes currently known Blizzard timeline events to the newly selected renderer.

### Localization
- Supported locales now use their **own complete string tables**; they no longer rely on French or English for missing UI text.
- Added a locale completeness audit that detects missing or unexpected keys without silently filling supported locales from another language.
- Technical identifiers and slash commands remain unchanged while their descriptions are translated for each client language.

## 2.8.0-beta5d2 — Deferred Cast Target Observatory

### Changed
- TrashCD diagnostics now distinguish castBarID-bearing events from unique castBarIDs.
- Added direct correlation checks between spellcast-event castBarID and UnitCastingInfo/UnitChannelInfo castBarID.
- Cast targets are sampled immediately and at 50/150/300 ms while the same NeverSecret castBarID remains active.
- Trash dumps now report immediate/final target class, recovery delay, probe count and completion reason.

### Safety
- No Combat Log events or CombatLogGetCurrentEventInfo.
- Secret spell IDs and secret target identities are still dropped.
- No enemy GUID/NPC reconstruction and no raw target-player names are persisted.
- StateResolver boss decisions are unchanged.

### Developer
- Includes Tools/Build_Release.py; the release builder excludes Tools/ from player ZIPs.

## 2.8.0-beta5d1 — Trash Cast Target Observatory

- **New** — Audits Blizzard's `UnitSpellTargetName()` on enemy cast bars without using the combat log.
- **New** — Classifies readable cast targets as SELF, TANK, HEALER, DPS, GROUP or OTHER.
- **Privacy/Safety** — Raw player names are never persisted; secret target names are counted and discarded.
- **Diagnostics** — `/tmb trashdoctor` now reports target visibility and target-class counts.
- **Diagnostics** — `/tmb trashdump` includes the coarse target class for each observable cast.
- **Unchanged** — StateResolver gameplay decisions, boss timers and P0-01 sentinel protection are unchanged.

## 2.8.0-beta5d — TrashCD Observatory & Persistent State Evidence

### TrashCD Observatory
- **New** — Added an observation-only Midnight-safe TrashCD probe for dungeon testing.
- **New** — Records NeverSecret `castBarID` values and non-secret enemy spell IDs exposed by Blizzard without using combat-log events.
- **New** — Secret enemy spell IDs are counted for diagnostics and discarded without being interpreted or stored.
- **New** — Added `/tmb trashdoctor` and `/tmb trashdump` for copyable dungeon test results.
- **New** — Added an optional `/tmb trashpreview on` diagnostic preview. It starts only after a real known non-secret cast and can issue a generic TTS warning near the next stable reference cooldown.
- **Changed** — Trash preview is OFF after every reload and does not replace TomoBoss's existing player-facing trash module.

### TrashCD Reference Validation
- **New** — Added a diagnostic reference catalog covering 8 Season 2 dungeon maps, 138 trash spell rows and 101 conservative preview candidates.
- **Changed** — Reference data can only be matched after Blizzard exposes the spell ID as non-secret; it never reveals or reconstructs restricted identities.
- **Changed** — Interrupted or failed observed casts cancel their pending diagnostic prediction rather than risking a stale warning.

### StateResolver Validation
- **New** — Runtime evidence for Adderis & Aspix (2124), Council of Tribes (2140), Mchimba (2142) and Lightwarden Ruia (3201) is now retained across later bosses.
- **New** — `/tmb statedump` exports the exact stored StateResolver decisions, guarded fallbacks and encounter-state markers from recent runs.
- **Changed** — Boss resolution rules themselves are unchanged from beta5c1.

### Midnight Safety
- **Changed** — No combat-log event or combat-log API is registered or used by the new observatory.
- **Changed** — No enemy GUID, enemy name or cast GUID is stored by TrashCD Observatory.
- **Changed** — `castBarID` is used only as an opaque cast identity/deduplication key and is never mapped back to a restricted spell.
- **Changed** — No Learn purge is required.

## 2.8.0-beta5c — Season 2 Timeline Reliability, Learn Profiles & Safer Boss-Mod Integration

### Season 2 — Timeline Reliability

- **Fixed** — TomoBoss now ignores invalid Blizzard timeline sentinel values instead of treating them as real boss timers. This prevents extremely long or impossible timers such as `9999` / `10001` seconds from appearing as player-facing alerts.
- **Fixed** — Repeated timeline entries are handled more safely, including encounters where multiple mechanics legitimately share the same duration.
- **Changed** — Ambiguous timers now prefer a safe generic fallback over guessing the wrong mechanic.
- **Changed** — Season 2 duration rules were audited and normalized against real in-game captures, with all configured rules resolving to a known mechanic.

### Season 2 — State-Aware Boss Resolution

- **New** — TomoBoss can now use encounter state to distinguish mechanics that share the same timer duration instead of relying only on static occurrence order.
- **New** — Added guarded state-aware handling for Adderis & Aspix, Council of Tribes, Mchimba the Embalmer and Lightwarden Ruia.
- **Changed** — Multi-phase encounters remain conservative: TomoBoss only uses a specific state-based result when the required encounter evidence has actually been observed.
- **Changed** — One intentionally ambiguous collision remains generic-safe rather than risking an incorrect warning.

### The Blinding Vale

- **New** — Learn now recognizes multiple valid timeline profiles for The Blinding Vale instead of treating different difficulty/profile patterns as conflicts.
- **New** — Added validated Mythic timeline profiles for Lightblossom Trinity, Ikuzz the Light Hunter, Lightwarden Ruia and Ziekket based on real in-game captures.
- **New** — Lightwarden Ruia now has Learn evidence for all three phases, including the Phase 3 `2.5s` transition marker and the repeating `32s` sequence.
- **Changed** — Ruia's Phase 3 resolution remains guarded by the native in-combat phase marker even when Learn/reference confidence is high.
- **New** — Ziekket's Mythic `50s` sequence and alternate `45s` profile are both tracked as valid profiles.

### Learn System

- **New** — Added profile evidence tracking so Learn can distinguish alternative and Mythic timeline signatures for the same encounter.
- **New** — Learn now records evidence for phase anchors, phase transitions and profile stability without requiring a database reset.
- **Changed** — Existing Learn history is preserved and reused; no Learn purge is required for this update.
- **New** — Invalid/sentinel timeline samples are counted for diagnostics while remaining excluded from player-facing timer resolution.

### Reference Validation

- **New** — Added an observation-only Reference Catalog covering all 28 Season 2 encounters.
- **New** — TomoBoss can cross-check its decisions against independent reference data from EXBossData and WeakAura mappings, while keeping Blizzard/TomoBoss as the runtime authority.
- **New** — Reference validation understands canonical mechanic IDs and physical cast aliases, preventing harmless ID differences from being reported as false conflicts.
- **Changed** — External references can confirm or flag a TomoBoss decision, but they can never create, replace or control a player-facing timer.

### BigWigs / DBM Compatibility

- **Fixed** — BigWigs timeline callbacks are now safe when Midnight exposes protected/secret spell text or icon values.
- **Fixed** — TomoBoss no longer attempts string operations on inaccessible BigWigs values, preventing the `invalid value (secret) ... table.concat` Lua error seen in raids.
- **Changed** — Safe native event identifiers are used when available; inaccessible external identities are simply ignored.
- **Changed** — DBM integration received the same secret-safe boundary handling in preparation for future interoperability.
- **Changed** — BigWigs and DBM remain audit/compatibility sources only and never control TomoBoss output.

### Doctor / Diagnostics

- **New** — `/tmb doctor` now reports Reference Catalog status, reference matches/conflicts, Learn profile evidence, alias resolutions and external audit results.
- **New** — Ruia diagnostics now separate Learn-gate readiness, Phase 3 Learn evidence and the live in-combat Phase 3 guard.
- **New** — Doctor reports observed sentinel timeline samples so Blizzard's invalid long-duration events can be verified without exposing them as timers.
- **Changed** — Season 2 collision coverage now distinguishes static, state-aware and deliberately generic-safe cases.

### Validation

- **Tested** — Season 2 timeline captures were validated across the current dungeon pool, including real Mythic captures from The Blinding Vale.
- **Tested** — BigWigs loads with the secret-safe bridge enabled and no new BigWigs integration Lua error observed in the validated sessions.
- **Tested** — The Reference Catalog remains observation-only and does not change existing player-facing timer decisions.
- **Tested** — Blizzard timeline sentinel protection remains active and validated in game.

## #########################################################################

## [2.7.3]

BlizzTimeline hardening pass, from 12.1 capture review: three failure modes
that produced wrong or duplicate alerts are now guarded against, and the
in-combat frame no longer resets the timeline on the wrong event.

### Added

- **Sentinel durations (~900 s+) are no longer rendered as timers.** 12.1
  captures show `ENCOUNTER_TIMELINE_EVENT_ADDED` occasionally carrying values
  around 999/1003 s — these are Blizzard state signals, not player-facing
  cooldowns. They are now recognised and skipped for bars/voice, while still
  being forwarded to the Recorder and broadcast on `TMB_TIMELINE_SENTINEL` for
  future phase-detection work.
- **`ENCOUNTER_END` is now handled explicitly** and is the primary trigger for
  clearing the timeline.

### Fixed

- **Ambiguous duration matches no longer pick an arbitrary winner.** When two
  or more distinct abilities fall within the match tolerance of each other,
  `MatchDuration` used to silently return the first one found. It now detects
  the tie and falls back to a generic alert instead of risking the wrong
  ability (and the wrong voice line).
- **Duplicate generic `ADDED` events are now suppressed.** Some 12.1 captures
  post the same unidentified event two or three times in a row (same duration,
  same end time). Without an identity to compare, these looked like separate
  mechanics and produced repeated alerts; they are now deduplicated the same
  way identified events already were.
- **`PLAYER_REGEN_ENABLED` no longer tears down the timeline mid-fight.**
  Leaving combat briefly (e.g. a short lull) used to reset everything. It now
  waits 0.25 s and only clears if the player is confirmed out of combat and no
  encounter is in progress; `ENCOUNTER_END` remains the authoritative signal.
- **`ENCOUNTER_TIMELINE_STATE_UPDATED` no longer triggers a destructive
  reset.** This event describes a state update, not a combat end — individual
  entries are already maintained via `ADDED`/`REMOVED`/`STATE_CHANGED`.

## [2.7.2]

Corpus extended to 32 encounters across 10 dungeons, including the first
Season 2 captures (Murder Row 2813, Altar of Fangs 2993). 1309 observations.

### Added

- **Chained casts are now identified and excluded from export.** A boss can
  relaunch the same spell continuously — Murder Row's first boss casts a 3.00 s
  spell every 3.65 s, leaving 0.65 s between them. That is not a cooldown, and
  giving it a voice line would mean an announcement every three seconds.

  When an ability's cycle barely exceeds its own cast time, the analysis says so
  in plain terms and the export skips it. One group out of the whole corpus is
  affected, so this is a label rather than a redesign — but it is exactly the
  kind of entry that would have made the addon unusable on that fight.

### Testing

- 286 abilities extracted across the 32-encounter corpus without error.
- A missing corpus key is now tolerated rather than failing the bench, so an
  assertion referring to a capture not currently loaded reports as ignored
  instead of red.

## [2.7.1]

### Fixed

- **`/tmb` did nothing and the addon appeared dead.** A constant added in 2.7.0
  was declared near the function it documents, at line 260 — but used at line 96.
  A Lua `local` only exists from its declaration line onward, so at line 96 it was
  a global `nil`, `C_Timer.NewTicker(nil, …)` raised, and initialisation stopped
  there. Everything after it, including slash command registration, never ran.
  The file compiles cleanly; the failure only appears at runtime.

### Changed

- **Commands are now registered first, before any module.** They were declared at
  the end of initialisation, so any earlier error left `/tmb` completely silent
  with no clue as to the cause. A command that answers is the minimum needed to
  diagnose anything.
- **Each module is initialised in isolation.** Nine modules were initialised in
  sequence with no protection: one failure took out every module after it. A
  faulty module now reports itself in chat and the rest of the addon keeps
  working.

### Testing

- `Tools/test_scope.lua` — static analysis for locals used above their
  declaration line. This class of bug compiles, passes syntax checking, and only
  surfaces at runtime by killing everything downstream. Verified both ways: it
  reports the original fault when reintroduced, and nothing across the 60 files
  of the fixed tree.

## [2.7.0]

### Fixed

- **Trash cast bars never appeared in dungeons.** The module filtered casts by
  npcID, extracted from `UnitGUID` — which Midnight masks. `NpcID` returned nil
  and the handler exited on its second line, every single cast, regardless of how
  good the database was. The whole feature has been silently dead under Midnight.

### Changed

- **Cast selection rebuilt on data that survives masking.** Three criteria, any
  one of which shows the bar:
  - **Important** — `C_Spell.IsSpellImportant`, the game's own classification.
    Requires no database of ours and covers dungeons we have not catalogued.
  - **Targeting you** — the cast is aimed at the player.
  - **Known** — the old npcID database, kept for the cases where the GUID is
    readable. It is now a bonus rather than a precondition.

### Added

- **Casts aimed at you are highlighted in red** and tracked live. A mob can
  switch target mid-cast, so targeting is re-evaluated four times a second rather
  than once at cast start — evaluating only at the start would miss exactly the
  cases that matter.
- Optional voice callout when a trash cast turns onto you, using the existing
  `target-on-you` line from both packs.
- Optional filter to show only casts the game classes as important, plus anything
  aimed at you — useful on noisy packs.

## [2.6.3]

Corpus extended to 27 encounters across 8 dungeons (Pit of Saron 658 added).

### Fixed

- **An encounter starting during the grace period was silently dropped** —
  a regression from 2.6.2. `Begin` gives up when a pull is still open, and the
  three-second grace period introduced in 2.6.2 makes that window common in
  Mythic+: combat drops after a boss, the group keeps moving, and the next boss
  engages before the previous pull has closed. The whole encounter was then never
  recorded. `ENCOUNTER_START` now closes any open pull before starting the new
  one, and `Begin` closes as a backstop rather than giving up.

- **Pulls below the observation minimum were discarded in silence.** A pull with
  fewer than four observations is not useful, but dropping it without a word
  looks exactly like the encounter never being recorded — and a boss is not
  replayed on demand. The drop is now reported with its count and the reason.

### Testing

- `Tools/test_finish.lua` gains the regression case: an encounter starting inside
  the grace period must be recorded with its own outcome.

## [2.6.2]

### Fixed

- **Kills were being recorded as "abandon".** When a boss dies, combat drops
  *immediately*, so `PLAYER_REGEN_ENABLED` usually arrives **before**
  `ENCOUNTER_END` — the only event carrying the actual outcome. The safety-net
  close fired first and overwrote the authoritative signal. In the captured
  corpus this hit 17 pulls out of 25, all of them recorded as abandoned while the
  bosses had in fact been killed.

  The fallback now waits three seconds before closing the pull, and
  `ENCOUNTER_END` cancels that deferred close. The pull keeps recording during
  the grace period, so nothing is lost either way.

### Testing

- `Tools/test_finish.lua` — six cases on a simulated clock: kill with combat
  dropping first, wipe announced by `ENCOUNTER_END`, abandon when
  `ENCOUNTER_END` never comes, direct kill, and the pull staying open during the
  grace period then closing after it.

## [2.6.1]

Corpus extended to 25 encounters across 7 dungeons (Skyreach 1209 added).

### Added

- **A missed encounter now says so.** With recording disabled, a boss could be
  fought and its data lost without a word — and a pull cannot be replayed. When
  an encounter starts inside the covered scope while recording is off, a single
  notice per session points at `/tmb learn on`. Once, not repeatedly: the goal is
  to inform, not to nag.

  `/tmb learn off` also states that the reminder will appear at the next dungeon
  or raid boss, and re-arms it, since switching off and forgetting to switch back
  on is exactly the case that loses data.

### Testing

- Skyreach's two recorded bosses join the regression fixture: both fold cleanly
  onto a single cycle (54 s and 39 s) across every ability, so they also serve as
  a check that regular encounters stay regular.

## [2.6.0]

Groundwork for building Season 2 data from scratch.

### Added

- **Per-pull phase folding.** Pooled folding is still tried first — when phases
  line up across pulls it is the strongest evidence available. When it fails,
  each pull is now folded on its own and the resulting series are combined
  position by position. A series is a sequence of intervals, so it survives a
  phase shift that destroys absolute positions. Verified: three pulls offset by
  16 s recover `{19, 63.8}` exactly, where pooled folding cannot.

  This is what lets confidence grow as pulls accumulate, which is the whole point
  of recording a fresh season.

### Corrected

- **The 2.5.1 diagnosis of Emberdawn was wrong.** I attributed the failure to
  inter-pull misalignment. It isn't: a single pull already fails to fold. The
  intervals run 36.4 / 15.8 / 36.4 / 18.2 / 31.6 — that is not a noisy cyclic
  series, it is a ~15.8 s cooldown *suspended* during the 16 s channelled
  intermission, so the long gaps are "cooldown + pause" with a varying pause.

  No amount of folding can describe that; the cyclic-series model is simply the
  wrong model for those encounters. The fix is to detect pause intervals — the
  intermissions are already identified as abilities — and subtract them before
  measuring the cycle. Documented in the module header with the corrected cause.

  Until then those encounters fall back to the median, flagged "no stable period
  found".

## [2.5.5]

### Fixed

- **Encounter names now come from `ENCOUNTER_START`, not from the journal.**
  The in-game diagnostic settled it: the journal loads, every `EJ_*` function is
  present, instance and encounter lookups work — but `EJ_GetEncounterInfoByIndex`
  returns **nil** for the dungeonEncounterID that Blizzard's documentation places
  in 7th position. The bridge between the two ID spaces does not exist by that
  route on this client.

  `ENCOUNTER_START` already carries the localized encounter name as its second
  argument. It is now stored with the pull, which removes the dependency on any
  ID matching. Spell lookups reach the journal by *name*, and only when that name
  is unique across the whole journal — an ambiguous name returns nil rather than
  risking another boss's abilities.

- `ResolveCurrentEncounter` compared a DungeonEncounterID against a name and
  could never match. It now takes its reference names from the engine's own
  encounter data, which is indexed on the same ID space as `ENCOUNTER_START`.

### Note

Captures recorded before this version carry no encounter name and will keep
showing `?`. New pulls will be named. `/tmb learn journal <key|name>` reports how
many encounters were indexed and traces a single lookup.

## [2.5.4]

### Fixed

- **The Encounter Journal is a load-on-demand addon.** Until the player opens it,
  the `EJ_*` functions may be absent or silent — which is why 2.5.3's ID
  translation still resolved nothing. `Blizzard_EncounterJournal` is now loaded
  explicitly before any journal walk.

### Added

- **`/tmb learn journal [id]`** — reports what each API actually returns instead
  of assuming: whether the journal addon loaded, which `EJ_*` functions exist,
  what `EJ_GetNumTiers` gives back, what a sample encounter lookup produces,
  whether the dungeonEncounterID really arrives in 7th position, and how many
  mappings got built. Pass an encounter ID to trace that specific lookup.

  This exists because the ID-space theory has now failed once in game. If loading
  the addon is not the whole story, this command says where it breaks rather than
  prompting another guess.

## [2.5.3]

### Fixed

- **Two encounter-ID spaces were being confused.** `ENCOUNTER_START` delivers a
  **DungeonEncounterID**; the `EJ_*` functions expect a **JournalEncounterID**.
  These are different namespaces — the `ENCOUNTER_END` documentation states it
  outright. Passing one for the other raises no error, it just fails silently:
  the boss name never resolves, `/tmb learn` prints the raw ID twice
  ("1895  1895"), and every analysis report said "spellID not resolved".

  `EJ_GetEncounterInfo` returns the dungeonEncounterID as its 7th value, so the
  reverse index can be built by walking the journal once — done lazily, out of
  combat, cached for the session. Unknown IDs return nil rather than a wrong
  name.

- **The recorder had no scope filter.** `ENCOUNTER_START` fires everywhere: old
  raids farmed solo, world bosses, delves, scenarios. Recording is now limited to
  party and raid instances, and skips encounters fought alone — those die in
  seconds, produce no usable cycle, and consume an encounter's pull quota.

### Added

- `/tmb learn` now separates encounters the engine covers from the rest, and
  shows each one's instance ID, so stray entries are identifiable at a glance.
- `/tmb learn purge` removes encounters outside the covered content.

### Note

The ID-space fix is derived from Blizzard's documentation and needs confirming in
game: after `/reload`, `/tmb learn` should show real boss names instead of
repeated numeric IDs. If names still fail to resolve, the journal walk is the
thing to instrument.

## [2.5.2]

Corpus extended to 22 encounters across 6 dungeons (Seat of the Triumvirate 1753
added). 1015 observations.

### Fixed

- **Marker events are now detected by observation, not by a fixed threshold.**
  2.5.1 treated durations above 300 s as identifiers rather than countdowns. The
  Triumvirate capture shows why a constant is the wrong tool: encounter 2065
  posts a 102 s duration on a 124 s pull, and its announced `fire` never falls
  inside the fight — it is a marker, but 102 is nowhere near 300. The same
  applies to the 104 s value on 3072.

  The rule is now the thing actually being asked: does the announced `fire` ever
  land inside the fight? Across the corpus, 8 groups out of 129 never do, and
  those are exactly the markers — including the two a fixed threshold missed. The
  300 s constant survives only as a fallback for a group seen once, where
  observation cannot decide.

  Practical effect on 2065: two abilities that were being read as broken timers
  are now recovered, one of them correctly split into two distinct spells.

### Testing

- 197 abilities extracted across the 22-encounter corpus without error. A new
  assertion covers the 102 s marker so a return to threshold-based detection
  fails the bench.

## [2.5.1]

Corpus extended to 18 encounters across 5 dungeons (Windrunner Spire 2805 added).

### Fixed

- **Out-of-scale durations were discarded as sentinels — they are real
  abilities.** Values above 300 s were filtered on the assumption they were
  encounter markers. On 3058, durations 999 and 1004 pair with a cast every
  single time (3.0 s and 5.0 s) and recur every ~66 s: three abilities of that
  boss were being thrown away.

  What is genuinely unusable is their *countdown*: the announced `fire` falls
  outside the fight in 18 cases out of 18. So the duration serves as a stable
  identifier while the ADD timestamp provides the timing. They are now kept as
  identities, anchored on the ADD rather than on `fire`.

- **Zero-duration timeline events are excluded from cycle analysis.** They fire
  at the instant they are posted (`fire == t`, three at once on 3058) — an
  immediate trigger signal, not an announcement, and with no duration identity.

### Known limitation

- **Phase folding mixes all pulls onto one cycle**, which assumes phases line up
  from pull to pull. That holds for a regular boss but breaks when a
  variable-length intermission shifts the rest of the fight: on Emberdawn the
  same ability folds to 7.6 s in one pull and 13.3 s in another.

  Accumulating pulls on those encounters therefore does not yet increase
  confidence — folding fails and the analysis falls back to the median, flagged
  "no stable period found". That is the intended behaviour (declare uncertainty
  rather than assert it), but it is not the final answer: the fix is to fold each
  pull separately and combine the resulting series. Documented in the module
  header so it is not rediscovered as a bug.

### Testing

- 155 abilities extracted across the 18-encounter corpus without error. The
  Emberdawn golden case now runs on two pulls (233 s wipe + 119 s kill), which is
  what surfaced the alignment limitation above.

## [2.5.0]

Corpus extended to 14 encounters across 4 dungeons (Academy 2526, Terrace 2811,
Maisara 2874, Nexus Point 2915).

### Added

- **Abilities sharing a timeline duration are now separated.** Encounter 3212
  posts eighteen events with a duration of 45 s; they are in fact *six distinct
  abilities*, each returning every 45 s at its own phase. Modelling them as one
  ability with a six-position series described the timing correctly but got the
  identity wrong — and identity is what carries role, severity and voice.

  The discriminator is the measured cast duration per position: six different
  spells have six different cast times. On the corpus the separation is
  unambiguous — 3.52 s of spread on 3212 against 0.02 s everywhere a single
  ability genuinely repeats. Two documented positions are enough to decide.

  Running this on a single pull of 3212 recovers cast-start offsets of
  **5, 12, 20, 28, 35 and 41 s** — exactly the values in `DurationRules.lua`,
  rediscovered without reading that file.

- Seeding-batch singletons are merged away. The pull-start batch announces each
  ability's *first* occurrence carrying its initial delay rather than its
  cooldown; those entries duplicate members produced by the split and are now
  dropped instead of appearing as six phantom one-observation abilities.

### Fixed

- **Pairing window widened from 0.05 s to 0.75 s.** It had been calibrated on
  Emberdawn, where the timeline ADD coincides with the cast start to within
  0.01 s. Other encounters delay the cast by more than half a second — up to
  0.61 s on Maisara — leaving those positions with no measured duration and
  blocking identity analysis. Widening requires picking the *nearest* unused
  cast rather than the first in range.

- Split members report their real first landing instead of the phase centre. A
  centre can cross the cycle boundary and report 0.5 s for an ability that
  actually lands at 45.5 s.

### Testing

- The corpus fixture grows from 8 to 14 encounters; 110 abilities extracted
  without error. A new assertion checks that 3212's 45 s group yields exactly six
  members with the expected offsets, so a regression on identity separation
  fails the bench rather than shipping.

## [2.4.2]

### Fixed

- **Taint error on every boss cast** (`Recorder.lua:144`, 118 occurrences in one
  session). The late boss-name resolution added in 2.3.7 read:

  ```lua
  if n and n ~= "" and not NS:IsSecret(n) then
  ```

  Lua evaluates `and` left to right, so `n ~= ""` runs *before* the guard. On a
  masked unit name that comparison raises — the very test meant to discard empty
  values was what crashed. This is the same mistake that was diagnosed and fixed
  in `readCast` three versions earlier and then reintroduced elsewhere.

- The same pattern in `Journal.lua:134` (`UnitName("boss"..i)` inside
  `ResolveCurrentEncounter`). It had not fired yet because the function is only
  reached when boss units are unavailable, but it was a latent crash.

### Added

- **`NS:SafeString(v)`**, the counterpart to `NS:SafeNumber`. Its absence is the
  reason the bug happened twice: with no helper, the "readable and non-empty"
  test is hand-rolled every time and the operand order eventually slips. Returns
  the string if readable and non-empty, `nil` otherwise, and never raises.

- **`Tools/test_taint.lua`** — static analyser for this class of bug. It relies
  on a distinction established from the crash report itself: in
  `if n and n ~= "" and not NS:IsSecret(n)`, the truthiness test `n and` did
  *not* raise — only `n ~= ""` did. Comparing a masked value to `nil` is
  therefore safe (different types); comparing it to a value of the *same* type is
  not. Only the latter is reported, so correct guards like
  `if x ~= nil and not IsSecret(x)` are not flagged. Verified both ways: it
  reports the original bug when reintroduced, and reports nothing on the fixed
  tree (3840 lines across 14 files).

## [2.4.1]

### Fixed

- **Duration-tie resolution no longer relies on a counter.** 22 of 41 encounters
  contain abilities sharing the same timeline duration — encounter 3212 has six
  at 45 s. Ties were resolved by a round-robin counter over `sequenceGroup`,
  which resolves by *counting*: a single missed `ADDED` desynchronised it and
  every subsequent callout in that group was wrong until the end of the pull.
  This is the same failure mode as index-based series detection, rejected in
  `Learn/Infer` for the same reason.

  The `sync` rules already carry what is needed: each ability's offset within the
  cycle (3212: 5, 12, 20, 28, 35, 41 s over 45 s). The phase of the incoming
  event is computed and the nearest member selected. A missed observation shifts
  nothing — the next phase is still correct. 8 of 9 sequence groups are fully
  covered by sync offsets; the ninth falls back to uniform spacing by
  `sequenceOrder`.

  **Drift tracking.** The nominal cycle is not the real one — a real capture
  shows 24.28 s where the data says 24. Uncorrected, the error accumulates and
  eventually crosses half the member spacing. The residual is tracked by a
  moving average with a low gain, and bounded to a quarter of the spacing so a
  doubtful resolution cannot drag the anchor.

  Where the phase cannot be computed (joined mid-encounter, so no pull anchor),
  the previous round-robin behaviour is kept as a fallback.

### Testing

- `Tools/test_phase.lua` replays the real capture of encounter 3074 (three
  abilities at 24 s, offsets 3 / 9 / 15) against both strategies. On the intact
  stream both score zero. With a single event dropped, round-robin reaches **17
  errors out of 17 remaining events** in the worst case and 8.5 on average;
  phase matching stays at **zero** in every case.

## [2.4.0]

### Fixed

- **The event bridge was never re-posted after a settings change.** What the game
  plays is baked in at the moment the sound is posted: file path (voice pack,
  voice on/off, generic fallback), volume, channel, trigger and colours. `Apply`
  only ran on login and zone change, so changing the voice pack or the volume
  slider mid-dungeon left the game playing the *old* files at the *old* volume
  until the next zone change. Every relevant option now triggers a re-post.

  Two safeguards make this safe rather than merely correct:

  - **Debounced** (0.4 s). Dragging a slider emits dozens of callbacks and a
    single post covers several hundred entries.
  - **Deferred out of combat.** `Apply` starts with `Clear`, which empties
    `_willPlay` — re-posting during an encounter would briefly convince
    `BlizzTimeline` that the game is no longer announcing, and the callout would
    fire twice. A refresh requested in combat is held and replayed on
    `PLAYER_REGEN_ENABLED`.

- Applying learned data with `/tmb learn apply` now refreshes the bridge and
  invalidates `BlizzTimeline`'s event-ID index, so freshly learned timings
  actually reach the game instead of waiting for a zone change.

### Added

- **`/tmb bridge` is now a real command.** The bridge settings existed in the
  saved profile with no way to change them in game: `on`/`off`, `son`,
  `couleurs`, `generique`, `declencheur 0|1|2`, `reposer`. Each toggle triggers a
  re-post.
- `/tmb bridge` and `/tmb learn` are listed in `/tmb aide` (both locales).
- `Tools/test_bridge.lua` — offline harness for the refresh logic (debounce,
  combat deferral, last-reason-wins, inactive module). Six cases.

## [2.3.9]

### Changed

- **Occurrences are anchored on the moment the mechanic lands**, not on the
  moment the server posts the event. A paired cast anchors on its completion; a
  timeline-only ability anchors on `fire`. Abilities seeded by the pull-start
  batch were previously given `firstSeenSec = 0`, which is not when anything
  happens — the Academy corpus now correctly reports 2 s, 5 s, 15 s, 40 s
  matching their announced durations.
- **Overfitting guard on series detection.** Each series position is a free
  parameter; with fewer than two observations per position, a long series
  "explains" noise. Emberdawn folded 9 occurrences into 6 positions across 3
  cycles — 1.5 points per bucket — and produced a six-value series where
  `{35.2, 15.8}` describes the same thing. Two observations per position are now
  required, and a single pull honestly reports low confidence instead.

### Added

- **Provenance tracking.** Every encounter definition now carries a
  `provenance` field (`exboss` / `littlewigs` / `bossreminder` / `observed` /
  `journal`), and `/tmb learn provenance` reports how much of the timing data
  still rests on third-party values. Data applied by `/tmb learn apply` is
  stamped `observed`, so the counter advances by itself.
- `PROVENANCE.md` states the situation plainly: neither EXBoss nor LittleWigs
  publishes a permissive licence — the LittleWigs repository has no LICENSE file
  at all, which means all rights reserved rather than freely reusable. Deleting
  the attribution comments would remove the paper trail without changing where
  the values came from; the document sets out the actual plan instead.

### Fixed

- The French voice pack credit is now consistent between the README and the
  in-game strings.

## [2.3.8]

Driven by a real corpus: 8 encounters across 2 dungeons (Academy 2526,
Terrace 2811), 340 observations. Every item below is a defect the corpus
exposed and no synthetic dataset had produced.

### Fixed

- **Circular clusters were measured as if sorted.** A phase bucket is a circular
  arc built in traversal order, so `last - first` could be negative, the
  wrap-around unwrap never triggered, and a perfectly regular ability was
  rejected. Seen on real data: occurrences at 0 / 44.00 / 88.02 with an estimated
  cycle of 44.01 — the 44.00 phase does not fold onto 0 because it is smaller.
  Each value is now unwrapped relative to the arc's first element, which is exact
  by construction and drops the half-cycle heuristic entirely.
- **Series ceiling was too low.** `MAX_PERIOD` was 4; the Academy corpus contains
  a five-value series — `{8.5, 9.5, 8.5, 7.5, 10.0}`, summing to exactly the 44 s
  loop. The pattern was inexpressible and collapsed to a mean 8.5 s cooldown,
  wrong every other cast. Raised to 8.
- **Instant casts all collapsed into one group.** An instant cast has zero
  duration and therefore no identity; every instant in an encounter merged into a
  single meaningless bucket (29 instants from five council members fused
  together). They are now separated by unit token.
- **Sentinel durations polluted the analysis.** Values above 300 s are encounter
  markers (enrage, phase aura), not cooldowns — 999 s and 975.9 s were observed.
  Filtered.
- **The dump verdict was misleading.** It counted instant casts as measured
  casts, so captures with zero usable duration still announced "both streams
  responding, identity can be (npcID, measured duration)". The verdict now
  distinguishes timed casts from instants and reports npcID availability.

### Changed

- A series that is a whole repetition of a shorter prefix collapses to that
  prefix: `{11, 3.5, 8.5, 10, 11, 3.5, 8.5, 10}` on a 66 s cycle is the 33 s loop
  written twice.

### Testing

- `Tools/corpus_real.lua` — the 8 real captures are now a permanent regression
  fixture, checked alongside the synthetic cases and the Emberdawn golden case.
  61 abilities extracted across the corpus without error.

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
