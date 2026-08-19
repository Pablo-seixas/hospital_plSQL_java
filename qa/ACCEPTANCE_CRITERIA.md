# Critérios de aceite

| Gate | Condição | Estado atual |
|---|---|---|
| Java | Build e testes sem falha | Aprovado |
| Segurança API | Acesso permitido e negado conforme authority | Parcialmente aprovado |
| Oracle | Todas as migrations aplicadas e `USER_ERRORS` vazio | Bloqueado |
| PL/SQL | Casos críticos aprovados | Bloqueado |
| Concorrência | Leito, estoque e liquidação testados em múltiplas sessões | Bloqueado |
| Performance | Planos registrados e índices avaliados | Bloqueado |
| Frontend | Instalação, lint e build aprovados | Bloqueado |
| Segredos | Nenhum segredo provável encontrado | Pendente de execução final |
| Release | Todos os gates High aprovados | No go |

