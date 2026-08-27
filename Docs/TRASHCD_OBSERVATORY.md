# TrashCD Observatory — beta5d

This prototype answers one question first: which enemy cast information does Midnight 12.1 expose safely enough for a future predictive TrashCD voice engine?

## Inputs used

Only ordinary unit-cast/nameplate/combat-boundary events are observed. Every enemy cast payload is treated as secret until proven otherwise with `issecretvalue`. `castBarID` is stored only when it is a normal number; spellID is stored only when it is non-secret.

No enemy name, GUID or NPC identity is needed or stored.

## Reference matching

`Data/TrashCDReference.lua` is a diagnostic-only compact catalog generated from the user-provided EXBossData TrashCDData/TrashCDPreset files. It contains 8 maps and 138 spell rows. A reference row is considered only after Blizzard itself exposes the spellID as non-secret.

The reference catalog does not change existing TomoBoss TrashCD bars or boss behavior.

## Preview mode

`/tmb trashpreview on` is opt-in diagnostic behavior. After a real non-secret known cast, a stable reference cooldown may schedule one warning around T-3 seconds. This is deliberately conservative and exists to test whether the Midnight-safe approach is viable before connecting TomoBoss's recorded voice packs.

## Persistent StateResolver evidence

beta5d also archives the last runtime evidence for 2124, 2140, 2142 and 3201 into TomoBossRecorderDB. This means King's Rest and Ruia can be checked at the end of the dungeon instead of requiring `/tmb doctor` immediately after each boss.

## State evidence export

`/tmb statedump` opens a copyable dump of the last three stored runs for 2124, 2140, 2142 and 3201, including the exact state-aware spellID decisions and guarded fallbacks. This is diagnostic-only and does not affect resolution.
