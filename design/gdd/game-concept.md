# Game Concept: Specimen

*Created: 2026-03-26*
*Status: Draft*

---

## Elevator Pitch

> It's a logic puzzle game where you diagnose and repair broken alien organisms —
> creatures from unknown worlds whose biology follows rules you've never seen —
> then press run to watch them either come alive or fail spectacularly.

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | Logic puzzle / deduction |
| **Platform** | Mobile (Android + iOS) |
| **Target Audience** | Explorer and Achiever players who love deduction and mastery |
| **Player Count** | Single-player |
| **Session Length** | 10-20 minutes (3-5 puzzles per session) |
| **Monetization** | Premium (TBD — consider one-time purchase + optional DLC packs) |
| **Estimated Scope** | Medium (5-8 months to V1, 3 months to MVP) |
| **Comparable Titles** | Opus Magnum, Strange Horticulture, Baba Is You |

---

## Core Fantasy

You are a xenobiologist operating a field station at the edge of known space.
Alien specimens arrive broken, dying, or inert — creatures whose biology was
never documented, whose organs you've never seen before, whose systems follow
rules you must discover entirely through observation and experiment.

When you fix one, it wakes up. When you get it wrong, it fails in a way that
teaches you exactly why.

You're not just solving puzzles. You're building mastery over an alien science
from scratch — every creature type a new branch of knowledge earned, not given.

---

## Unique Hook

> Like Opus Magnum, AND ALSO the rules of the machine are alien — you must
> first *discover* the biology before you can fix it, turning every new
> creature type into a deduction challenge as well as a repair challenge.

No prior biology knowledge is required. The biology is invented. The player's
knowledge accumulates through play, not instruction.

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Sensation** (sensory pleasure) | 3 | The "run" moment — bioluminescent activation or catastrophic visual failure |
| **Fantasy** (make-believe, role-playing) | 4 | The xenobiologist identity; alien world framing |
| **Narrative** (drama, story arc) | 5 | Ambient environmental story — who sends specimens? where do they come from? |
| **Challenge** (obstacle course, mastery) | 1 | Every puzzle has a discoverable correct answer; difficulty scales with new organ types |
| **Fellowship** (social connection) | N/A | Single-player; no social hooks at MVP |
| **Discovery** (exploration, secrets) | 2 | Alien biology rules are learned through play; new creature types are mysteries |
| **Expression** (self-expression, creativity) | N/A | No open-ended expression — puzzles have target states |
| **Submission** (relaxation, comfort zone) | N/A | This is not a relaxation game — challenge and discovery dominate |

### Key Dynamics (Emergent player behaviors)

- Players will form hypotheses about alien biology rules and test them deliberately
- Players will replay failed puzzles to understand *why* the failure happened before attempting again
- Players will feel reluctance to press "run" until confident — building anticipation
- Players will carry knowledge from one creature type to the next, noticing what transfers

### Core Mechanics (Systems we build)

1. **Specimen viewer** — inspect an alien creature's organ layout; visual indicators show malfunction location
2. **Organ repair system** — replace, reconnect, or reorient biological components from a limited part vocabulary
3. **Run simulation** — press run to execute the biology; systems pass or cascade-fail with visible feedback
4. **Discovery journal** — passive accumulation of known rules; shows patterns the player has verified

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** (freedom, meaningful choice) | Player chooses which component to replace and how; multiple diagnostic paths for some puzzles | Supporting |
| **Competence** (mastery, skill growth) | Mastering alien biology rules across creature types; the "mastery click" when a complex repair works | Core |
| **Relatedness** (connection, belonging) | Ambient narrative — relationship with the unknown world the specimens come from | Supporting |

### Player Type Appeal (Bartle Taxonomy)

- [x] **Achievers** (goal completion, collection, progression) — How: completing puzzle sets; filling the discovery journal
- [x] **Explorers** (discovery, understanding systems, finding secrets) — How: the alien biology is literally a system to discover and map
- [ ] **Socializers** (relationships, cooperation, community) — Not in scope at MVP
- [ ] **Killers/Competitors** (domination, PvP, leaderboards) — Not in scope

### Flow State Design

- **Onboarding curve**: First 3 puzzles use a single organ type with obvious symptoms. Rules are never stated — they emerge visually from failure and success.
- **Difficulty scaling**: New creature types introduce new organ types with unknown rules. Each type starts easy (obvious malfunction) and escalates (subtle or multi-system failures).
- **Feedback clarity**: Successful run = bioluminescent activation sequence. Failed run = specific visual failure at the faulty organ, making the cause readable.
- **Recovery from failure**: Immediate retry; no lives system. Failure is educational — the visual shows *where* it broke, not *why*, leaving deduction to the player.

---

## Core Loop

### Moment-to-Moment (30 seconds)
Tap to inspect an organ. Tap to select a replacement from inventory. Drag to reconnect a severed channel. The act of examining and placing biological components — touching a strange living system and deciding what's wrong with it.

### Short-Term (5-15 minutes)
One puzzle = one specimen. Examine the creature, identify the fault through visual clues and knowledge of biology rules, repair it, press run. 2-3 attempts on average before a clean solve. One puzzle feels complete in 3-5 minutes; a session is 3-5 puzzles.

### Session-Level (30-120 minutes)
A session progresses through a set of related specimens (same creature type, escalating complexity). The session ends when the creature type's puzzle set is complete — the player has "understood" this organism. A new creature type is unlocked as the hook for next session.

### Long-Term Progression
Players build expertise over creature archetypes. Each new archetype is a new branch of alien biology with new organ types and new rules. The discovery journal fills with verified knowledge. The long-term goal: master all creature types and uncover the ambient narrative of where the specimens come from.

### Retention Hooks
- **Curiosity**: The next creature type is visually previewed but locked — its biology unknown
- **Investment**: The discovery journal grows; the player's accumulated knowledge is visible
- **Mastery**: Harder difficulty variants of solved puzzle sets ("minimal parts", "timed diagnosis") for replay value
- **Narrative**: Ambient fragments in solved specimens hint at a larger mystery about the world

---

## Game Pillars

### Pillar 1: Discovery Through Deduction
The player learns alien biology by observing and experimenting — never by reading tooltips or tutorials. Every rule reveals itself through play. The joy of understanding is the reward.

*Design test: If we're debating between a tutorial tooltip and letting the player experiment, this pillar says we always let them experiment.*

### Pillar 2: Alien Logic, Learnable Rules
The biology is strange but internally consistent. Once the player understands a rule, they can predict outcomes. Rules never change mid-game; no hidden exceptions; no randomness in puzzle states.

*Design test: If we're debating between a "surprising" rule exception and consistency, this pillar says consistency wins.*

### Pillar 3: The Run Button Moment
Pressing "run" must always produce a memorable visual outcome. Success (creature activates) and failure (system collapse) are both worth watching. The spectacle IS part of the reward — the run button is the game's emotional peak.

*Design test: If we're debating between a subtle failure indicator and a dramatic one, this pillar says dramatic, always.*

### Pillar 4: Mastery Is Earned, Not Given
Every puzzle has a discoverable correct answer accessible through logic alone. No luck, no randomness in the core puzzle state. A player who thinks hard enough will always find the solution.

*Design test: If we're debating between adding randomness for variety and designing a hand-crafted challenge, this pillar says design the challenge.*

### Anti-Pillars (What This Game Is NOT)

- **NOT a biology lesson**: The alien biology is entirely invented. No real-world biology knowledge should help or hurt the player. This would compromise *Alien Logic* and break immersion for non-biologists.
- **NOT an action game**: No real-time pressure, no reflexes required. This is a thinking game for mobile — it must be pauseable, resumable, and playable in short bursts. Action mechanics would compromise the deduction focus.
- **NOT a creative sandbox**: Every puzzle has a target state. The player is solving a specific problem, not freely expressing themselves. Open-ended building without success/fail states would undermine the mastery pillar.

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| **Opus Magnum** | Visual satisfaction of a working machine; elegance as a goal | Our machine is *biological*, not mechanical; we add deduction as a layer on top of repair | Proves the "watch it run" emotional moment works; ~500k sales validating the audience |
| **Strange Horticulture** | Deduction over an invented system; strange aesthetic; mobile-friendly sessions | We have explicit right/wrong states per puzzle; Strange Horticulture is more open-ended | Proves unusual subject matter + deduction works on mobile |
| **Baba Is You** | Rule discovery through play; no explicit tutorials; player infers everything | We don't rewrite rules mid-play; biology is consistent, not manipulable | Proves players will engage deeply with systems they have to figure out themselves |

**Non-game inspirations**:
- Xenobiology fiction (Roadside Picnic, Annihilation) — the feeling of encountering biology that doesn't follow human intuition
- Medical diagnosis (the deductive structure of "here are symptoms, find the cause")
- Clockwork automata and anatomical illustration — visual vocabulary reference

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | 20-40 |
| **Gaming experience** | Mid-core to hardcore puzzle players |
| **Time availability** | 15-30 minute sessions on commute or evenings; occasional longer weekend sessions |
| **Platform preference** | Mobile (their primary gaming device for puzzle games) |
| **Current games they play** | Opus Magnum / SpaceChem, Strange Horticulture, The Room series, Baba Is You |
| **What they're looking for** | A puzzle game with depth and original ideas — not match-3, not another incremental; something that makes them think |
| **What would turn them away** | Timers, energy systems, pay-to-win mechanics, real-time pressure, artificial difficulty spikes |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Recommended Engine** | **Godot 4.6** — already configured; 2D pipeline is ideal; excellent Android/iOS export; GDScript for solo dev velocity |
| **Key Technical Challenges** | Biological simulation must be consistent and readable; visual failure sequences need particle/animation system; touch UI for organ placement must feel precise |
| **Art Style** | 2D stylized — bioluminescent alien palette; modular creature anatomy; strange but legible |
| **Art Pipeline Complexity** | Medium — custom 2D art; modular organ components (reused across creature types); particle effects for run sequences |
| **Audio Needs** | Moderate — ambient alien soundscape; distinct audio signatures for successful activation vs. failure cascade; minimal music |
| **Networking** | None |
| **Content Volume** | MVP: 10 puzzles, 1 creature type, 4 organ types. V1: 30 puzzles, 3 creature types, 10 organ types. Full: 60+ puzzles, 6 creature types |
| **Procedural Systems** | None in core puzzles (all hand-authored). Optional: procedural failure visual generation. |

---

## Risks and Open Questions

### Design Risks
- **Rule learning curve may spike**: The tutorial-free approach is a core pillar, but early players may hit a wall if the first creature's rules aren't legible enough from visual feedback alone
- **Puzzle authoring is slow**: Designing each puzzle to have exactly one logical solution, with visual clues that don't over-hint, is time-intensive — this is the #1 production bottleneck
- **Discovery journal scope creep**: The journal could become a second game if not scoped tightly

### Technical Risks
- **Simulation consistency**: Alien biology rules must behave deterministically across all edge cases — bugs in the simulation undermine the "learnable rules" pillar
- **Touch precision on small screens**: Organ placement UX may be frustrating if not carefully designed for mobile (especially small organ components)
- **Run animation quality**: The "run button moment" lives or dies on visual polish — this requires good particle/animation work which is time-consuming for a solo dev

### Market Risks
- **Mobile premium pricing resistance**: The target audience exists, but premium mobile puzzle games require strong word-of-mouth and a compelling store page
- **Discoverability**: Alien/xenobiology aesthetic is distinctive but may not be searchable on app stores — needs strong visual identity for screenshots/trailer

### Scope Risks
- **First-time developer**: Many systems being designed simultaneously (simulation, UI, art pipeline, level authoring) — risk of underestimating integration time
- **Art bottleneck**: Solo dev must handle both code and art; bioluminescent 2D art is achievable but non-trivial

### Open Questions
- **Q: Is the tutorial-free onboarding achievable?** → Answered by MVP playtesting: do 5 external players understand the first puzzle's rules without being told?
- **Q: How long is the "run button moment" satisfying?** → Answered by prototype: record player facial expressions and repeat-run behavior during first playtest
- **Q: What is the right difficulty curve for first creature type?** → Answered by playtesting 10-puzzle set with target audience

---

## MVP Definition

**Core hypothesis**: Players find the diagnose-and-repair loop engaging — specifically, that the combination of deduction (figuring out what's wrong) and repair (fixing it) followed by the run sequence creates a satisfying, repeatable moment.

**Required for MVP**:
1. 10 hand-authored puzzles using a single creature type with 4 organ types
2. Visual malfunction indicators — player can see *something* is wrong, must determine *what*
3. Organ replacement mechanic — touch to select from limited inventory, drag to place
4. Run simulation — deterministic pass/fail with distinct visual outcomes for success and failure
5. Basic discovery journal — passively logs verified biology rules the player has discovered

**Explicitly NOT in MVP** (defer to later):
- Narrative framing / ambient story — pure puzzle experience first
- Multiple creature types — validate the loop with one before designing the second
- Difficulty variants / replay modes — test core loop first
- Audio polish — placeholder audio acceptable; do not block on SFX
- Store/monetization setup — validate concept before distribution planning

### Scope Tiers (if budget/time shrinks)

| Tier | Content | Features | Timeline |
| ---- | ---- | ---- | ---- |
| **MVP** | 10 puzzles, 1 creature type, 4 organ types | Core loop: inspect, repair, run | ~10-12 weeks |
| **Vertical Slice** | 20 puzzles, 2 creature types, 7 organ types | + Discovery journal, basic narrative framing | ~20 weeks |
| **V1 / Alpha** | 30 puzzles, 3 creature types, 10 organ types | All core features, rough polish | ~6 months |
| **Full Vision** | 60+ puzzles, 6 creature types, full narrative | All features, polished, store-ready | ~10-12 months |

---

## Next Steps

- [ ] Get concept approval from creative-director
- [ ] Fill in CLAUDE.md technology stack based on engine choice (`/setup-engine`)
- [ ] Create game pillars document (`/design-review` to validate)
- [ ] Decompose concept into systems (`/map-systems` — maps dependencies, assigns priorities, guides per-system GDD writing)
- [ ] Create first architecture decision record (`/architecture-decision`)
- [ ] Prototype core loop (`/prototype core-repair-loop`)
- [ ] Validate core loop with playtest (`/playtest-report`)
- [ ] Plan first milestone (`/sprint-plan new`)
