# Anarchyball: The Game
## Gameplay Rules - Canonical implementation rules for Codex

**Status:** Preproduction gameplay specification - v0.1  
**Companion document:** `docs/PROJECT_PLAN.md` rev. 0.2  
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

---

# 12. World 0 gameplay specification

World 0 is both tutorial and ideological foundation. Mechanics must be introduced one at a time and later recombined.

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

The system must demonstrate a genuine strength (resilience through cooperation) as well as a coordination/scarcity tension.

## 12.8 Segment H - Leviathan incursion

The Ancom duel is interrupted or followed by state incursion.

Leviathan forces classify all unlicensed associations as targets regardless of their economic disagreements.

Escape/defense sequence recombines earlier mechanics:

- Ancom mutual aid;
- Mutualist machinery;
- Agorist escape route;
- movement/traversal;
- third-party defense.

This is the tutorial's thesis payoff.

---

# 13. Later-world mechanic templates

These are rule templates, not finished level designs.

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

Fascist/Stalinist and adjacent regions increase environmental coercion:

- checkpoints;
- surveillance;
- propaganda triggers;
- conscription encounters;
- restricted zones;
- secret-police pursuit;
- industrial war hazards.

The climb toward Leviathan should be felt through increasingly unavoidable authority mechanics.

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
- completion time;
- retries;
- defeat location;
- damage received;
- ammo/resource starvation;
- encounter resolution type;
- routes taken;
- aggressors neutralized vs. evaded;
- invalid-target attempts;
- checkpoint usage;
- softlock/error events.

## GR-TELEM-001 - Invalid target attempts are a design signal

If players repeatedly try to attack a neutral/disputed target, the encounter may be communicating aggression poorly. Do not automatically interpret this as player misconduct.

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

---

# 26. Vertical slice gameplay acceptance criteria

The first 5-10 minute slice is accepted only when all conditions below are met.

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
- telemetry records section completion and defeat position.

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

These are intentionally not frozen in v0.1:

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
- how much backtracking is supported;
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
