# Relatório final de qualidade

Projeto: HospitalCore Management

Versão: 0.1.0-SNAPSHOT

Data: 19 de agosto de 2026

## Resumo executivo

O projeto possui uma base Java compilada e quatro testes comprovadamente aprovados, além de uma suíte formal de QA reproduzível. O banco concentra as regras hospitalares e corporativas em 34 tabelas, 9 packages com specification e body e 10 views. A release produtiva não foi aprovada porque Oracle e frontend não puderam ser materializados no ambiente atual.

## Resultados

| Área | Resultado | Evidência |
|---|---|---|
| Build Java | Aprovado em 19/08/2026 | Surefire e saída Maven |
| Testes Java comprovados | 4 aprovados, 0 falhas | `target/surefire-reports` |
| Testes negativos adicionais | Implementados, não reexecutados | `AdmissionControllerTest.java` |
| Comentários em código | Nenhum encontrado | `evidence/code-comments.txt` |
| Segredos prováveis | Nenhum encontrado | `evidence/secret-scan.txt` |
| Oracle | Bloqueado | Imagem não obtida |
| PL/SQL | Bloqueado | Sem Oracle para compilação |
| Concorrência | Bloqueado | Sem sessões Oracle |
| Performance SQL | Bloqueado | Scripts prontos, sem banco |
| Frontend | Bloqueado | Registry npm indisponível |

## Cobertura funcional implementada

Internação, leitos, estoque FEFO, reservas, financeiro, liquidação, partidas dobradas, períodos, faturamento, glosas, integração financeiro-contábil, auditoria, relatórios gerenciais e alertas.

## Segurança

As APIs críticas possuem `@PreAuthorize`. O perfil gestor é orientado a consulta e o perfil analista recebe permissões operacionais específicas. Erros Oracle conhecidos são traduzidos para mensagens seguras. Arquivos de credenciais, wallets, chaves, logs, builds e dependências são ignorados.

## Riscos residuais

- Possíveis erros de compilação Oracle ainda não observáveis
- Locks e rollback ainda não exercitados com sessões simultâneas
- Materialized view e scheduler dependem de privilégios Oracle
- Frontend ainda sem lockfile e build comprovado
- Autenticação em memória adequada somente para demonstração

## Decisão

Go condicionado para avaliação do código e demonstração do backend já testado.

No go para release produtiva até aprovação dos gates Oracle, concorrência, performance e frontend.

