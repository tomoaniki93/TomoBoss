# PhaseDetector — 2.8.0-beta5

`Engine/Phases/PhaseDetector.lua` remains deliberately **observation-only**.
It cannot create, rename, reschedule or voice a TomoBoss mechanic.

## Signals observed

- `ENCOUNTER_START` / `ENCOUNTER_END`
- native `ENCOUNTER_TIMELINE_EVENT_ADDED`
- `ENCOUNTER_TIMELINE_STATE_UPDATED`
- `INSTANCE_ENCOUNTER_ENGAGE_UNIT` / boss-unit count
- normalized external BossModBridge activity as a confirmation counter only

## Phase anchors

A phase anchor is not automatically a phase. It is a reproducible batch of native Timeline identities posted together by Blizzard. Exact duplicate durations inside a batch are collapsed for the signature.

The detector compares signatures across stored Learn pulls and classifies them as stable or tentative. This evidence may unlock a separately coded StateResolver gate, but PhaseDetector itself still makes no player-facing identity decision.

## beta5 hand-off

Lightwarden Ruia (3201) is the first explicit gate: the 32 s state rule remains locked until Learn contains at least two pulls and PhaseDetector finds at least one stable anchor. Even after the gate arms, the StateResolver still requires the correct runtime stage before it can return a specific event.
