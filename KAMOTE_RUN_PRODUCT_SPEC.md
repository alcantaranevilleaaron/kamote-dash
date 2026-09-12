# KAMOTE DASH — Product Specification (Single Source of Truth)

Version: 0.1
Date: 2026-09-12
Author: Product Owner

Table of Contents
- Overview
- Confirmed Decisions vs Assumptions
- Core Gameplay Concept
- Product Vision
- Target Audience
- MVP Principles
- Initial MVP Features
  - Motorcycle Player
  - Endless Road / Environment
  - Kamote Collection
  - Obstacles
  - Increasing Difficulty
  - Score
  - Game Over
- Controls
- Visual Style
- Audio
- Filipino Identity
- Monetization (MVP stance)
- Progression (MVP stance)
- Future Game Modes
- Product Success Criteria
- Technical Direction
- Product Development Principles
- MVP vs Post-MVP vs Future
- Product Backlog
- Open Product Decisions (TBD)
- Change Log
- Instructions for AI Coding Agents

---

OVERVIEW
========

Kamote Dash is a mobile endless-runner game centered on Filipino motorcycle culture and the humorous concept of the "kamote rider."

The player controls a motorcycle traveling continuously through traffic and must decide how they want to ride:

- **Follow basic traffic rules** to stay on the safe path and collect **coins**.
- **Break basic traffic rules** and ride recklessly to access and collect **kamote**.

Coins represent responsible riding and provide positive rewards.

Kamote represents reckless riding. Collecting kamote increases the player's **Kamote Bar**, which progressively increases the difficulty and risk of the run. The more "kamote" the player becomes, the more chaotic and challenging the ride becomes.

This creates the game's central risk-versus-reward mechanic:

**Ride responsibly → Collect Coins → Lower Risk**

**Ride recklessly → Collect Kamote → Kamote Bar increases → Higher Difficulty → Higher Risk**

The game should continuously encourage players to decide whether to play safely for steady rewards or take increasingly risky actions for greater potential rewards.

Kamote Dash is inspired by the accessible gameplay format of endless runners such as Temple Run, but its core identity comes from the combination of motorcycle gameplay, Filipino traffic culture, humor, and the Kamote Bar risk/reward system.

This document is the authoritative product specification and single source of truth for the project. It is intended for product stakeholders, designers, artists, developers, and AI coding agents (e.g., GitHub Copilot) as the primary product reference before implementing or modifying product-related functionality.

GUIDELINES FOR THIS DOCUMENT
============================

- Clearly distinguish **confirmed decisions**, **assumptions**, and **TBD** items.
- Do NOT implement features from this specification without Product Owner approval and a clear task derived from the product backlog.
- Keep the MVP scope minimal and focused on validating the core gameplay loop.
- Do not treat coins and kamote as equivalent collectibles; they represent fundamentally different player behaviors.
- Preserve the core **Safe Riding vs. Kamote Riding** risk/reward mechanic when proposing or implementing gameplay features.
- The **Kamote Bar** is a core gameplay mechanic that controls increasing difficulty, not simply a counter for collected items.
- Avoid adding features that distract from or weaken the core gameplay loop.

CONFIRMED DECISIONS vs ASSUMPTIONS
==================================
Confirmed (from product intent and repository contents):
- The playable entity is a motorcycle (not a human character). (Product intent)
- The primary collectible is called "KAMOTE". (Product intent)
- Target platform for the initial MVP: iOS. (Product intent)
- Repository currently contains SpriteKit-based code (e.g., `GameScene.swift` in `Kamote Dash Shared`). Therefore SpriteKit + iOS is an available/valid technical direction to consider; this file does NOT mandate engine choice for the product but records what exists in the repo today. (Confirmed)
- The game will be a single-player endless-runner, arcade-style (Product intent)

Assumptions (explicitly called out so they can be validated):
- The initial MVP will use one simple environment (not multiple). (Product intent / MVP principle)
- Controls should be mobile-first (swipe left/right as preferred). (Product intent)

TBD (decisions not yet made — do not assume):
- Exact number of lanes and lane widths. (TBD)
- Exact scoring formula (distance vs kamote weighting). (TBD)
- Difficulty curve details (how speed increases over time). (TBD)
- Final motorcycle visual design and art style specifics. (TBD)
- Exact set of initial obstacles for the MVP (choose a small subset). (TBD)
- Monetization approach (deferred). (TBD)
- Analytics, leaderboards, social features. (TBD)

CORE GAMEPLAY CONCEPT
=====================
Core concept (updated):

Kamote Dash is built around a traffic-rule risk/reward system. The player rides a motorcycle through traffic and is repeatedly presented with a meaningful choice: follow the traffic rules and collect coins, or break the rules and collect kamote. Reckless play (kamote) increases the Kamote Bar, which in turn increases difficulty — creating a deliberate risk/reward loop that is central to the gameplay.

High-level loop (player-facing):
START RUN → RIDE THROUGH TRAFFIC → CHOOSE SAFE OR RECKLESS PATH → SAFE BEHAVIOR → COLLECT COINS OR RECKLESS BEHAVIOR → COLLECT KAMOTE → (IF KAMOTE) KAMOTE BAR ↑ → DIFFICULTY ↑ → CONTINUE → CRASH → SHOW RESULTS → RESTART

Core player goals:
- Survive as long as possible
- Make intentional risk/reward choices (safe vs kamote)
- Collect coins by following rules or collect kamote by breaking rules
- Manage the Kamote Bar to balance reward and difficulty

Key rules (high level):
- The motorcycle moves forward automatically.
- The player controls lateral movement (lane changes/position) to follow or break traffic rules.
- Collisions result in crash / end of run (MVP behavior).

Important design principle: Coins and Kamote are distinct mechanics tied to player behavior, not interchangeable collectibles. Do NOT model them as a single generic collectible in the product design.

PRODUCT VISION
==============
Create a fun, humorous, highly replayable Filipino-themed endless runner that becomes a recognizable casual mobile game/IP. The core product differentiator is the traffic-rule risk/reward system: players choose between responsible riding (collecting coins) or reckless kamote riding (collecting kamote) at the cost of increasing the Kamote Bar and difficulty. The product should be framed around that meaningful choice.

TARGET AUDIENCE
===============
Primary:
- Filipino mobile gamers, casual players.
- Those familiar with Filipino motorcycle culture and the humor around "kamote riders".

Secondary:
- Filipino diaspora
- Southeast Asian casual gamers
- General casual gamers attracted to humorous, culturally-themed experiences

MVP PRINCIPLES
==============
MVP must be deliberately small and focused on validating these questions:
- Is the core riding mechanic fun?
- Is avoiding obstacles satisfying?
- Is collecting kamote satisfying and visible?
- Does the Filipino theme add flavor without confusing new players?

Avoid building complex nonessential systems (multiplayer, live services, heavy progression) for MVP.

INITIAL MVP FEATURES
=====================
The following features describe the minimal scope for the first playable build (MVP). Each section has requirements and acceptance criteria.

1) Motorcycle Player (P0)
- Requirements:
  - Motorcycle automatically moves forward.
  - Player controls left/right movement (lane changes, or continuous lateral movement); input should feel responsive.
  - Recognizable Filipino-inspired visual identity (high level; final art TBD).
  - Clear collision bounds for hit detection.
- Acceptance Criteria:
  - Player can start a run and control lateral position to avoid obstacles and collect kamote.

2) Endless Road / Environment (P0)
- Requirements:
  - A repeating or procedural lane-based road that appears endless.
  - Simple, single environment for MVP (artistically coherent).
- Acceptance Criteria:
  - Player can ride indefinitely until collision; environment tiles loop or spawn procedurally without noticeable seams.
- Notes:
  - Candidate environments may reference Metro Manila or a barangay street, but the exact environment for MVP is TBD.

3) Coins & Kamote (P0)
-- Overview:
  - The collectible systems are split into two distinct mechanics tied to player behavior: Coins (reward for following traffic rules) and Kamote (reward for reckless behavior). These are not interchangeable and should be implemented as separate gameplay systems.

Coins (Product concept):
- Requirements:
  - Coins are placed to reward responsible riding (staying in lane, following direction, avoiding obstacles).
  - Collecting a coin provides immediate visual/audio feedback and increases score and/or a coin counter.
- Acceptance Criteria:
  - Collecting coins increments the player's coin count and/or score and plays a feedback effect.
- Notes:
  - Coins should be placed to encourage rule-following; do not randomly scatter coins everywhere. Exact coin economy (points vs currency) is TBD.

Kamote (Product concept):
- Requirements:
  - Kamote collectibles are placed in locations or along paths that require rule-breaking to obtain (between lanes, sidewalks, restricted paths, etc.).
  - Collecting kamote increases the Kamote Bar and provides a greater immediate reward (score/currency), but also increases difficulty via the Kamote Bar.
- Acceptance Criteria:
  - Collecting a kamote visibly increases the Kamote Bar and increments kamote count or score; visual/audio feedback communicates risk/reward.
- Notes:
  - Kamote must feel like a deliberate temptation. The player should understand they are trading increased difficulty for immediate reward.

Kamote Bar (core mechanic):
- Requirements:
  - The Kamote Bar measures accumulated reckless behavior during a run.
  - Collecting kamote increases the Kamote Bar.
  - The Kamote Bar should be distinct from score: its primary purpose is to influence dynamic difficulty.
- Acceptance Criteria:
  - Kamote Bar changes are visible to the player and tied to measurable changes in difficulty (see Dynamic Difficulty).
- Notes:
  - Exact Kamote Bar scale, thresholds, and whether it can decay over time are TBD. Do not treat the Kamote Bar as merely another score counter.

4) Obstacles (P0)
- Requirements:
  - Player must avoid a small, curated set of obstacles (2–4 obstacle types for MVP).
  - Obstacles must create interesting decision points and be clearly readable at mobile size.
- Candidate obstacle examples (choose a small subset for MVP): tricycle, stopped vehicle, pothole, pedestrian. (Initial set: TBD)

5) Dynamic Difficulty (P0)
- Requirements:
  - Difficulty should increase over time (natural progression) and be affected by the Kamote Bar level.
  - The Kamote Bar is the primary unique difficulty driver: as Kamote Bar increases, one or more difficulty parameters should become more challenging (speed, traffic density, spawn patterns, etc.).
- Acceptance Criteria:
  - Players perceive increasing difficulty over the course of a run and when their Kamote Bar increases.
- Notes:
  - Exact mappings from Kamote Bar to difficulty parameters (continuous vs tiered, which parameters change, thresholds) are TBD and should be addressed during design spikes. Do NOT implement speculative difficulty behaviors in the MVP without explicit backlog items.

6) Score (P0)
- Requirements:
  - Display a persistently visible score during runs.
  - Score should be simple: combination of distance + kamote (exact formula TBD).
- Acceptance Criteria:
  - Score updates in real-time and is shown at game-over.

7) Game Over (P0)
- Requirements:
  - Crash ends the run.
  - Game-over screen shows final score, kamote collected, distance/time, best score, and restart button.
  - Fast restart (tap to restart) is supported.
- Acceptance Criteria:
  - Player can immediately restart a run from the game-over screen.

TRAFFIC RULE / BEHAVIOR SYSTEM
==============================
The MVP must not attempt to simulate real-world traffic rules comprehensively. Instead, define a small, clear set of gameplay rules that are:

- Easy to understand
- Easy to detect programmatically
- Visually obvious
- Fun and consistent

Example conceptual rules (proposed / TBD):
SAFE (rule-following examples):
- Stay within designated lane.
- Stay on road.
- Follow intended direction.
- Avoid obstacles.

KAMOTE (reckless examples):
- Lane splitting (riding between vehicles).
- Sidewalk riding.
- Entering a restricted lane or path.
- Deliberately taking dangerous routes to shortcut or bypass traffic.

These example rules are proposed and must be finalized during design spikes. The implementation should use a minimal set of detectible conditions for the MVP to award coins or kamote.

CONTROLS
========
MVP preferred control scheme (mobile-first):
- Swipe left → move left (lane change or continuous lateral movement)
- Swipe right → move right

Acceptance:
- Controls should be responsive and understandable within seconds.

Fallback or future controls (Post-MVP):
- Tap-to-change-lane
- Tilt controls
- Alternate accessibility controls

VISUAL STYLE
============
Guidelines:
- Colorful, playful, humorous, and readable at small sizes.
- Strong silhouettes and exaggerated Filipino visual references (jeepneys, signboards, street vendors, etc.).
- Not photorealistic; stylized and suitable for marketing screenshots.
- Visual identity should make the title recognizable as "Kamote Dash".

AUDIO
=====
MVP audio (minimal set):
- Motorcycle engine loop (subtle)
- Kamote collect sound
- Collision/crash sound
- UI tap/confirm sounds

Optional future audio:
- Filipino-inspired background music
- Traffic ambient sounds
- Funny voice lines / memes

FILIPINO IDENTITY
=================
Design principles:
- Use Filipino cultural references and humor tied to kamote-rider stereotypes, traffic, and local landmarks.
- Avoid copyrighted or trademarked material.
- Keep references accessible to non-Filipino players (meaningful gameplay cues should not rely on local knowledge alone).

MONETIZATION
============
- Monetization is NOT a priority for MVP. Keep product decisions and technical hooks decoupled from monetization until post-MVP.
- Potential future monetization (P2/P3): rewarded ads, interstitials, cosmetic skins, IAPs. (TBD)

PROGRESSION
===========
- MVP: Minimal or no progression; primary loop focuses on score and replayability.
- Post-MVP: Skins, unlockable motorcycles, achievements, missions, daily challenges (P1/P2).

FUTURE GAME MODES
=================
Ideas (not part of MVP):
- Time Trial, Daily Challenge, Challenge Mode, Boss/Chase sequences, Multiplayer, Leaderboards.

PRODUCT SUCCESS CRITERIA
=========================
MVP is successful if:
- New players understand the game without long instructions.
- Players can start a run quickly and controls feel responsive.
- Core gameplay is fun and invites replay.
- Filipino identity is recognizable and adds charm.
- Players want to beat previous high scores.
- The game is presentable for short gameplay demos and App Store submission.
Additional gameplay-specific success criteria:
- Players understand that coins are associated with following traffic rules.
- Players understand that kamote is associated with breaking traffic rules.
- Players understand that collecting kamote increases the Kamote Bar.
- Players understand that a higher Kamote Bar makes the game harder.
- Players intentionally make risk/reward decisions during runs.
- Players feel tempted to collect kamote despite the increased risk.
- The Kamote Bar creates a meaningful "one more run" mechanic.
- The game feels distinct from a generic endless runner.

### Camera Perspective

**CONFIRMED FOR MVP**

Kamote Dash uses a **third-person, behind-the-motorcycle perspective**.

The camera follows the motorcycle from behind and slightly above, providing a forward-looking view of the road, traffic, collectibles, and environment.

The motorcycle should remain visible in the lower portion of the screen while the road and environment extend toward the horizon.

The perspective should communicate the feeling of actually riding a motorcycle through traffic rather than viewing the road from directly above.

Key visual characteristics:

- Motorcycle is visible as the player's primary entity.
- Road extends toward a visible horizon.
- Traffic appears ahead of the motorcycle.
- Three lanes remain visually distinguishable.
- Coins and kamote are visible as upcoming route choices.
- The environment surrounds the road and provides a sense of forward movement.

The reference experience is a third-person motorcycle endless runner, while the visual identity and environment should be unique to Kamote Dash.

TECHNICAL DIRECTION
===================
High-level guidance:
- Target platform: iOS
- Existing technology: Swift + SpriteKit
- Camera: Third-person, behind-the-motorcycle perspective
- Gameplay: Three-lane endless runner
- Environment: EDSA-inspired Metro Manila corridor
- Initial route concept: Mall of Asia ↔ SM North EDSA

Confirmed technical note:
- The repository contains SpriteKit / iOS files (e.g., `GameScene.swift`). This indicates an existing, actionable engine choice in the repo; teams may continue with SpriteKit or choose another engine, but do not change technology without explicit product approval.

The implementation should prioritize achieving the intended third-person gameplay experience while remaining practical within the existing SpriteKit architecture.

Do NOT assume additional backend services or live infrastructure for MVP.

PRODUCT DEVELOPMENT PRINCIPLES
=============================
Priority list for development decisions:
1. Gameplay over technology
2. MVP over feature creep
3. Fun over realism
4. Filipino identity over generic assets
5. Fast iteration
6. Maintainable code
7. Testable gameplay systems
8. App Store viability
9. Performance on supported iPhones
10. Ability to expand later

MVP vs POST-MVP vs FUTURE
=========================
MVP (P0):
- Motorcycle player
- Endless road/environment (single)
- Traffic / lane system (simple)
- Coin collection (reward for rule-following)
- Kamote collection (reward for reckless behavior)
- Rule-following detection
- Reckless behavior detection
- Kamote Bar
- Basic difficulty increase tied to Kamote Bar
- Score display and Game Over
- Swipe left/right controls
- Minimal audio feedback

Post-MVP (P1):
- Additional environments
- More obstacle types and variations
- Simple progression (skins, cosmetics)
- Improved audio and music
- Leaderboard integration (Game Center)

Future / Ideas (P2/P3):
- Multiplayer
- Ads & monetization framework
- In-depth progression and meta-systems
- Large content expansions

PRODUCT BACKLOG
===============
| ID | Feature | Priority | Status | Notes |
|----|---------|----------|--------|-------|
| PB-001 | Motorcycle Player (movement, collision) | P0 | Proposed | Core playable entity; define collision bounds and input mapping |
| PB-002 | Endless Road / Procedural Environment | P0 | Proposed | Single environment for MVP; seamless looping tiles |
| PB-003 | Coin system (placement, scoring, feedback) | P0 | Proposed | Coins reward rule-following; placement enforces safe path |
| PB-004 | Kamote system (placement, collect, Kamote Bar interaction) | P0 | Proposed | Kamote placed on reckless paths; increases Kamote Bar |
| PB-005 | Rule-following detection (safe path rules) | P0 | Proposed | Detect when player follows rules to award coins |
| PB-006 | Reckless behavior detection (kamote rules) | P0 | Proposed | Detect lane-splitting, sidewalk riding, restricted paths to award kamote and increase Kamote Bar |
| PB-007 | Kamote Bar (UI + difficulty hooks) | P0 | Proposed | UI meter and hooks for dynamic difficulty adjustments |
| PB-008 | Kamote-driven difficulty (mapping Kamote Bar to difficulty) | P0 | Proposed | Define effects (speed, spawn rate, traffic) TBD in design spike |
| PB-009 | Obstacles (initial small set) | P0 | Proposed | Pick 2–4 obstacle types (TBD specific types) |
| PB-010 | Swipe Controls (left/right) | P0 | Proposed | Mobile-first; responsive control feel |
| PB-011 | Score system (UI + final screen) | P0 | Proposed | Real-time score + Game Over display; combine distance/coins/kamote as defined (TBD)
| PB-012 | Game Over UI + Fast Restart | P0 | Proposed | Show final metrics and restart quickly |
| PB-013 | Basic audio (collect, crash, UI) | P1 | Proposed | Minimal sounds to support feedback |
| PB-014 | HUD (score, coin/kamote counts, Kamote Bar) | P1 | Proposed | Readable at mobile sizes |
| PB-015 | Visual polish (art pass) | P1 | Postpone | MVP uses placeholder assets until art is ready |
| PB-016 | Basic analytics hooks (events) | P2 | Backlog | Minimal telemetry TBD (privacy compliant) |
| PB-017 | Game Center / Leaderboard integration | P2 | Backlog | Post-MVP consideration |

OPEN PRODUCT DECISIONS (TBD)
=============================
The following items are explicitly undecided and must be resolved before implementation or should be validated during design spikes:
- Game engine/framework for final build (Confirmed: SpriteKit present in repo; decision whether to continue is TBD)
- Camera perspective: third-person, behind-the-motorcycle pseudo-3D view — Confirmed
- Number of lanes vs continuous lateral movement — TBD
- Exact scoring formula (distance vs kamote weighting) — TBD
- Kamote scoring values and combo behavior — TBD
- Difficulty curve parameters and pacing — TBD
- Initial obstacle set (exact types for MVP) — TBD
- Initial environment art direction (which Filipino environment to depict) — TBD
- Final motorcycle visual design / silhouette — TBD
- Art direction specifics (palette, level of exaggeration) — TBD
- Sound direction and music licensing approach — TBD
- App name finalization beyond "Kamote Dash" (branding details) — TBD
- Monetization model and timing — TBD
- Analytics and telemetry design (privacy & data retention) — TBD
- Game Center / social integration — TBD

Additional open product decisions (TBD):
- Exact traffic rules represented in MVP (which rules to include and how to express them in-game) — TBD
- Exact conditions that qualify as reckless behavior (precise detection rules) — TBD
- How coins are spawned and visually placed to reinforce safe paths — TBD
- How kamote is spawned and visually placed to tempt reckless play — TBD
- Whether coin and kamote paths can overlap (and under what conditions) — TBD
- Exact Kamote Bar scale and units (how many kamote = full bar) — TBD
- Whether the Kamote Bar can decay over time or require active mitigation — TBD
- Exact difficulty thresholds and mappings from Kamote Bar to difficulty changes — TBD
- Whether difficulty increases continuously or in discrete tiers — TBD
- Maximum Kamote Bar level and any special behavior at maximum — TBD
- Exact rewards/value for coins (points vs currency) — TBD
- Exact rewards/value for kamote (points vs currency vs multipliers) — TBD
- Whether reckless behavior produces additional score multipliers or bonuses — TBD
- Whether crashing under high Kamote level has any special consequences or scoring differences — TBD

CHANGE LOG
==========
| Date | Decision | Reason |
|------|----------|--------|
| 2026-09-12 | Created KAMOTE_RUN_PRODUCT_SPEC.md as the initial product specification / single source of truth | Project kickoff: capture product vision, MVP scope, backlog, and open decisions |
| 2026-09-12 | Official product name confirmed as "Kamote Dash" | Product naming decision to standardize references in the spec |
| 2026-09-12 | Core gameplay revised to Safe Riding vs Kamote Riding (traffic-rule risk/reward) | Product Owner moved design toward a unique Kamote Bar mechanic to create meaningful decisions |
| 2026-09-12 | Coins introduced as reward for following traffic rules | Distinguish coins from kamote; coins represent responsible riding rewards |
| 2026-09-12 | Kamote and Kamote Bar introduced as risk/difficulty mechanics | Kamote represents reckless riding and increases the Kamote Bar which affects difficulty |
| 2026-09-12 | Camera perspective confirmed as third-person behind the motorcycle | Product Owner confirmed the target gameplay composition should feel like riding forward through traffic |

INSTRUCTIONS FOR AI CODING AGENTS
=================================
This section is deliberately targeted at AI coding agents (Copilot-like assistants) that will implement code from the product backlog.

Before you implement anything, follow these rules:

- Read `KAMOTE_RUN_PRODUCT_SPEC.md` before implementing product-related changes.
- Treat this file as the primary product reference. If a code-level request conflicts with this document, flag the conflict to the human reviewer before proceeding.
- Do not expand the MVP scope without explicit approval from the Product Owner.
- Do not assume any TBD decision is finalized. If a decision is marked TBD, ask or create a discrete design task to resolve it.
- Keep product decisions (this document) separate from technical implementation details in code. Implementation should reference this file for product intent.
- Update this document when an important product decision is explicitly approved and provide a short rationale and date in the Change Log.
- Do not silently change product requirements.
- Prefer small, incremental implementations that can be playtested quickly.
- Preserve the ability to test the core gameplay independently (minimize coupling until systems are proven).
- When proposing new features or design changes, always classify them as MVP / Post-MVP / Future and annotate expected priority (P0/P1/P2/P3).
- Include test cases or playtest acceptance criteria with each implementation PR that touches gameplay.
 - Do not treat coins and kamote as equivalent collectibles: implement separate systems and UI representations for each.
 - Do not implement a generic collectible system that ignores the behavioral meaning of coins versus kamote.
 - When implementing gameplay tasks, reference the specific PB- IDs in the Product Backlog and keep PRs linked to those PB- items.

QUALITY CHECK (for implementers and agents)
- Confirm no contradictory requirements exist across the spec.
- Avoid product scope creep in PRs: link each PR to a PB- ID from the backlog.
- Ensure UI is readable on small iPhone screens (acceptance metric: readable at iPhone SE class sizes).

---

Appendix: Quick References
- Root backlog and PB- IDs live in the "Product Backlog" section of this file.
- Update the Change Log for any product decision changes.



