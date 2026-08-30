# HospitalCore Management

Sistema de gestão hospitalar desenvolvido para demonstrar como eu organizo regras de negócio críticas com Java, Spring Boot, Oracle e PL/SQL.

Neste projeto, eu não deixei o banco apenas como armazenamento. As regras que exigem consistência forte ficam próximas dos dados, protegidas por packages, constraints, locks, idempotência e auditoria. A API Java organiza os casos de uso, controla o acesso e apresenta contratos HTTP seguros.

## Visão geral

O HospitalCore Management cobre cenários que fazem parte da rotina de uma operação hospitalar:

- internação e transferência de leitos
- controle de estoque por FEFO
- reservas e movimentações de produtos
- contas a pagar e a receber
- liquidação, cancelamento e estorno financeiro
- contabilidade por partidas dobradas
- faturamento, glosas e recursos
- integração financeiro-contábil
- auditoria transacional
- indicadores executivos e materialized views

Meu objetivo foi construir um projeto que pudesse ser explicado com clareza em uma entrevista, mas que também demonstrasse decisões técnicas aplicáveis a sistemas corporativos reais.

## Tecnologias

- Java 21
- Spring Boot 3.4
- Spring Web MVC
- Spring Security
- Spring JDBC e Spring Data JPA
- Oracle Database Free 23
- PL/SQL
- Flyway
- Maven
- JUnit 5 e Mockito
- OpenAPI e Swagger UI
- Docker Compose

## Arquitetura

O backend segue o modelo de monólito modular. Os módulos compartilham o mesmo banco e as mesmas transações, mas cada área possui responsabilidades bem definidas.

```text
Cliente
  |
Controller REST
  |
Porta de aplicação
  |
Adapter de infraestrutura
  |
Package PL/SQL, tabela, view ou materialized view
```

Organização principal:

- `api`: endpoints, validação, autorização e respostas HTTP
- `application`: comandos, consultas e contratos de aplicação
- `infrastructure`: JDBC, chamadas Oracle e tradução de erros
- `shared`: tratamento de exceções e componentes comuns
- `db/migration`: schema, packages, views, índices e dados sintéticos

Escolhi um monólito modular porque os domínios ainda dependem de transações fortes e do mesmo Oracle. Criar microserviços neste cenário acrescentaria comunicação distribuída e consistência eventual sem uma necessidade comprovada.

## Por que usei PL/SQL

Algumas regras precisam continuar válidas mesmo quando outro sistema acessa o banco sem passar pela API Java.

Por isso, o Oracle é responsável por operações como:

- bloquear um título antes de alterar seu saldo
- impedir duas ocupações ativas no mesmo leito
- consumir primeiro o lote com vencimento mais próximo
- rejeitar lançamentos contábeis desequilibrados
- impedir operações financeiras em competência fechada
- garantir idempotência em títulos, liquidações e integrações
- registrar auditoria na mesma transação da operação

O Java continua responsável por coordenar os casos de uso, validar os contratos HTTP, aplicar segurança e traduzir os erros Oracle sem expor detalhes internos.

## Núcleo financeiro

O package `PKG_FINANCIAL` concentra o ciclo de vida financeiro.

Ele oferece:

- criação idempotente de títulos
- detecção de chave idempotente com payload diferente
- liquidação parcial e total
- juros, multa e desconto validados
- cancelamento de títulos abertos
- estorno de liquidações
- bloqueio pessimista com timeout
- validação de competência contábil aberta
- auditoria das alterações

Exemplo do fluxo de liquidação:

```text
POST /settlements
  |
FinancialCommandHandler
  |
OracleFinancialOperations
  |
PKG_FINANCIAL.SETTLE_TITLE
  |
Lock do título, validações, liquidação e auditoria
```

As consultas financeiras seguem uma separação no estilo CQRS. Os comandos passam pelas procedures e as leituras usam tabelas e views preparadas para consulta, como `VW_MC_FINANCIAL_AGING`.

## Contabilidade

O package `PKG_ACCOUNTING` protege as partidas dobradas.

Antes de postar um lote, ele confere:

- situação do lote
- situação da competência
- total de débitos
- total de créditos
- existência de valor contábil

Uma competência não pode ser encerrada enquanto houver lotes em rascunho. Os saldos consideram somente lotes efetivamente postados.

## Materialized view e indicadores

A `MV_MC_EXECUTIVE_KPI` consolida por unidade:

- internações ativas
- leitos disponíveis
- valores a receber
- valores a pagar

O refresh não é mais uma chamada isolada. O package `PKG_REPORTING` executa a atualização e registra cada tentativa em `MC_ANALYTICS_REFRESH_LOG`.

A view `VW_MC_ANALYTICS_REFRESH_STATUS` permite consultar:

- data de início e término
- resultado do refresh
- responsável pela execução
- mensagem de erro controlada
- quantidade de linhas atualizadas

O job `JOB_MC_REFRESH_ANALYTICS` fica agendado no Oracle e chama o package de relatório. Assim, o processo fica centralizado, rastreável e testável.

## Concorrência e consistência

O projeto usa estratégias diferentes conforme o tipo de disputa:

- `SELECT FOR UPDATE` para títulos, internações e recursos exclusivos
- `WAIT` com tradução de timeout para erro de domínio
- `SKIP LOCKED` para filas e consumo concorrente de estoque
- constraints para proteger invariantes fora da aplicação
- chaves únicas para idempotência
- versionamento de registros críticos

Os packages de negócio não executam `COMMIT`. A transação continua sob controle da aplicação. A exceção é o registro técnico do refresh da materialized view, que utiliza transação autônoma para preservar a evidência de sucesso ou falha.

## Segurança

As rotas de negócio exigem autenticação e permissões específicas.

Principais permissões:

- `admission.transfer`
- `financial.view`
- `financial.settle`
- `reports.view`

O ambiente de desenvolvimento utiliza usuários em memória. Para produção, a evolução planejada é OIDC ou JWT com RBAC persistente.

Os códigos Oracle conhecidos são convertidos em erros de domínio. SQL, nomes internos e dados sensíveis não são devolvidos diretamente ao cliente.

## Endpoints disponíveis

| Método | Endpoint | Responsabilidade |
|---|---|---|
| POST | `/api/v1/admissions/{id}/bed-transfers` | Transferir paciente entre leitos |
| POST | `/api/v1/financial/titles/{id}/settlements` | Liquidar título financeiro |
| GET | `/api/v1/financial/titles/{id}` | Consultar título financeiro |
| GET | `/api/v1/financial/titles/aging/{unitId}` | Consultar aging da unidade |
| GET | `/api/v1/analytics/executive` | Consultar indicadores executivos |

## Como executar

Pré-requisitos:

- JDK 21
- Maven 3.9 ou superior
- Docker Desktop

Crie o arquivo `.env` com base em `.env.example` e ajuste a conexão local.

```powershell
docker compose up -d
mvn -Poracle spring-boot:run
```

Recursos da aplicação:

- Swagger UI: `http://localhost:8080/swagger-ui.html`
- Health check: `http://localhost:8080/actuator/health`

## Testes

Testes Java:

```powershell
mvn test
```

Suíte SQL no Oracle:

```powershell
sql usuario/senha@localhost:1521/FREEPDB1 @qa/sql/run_all.sql
```

Os testes PL/SQL cobrem:

- rejeição de lote contábil desequilibrado
- prevenção de estoque negativo
- liquidação parcial e total
- duplicidade financeira
- divergência de payload idempotente
- competência fechada
- estorno de liquidação
- refresh e rastreabilidade da materialized view
- integridade geral do schema
- planos de execução dos principais relatórios

## Evidências verificadas

A validação mais recente foi executada em Oracle Database Free 23 dentro de container Docker.

| Verificação | Resultado |
|---|---|
| Migrations aplicadas do zero | 7 aprovadas |
| Objetos Oracle criados | 178 |
| Objetos inválidos | 0 |
| Invariantes contábeis | Aprovadas |
| Invariantes de estoque | Aprovadas |
| Ciclo financeiro e estorno | Aprovados |
| Refresh da materialized view | Aprovado |
| Scheduler de analytics | Ativo e agendado |
| Planos com índices principais | Confirmados |

## Migrations

- `V1`: schema hospitalar, estoque, financeiro e contabilidade
- `V2`: packages transacionais principais
- `V3`: faturamento, relatórios e materialized view
- `V4`: dados sintéticos para demonstração
- `V5`: reservas e integração contábil
- `V6`: indicadores e alertas gerenciais
- `V7`: controles financeiros, estornos e refresh rastreável da materialized view

## Como eu apresentaria este projeto

Eu desenvolvi este sistema para mostrar como separo responsabilidades entre Java e Oracle. Mantive no PL/SQL as regras que precisam de consistência forte, como transferência de leitos, estoque FEFO, partidas dobradas e liquidação financeira. No Java, organizei a API, a segurança e os contratos de aplicação. Também implementei idempotência, controle de concorrência, auditoria e indicadores executivos com materialized view.

O ponto mais importante não é apenas a quantidade de funcionalidades. É a forma como cada regra foi colocada na camada que melhor consegue protegê-la.

## Próximas evoluções

- autenticação OIDC ou JWT com RBAC persistente
- testes de concorrência coordenados em múltiplas sessões
- pipeline de integração com Oracle dedicado
- métricas, traces e correlação de requisições
- gestão de segredos em cofre corporativo
- paginação e filtros adicionais nas consultas

## Documentação

- `docs/ARCHITECTURE.md`: decisões de arquitetura
- `docs/PLSQL.md`: catálogo das rotinas PL/SQL
- `qa/TRACEABILITY_MATRIX.md`: rastreabilidade entre requisitos e testes
- `RELATORIO_ENTREGA.md`: relatório técnico da entrega validada

## Estrutura principal

```text
hospital-java/
|-- database/tests
|-- docs
|-- qa
|-- src/main/java/com/medcore
|   |-- admission
|   |-- analytics
|   |-- configuration
|   |-- financial
|   `-- shared
|-- src/main/resources/db/migration
|-- src/test
|-- docker-compose.yml
`-- pom.xml
```
