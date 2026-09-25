# Anarchyball: The Game
## Gameplay Rules - Canonical implementation rules for Codex

**Status:** Preproduction gameplay specification - v0.3
**Last revision:** 2026-09-12
**Companion document:** `docs/PROJECT_PLAN.md` rev. 0.4
**Target engine:** Godot 4.x stable  
**Language:** Typed GDScript  
**Primary target:** Windows/Steam; Android and iOS supported by the input and UI architecture from the start.

> **Authority rule:** When this file conflicts with general gameplay wording in `PROJECT_PLAN.md`, this file governs the implementation of moment-to-moment gameplay. Narrative/world direction remains governed by `PROJECT_PLAN.md`.

---

# 1. Purpose of this document

This file translates the project vision into rules Codex can implement and test. It is intentionally closer to an engineering gameplay specification than to a narrative GDD.

The document must answer, for any gameplay feature:

- what the player is allowed to do;
- what the game must prevent;
- which state owns the decision;
- what feedback is required;
- what is data-driven;
- what is testable;
- what remains a tunable value rather than a hard design commitment.

The project follows a simple priority order:

1. **Movement must feel good.**
2. **Combat must be readable and mechanically coherent with non-aggression.**
3. **Classes must solve the same obstacles differently.**
4. **Ideological concepts must appear as level rules and obstacles.**
5. **Dialogue explains or complicates what the player already experienced.**

---

# 2. Gameplay invariants

These are hard rules. Codex must not silently violate them to simplify implementation.

## GR-CORE-001 - AnarchyBall cannot initiate ordinary aggression

The normal player moveset must not provide a viable route for attacking neutral or merely disputed characters.

The game is **not** a karma system where aggression is possible but costs reputation. Damage eligibility is structurally gated by encounter state.

## GR-CORE-002 - The player does not need to absorb the first hit

A hostile actor becomes a valid defensive target when an aggressive action is sufficiently immediate, even before hit points are lost.

A guard receiving an order to seize the player, a collector beginning forced confiscation, or a weapon attack entering its committed telegraph can transition to `AGGRESSOR` before damage occurs.

## GR-CORE-003 - Defense of third parties is valid gameplay

The player may intervene against aggression directed at an NPC, community or established protected object. Rescue encounters are a primary source of proactive action.

## GR-CORE-004 - Philosophical disputes are not automatically combat permission

A disagreement about property theory, occupancy-and-use, original appropriation, contract interpretation or similar doctrine enters `DISPUTED` unless the encounter has already established an unambiguous aggressive act.

## GR-CORE-005 - Surrender immediately ends offensive target validity

Once a character enters `SURRENDERING`, damaging that character is no longer valid gameplay. Player attacks must cancel, miss or apply no offensive effect to that target.

## GR-CORE-006 - Every class can finish required content without violating the non-aggression rule

Contractor, Runner, Tinkerer, Trader and Agorist are action styles, not moral alignments.

## GR-CORE-007 - Ideology changes gameplay, not only dialogue or art

A world or ideological sub-zone is not complete until it has at least:

- one observable rule;
- one physical obstacle or traversal consequence;
- one counterplay path;
- one encounter that demonstrates the underlying idea.

## GR-CORE-008 - No required encounter has only one class-specific solution

Class-specific routes may be easier, cheaper, safer or reward secrets, but all mandatory content must have a class-agnostic baseline solution.

## GR-CORE-009 - Defeating a ball does not imply killing it

Humanoid/ball opponents normally resolve through surrender, disarm, stun, retreat, capture or loss of resolve. Machines and clearly disposable hostile constructs can be destroyed.

## GR-CORE-010 - The game must remain an action-platformer

No ideological mechanic may require persistent economic simulation, population management, production timers, territory administration or 4X systems in order to complete normal levels.

---

# 3. Player action model

## 3.1 Input actions

Gameplay code consumes abstract Godot input actions rather than device-specific keys.

Required actions for the first vertical slice:

```text
move_left
move_right
jump
crouch_or_drop
attack_primary
attack_secondary
aim_x / aim_y or equivalent vector
ability_1
ability_2
interact
dodge_or_dash
pause
```

Later optional actions:

```text
weapon_next
weapon_previous
quick_item
class_utility
map
codex
```

Keyboard, gamepad and touch map into the same action layer. Gameplay scripts must not branch on `keyboard`, `Xbox`, `touch`, etc. unless the difference is purely UI/presentation.

## 3.2 Aim abstraction

The gameplay layer receives an `aim_vector` and does not own the final aiming scheme.

Supported control strategies may include:

- mouse / right-stick free aim;
- directional snapping;
- assisted mobile aim;
- optional target assist.

The vertical slice should use the simplest scheme that provides reliable shooter testing on desktop while preserving the abstraction for mobile.

## 3.3 Player state machine

Minimum locomotion/action states:

```text
GROUND
AIR
DASH
INTERACT
HURT
STUNNED
DISABLED
```

Combat/class actions should usually be layered components rather than encoded as dozens of exclusive player states.

A state must exist only if it changes movement, input acceptance, collision or animation semantics in a meaningful way.

---

# 4. Movement and platforming

## GR-MOVE-001 - Movement feel precedes content production

World 0 production must not start until the debug room has acceptable movement, jump and camera feel.

## 4.1 Tunable movement profile

All movement constants live in a `PlayerMovementProfile` Resource or equivalent configuration. No world level should hardcode them.

Required tunables:

```text
run_speed
run_acceleration
run_deceleration
air_acceleration
air_control
gravity
jump_velocity
max_fall_speed
coyote_time
jump_buffer_time
short_hop_multiplier
dash_speed
dash_duration
dash_cooldown
```

Exact values are prototype tunables, not lore/design constants.

## GR-MOVE-002 - Coyote time and jump buffering are mandatory

The base controller must support both. Initial prototype ranges:

- coyote time: roughly 80-150 ms;
- jump buffer: roughly 80-150 ms.

Final values are selected through playtesting.

## GR-MOVE-003 - Variable jump height

Releasing jump before the apex reduces upward velocity. Platforming must not rely on frame-perfect tap duration.

## GR-MOVE-004 - Core completion cannot require advanced class movement

Main route geometry is validated using the baseline movement profile. Runner-specific movement can unlock optional routes and shortcuts.

## 4.2 Level geometry metrics

The level validator should derive from movement configuration:

- maximum standing jump horizontal distance;
- maximum useful vertical rise;
- safe landing width;
- dash reach when dash is considered mandatory;
- minimum head clearance;
- fall thresholds for hazards/checkpoints.

Generated levels must not rely on LLM intuition for reachability.

---

# 5. Conflict model and target validity

This system is central to the game and should be implemented before ideological content.

## 5.1 ConflictState

Every ball capable of participating in an encounter exposes one `ConflictState`:

```text
NEUTRAL
DISPUTED
THREATENING
AGGRESSOR
SURRENDERING
NEUTRALIZED
```

`ConflictState` is separate from faction friendliness. A RepublicanBall may be friendly, neutral, disputed or an aggressor depending on the current encounter.

## 5.2 State semantics

### NEUTRAL

No active coercive conflict exists. The player may talk, trade, pass, ignore or use allowed environmental interactions.

Offensive damage: **not valid**.

### DISPUTED

A claim, contract, resource or rule is contested, but the engine does not declare one party a legitimate offensive target.

Allowed gameplay:

- dialogue;
- investigation;
- arbitration;
- bypass;
- negotiated contract;
- consented duel if the scenario supports it.

Offensive damage: **not valid**.

### THREATENING

A credible warning or pre-commitment is occurring, but aggression is not yet sufficiently immediate for ordinary offensive response.

Examples:

- guard raises weapon but still offers a meaningful option to leave;
- countdown to a coercive action is visible;
- hostile unit takes an attack stance without committing the strike.

Allowed gameplay:

- aim;
- block;
- shield;
- dodge;
- escape;
- interact;
- prepare gadgets.

Offensive damage: **normally not valid** until transition to `AGGRESSOR`.

### AGGRESSOR

The actor has committed or is immediately executing coercive force.

Examples:

- attack launched;
- order to seize/drag the player is being executed;
- forced confiscation animation begins;
- NPC is being assaulted;
- coercive machine has activated against a protected target.

Offensive damage: **valid**.

### SURRENDERING

The actor has stopped the aggressive action and is yielding.

Offensive damage: **not valid**.

### NEUTRALIZED

The encounter contribution of that actor has ended through surrender, stun, disarm, retreat, capture or scripted resolution.

Offensive damage: **not valid** unless a later encounter explicitly creates a new Aggressor transition.

## 5.3 ValidTarget query

All offensive systems must ultimately call a shared target eligibility API rather than duplicating checks.

Conceptual contract:

```text
can_receive_offensive_effect(source, target, effect_context) -> TargetPermission
```

Suggested result values:

```text
ALLOW
BLOCK_NEUTRAL
BLOCK_DISPUTED
BLOCK_SURRENDERED
ALLOW_DUEL
ALLOW_HOSTILE_MACHINE
```

The player weapon, projectile, melee, drone and class ability layers must use the same authority.

## GR-CONFLICT-001 - No class bypasses target validity

A Tinkerer drone, Trader summon or Agorist trap may not damage a target that the player could not validly attack. Indirect damage does not create a loophole.

## 5.4 Threat vs. aggression transition

Transitions should be explicit encounter events, not inferred from animation frames scattered across enemy scripts.

Examples:

```text
collector.begin_forced_confiscation -> AGGRESSOR
guard.execute_detain_order -> AGGRESSOR
attacker.commit_attack -> AGGRESSOR
attacker.cancel_attack -> previous valid non-aggressor state
```

## 5.5 Defense of third parties

An Aggressor flag can be created by aggression against:

- player;
- allied NPC;
- neutral NPC protected by the encounter;
- protected community objective;
- property whose entitlement was already established by the mission.

The player does not need to be the victim.

## 5.6 Disputed claims

A property or contract dispute must use data describing why it is disputed rather than silently granting a side combat permission.

Conceptual data:

```text
DisputeContext
- dispute_type
- claimant_ids
- evidence_flags
- arbitration_available
- duel_available
- bypass_available
```

World 0 relies heavily on this system.

---

# 6. Damage, Resolve, surrender and defeat

## 6.1 Player health

The player may use conventional `Health` for implementation even if final UI terminology changes.

The system should support:

- current/max health;
- invulnerability frames where appropriate;
- stagger/knockback;
- hazard damage;
- healing;
- checkpoint recovery.

## 6.2 NPC Resolve

Ball opponents should preferably expose `Resolve` rather than implying lethal bodily damage.

Resolve represents willingness/capacity to continue the encounter and can be reduced by:

- weapon hits;
- stun;
- disarm;
- intimidation mechanics if later implemented;
- objective failure;
- boss phase mechanics.

When Resolve reaches its surrender threshold, the default transition is:

```text
AGGRESSOR -> SURRENDERING -> NEUTRALIZED
```

The surrender threshold and defeat response are archetype policy, not faction-name checks. Actors inclined to preserve themselves may use a raised threshold and surrender after limited Resolve pressure. A committed occupation enforcer may instead resist until its Resolve is depleted and transition directly to `NEUTRALIZED`; this never makes it immortal, lethal by default or targetable after neutralization.

## GR-COMBAT-001 - Lethality is not the default reward loop

The game does not award bonus experience for killing balls. Progression comes from encounters, objectives, exploration, contracts, bosses and discoveries.

## 6.3 Machines and objects

Destructible world objects expose a `DamagePermission` category:

```text
HOSTILE_DEVICE
FREE_DESTRUCTIBLE
OWNED_NEUTRAL
DISPUTED_PROPERTY
SCRIPTED_TARGET
```

Owned neutral or disputed property cannot be casually destroyed by normal player attacks.

## 6.4 Loot and salvage

Defeating a character does not automatically grant ownership of everything they carried.

Reward sources should be explicit:

- mission payment;
- voluntary reward;
- abandoned item;
- hostile machine salvage;
- returned/stolen property restored to the player;
- world pickup placed as unowned/collectible resource.

This keeps reward design consistent without requiring a detailed property-law simulator.

---

# 7. Combat rules

## GR-COMBAT-002 - Encounters need objectives, not only enemy counts

Prefer objectives such as:

- reach the exit;
- protect an NPC;
- stop confiscation;
- disable a checkpoint;
- survive until evacuation;
- recover an item;
- force boss surrender;
- escape pursuit.

`Defeat all aggressors` remains valid where appropriate but must not be the universal structure.

## 7.1 Offensive effect types

Base effect categories:

```text
KINETIC_DAMAGE
STUN
KNOCKBACK
DISARM
EMP
HACK
SLOW
SHIELD_BREAK
```

Effects should declare whether target validity is required. For example, a harmless scanner may target neutrals, while an EMP that destroys owned neutral equipment may not.

## 7.2 Enemy telegraphing

All dangerous attacks must communicate:

- source;
- direction or area;
- commitment timing;
- impact timing where relevant.

A player must be able to distinguish `THREATENING` from committed `AGGRESSOR` behavior without reading debug labels.

## 7.3 Friendly fire

Default:

- player cannot offensively damage neutrals/allies;
- enemy attacks can affect environment and, when designed, other NPCs;
- third-party aggression should transition the attacker as needed.

Optional high-difficulty friendly fire is not part of MVP.

## 7.4 Boss target validity

Boss intros must establish one of:

- voluntary duel;
- explicit aggression;
- aggression against a third party;
- machine/construct hostile status.

Bosses do not become valid targets merely because the HUD says `BOSS`.

---

# 8. Class system

Classes modify **how** the player solves action problems. They do not modify whether non-aggression applies.

Each class is represented by a data-driven `ClassLoadout` plus abilities/components.

Common class contract:

```text
class_id
base_stat_modifiers
allowed_weapon_tags
active_abilities
passive_abilities
world_interaction_tags
resource_model
```

## 8.1 Contractor

Core fantasy: defensive combat specialist.

Rules:

- strongest direct response once an aggressor is valid;
- improved weapon handling/armor;
- tools for protecting NPCs;
- does not gain permission to preempt neutral actors.

Signature concept: `Defensive Response`.

Possible triggers:

- player becomes target of aggression;
- protected NPC becomes target of aggression.

Possible effects:

- short accuracy bonus;
- temporary guard/armor;
- faster weapon readiness.

## 8.2 Runner

Core fantasy: avoid, outmaneuver and disarm.

Rules:

- strongest baseline traversal;
- optional routes, speed lines and vertical shortcuts;
- can complete many hostile sections without neutralizing every aggressor;
- stun/disarm tools should emphasize escape rather than DPS.

Runner-exclusive geometry is optional content unless the level is an explicit class challenge.

## 8.3 Tinkerer

Core fantasy: manipulate systems and machines.

Rules:

- EMP/hack devices;
- temporary control of hostile machines;
- mechanical traversal solutions;
- drones inherit player target-validity restrictions.

Tinkerer should often transform an obstacle rather than merely bypass it.

## 8.4 Trader

Core fantasy: solve immediate problems through exchange, capital and contracted assistance.

Trader is **not** an economy-management class.

Primary resource: `Capital`.

Fast actions may include:

- purchase supply drop;
- contract temporary SecurityBall support;
- buy access/easement when the owner offers it;
- convert eligible salvage/resources;
- emergency medical service;
- temporary utility rental.

Contracted allies inherit the player's offensive target rules.

## 8.5 Agorist

Core fantasy: bypass coercive systems through unofficial routes and counter-economics.

Rules:

- stealth/smoke;
- smuggler routes;
- hidden vendors;
- permit bypasses;
- contraband gear;
- reduced detection where fiction supports it.

The class does not receive a generic `ignore all locks` ability. Every shortcut must exist as level data or an explicit interaction tag.

---

# 9. Philosophical lenses

A lens is separate from class. Lenses provide interpretation, dialogue options and small mechanical biases without changing the hard non-aggression rule.

## GR-LENS-001 - No lens grants permission to attack a neutral target

This is non-negotiable.

## 9.1 Natural Rights / Rothbardian

Focus:

- established rights/claims;
- restitution;
- defensive justification.

Possible systems:

- `Rights Sense` shows richer provenance when a target becomes Aggressor;
- tracks established Claim records;
- improves restitution/recovery outcomes;
- defensive bonuses in unequivocal aggression encounters.

Important: essential target validity is readable for all players. This lens adds *why*, not basic usability.

## 9.2 Consequentialist

Focus:

- outcome quality;
- collateral reduction;
- de-escalation.

Possible bonuses:

- rewards encounters completed with low collateral damage;
- improved stun/non-destructive tools;
- better outcome preview for certain decisions.

## 9.3 Austrian / Institutional

Focus:

- dispersed information;
- scarcity;
- price/resource signals;
- institutional incentives.

Possible bonuses:

- reveal supply bottlenecks;
- identify alternative resource locations;
- expose distorted price/stock relationships;
- additional world-rule hints.

## 9.4 Polycentric Legal

Focus:

- arbitration;
- competing institutions;
- dispute resolution.

Possible bonuses:

- extra arbitration routes;
- lower dispute-resolution cost;
- additional evidence interactions;
- improved surrender/settlement outcomes.

## 9.5 Lens progression rule

Lenses should remain small enough that they modify encounters without doubling the content burden for every world.

The first vertical slice does not need the full lens system. It only needs architecture that does not make future lenses impossible.

---

# 10. Interaction system

## 10.1 Interaction categories

Every interactable declares one or more tags:

```text
TALK
TRADE
CONTRACT
CLAIM
ARBITRATE
HACK
BYPASS
LOOT_ALLOWED
RESCUE
WORLD_RULE
```

Class and lens interactions are surfaced through these tags, not by hardcoding ideology names into the player.

## 10.2 Contracts

A contract is a lightweight quest/interaction object, not a legal simulator.

Minimum data:

```text
contract_id
issuer
objective
reward
optional_cost
failure_condition
completion_flags
```

Optional later data:

```text
deadline
collateral
arbitrator
restitution_rule
```

## 10.3 Player choice

Choices should preferably modify something the player can observe:

- route opens/closes;
- NPC accompanies/refuses;
- cost changes;
- resource becomes available;
- future dialogue/encounter changes.

Avoid choice menus whose only result is lore text.

---

# 11. Ideology Rule system

Ideological content is built from composable rule components rather than giant `if world == ...` branches.

Conceptual interface:

```text
IdeologyRule
- rule_id
- world_tags
- activate(context)
- deactivate(context)
- modify_pickup(...)
- modify_interaction(...)
- modify_spawn(...)
- modify_environment(...)
```

Not every rule implements every hook.

## GR-WORLD-001 - One primary rule per level/sub-zone

A level should normally spotlight one primary ideological rule. Secondary mechanics may support it, but the player should be able to state what changed.

## GR-WORLD-002 - Every penalty needs counterplay

Counterplay can be:

- skill;
- alternate route;
- class ability;
- resource cost;
- timing;
- optional compliance;
- hacking;
- negotiation;
- environmental manipulation.

A world rule should not be a passive permanent stat penalty with no interaction.

## GR-WORLD-003 - Rival systems may provide real benefits

When relevant, ideological mechanics can provide a benefit paired with a cost.

Example: a social-democratic sub-zone may withhold part of coin income while offering free public healing. The player experiences a trade-off before dialogue comments on it.

## GR-WORLD-004 - A later world earns its climax through an arc

A later-world package normally provides these mission functions before its climax:

1. demonstrate a real benefit or credible promise of the primary rule;
2. expose a cost, limit or conflict;
3. teach baseline counterplay and optional class shortcuts;
4. combine the rule with previously learned systems under pressure;
5. culminate in a boss or crisis that embodies the rule.

Five missions are the production baseline, not a quota. Merge or remove a mission when it does not create a distinct gameplay decision.

## GR-WORLD-005 - Convergence does not erase ideological differences

When one world contains more than one ideological current, every current keeps a distinct sub-zone, visual language, claimed benefit, primary rule and counterplay. Shared coercion mechanics may support comparison, but faction or ideology names never substitute for an implemented gameplay distinction.

---

# 12. World 0 gameplay specification

Approved revision 2026-09-23: `LEVEL_01_PARTS_2_3.md` supersedes the older
BlackAnarchy coordination and LeftLibertarian corridor main challenges for this
level. Their hostile encounters use bounded autonomous flanking/individual
ceasefire and telegraphed spatial pulses/clean-dodge ceasefire bonuses respectively.
Mutualist owns paid mechanical route services. The mixed final encounter has
one shared clock and explicit subgroup surrender, capped simultaneous attacks,
and staged aggression; neither affiliation nor inactive membership grants damage
eligibility. Old friendly story briefs remain secondary, not completion gates.

World 0 is both tutorial and ideological foundation. Mechanics must be introduced one at a time and later recombined. The segments below are teaching beats, not a one-to-one mandate for level files; production packaging is governed by `PROJECT_PLAN.md` §12.8.

Leviathan security agencies already maintain a fragmented occupation when World 0 begins. Early raids provide recurring action pressure, while the final incursion is an escalation with reinforcements rather than their first appearance. Institutional affiliation never replaces an inspectable aggression source: an occupation unit may begin an encounter as `AGGRESSOR` only when the scene establishes that it is already carrying out detention, confiscation, attack or another immediate coercive act.

## 12.0 Active level packaging — 2026-09-22

Level 1 preserves Mutualist, Ancom and Egoist in part 1; introduces BlackAnarchy
in part 2 through distributed coordination and role rotation; introduces
LeftLibertarian in part 3 through reversible resource-use/access decisions; and
ends in a statist boss encounter with all five allies providing distinct support.
See `LEVEL_01_COALITION.md`. The numbered segments below are source mechanics,
not required mission order. The Ancom duel/interruption is a deferred variant,
not this level's finale. Kraterocracy is a proposed boss identity pending approval.
Agorist remains a player class, never a required NPC or main-route class gate.

Police aggression must remain inspectable in each part. Friendly coordination
or refusal of access does not create target eligibility. Required ally support
is taught before the boss, cannot depend on hidden optional collectibles, and
must recover after interruption/checkpoint. All indirect attacks use TargetValidity.
This packaging clarifies GR-WORLD-005, GR-LEVEL-001/003/005/008/009,
GR-BOSS-001..003 and GR-RETRY-001; it does not relax conflict or combat rules.

## 12.1 Segment A - AnarchyBall / aggression tutorial

Required encounter:

- MerchantBall is neutral;
- RobberBall threatens, then begins coercive taking;
- RobberBall transitions to `AGGRESSOR`;
- player may intervene;
- RobberBall eventually surrenders/retreats.

Teaches:

- movement;
- aim/attack;
- target validity;
- third-party defense;
- surrender.

## 12.2 Segment B - EgoistBall / rule compliance

Gameplay object: a simple bridge/access contract.

EgoistBall ignores an agreement and creates a chase/puzzle demonstrating that written rules do not enforce themselves.

Do not turn EgoistBall into a generic criminal faction. The point is to raise the question of why norms bind actors.

## 12.3 Segment C - MutualistBall / occupancy and use

World mechanic:

```text
OccupancyState
UNUSED
IN_USE
ABANDONED
DISPUTED
```

A previously abandoned industrial object becomes useful when occupied/operated by MutualistBalls.

The level physically changes through cranes/platforms/machinery.

The workshop must read as a connected communal production space. Elevated floors use their dedicated ledge art and continuous columns down to a lower structural surface. Required-route status and visual construction style are separate data; a required platform may still be column-supported. Floating platforms and road tiles reused as unsupported ledges are invalid presentation for this mission.

The workshop has five connected work areas: requisitioned reception, production, shared depot, elevated storage and dispatch. Reception and dispatch are the only mandatory combat closures. Intermediate encounters modify local access or offer useful rewards rather than adding a gate to every corridor. Patrols expose observable non-offensive interactions and room to withdraw; withdrawing before commitment clears the warning timer.

Their non-offensive verbs remain distinct. An Ancom patrol accepts a visible truce signal, opening its service walkway; defensive surrender also releases that route. Egoist explicitly permits recovery of a useful cache as a challenge, without a proximity attack timer: claiming it grants its advertised effect. Mutualist operators control machinery: restoring a feeder enables an upper control, reached using a lift or baseline recovery stairs. Dependencies and destinations must be visible, and occupied/disputed equipment cannot be seized through interaction. Dispatch can be cleared through defensive neutralization or by reaching and operating the alternate upper control even while police aggression is active. This mechanical escape does not cancel aggression or make police peaceful. Truce and supplies facilitate the escape but are not hidden mandatory checkboxes.

Machinery must create more than static ledges. At least one workshop machine drives a visible moving elevator, while other controls may reveal bypasses or reroute access. Moving machinery is optional traversal utility and may not become the only way to recover from a fall or leave the current arena.

Later, another actor presents an older title claim, moving the conflict to `DISPUTED` rather than immediately creating an aggressor.

The player also sees that an occupied machine still excludes simultaneous use by others.

## 12.4 Segment D - LeftLibertarianBall / original appropriation and access

The player can establish a claim over a resource in a controlled puzzle.

The claim changes traversal or blocks an existing path.

Possible responses:

- easement;
- fee/access contract;
- compensation;
- abandon claim;
- alternate path.

The mechanic should demonstrate external consequences without requiring the game to declare a final philosophical winner.

## 12.5 Segment E - BlackAnarchyBall / informal hierarchy

Community has no formal commander.

`SocialInfluenceComponent` causes nearby NPC behavior to respond disproportionately to a `PopularBall`.

Observable effects:

- merchants refuse or accept based on social signal;
- followers close/open a route;
- group behavior changes without an official command hierarchy.

A later variation introduces rotation/distributed facilitation, reducing reliance on a single influence source.

## 12.6 Segment F - voluntary hierarchy vs coercive authority

Two back-to-back encounters teach the distinction mechanically.

### Voluntary work crew

- ForemanBall coordinates task;
- player explicitly opts in;
- player may leave;
- leaving ends reward/contract, not freedom of movement.

### Coercive checkpoint

- Commander/GuardBall imposes a requirement unrelated to voluntarily entered property/contract;
- player attempts to leave;
- guard escalates to detention;
- aggression transition occurs.

The difference must be experienced through the availability of exit.

## 12.7 Segment G - Ancom territory / mutual aid

Primary mechanic: `CommonPool`.

Possible shared resources:

- healing capacity;
- shield pool;
- support ammunition;
- role replacement.

Boss/duel behavior:

- AncomBall receives support from the network;
- support roles can rotate;
- focused DPS alone should be less effective than understanding the network.

Secondary tension:

A finite shared resource cannot power all desired systems simultaneously, forcing visible prioritization.

Some Ancom patrols distrust AnarchyBall. They may observe, follow, block or telegraph an attack, but the encounter must preserve an exit, avoidance route or de-escalation opportunity. If they commit an attack they transition to `AGGRESSOR`; ideology alone never makes them a valid target.

If an Ancom patrol does commit aggression, its preferred response to meaningful defensive pressure is withdrawal or early surrender rather than fighting to depletion. This preference does not bypass the ordinary `TargetValidity` transition: before commitment it remains non-hostile, and after surrender it immediately ceases to be a valid offensive target.

The system must demonstrate a genuine strength (resilience through cooperation) as well as a coordination/scarcity tension.

## 12.8 Segment H - Leviathan incursion

Historical variant for a later encounter, not the active level 1 finale: the Ancom duel may be interrupted or followed by an escalation of the occupation. Level 1 instead closes with the statist boss and allied support specified in §12.0.

Leviathan forces classify all unlicensed associations as targets regardless of their economic disagreements.

Escape/defense sequence recombines earlier mechanics:

- Ancom mutual aid;
- Mutualist machinery;
- shared access corridor (class-independent; no required Agorist NPC);
- movement/traversal;
- third-party defense.

This is the tutorial's thesis payoff.

---

# 13. Later-world mechanic templates

These are rule templates, not finished level designs. Provisional mission packages, IDs and durations live in `PROJECT_PLAN.md` §13.6; they do not authorize simultaneous production of every world.

## 13.1 Minarchy / The Night Watch

Primary theme: institutional ratchet.

Possible world rule:

```text
EmergencyPowerLevel
```

Escalation unlocks:

- additional checkpoints;
- temporary tax;
- permit restrictions;
- increased surveillance.

Level gameplay should let the player see that measures introduced as temporary accumulate.

## 13.2 SocialdemBall

Possible primary rule:

- automatic withholding from eligible monetary pickups;
- public healing stations have zero direct cost.

Counterplay may include:

- route/resource planning;
- Trader optimization;
- voluntary alternative services in optional areas.

Do not make the entire world `coins -30%` with no interaction.

## 13.3 Planned economy / Communist world

Possible rule:

- zone-based resource allocation.

Obstacles:

- quota gates;
- central depots;
- fixed-price/empty-stock interactions;
- synchronized production machinery.

Counterplay varies by class.

## 13.4 CorporatistBall

Possible rule:

- private-looking facilities require licensed/privileged access.

Obstacles:

- license gate;
- exclusive charter;
- customs barrier;
- authorized provider route.

The world must visually distinguish corporatism/cronyism from ordinary market exchange.

## 13.5 Republican/DemocraticBall

Possible rule:

- periodic majority decision modifies level state.

Examples:

- bridge route opens/closes;
- levy changes;
- facility access changes.

Some votes should help the player and some should hurt, so the mechanic communicates majority jurisdiction rather than simply `democracy debuff`.

## 13.6 High-authority worlds

Monarchy/Tradition, Fascist and Stalinist regions increase environmental coercion through distinct primary mechanics:

- inherited jurisdiction and oath/exit rules for Monarchy/Tradition;
- national mobilization, conscription and industrial war hazards for Fascist sub-zones;
- party directives, political quotas and secret-police pursuit for Stalinist sub-zones.

Checkpoints, surveillance and restricted zones may recur as supporting language, but cannot be the only mechanical difference. The climb toward Leviathan should be felt through increasingly unavoidable authority while preserving the distinctions required by `GR-WORLD-005`.

---

# 14. Encounter design contract

Every encounter data asset should be able to answer:

```text
encounter_id
entry_condition
objective
initial_conflict_states
aggression_triggers
success_conditions
failure_conditions
surrender_conditions
allowed_resolutions
class_shortcuts
lens_options
rewards
telemetry_tags
```

## GR-ENCOUNTER-001 - Aggression source must be inspectable

When an actor becomes `AGGRESSOR`, debug builds must record the event/reason that caused it.

Example:

```text
AGGRESSOR_REASON = FORCED_CONFISCATION
AGGRESSOR_REASON = ATTACK_COMMIT
AGGRESSOR_REASON = THIRD_PARTY_ASSAULT
AGGRESSOR_REASON = DETENTION_EXECUTION
```

This is important both philosophically and for debugging accidental combat permissions.

## GR-ENCOUNTER-002 - Mandatory encounters need at least two resolution verbs when practical

For example:

- fight or evade;
- hack or fight;
- negotiate or bypass;
- protect until escape or neutralize aggressors.

Bosses can be more constrained.

---

# 15. Boss rules

## GR-BOSS-001 - Bosses embody a mechanic, not only a health pool

A boss must combine:

- recognizable attack patterns;
- one world/ideology mechanic;
- one adaptation or phase change;
- surrender/resolution condition.

## GR-BOSS-002 - Boss fights must establish combat legitimacy

Use one of:

- voluntary duel;
- explicit aggression;
- third-party aggression;
- hostile machine/construct.

## GR-BOSS-003 - Ideological boss dialogue occurs around gameplay

Long dialogue should not interrupt the fight every few seconds. Preferred placements:

- intro;
- short phase transitions;
- post-fight argument/resolution;
- optional Archive entry.

## 15.1 Leviathan final boss

Leviathan changes justification and mechanics by phase while retaining the same underlying coercive core.

Candidate phases:

- Tradition/Crown;
- Majority;
- Planning;
- Security/Emergency;
- Leviathan.

Allies recruited during the game should contribute mechanically, not only appear in a cutscene.

---

# 16. The Agora gameplay rules

The Agora is a preparation and character hub.

Allowed functions:

- class/loadout change;
- upgrades;
- equipment;
- dialogue;
- optional contracts;
- Archive;
- world map selection;
- visible coalition growth.

Not allowed in MVP:

- passive hourly production;
- timers;
- worker assignment;
- population management;
- territory tax simulation;
- city-builder loops.

## GR-HUB-001 - Hub actions should resolve immediately

If the player buys, equips, changes class or reads an entry, no real-time wait is required.

---

# 17. Progression

## 17.1 Shared progression

Prefer one global character progression plus class-specific unlocks.

Avoid forcing the player to replay the campaign to level each class from zero.

## 17.2 Upgrade scope

Possible progression:

- base health/resolve tolerance;
- weapon handling;
- class ability unlocks;
- equipment slots;
- utility capacity;
- class resource capacity;
- lens perks.

Avoid percentage inflation as the primary reward. New verbs and meaningful modifiers are preferred.

## 17.3 Class switching

Class switching occurs at The Agora or explicit safe loadout points, not continuously mid-combat in MVP.

---

# 18. Checkpoints, failure and retry

## GR-RETRY-001 - Retry must be fast

After player defeat, return to the last checkpoint with minimal loading and without replaying long dialogue.

## 18.1 Checkpoint stores

At minimum:

- player position/section;
- health/resource baseline defined by level;
- encounter completion flags;
- major world-rule state;
- collected persistent rewards;
- boss phase only if explicitly designed.

## 18.2 Failure should not create grind

The player does not lose permanent progression, XP or large amounts of currency on ordinary death in MVP.

## 18.3 Dialogue replay

Previously seen pre-boss dialogue should support skip/fast-forward on retry.

---

# 19. Resources and economy

Workshop tactical extension (user requested): the first Ancom collective has
three members. A wounded member retreats toward the farthest reachable active
comrade away from the player, to a supported and unoccupied nearby position.
No replacement moves into the vacated post (revised by user request). A retreat
must increase distance from the player; unreachable or crowded destinations
are rejected. One surrender still resolves the entire
collective, as does survival to the shared ceasefire. No healing or
invulnerability is granted by a tactical retreat.

User-approved anti-edge extension: the Ancom survival clock advances only inside
the central 70% of the authored roster's horizontal footprint (15% inset per
side, excluding detection padding). Bounds remain fixed during movement and
retreat. Outside, the clock pauses without resetting; attacks, defensive target
validity and collective surrender remain active. HUD communicates pause and
direction back into the arena. Other challenge profiles keep their prior timing.

Contact raiders have bounded pursuit around their original posts. They return
by traversing valid terrain, not teleporting. After physically returning and
ceasing aggression they become neutral; renewed pursuit requires a fresh warning
and committed act before offensive eligibility. Disengagement is not surrender,
loot or encounter resolution. Resolve, stolen goods and the shared timer persist.
The timer pauses when nobody is engaging the player. Both tactical movement modes
may jump along reachable supported routes; neither may phase through walls.

## GR-ECON-002 - Approved local inventory and workshop trade

Level 1 may use two finite-ammo weapons, deterministic stackable loot, protected
mission keys/components and fictional bitcoin stored as integer satoshis. A local
shop sells ammunition/healing and buys declared trade goods. This is not a real
wallet, random loot economy or persistent economic simulation. Mandatory keys and
service components cannot be sold or stolen. Checkpoints restore inventory and
world rewards together; replaying a resolved encounter never duplicates payment.
Each raider owns the items it actually stole. On surrender or neutralization,
that raider releases a separate collectible; collecting another raider's bag
must not return these items. A ceasefire releases any bags still held by its
participants. Existing encounter-wide checkpoint bags remain recoverable.
See `LEVEL_01_ECONOMY.md`. Existing ownership and target eligibility rules remain
authoritative, including after surrender.

Collectible presentation/lifetime extension (user approved): every available
pickup has a visible light aura. Only spawned drops expire; authored level
pickups, especially required keys/components, remain until collected. Drops
warn by blinking before expiry. Lifetime uses gameplay time (paused in menus);
checkpoints restore remaining time and terminal states together with inventory.
Expiry never grants currency, collection credit or encounter progress.

Resources should remain few and legible.

Candidate categories:

```text
Health
Ammo or weapon-specific resource
Class resource
Capital (Trader)
Persistent upgrade currency
```

Do not create separate food/wood/electricity style economies.

## GR-ECON-001 - Pickups must have ownership/reward semantics

World pickups should be tagged as:

- unowned collectible;
- mission reward;
- returned property;
- permitted salvage;
- class-generated supply.

This prevents normal progression from depending on arbitrary theft from neutral NPCs.

---

# 20. UI and feedback

## 20.1 HUD minimum

Vertical slice HUD:

- health;
- weapon/ammo if applicable;
- class ability cooldown/resource;
- objective prompt;
- boss Resolve when active.

## 20.2 Conflict feedback

Normal players should understand target validity through presentation:

- posture;
- weapon telegraph;
- outline/icon only when needed;
- sound cue;
- enemy HUD activation.

Debug mode may show explicit state labels.

First invalid attack against a neutral may produce a short one-time message such as:

```text
Not an aggressor.
```

Do not spam the message.

## 20.3 Natural Rights lens feedback

This lens may show richer reason labels:

```text
THIRD-PARTY AGGRESSION
FORCED CONFISCATION
DETENTION ATTEMPT
ESTABLISHED CLAIM VIOLATION
```

Basic combat readability cannot depend on the lens.

## 20.4 Ideology rule feedback

When a level rule changes the player's resources or route, explain it at the moment of first effect.

Example:

```text
Pickup: +100
Mandatory withholding: -30
Net: +70
```

After the player has learned the rule, UI can become more compact.

---

# 21. Accessibility and platform input

The first implementation should not lock mechanics to high precision unavailable on touch.

Required design goals:

- remappable keyboard/gamepad inputs where practical;
- readable controller prompts;
- scalable UI;
- mobile safe areas;
- aim assist architecture;
- no mandatory hover interactions;
- adjustable screen shake;
- subtitles for narrative dialogue;
- color is never the sole indicator of conflict state.

Potential later options:

- reduced flashing;
- simplified hold/tap controls;
- difficulty assists for platform timing;
- auto-aim strength.

---

# 22. Level design rules

## GR-LEVEL-001 - Teach, test, combine, climax

Revisión aprobada del nivel 1: `LEVEL_01_VERTICAL_REDESIGN.md`. Como regla general,
la verticalidad cambia avance, combate o recompensa; mecanismos sin beneficio
se eliminan. Cada parte de este nivel incluye ascenso y descenso principales,
retorno base y desvíos señalizados sin recursos obligatorios ocultos.
Ancom mantiene rendición colectiva, pero su retirada puede recibir cobertura
de hasta dos compañeros cercanos, sin curación ni invulnerabilidad. Esto reemplaza
la restricción anterior de retirada sin apoyo. BlackAnarchy añade ruptura de
cerco y LeftLibertarian corredores seguros amplios. El arma principal prueba
cuatro tiros y recarga automática; no altera elegibilidad ofensiva.

New major mechanics follow:

```text
INTRODUCE
DEMONSTRATE
CHALLENGE
COMBINE
MASTERY/CLIMAX
```

Not every short level needs all five stages, but a world gimmick should follow this progression across its content.

## GR-LEVEL-002 - Readability before decoration

Todas las balls jugables y de World 0 deben comunicar sus estados mediante animación real: cada estado runtime dispone de al menos cuatro frames visualmente distintos. Respiración, desplazamiento, salto, acción, daño, amenaza, rendición y neutralización no pueden simular animación repitiendo una misma pose estática.

La acción de disparo conserva el cuerpo orientado hacia su objetivo y muestra el arma en un socket lateral compartido. Una pose de golpe, giro corporal o daño no puede reutilizarse como disparo ni como desplazamiento; esas siluetas pertenecen únicamente a su estado correspondiente.

Antes de crear un proyectil, el atacante actualiza su orientación horizontal según la dirección del disparo. El proyectil nace en el lateral del arma, nunca desde el centro ni desde la espalda de la ball.

Los proyectiles de ambos bandos atraviesan pasarelas delgadas de arriba hacia
abajo. Desde abajo y por los laterales siguen bloqueados; paredes, bloques
sólidos y compuertas bloquean en todas direcciones. Esta regla de proyectiles
no cambia la colisión de personajes ni TargetValidity. Se aplica también al
trayecto del cañón al punto de aparición para no bloquear disparos al nacer.

Las barreras obligatorias deben mostrar arte integrado del nivel y retirar su colisión al resolverse el encuentro asociado. Un mensaje de “paso abierto” sin paso físico constituye un fallo bloqueante del nivel.

Enemy, hazard, platform and interactable silhouettes must remain readable over ideology-themed art.

## GR-LEVEL-003 - Required path uses baseline movement

LevelValidator validates the main path with baseline capabilities.

## GR-LEVEL-004 - Class routes are authored as tags

Examples:

```text
route_tags: [RUNNER]
interaction_tags: [TINKERER_HACK]
vendor_tags: [AGORIST_BLACK_MARKET]
contract_tags: [TRADER_ACCESS]
```

Do not detect the class through arbitrary node names.

## GR-LEVEL-005 - Generated levels are drafts

Codex may generate LevelSpecs, but shipping levels require human playtest and curation.

## GR-LEVEL-006 - Every shipping candidate declares a mission profile

Before curation, a level declares its type and target ranges in a design sheet associated with its stable `level_id`.

| Type | First clear | Clean replay | Completionist | Effective route | Checkpoints |
|---|---:|---:|---:|---:|---:|
| Optional challenge | 1-3 min | under 2 min | up to 4 min | 2-5 screens | 0 |
| Short mission | 4-7 min | 2-4 min | 6-10 min | 7-11 screens | 0-1 |
| Standard mission | 8-12 min | 4-6 min | 10-16 min | 12-18 screens | 1-2 |
| Climax mission | 12-15 min | 6-9 min | 15-22 min | 16-24 screens including its arena | 2-3 |

`First clear` means a new player from first gaining control to the exit, including checkpoint retries but excluding pause and optional Archive reading. `Clean replay` means a familiar player without deaths and without deliberate speedrunning. `Completionist` includes reasonable optional-route and secret collection.

These are production targets, not structural-validity limits. A level may deviate when its design sheet explains why and human playtest supports the exception. Prototypes and validation fixtures do not need to meet campaign scale, but they cannot be used as evidence that a shipping mission does.

## GR-LEVEL-007 - Spatial length is measured on the traversed route

One effective-screen equivalent is a meaningful route segment normalized against the current 1280 px reference viewport. Ascents, descents and significant returns count; overlapping branches count only when the player actually traverses them. `bounds.width / 1280` is not a substitute for route length. Renormalize design sheets if the base viewport changes.

## GR-LEVEL-008 - Duration must come from active play

A standard mission starts with this content budget:

- one primary ideological rule used safely, under pressure and in combination;
- five readable beats: introduce, demonstrate, challenge, combine and climax;
- no more than two substantial mandatory encounters, including the climax when applicable;
- two or three platforming challenges with distinct purposes;
- one or two optional routes that rejoin the main route in about one minute;
- two or three optional secrets or rewards.

Waiting, repeated waves, forced backtracking and non-interactive dialogue must not be used to reach a duration target. If the mechanic cannot sustain its target, shorten or reclassify the mission before adding filler.

## GR-LEVEL-009 - Checkpoints follow risk and elapsed play

Standard missions target a checkpoint every 2.5-4 minutes of active play and before a climax that changes the kind of challenge. Checkpoint placement is adjusted from human retry and section-time data, not from distance alone.

## GR-LEVEL-010 - Elevated floors require structural support

A traversable floor may not read as an unexplained floating rectangle. Every elevated platform must connect visually to terrain, architecture or machinery through supports appropriate to the level's art set, such as columns, walls, scaffolding, roots, suspended mechanisms or natural rock.

When a route adds additional stories, its support system continues or stacks coherently to the structure below. Ground roads and elevated floors use their corresponding tiles instead of reusing the same surface indiscriminately. Exceptions require an explicit diegetic reason, such as a visibly powered levitation mechanism.

---

# 23. Data-driven content contracts

Prefer Godot Resources for stable gameplay definitions and JSON/structured LevelSpec for agent-generated level drafts where text diffs are valuable.

## 23.1 Core data assets

Recommended definitions:

```text
PlayerMovementProfile
WeaponDefinition
AbilityDefinition
ClassLoadout
LensDefinition
BallDefinition
EnemyArchetype
IdeologyRuleDefinition
EncounterDefinition
LevelSpec
WorldDefinition
```

## 23.2 No ideology conditionals in core player code

Bad:

```gdscript
if current_world == "communism":
    ammo *= 0.5
```

Preferred:

```text
WorldDefinition
  -> active IdeologyRule components
  -> resource allocation rule modifies pickup/service behavior
```

## 23.3 Stable IDs

Content references use stable snake_case IDs, not display names.

Examples:

```text
world_00_anarchist_frontier
rule_occupancy_use
encounter_merchant_robbery
boss_ancomball
class_agorist
lens_natural_rights
```

---

# 24. Telemetry

Telemetry is for balancing and automated level iteration, not for building a live-service analytics platform.

Per run/attempt, optionally record locally:

- level/section ID;
- class;
- lens;
- playtest profile: first clear, clean replay or completionist when known;
- total completion time and, when instrumented, active-control vs. non-interactive time;
- time split between traversal, combat and interaction when those states are observable;
- time per section and elapsed time between checkpoints;
- retries;
- defeat location;
- damage received;
- ammo/resource starvation;
- encounter resolution type;
- routes taken, optional detours and backtracking;
- aggressors neutralized vs. evaded;
- invalid-target attempts;
- checkpoint usage;
- softlock/error events.

## GR-TELEM-001 - Invalid target attempts are a design signal

If players repeatedly try to attack a neutral/disputed target, the encounter may be communicating aggression poorly. Do not automatically interpret this as player misconduct.

## GR-TELEM-002 - Diagnose duration by section, not only by total time

When a level misses its target, inspect where time accumulated and what the player was doing. A target reached through waiting, repeated dialogue or low-variation combat is a level-design failure, not a successful duration result.

---

# 25. Automated testing requirements

The gameplay architecture must make the following tests practical.

## 25.1 Conflict tests

Required cases:

1. Neutral cannot receive offensive damage from player.
2. Disputed cannot receive offensive damage.
3. Threatening cannot receive ordinary offensive damage before commitment.
4. Aggressor can receive offensive damage.
5. Aggression against a third party makes attacker valid.
6. Surrendering immediately blocks further offensive damage.
7. Voluntary duel participants can damage each other.
8. Contractor/Tinkerer/Trader indirect attacks obey same target validity.
9. Hostile machine can be damaged when its permission allows it.
10. Neutral owned machine cannot be casually destroyed.

## 25.2 Movement tests

At minimum:

- jump buffer fires within configured window;
- coyote jump fires within configured window;
- baseline reachability calculation agrees with movement config;
- required LevelSpec gaps do not exceed safe metrics.

## 25.3 Encounter tests

- aggression trigger produces expected `AGGRESSOR_REASON`;
- objective completes through declared resolutions;
- surrendered NPC cannot re-enter combat unless explicitly reset;
- checkpoint restores encounter state correctly.

## 25.4 Data validation

CI should fail when:

- content references unknown stable IDs;
- mandatory LevelSpec fields are missing;
- a required route is unreachable;
- an encounter has no success condition;
- a boss lacks a legitimacy context/aggression trigger;
- an IdeologyRule is referenced but not registered.

The curated-level gate should also warn when a shipping candidate has no associated mission profile, falls outside its route or checkpoint envelope, or lacks enough human timing samples. These warnings do not belong in the closed `LevelSpec v0` schema unless a compatible extension or migration is accepted.

---

# 26. Vertical slice gameplay acceptance criteria

The vertical-slice target is 8-12 minutes on first clear and 4-6 minutes on a clean replay. The already approved technical MVP proves the gameplay and content contracts; this duration profile governs its campaign-scale curation and does not retroactively turn a pipeline fixture into a failed shipping level.

## Movement

- controller feels responsive on keyboard and gamepad;
- coyote time and input buffering work;
- camera does not fight the player;
- at least one short platforming challenge exists.

## Combat

- one neutral NPC exists;
- one enemy becomes Aggressor through an observable act;
- player can defend a third party;
- neutral cannot be damaged by normal offensive actions;
- enemy can surrender/be neutralized without death;
- at least one hostile machine or destructible object exists.

## Class

- Contractor is playable;
- `Defensive Response` or equivalent class identity is observable;
- class architecture does not hardcode future classes into PlayerController.

## Ideological gameplay

- at least one ideological obstacle affects traversal or interaction;
- player can understand the mechanic before reading Archive lore;
- the mechanic has counterplay.

## Level pipeline

- level can be represented by LevelSpec or equivalent data;
- LevelBuilder loads/builds it;
- LevelValidator catches at least one intentionally impossible test case;
- telemetry records section completion, checkpoint timing and defeat position;
- the shipping candidate has a mission profile and playtest evidence for its duration and effective route.

## Technical

- project imports headlessly without errors;
- automated gameplay tests pass;
- Windows build is reproducible;
- no mandatory mechanic depends on a specific physical input device.

---

# 27. Rules for Codex contributions

When implementing gameplay, Codex must:

1. Read this document plus `PROJECT_PLAN.md` and `AGENTS.md`.
2. Identify rule IDs affected by the task.
3. Prefer a central reusable rule over duplicated conditionals.
4. Add or update tests for deterministic gameplay logic.
5. Keep tunable values in Resources/configuration.
6. Avoid adding a new global manager unless the need is demonstrated.
7. Never solve target-validity problems by checking ideology/faction names directly.
8. Never make a required route depend on a class unless explicitly specified.
9. Run relevant tests and headless import before declaring completion.
10. If implementation requires changing a hard rule, stop and propose a documentation change rather than silently altering behavior.

Suggested task-report format:

```text
Rules implemented/affected:
- GR-CONFLICT-001
- GR-COMBAT-002

Files changed:
- ...

Tests executed:
- ...

Known limitations:
- ...
```

---

# 28. Anti-patterns

Do not implement:

- a universal morality meter;
- neutral NPC damage followed by reputation penalties;
- `kill everyone` as the dominant objective pattern;
- enemy hostility purely because of ideology label;
- classes that bypass NAP target validity;
- long unskippable ideological lectures inside platforming sections;
- passive ideology debuffs with no counterplay;
- resource-production timers;
- deep crafting or 4X systems;
- procedural shipping levels without human curation;
- dozens of one-off enemy scripts when a reusable component fits;
- hardcoded `world_name` branches in PlayerController;
- lethal rewards as the main XP loop.

---

# 29. Open gameplay decisions

These are intentionally not frozen in v0.3:

- final desktop aiming model: free aim vs. directional snapping;
- mobile aim-assist behavior;
- visible name `Health` vs. `Resolve` for player/opponents;
- exact movement constants;
- weapon roster;
- exact number of active abilities;
- whether dash is universal or class-modified;
- final lens roster and perk depth;
- exact world order after Minarchy;
- whether optional pacifist-style achievements exist;
- the exact optional-backtracking budget inside the predominantly linear structure;
- whether boss Resolve is shown numerically or only as a bar.

Codex must not treat an open decision as settled unless a later ADR or document revision resolves it.

---

# 30. First implementation sequence derived from these rules

Recommended order:

```text
1. Input abstraction
2. Player movement + camera
3. Health/Resolve primitives
4. ConflictStateComponent
5. TargetValidityService/component
6. Basic weapon/projectile
7. Neutral NPC + Aggressor enemy
8. Third-party defense encounter
9. Surrender/Neutralized flow
10. Contractor class layer
11. Checkpoint/retry
12. One ideology obstacle
13. EncounterDefinition
14. LevelSpec + LevelBuilder
15. LevelValidator
16. Telemetry
17. Vertical slice polish
```

Do **not** start implementing the full ideology roster or The Agora before this sequence proves the moment-to-moment game.

---

# 31. Final gameplay principle

The player should come away with the impression that the protagonist's philosophy changes **what counts as a valid conflict and how problems are approached**, not merely what text appears in dialogue boxes.

AnarchyBall is allowed to be armed, forceful and proactive while still being structurally unable to make ordinary aggression the winning strategy. The game creates action by placing the player in situations where coercion is already occurring, is becoming immediate, or is directed against others. Classes then provide different ways to answer that same problem.

If a future mechanic makes the game more fun but contradicts this foundation, the correct response is to redesign the mechanic or explicitly revise the project rules - not to hide the contradiction behind a reputation penalty.
