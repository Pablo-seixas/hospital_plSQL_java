# Matriz de rastreabilidade

| Requisito | Implementação | Testes |
|---|---|---|
| Impedir dupla ocupação | Índices `UK_MC_ACTIVE_BED`, `UK_MC_OPEN_BED_OCCUPANCY`, `PKG_ADMISSION` | ADM-001 a ADM-003 |
| Estoque FEFO sem saldo negativo | `PKG_INVENTORY`, `PKG_INVENTORY_RESERVATION` | INV-001 a INV-004 |
| Idempotência financeira | Chaves únicas de título, liquidação e movimento | FIN-001 a FIN-003 |
| Partidas dobradas | `PKG_ACCOUNTING.POST_BATCH` | ACC-001 a ACC-003 |
| Rastreabilidade contábil | `MC_ACCOUNTING_INTEGRATION`, `VW_MC_INTEGRATION_TRACE` | ACC-004, INT-001, INT-002 |
| Fechamento de faturamento | `PKG_BILLING` | BIL-001 a BIL-003 |
| Relatórios gerenciais | Views `VW_MC_MANAGEMENT_MONTHLY`, `VW_MC_HOSPITAL_KPI`, `VW_MC_MANAGEMENT_ALERT` | REP-001, REP-002 |
| Erros Oracle seguros | `ORACLE_ERROR_TRANSLATOR`, `GLOBAL_EXCEPTION_HANDLER` | API-002 |
| Autorização backend | `SECURITY_CONFIGURATION`, `@PREAUTHORIZE` | SEC-001 a SEC-004 |
| Console view-first | Dashboard React e authorities de consulta | FE-001 a FE-003 |

