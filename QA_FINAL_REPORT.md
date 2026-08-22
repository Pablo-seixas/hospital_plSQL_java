# Relatório final de QA

Projeto: HospitalCore Management

Versão avaliada: 0.1.0-SNAPSHOT

Data: 19 de agosto de 2026

Decisão: No go para produção. Go condicionado para demonstração técnica do backend.

## Escopo e ambiente

Foram avaliados build Java 21, testes de autorização, integração Spring, estrutura Oracle/PLSQL, credenciais, frontend e pipeline. O computador possui Java 21, Maven 3.9.16, Node 24, npm 10, Git e Docker. O daemon Docker 26.1.1 foi iniciado. A tentativa de obter Oracle Free excedeu o limite de execução e não criou imagem ou contêiner.

## Resultados

| Área | Executados | Aprovados | Reprovados | Bloqueados |
|---|---:|---:|---:|---:|
| Build Java | 1 | 1 | 0 | 0 |
| Testes Java | 4 | 4 | 0 | 0 |
| Autorização API | 2 | 2 | 0 | 0 |
| Tradução segura de erros | 2 | 2 | 0 | 0 |
| PL/SQL em Oracle real | 0 | 0 | 0 | 1 |
| Concorrência multissessão | 0 | 0 | 0 | 1 |
| Frontend build | 0 | 0 | 0 | 1 |

O build foi executado com `mvn -o test`, Java 21 e cache Maven local. Foram aprovados quatro testes, sem falhas. O frontend não instalou dependências: três tentativas no registry excederam o tempo limite, incluindo cache isolado no projeto. SSL não foi desabilitado e configurações globais não foram alteradas.

## Matriz de risco

| Achado | Severidade | Estado | Recomendação |
|---|---|---|---|
| Migrations não compiladas em Oracle Free | High | Bloqueado | Subir Oracle, executar Flyway e consultar `USER_ERRORS` |
| Concorrência sem múltiplas sessões reais | High | Bloqueado | Testar leito, estoque e liquidação em sessões coordenadas |
| Autenticação local em memória | High | Aceita somente em demonstração | Integrar OIDC antes de produção |
| Frontend sem lockfile validado | Medium | Bloqueado pelo registry | Gerar e versionar lockfile em rede funcional |
| Mockito usa anexação dinâmica de agente | Low | Aberto | Configurar agente no Surefire futuramente |

## Banco e PL/SQL

As invariantes são protegidas por constraints, índices funcionais, locks pessimistas, idempotência e packages. Existem rotinas para transferência de leito, estoque FEFO, reservas, liquidação, partidas dobradas, fechamento, faturamento, glosas, integração contábil e relatórios. A análise estática não substitui compilação Oracle. Testes SQL de lançamento desequilibrado e estoque insuficiente estão em `database/tests`.

## Segurança

Credenciais e artefatos sensíveis são ignorados. Mensagens Oracle são traduzidas sem expor SQL. APIs críticas exigem authorities específicas. Os usuários locais são configuráveis por ambiente e não são adequados para produção. SAST, dependency scan e secret scan ainda dependem do pipeline.

## Conclusão

O backend está compilável e testado no escopo disponível. Não há evidência suficiente para aprovar migrations, performance ou concorrência sem Oracle real. O projeto pode ser apresentado como demonstração técnica com essa limitação declarada, mas release produtiva permanece bloqueada.
