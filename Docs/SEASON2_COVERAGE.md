# Midnight Season 2 — Learn coverage snapshot

Reference snapshot used for the current audit (August 2026).

| Content | Instance | Learn data available | Current note |
|---|---:|---|---|
| Murder Row | 2813 | Yes | Mythic capture supplied |
| Den of Nalorakk | 2825 | Yes | Mythic capture supplied |
| The Blinding Vale | 2859 | Yes | ALT + confirmed Mythic profiles captured for all four bosses |
| Voidscar Arena | 2923 | Yes | Mythic capture supplied |
| Altar of Fangs | 2993 | Yes | Multiple pulls supplied |
| Ruby Life Pools | 2521 | Yes | Mythic capture supplied |
| Temple of Sethraliss | 1877 | Yes | Mythic capture supplied |
| King's Rest | 1762 | Yes | Mythic capture supplied |
| The Venomous Abyss | 3004 | Partial | Normal raid capture, encounter 3470 |
| Tides raid capture | 2987 | Partial | LFR capture, encounter 3379 |

## Confirmed signals from Learn captures

- Native timeline re-add/reinjection occurs during real encounters.
- Strict duplicate timeline entries can be emitted at the same timestamp.
- Very large native durations occur and must not become player-facing timers. The confirmed Mythic Ikuzz dump also contains `9999` and `10001` sentinel values.
- Some encounters can be useful with timeline-only identity even when no boss cast event is available.

The P0-01 guard remains the baseline for all further Season 2 work.


## 2.8.0-beta3 P0-02

- Beta2 Doctor result: 0/51 legacy S2 `eventID` rules resolved.
- Beta3 clears those legacy S2 rules at runtime.
- Deterministic collisions are now targeted by TomoBoss `spellID`.
- Adderis/Aspix, Council of Tribes and Mchimba keep generic-safe handling for state-dependent collisions.
- The Blinding Vale is now included in Doctor's S2 validator, but still lacks user Learn captures.
- BossModBridge remains observation-only.


## 2.8.0-beta4 P0-03

- PhaseDetector observes native Timeline batch signatures and state updates only.
- Stored Learn pulls are reused; no purge is required.
- Learn Confidence scores pull count and Infer quality without changing encounter data.
- Stable/tentative phase anchors are surfaced through `/tmb doctor`.
- The 8 generic-safe collision groups remain generic until a later state-aware resolver is proven by repeated pulls.

## beta5b reference coverage

- 28/28 Season 2 dungeon encounters represented in the external reference catalog.
- 143 EXBossData event mappings.
- 205 EXBossData duration/phase/sequence rows (204 map directly to an EXBossData spellID).
- 113 WeakAura boss-mod reference IDs.
- Reference data is audit-only and does not change collision coverage or player-facing behavior.


## beta5c Blinding Vale consolidation

- 3199 Mythic observed: `5/8/20/35`, followed by the ~45 s cycle.
- 3200 Mythic observed: `6/22/50`, repeated `29`, plus native sentinel values `9999/10001`.
- 3201 P1, P2 and P3 are now all observed. P3 includes native `2.5`, then `7.3/15.3/23.3/31.3`, then repeated `32`.
- 3202 Mythic observed: `4/14/26/40`, followed by the 50 s sequence.
- Previous alternate profiles remain valid Learn evidence and are not overwritten by the Mythic profile.
