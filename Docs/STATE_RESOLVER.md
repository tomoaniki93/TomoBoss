# StateResolver — 2.8.0-beta5

`Engine/Phases/StateResolver.lua` is the first player-facing consumer of encounter state in the 2.8 architecture.

## Safety contract

The resolver may return a specific encounter event only when its local state machine has enough evidence. If state is unknown, incomplete, or the addon attached mid-fight, it returns `nil`; `Modules/BlizzTimeline.lua` then uses its validated P0-01 generic-safe path.

External addons are never authoritative. BigWigs/DBM timers are compared after a local decision only to count confirmations/mismatches in `/tmb doctor`.

## beta5 modeled collisions

- **2124 Adderis and Aspix**
  - 45 s: deterministic four-event cycle.
  - 19 s: resolved only after a native boss-death state marker identifies which boss remains.
  - 5 s remains intentionally generic-safe because 12.1 re-sync/death batches can contain duplicate 5 s entries around the state marker.
- **2140 Council of Tribes**
  - 20 s: Barrel Through while Aka'ali's native Timeline bar is still alive; Call of the Elements after its explicit cancellation.
- **2142 Mchimba the Embalmer**
  - 30 s: Awakening Slam in the initial/post-Entomb group, Burn Corruption in the follow-up group.
- **3201 Lightwarden Ruia**
  - 32 s stage-3 cycle is implemented but gated. It requires at least two Learn pulls plus one stable phase anchor before it can arm.

## Static cycles added alongside StateResolver

Ziekket's shared Timeline branch is deterministic by duration family and remains better represented as static spellID counter rules:

- 45 s: Normal/Heroic three-event cycle.
- 50 s: Mythic four-event cycle.
