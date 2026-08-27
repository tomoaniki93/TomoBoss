# TomoBoss architecture — 2.8.0-beta5

The XML-loader hierarchy separates load order from runtime responsibilities while stable production Lua modules are moved only in isolated, testable steps.

## Load domains

- `Core/` — namespace, locale, DB, theme and media bootstrap.
- `Engine/` — encounter scheduler and pull countdown.
- `Engine/Phases/` — `PhaseDetector` (observation) + `StateResolver` (guarded state matching).
- `Engine/Encounters/` — encounter definitions grouped by Season 1 / Midnight Season 2 / raids through XML loaders.
- `UI/` — movers, bars, rings, countdown and flash text.
- `Data/` — interrupt, trash, map and duration-rule data.
- `Modules/` — existing production modules kept physically in place until each move is independently validated.
- `Integrations/` — optional external timer sources and normalized observation bridge.
- `Learn/` — observation, storage, inference, confidence and export.
- `Diagnostics/` — runtime validation and `/tmb doctor`.
- `Docs/` — architecture and coverage notes.

## Why XML loaders

`TomoBoss.toc` loads domains rather than enumerating every Lua file. Each XML uses ordered `<Include>` entries, preserving deterministic dependency order while keeping the TOC small.

## Timeline authority model

1. Blizzard `C_EncounterTimeline` remains the authoritative runtime source.
2. Static `spellID` rules resolve deterministic equal-duration sequences.
3. `StateResolver` may resolve selected state-dependent collisions only when its native runtime guard is complete.
4. P0-01 generic-safe is the mandatory fallback for ambiguity.
5. Better Timeline / BigWigs / DBM remain external observation/audit sources and never override a TomoBoss identity in beta5.

## PhaseDetector vs StateResolver

`PhaseDetector` learns batch signatures and confidence but remains observation-only. `StateResolver` does not blindly consume a HIGH label; it implements explicit per-encounter state machines and returns `nil` when their prerequisites are missing.

The first gated hand-off is Lightwarden Ruia 32 s: its state machine exists, but it cannot arm until Learn has at least two pulls and one stable phase anchor.

## beta5b Reference Catalog

`Data/ReferenceCatalog.lua` is an observation-only evidence layer loaded after external integrations and before Learn/Phase resolution. Static and state-aware resolvers may report decisions to it, but it cannot return a gameplay decision to those resolvers. Canonical mechanic IDs and physical cast aliases are modeled separately.
