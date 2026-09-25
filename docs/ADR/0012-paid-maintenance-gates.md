# ADR-0012: compuertas mecánicas pagadas

Estado: aceptado dentro de los servicios Mutualist aprobados para partes 2/3.

LevelSpec v0 añade `rule_objects[].service_gate_id` opcional y el tag de puerta
`mechanical_service`. Una terminal puede tener esta compuerta como objetivo sin
plataformas. El validador exige la referencia bidireccional y rechaza vincular
un servicio a una puerta de resolución de combate.

RunEconomyDefinition conecta el ID de terminal con el ID de compuerta mediante
`service_gates`. Exige un coste y componentes protegidos garantizados. El pago
usa la confirmación existente. WorkshopEconomy abre la puerta solo cuando la
máquina cambia a ocupada; no resuelve ningún encuentro. El guardado existente
restaura juntos inventario, máquina y puerta, sin repetir pago ni recompensas.

Reglas afectadas: GR-LEVEL-010, GR-ECON-001/002, GR-RETRY-001.
