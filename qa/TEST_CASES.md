# Casos de teste

| ID | Domínio | Cenário | Resultado esperado | Automação |
|---|---|---|---|---|
| SEC-001 | Segurança | Gestor consulta dashboard | HTTP 200 | Planejada |
| SEC-002 | Segurança | Gestor tenta transferir leito | HTTP 403 | Automatizada |
| SEC-003 | Segurança | Analista transfere leito | HTTP 204 | Automatizada |
| SEC-004 | Segurança | Requisição sem autenticação | HTTP 401 | Automatizada |
| API-001 | API | Payload de transferência inválido | HTTP 400 | Automatizada |
| API-002 | API | Erro ORA-20202 | HTTP 422 sem SQL interno | Automatizada |
| ADM-001 | Internação | Transferência válida | Leito anterior liberado e novo ocupado | Oracle |
| ADM-002 | Internação | Dois usuários ocupam o mesmo leito | Uma operação aprovada e outra rejeitada | Oracle concorrente |
| ADM-003 | Internação | Estado esperado divergente | Rollback integral e ORA-20102 | Oracle |
| INV-001 | Estoque | Baixa maior que o saldo | ORA-20202 e saldo preservado | Script SQL |
| INV-002 | Estoque | Duas baixas concorrentes | Saldo nunca negativo | Oracle concorrente |
| INV-003 | Estoque | Baixa com lotes diferentes | Lote com menor validade consumido primeiro | Oracle |
| INV-004 | Estoque | Reserva cancelada | Quantidade reservada devolvida | Oracle |
| FIN-001 | Financeiro | Liquidação parcial | Título em PARTIAL e saldo correto | Oracle |
| FIN-002 | Financeiro | Liquidação total | Título em SETTLED e saldo zero | Oracle |
| FIN-003 | Financeiro | Liquidação duplicada | ORA-20403 sem movimento duplicado | Oracle |
| FIN-004 | Financeiro | Competência fechada | Operação rejeitada | Oracle |
| ACC-001 | Contabilidade | Lote balanceado | Lote contabilizado | Oracle |
| ACC-002 | Contabilidade | Débito diferente de crédito | ORA-20303 | Script SQL |
| ACC-003 | Contabilidade | Fechamento com lote aberto | ORA-20304 | Oracle |
| ACC-004 | Contabilidade | Integração financeira | Dois lançamentos balanceados e origem rastreável | Oracle |
| INT-001 | Integração | Erro durante processamento | Status ERROR e mensagem técnica controlada | Oracle |
| INT-002 | Integração | Reprocessamento | Mesmo evento sem duplicação contábil | Oracle |
| BIL-001 | Faturamento | Conta com item inconsistente | Fechamento rejeitado | Oracle |
| BIL-002 | Faturamento | Conta válida | Fatura e título a receber gerados | Oracle |
| BIL-003 | Faturamento | Glosa parcial | Valor e status atualizados | Oracle |
| REP-001 | Relatórios | Aging financeiro | Faixas e totais reconciliados | Oracle |
| REP-002 | Relatórios | Variação mensal | LAG e percentual corretos | Oracle |
| PERF-001 | Performance | Fila de integração pendente | Índice de fila utilizado | EXPLAIN PLAN |
| PERF-002 | Performance | Aging por unidade | Índice de aging avaliado | EXPLAIN PLAN |
| FE-001 | Frontend | Build de produção | Build sem erros | npm |
| FE-002 | Frontend | Layout gerencial | Dashboard legível em desktop | Manual |
| FE-003 | Frontend | API indisponível | Modo demonstração identificado | Manual |

