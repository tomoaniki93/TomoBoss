# Data provenance

TomoBoss ships two very different kinds of data, and they carry very different
obligations.

**Code, interface, voice integration, engine** — written from scratch. No issue.

**Voice packs** — 185 French and 185 English `.ogg` files, produced for this
addon. No issue.

**Encounter timing data** — this is the part that needs care, and this document
exists so the situation is stated plainly rather than buried in file headers.

## Current state

Every encounter definition carries a `provenance` field. Run `/tmb learn
provenance` in game for the live count.

| Source | Encounters | Status |
|---|---|---|
| `exboss` | 29 | Third party — needs replacing |
| `littlewigs` | 28 | Third party — needs replacing |
| `bossreminder` | 10 | Third party — same upstream origin |
| `observed` | 0 | Produced by `/tmb learn` from my own pulls |
| `journal` | 0 | From Blizzard's Encounter Journal API |

## Why this matters

Neither project publishes a permissive licence.

The **LittleWigs** repository has **no LICENSE file at all**. Source being
readable on GitHub is not a grant of rights: with no licence text, ordinary
copyright applies and everything is reserved by default. "Open source" in the
colloquial sense is not a licence.

**EXBoss** is distributed as a packaged addon with no permissive terms either.

What was extracted here is numeric timing data and event identifiers, not code.
Bare facts enjoy weak protection in most jurisdictions. But this project is
maintained from France, where the EU database directive (96/9/EC) creates a
*sui generis* right covering substantial extraction from a database representing
substantial investment — and 264 duration rules across 41 encounters is
substantial. That is a stricter position than a US-based developer would be in.

None of this is legal advice. The practical risk is simpler than the legal one:
a CurseForge takedown does not come from a lawsuit, it comes from an author
filing a report, and the BigWigs maintainers are prominent and active.

## What is *not* the fix

Deleting the attribution comments. The values would have the same origin; only
the paper trail would be gone. Attribution is the honest part of the current
situation, not the problem.

## The plan

1. **Ask.** Open a polite issue on the LittleWigs repository asking whether
   extracting duration values for matching purposes, with attribution, is
   acceptable. Many addon authors say yes. Ten minutes converts a risk into a
   written permission.

2. **Regenerate.** `/tmb learn` produces timing data from my own pulls using
   three Blizzard-only sources: `C_EncounterTimeline`, `UNIT_SPELLCAST_*`
   ordering, and the Encounter Journal. Applied data is stamped
   `provenance = "observed"`, so the counter above moves on its own.

3. **Track.** `/tmb learn provenance` reports how many encounters still rest on
   third-party values. The target is zero.

Season 1 encounters are the priority: they are the oldest import and the ones
being played least, so replacing them costs the fewest pulls per encounter
removed.
