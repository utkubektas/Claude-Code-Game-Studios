# Prototype Report: Core Repair Loop

**Date**: 2026-04-01
**Status**: Ready for manual playtesting

---

## Hypothesis

The "inspect → replace organ → press Run → success/failure" loop will be satisfying
as a standalone mechanic — before any VFX, audio, or narrative is added.

Specifically:
1. Tapping a slot, seeing it highlight, and selecting a replacement will feel responsive and clear
2. The "RUN" button will create anticipation
3. The cascade-activation success animation will produce a small but real emotional reward
4. The failure flash (showing *which* slot failed, not *why*) will prompt deduction rather than frustration

---

## Approach

Built a minimal Godot 4.6 scene (480×854 portrait) entirely in GDScript — no
binary assets, no audio, colored rectangles only. One puzzle: slot 2 has a
`vordex_emitter` where a `valdris_gate` should be. Player taps slot 2,
recognizes the mismatch (both colors are distinct), selects `valdris_gate`
from inventory, presses RUN.

**Shortcuts taken**:
- Hardcoded puzzle state (no Puzzle Data System or Registry)
- No physics, no drag-and-drop (tap-to-select + tap-to-place)
- Validation is `current_config == healthy_config` (no Biology Rule Engine graph traversal)
- No audio
- Placeholder colored rectangles as organ visuals
- No discovery journal, no progression

**Estimated build time**: ~1.5 hours

---

## What to Observe During Playtesting

Test with 3-5 people who have never seen the game. Watch for:

| Signal | Good | Bad |
|--------|------|-----|
| First tap — where do they tap first? | Tap the obviously-wrong slot (slot 2 - duplicate color) | Tap randomly, confused by layout |
| Selection clarity | "Oh, slot 2 is selected, now I pick a replacement" | Unclear what's selected or what to do next |
| RUN anticipation | Pause before pressing RUN; look at the configuration | Press RUN immediately without checking |
| Success reaction | Smile, lean in, want to try again | Neutral / no reaction |
| Failure reaction | "OK so that slot is wrong, let me try again" | Frustrated, wants a hint |
| Replay desire | Immediately interacts again after reset | Puts device down |

---

## Metrics (Fill in after playtesting)

- Median attempts to first solve: [ ]
- Did players understand the tap-select-replace flow without instruction: [ ] Y/N
- Did players notice slot 2 was wrong before pressing RUN: [ ] Y/N
- Success animation reaction (1-5 subjective): [ ]
- Failure feedback clarity (1-5 subjective): [ ]
- "Would you play more of this?" (Y/N): [ ]

---

## Recommendation: [TO BE DETERMINED after playtesting]

*Fill in after at least 3 playtest sessions.*

---

## If Proceeding

Production implementation changes from this prototype:

1. **Input model**: Prototype uses tap-select-tap-replace. Production may benefit
   from drag-and-drop. Test both — the GDD does not mandate one.

2. **Biology Rule Engine**: Prototype validates `config == healthy_config`. Production
   needs full graph traversal (already designed in `biology-rule-engine.md`). The
   prototype confirms the *loop* works; the production engine will add deduction depth.

3. **Visual language**: Colored rectangles work for the prototype but aren't
   alien-feeling. Production needs the bioluminescent sprite set. The organ
   color-coding system (each organ has a unique color) is validated here — keep it.

4. **Failure feedback**: Prototype shows *which slot* failed. Production should
   show *which connection* is wrong (e.g., the channel between slots goes dark).
   This adds deduction without adding explanation.

5. **Success animation**: Prototype cascades top-to-bottom with a 180ms delay.
   This feel should be preserved in production — the staggered reveal is more
   satisfying than simultaneous activation.

6. **Puzzle reset**: Auto-reset after 2.5s feels slightly rushed. Consider
   "Tap to retry" after success to give the player time to absorb.

---

## Lessons Learned

- [ ] Fill in after playtesting
