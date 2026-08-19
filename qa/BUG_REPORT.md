# Relatório de defeitos e impedimentos

| ID | Severidade | Componente | Descrição | Evidência | Estado |
|---|---|---|---|---|---|
| QA-001 | High | Oracle | Nenhuma instância Oracle disponível para compilar migrations | Docker sem imagem ou contêiner Oracle | Bloqueado externamente |
| QA-002 | High | Oracle | Packages e materialized view não possuem evidência de compilação real | `USER_ERRORS` não consultado | Bloqueado externamente |
| QA-003 | High | Concorrência | Locks de leito, estoque e financeiro não foram exercitados em múltiplas sessões | Casos ADM-002 e INV-002 pendentes | Bloqueado por QA-001 |
| QA-004 | Medium | Frontend | Registry npm excedeu o tempo limite e não gerou lockfile | Três tentativas sem `node_modules` | Bloqueado externamente |
| QA-005 | Medium | CI | Frontend usa `npm install` enquanto não existe lockfile | `.github/workflows/ci.yml` | Aberto |
| QA-006 | Low | Testes Java | Mockito alerta sobre futura restrição de agente dinâmico | Saída Maven em Surefire | Aberto |

## Avaliação

Nenhum defeito Critical foi comprovado. Os achados High representam ausência de evidência, não aprovação implícita. QA-001 a QA-003 bloqueiam release produtiva.

