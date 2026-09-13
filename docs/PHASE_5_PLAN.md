# Phase 5 - MVP Hardening

- **Estado:** COMPLETADA Y APROBADA
- **Inicio:** 2026-09-09
- **Cierre:** 2026-09-12
- **Reglas afectadas:** `GR-CORE-001` a `GR-CORE-010`, `GR-COMBAT-001/002`, `GR-BOSS-001` a `003`, `GR-RETRY-001`, `GR-LEVEL-001` a `005`, `GR-TELEM-001`

## Objetivo

Convertir el slice aprobado en una base compartible y resistente a regresiones sin ampliar el MVP. Esta fase endurece presentación, medición, automatización y proceso de extensión; no inicia World 0 ni introduce sistemas de campaña.

## Entregables técnicos

- opciones persistentes de screen shake, subtítulos descriptivos y escala de UI;
- estados de conflicto legibles mediante texto y símbolos además de color;
- resumen determinista de telemetría con señales para pacing, retries y target validity;
- variante compacta no-shipping creada solo mediante LevelSpec;
- CI con importación, smoke, suite headless y export Windows;
- preset y script de export Windows reproducible;
- guía de extensión para enemigos, encounters, reglas y niveles;
- deuda y decisiones abiertas registradas en este documento.

## Balance inicial

La fase 4 fue aprobada sin bloqueos ni correcciones nuevas reportadas. Por ello se conserva el balance base y se evita ajustar números sin evidencia. El cierre muestra tiempo, retries e intentos contra objetivos inválidos, y `TelemetryBalanceSummary` genera recomendaciones con umbrales explícitos. Los siguientes cambios de balance deben adjuntar al menos tres snapshots completos comparables.

## Gate técnico

- [x] accesibilidad básica configurable y persistente;
- [x] ninguna señal obligatoria depende solo del color;
- [x] telemetría resumible mediante lógica cubierta por tests;
- [x] variante data-driven validada sin modificar `PlayerController`;
- [x] suite headless y smoke estables localmente;
- [x] pipeline CI declara verificación y artefacto Windows;
- [x] preset y script de build Windows reproducibles;
- [x] extensión de contenido documentada;
- [x] export Windows ejecutado localmente con templates oficiales instalados;
- [ ] build Windows ejecutado en una máquina limpia de desarrollo;
- [x] tres playtests completos consecutivos sin softlocks;
- [x] accesibilidad comprobada visualmente a 100%, 115% y 130%;
- [ ] CI observado en remoto tras publicar el commit.

## Registro de aceptación

El gate humano fue aprobado el 2026-09-12 después de completar los playtests manuales. Durante la validación se detectó que `pickup_merchant_reward` estaba sobre una plataforma opcional fuera del alcance de Contractor; la recompensa se movió a la ruta base, se añadió una regresión al validador y la mecánica corregida fue aprobada manualmente.

La importación headless, el smoke test y las 55 pruebas automatizadas pasan localmente. La comprobación en una máquina limpia y la observación del CI remoto permanecen como verificaciones operativas de distribución y no bloquean el inicio de la fábrica de contenido; deben completarse antes de declarar un candidato de release público.

## Deuda y decisiones abiertas

- El arte y audio continúan siendo placeholders del MVP.
- Los subtítulos describen cues relevantes; no existe voice acting.
- El resumen de telemetría es local y deliberadamente no envía datos.
- La accesibilidad completa, remapeo y controles táctiles pertenecen a fases posteriores.
- El export no está firmado y no incluye integraciones de tienda.
- La variante `mvp_hardening_variant` es un fixture jugable, no contenido shipping hasta playtest humano.
