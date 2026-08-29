# TomoBoss

Boss timers, voice callouts and visual warnings for **World of Warcraft: Midnight 12.1**, with a focus on reliable behavior under the restricted encounter-data model.

## Current development focus

TomoBoss 2.8.0-beta5c keeps the validated P0-01/P0-02/P0-03 base and adds **guarded state-aware resolution** for a small set of Season 2 duration collisions. The new resolver only returns a specific mechanic when the current native Timeline state proves it; otherwise P0-01 intentionally keeps the warning generic.

## Core features

- Boss timer bars, visual warnings and FR/EN voice callouts.
- Official Blizzard `C_EncounterTimeline` integration.
- Re-sync-safe Timeline matching.
- Stable spellID duration rules for deterministic collisions.
- Guarded state-aware matching for selected multi-phase/state collisions.
- Interrupt tracking and dangerous-trash tracking.
- Central progress rings and movable UI elements.
- Custom alerts and sharing.
- Learn/Recorder pipeline for collecting live Midnight encounter observations.

## Commands

- `/tmb` — options.
- `/tmb pull [n]` — pull countdown.
- `/tmb unlock` — move UI elements.
- `/tmb kicks` — Mythic+ interrupt count.
- `/tmbv` — group version check.

## 2.8.0-beta5c safety model

- `PhaseDetector` stays **observation-only**.
- `BossModBridge` stays **diagnostic/audit-only**; Better Timeline, BigWigs and DBM never decide a TomoBoss identity.
- `StateResolver` is **guarded-active** only for explicitly modeled collisions.
- Missing, late, or contradictory runtime state returns `nil`, which deliberately falls back to the P0-01 generic warning.
- Lightwarden Ruia's 32 s collision remains controlled by the existing Learn gate and native 2.5 s P3 runtime marker; beta5c only reports those proofs separately.

See `Docs/ARCHITECTURE.md`, `Docs/SEASON2_COVERAGE.md`, `Docs/PHASE_DETECTOR.md` and `Docs/STATE_RESOLVER.md`.


## beta5c — Learn profile consolidation

Keeps the beta5b observation-only 4-source audit and adds persisted Learn profile evidence for The Blinding Vale. The previously observed ALT and confirmed MYTHIC native duration profiles are stored as separate diagnostic signatures. `/tmb doctor` now reports Learn profile counts, Ruia P1/P2/P3 evidence, native sentinel samples, and the Ruia runtime P3 guard separately. None of these diagnostics can alter bars, rings or voices.
