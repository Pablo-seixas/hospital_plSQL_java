# Relatório de execução de testes

Data: 19 de agosto de 2026

Executor: `qa/run-qa.ps1`

## Resultado consolidado

| Verificação | Resultado | Evidência |
|---|---|---|
| Build e testes Java previamente executados | Aprovado | `target/surefire-reports`, 4 testes, 0 falhas |
| Nova execução Maven no sandbox | Bloqueada | `qa/evidence/java-tests.txt` |
| Comentários em código | Aprovado | `qa/evidence/code-comments.txt` |
| Segredos prováveis | Aprovado | `qa/evidence/secret-scan.txt` |
| Frontend | Bloqueado | Dependências npm indisponíveis |
| Oracle e PL/SQL | Bloqueado | Imagem Oracle Free indisponível |
| Runner de QA | Aprovado | `qa/evidence/qa-summary.json`, código 0 |

## Observações

Dois novos cenários negativos de API foram adicionados após a última execução Maven aprovada: acesso anônimo e payload inválido. Eles estão implementados, mas aguardam nova execução externa quando o limite temporário for liberado. Por isso não foram somados aos quatro testes comprovados.

Não foram falsificados resultados de banco, frontend, performance ou concorrência.

