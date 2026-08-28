# TrashCD Observatory — beta5d2

Observation-only prototype for Retail Midnight 12.x.

## Safety policy

- Never registers COMBAT_LOG_EVENT or COMBAT_LOG_EVENT_UNFILTERED.
- Never calls CombatLogGetCurrentEventInfo.
- Never serializes, stringifies, compares or reconstructs secret enemy spell identities.
- Never stores enemy GUIDs, castGUIDs or raw target-player names.
- castBarID is treated only as Blizzard's NeverSecret opaque cast identity.

## beta5d2 observations

For START/CHANNEL casts, TomoBoss records the event castBarID and compares it with the NeverSecret castBarID returned by UnitCastingInfo/UnitChannelInfo.

Cast-target observation uses UnitSpellTargetName only through pcall and secret guards. If the immediate result is NONE, beta5d2 probes again at 50 ms, 150 ms and 300 ms. A deferred result is accepted only while UnitCastingInfo/UnitChannelInfo still reports the same castBarID. If the cast changes or ends, the probe becomes STALE and no target is attributed.

Only coarse target classes are stored:
SELF / TANK / HEALER / DPS / GROUP / OTHER / SECRET / NONE.

## Commands

- `/tmb trashdoctor`
- `/tmb trashdump`
- `/tmb trashreset`
- `/tmb trashpreview on|off` (diagnostic preview only)

## Important metrics

- `castBarID-bearing events`: every observed event carrying a non-secret castBarID.
- `unique castBarIDs`: distinct opaque casts seen during the session.
- `CastBar API correlation`: event castBarID vs UnitCastingInfo/UnitChannelInfo castBarID.
- `Target immediate`: what UnitSpellTargetName returns at START/CHANNEL.
- `Target deferred recovery`: immediate NONE that becomes usable/secret while the same cast remains active.
- `Target final visibility`: final result after at most 300 ms.

This module is a candidate foundation for replacing the legacy TrashCD implementation, but beta5d2 remains observation-only unless the explicit diagnostic preview is enabled.
