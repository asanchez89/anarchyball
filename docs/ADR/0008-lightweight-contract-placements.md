# ADR-0008: contratos ligeros como contenido y placement

- Estado: aceptado
- Fecha: 2026-09-20

## Contexto

`w0_02_contract_bridge` necesita consentimiento explícito, prestación observable, incumplimiento y resolución no ofensiva. `AccessGate` solo verifica un tag y no representa el ciclo de vida mínimo exigido por `GAMEPLAY_RULES.md` §10.2. Reutilizar el objeto de occupancy mezclaría dos reglas distintas.

## Decisión

Se añade `ContractDefinition` al catálogo con los datos mínimos canónicos y una colección opcional `contracts` a LevelSpec v0. Cada placement conecta una definición con gates, un encounter contextual y posiciones de prestación, resolución y escape. `ContractRuntimeObject` mantiene el estado local y emite transiciones observables; no decide target validity ni concede agresión.

## Consecuencias

- Los niveles existentes siguen siendo válidos porque `contracts` es opcional.
- Los contratos cambian rutas y encounters de forma observable sin introducir un quest manager global.
- Un incumplimiento contractual permanece `Disputed`; no convierte al counterparty en objetivo ofensivo.
- Las referencias locales y de catálogo se validan antes de construir el nivel.
