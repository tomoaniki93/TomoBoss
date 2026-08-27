# Reference Catalog — beta5c

`Data/ReferenceCatalog.lua` is an observation-only evidence layer.

It is derived from the user-provided Season 2 reference corpus:

- EXBossData `EncounterData.lua`: eventID -> physical spellID mappings.
- EXBossData `FixedTimelineBosses.lua`: duration, phase and sequence reference rules.
- WeakAura `DfWtfh5H_` v10: boss-mod/canonical mechanic IDs.
- TomoBoss runtime encounter definitions are compared dynamically.
- Learn/PhaseDetector remains the local observed evidence source.

## Authority

The catalog never creates, renames, reschedules, cancels or voices an alert.
Blizzard Timeline and TomoBoss encounter/state logic remain authoritative.

## Alias model

A canonical mechanic ID may differ from the physical cast spellID observed by another source.
Beta5c preserves this distinction instead of treating it as a conflict.

Confirmed example:

- Kyrakka & Erkhart: canonical `381862`, physical casts `381602` / `381605`.

Observation-only candidate:

- Lightblossom Trinity Thornblade: canonical `1235640`, EXBossData physical `1261276`.

## Runtime audit

StateResolver and TimelineRuleResolver report their already-made decisions to ReferenceCatalog.
The catalog compares those decisions to reference duration rules and recent normalized BigWigs observations.
A reference mismatch is diagnostic only; it cannot alter player-facing output.

## Ruia

Lightwarden Ruia has HIGH external reference confidence because EXBossData and WeakAura agree with the beta5a stage-3 sequence.
The runtime 32-second gate remains controlled by the existing Learn gate plus the native 2.5-second P3 marker. Beta5c reports three separate facts instead of conflating them: Learn gate state, persisted Learn P3/32-second evidence, and the runtime P3 marker/32-second observations.

## Learn duration profiles

`Learn/ProfileEvidence.lua` caches diagnostic-only native Timeline signatures from stored Learn pulls. For The Blinding Vale it keeps the previously observed ALT profile and the user-confirmed MYTHIC profile separate:

- 3199 ALT: `5/20/35` + `4/10` branch + ~`45`; MYTHIC: `5/8/20/35` + ~`45`.
- 3200 ALT: `6/20/40`; MYTHIC: `6/22/50` + `29`.
- 3201: P1 `0.5/5/18`, P2 `3/9`, P3 `2.5 + 7.3/15.3/23.3/31.3 + 32`.
- 3202 ALT: `4/18/32` + `45`; MYTHIC: `4/14/26/40` + `50`.

These signatures describe observed native duration profiles only; they never select a mechanic identity.
