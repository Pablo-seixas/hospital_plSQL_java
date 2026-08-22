# HospitalCore Management

HospitalCore Management e uma plataforma ficticia de gestao hospitalar criada para demonstrar uma arquitetura corporativa com Java 21, Spring Boot e Oracle PL/SQL.

O projeto cobre internacao, leitos, estoque, financeiro, contabilidade, faturamento, auditoria, integracao e indicadores gerenciais. As regras transacionais criticas ficam no Oracle e a API Java controla acesso, validacao, contratos HTTP e traducao segura de erros.

## Objetivo do projeto

O sistema representa problemas comuns de um hospital:

- transferir pacientes entre leitos sem gerar ocupacao duplicada
- consumir estoque pelo criterio FEFO
- impedir saldo negativo de produtos
- criar e liquidar titulos financeiros com idempotencia
- garantir partidas dobradas na contabilidade
- fechar contas hospitalares e gerar faturamento
- registrar auditoria junto com a transacao de negocio
- processar integracoes contabilmente rastreaveis
- apresentar indicadores executivos e alertas gerenciais

## Stack

- Java 21 e Spring Boot 3.4
- Spring Web MVC, Security, JDBC, Data JPA e Bean Validation
- Oracle Database Free 23, PL/SQL e Flyway
- Maven, JUnit 5 e Mockito
- OpenAPI e Swagger UI
- React, Vite e ECharts
- Docker Compose

## Arquitetura

O backend e um monolito modular. Cada area de negocio pode evoluir com baixo acoplamento, mas continua compartilhando transacoes fortes e o mesmo banco Oracle.

```text
Cliente
  |
  v
Controller REST
  |
  v
Porta de aplicacao
  |
  v
Adapter JDBC ou Oracle
  |
  v
Package PL/SQL, tabelas e views
```

As principais responsabilidades sao:

- `api`: endpoints, status HTTP, validacao e autorizacao
- `application`: comandos, consultas, portas e modelos de resposta
- `infrastructure`: JDBC, SimpleJdbcCall e acesso ao Oracle
- `shared`: erros de dominio e tratamento global de excecoes
- `db/migration`: schema, packages, views, indices e dados sinteticos

O Oracle protege invariantes que devem valer para qualquer canal de entrada. O Java organiza os casos de uso e transforma falhas Oracle em respostas seguras.

## Virtual Threads

O projeto usa Java 21 e habilita Virtual Threads pelo Spring Boot:

```yaml
spring:
  threads:
    virtual:
      enabled: true
```

Isso permite que requisicoes bloqueantes, como chamadas JDBC, usem threads virtuais. Elas sao mais leves que threads tradicionais e ajudam o servidor a manter muitas requisicoes concorrentes.

Virtual Threads nao aumentam a capacidade do banco. O pool Hikari continua limitado a 20 conexoes para proteger o Oracle. Na entrevista, a resposta importante e: Virtual Threads melhoram a escalabilidade do lado Java para tarefas bloqueantes, mas o pool de conexoes e o banco continuam sendo recursos limitados.

## CQRS na parte financeira

CQRS separa operacoes que alteram estado das operacoes de leitura.

No modulo financeiro:

- `FinancialCommandHandler` representa o lado de comando
- `OracleFinancialOperations` executa a liquidacao pela procedure `PKG_FINANCIAL.SETTLE_TITLE`
- `FinancialQueryService` representa o lado de consulta
- `JdbcFinancialQueryService` le tabelas e views otimizadas para consulta
- `FinancialTitleView` e `FinancialAgingView` sao modelos exclusivos de leitura

```text
POST settlement -> FinancialCommandHandler -> PKG_FINANCIAL.SETTLE_TITLE

GET title ------> FinancialQueryService ---> MC_FINANCIAL_TITLE
GET aging ------> FinancialQueryService ---> VW_MC_FINANCIAL_AGING
```

O projeto usa CQRS no nivel de codigo e responsabilidade. Ele nao usa bancos separados nem consistencia eventual, porque o contexto atual precisa de consistencia forte e nao justifica essa complexidade.

## Modulos de negocio

### Internacao

`PKG_ADMISSION.TRANSFER_BED` bloqueia a internacao e os leitos envolvidos, confere o leito esperado, encerra a ocupacao anterior, cria a nova ocupacao e registra auditoria.

### Estoque

`PKG_INVENTORY.ISSUE_FEFO` escolhe primeiro os lotes que vencem antes. `FOR UPDATE SKIP LOCKED` permite processamento concorrente sem duas operacoes consumirem o mesmo saldo bloqueado.

### Financeiro

`PKG_FINANCIAL` cria titulos e realiza liquidacoes parciais ou totais. Chaves de idempotencia evitam que uma repeticao de requisicao gere pagamento duplicado. O titulo e bloqueado durante a liquidacao.

### Contabilidade

`PKG_ACCOUNTING` valida debitos e creditos antes da postagem. Um lote so pode ser postado se estiver balanceado. O fechamento de periodo recusa estados inconsistentes.

### Faturamento

`PKG_BILLING` fecha contas hospitalares, processa lotes de faturas e registra glosas. As tabelas mantem itens cobraveis, faturas, glosas e recursos.

### Integracao

`PKG_INTEGRATION` mantem uma fila contabil com idempotencia, tentativas e estado de processamento. Itens podem ser processados em lote ou reenviados depois de uma falha.

### Auditoria e analytics

Eventos de auditoria sao gravados na mesma transacao do negocio. Views e uma materialized view fornecem ocupacao, aging financeiro, balanco, faturamento e KPIs executivos.

## Concorrencia e consistencia

- lock pessimista para recursos disputados, como leitos e titulos
- `SKIP LOCKED` para filas e consumo concorrente de estoque
- idempotencia para impedir efeitos duplicados
- constraints para proteger regras mesmo fora da API Java

Os packages PL/SQL nao executam `COMMIT`. Assim, a fronteira transacional continua sob controle da aplicacao. Savepoints internos podem desfazer trabalho parcial sem quebrar essa responsabilidade.

## Seguranca

Todas as rotas de negocio exigem autenticacao. A autorizacao usa permissoes especificas:

- `admission.transfer`
- `financial.view`
- `financial.settle`
- `reports.view`

Existem usuarios em memoria apenas para desenvolvimento. Senhas sao recebidas por variaveis de ambiente. Em producao, a evolucao recomendada e integrar OIDC ou JWT e persistir RBAC.

Erros internos do Oracle nao sao enviados diretamente ao cliente. `OracleErrorTranslator` converte codigos conhecidos em erros de dominio e `GlobalExceptionHandler` padroniza a resposta HTTP.

## Endpoints implementados

| Metodo | Endpoint | Permissao | Funcao |
|---|---|---|---|
| POST | `/api/v1/admissions/{id}/bed-transfers` | `admission.transfer` | Transfere o leito da internacao |
| POST | `/api/v1/financial/titles/{id}/settlements` | `financial.settle` | Liquida um titulo |
| GET | `/api/v1/financial/titles/{id}` | `financial.view` | Consulta um titulo |
| GET | `/api/v1/financial/titles/aging/{unitId}` | `financial.view` | Consulta aging da unidade |
| GET | `/api/v1/analytics/executive` | `reports.view` | Consulta KPIs executivos |

## Como executar

### Pre requisitos

- JDK 21
- Maven 3.9 ou superior
- Docker Desktop para subir o Oracle local
- Node.js para executar o frontend

Crie `.env` baseado em `.env.example`, ajuste as senhas e execute:

```powershell
docker compose up -d
mvn -Poracle spring-boot:run
```

Recursos locais:

- Swagger UI: `http://localhost:8080/swagger-ui.html`
- Health check: `http://localhost:8080/actuator/health`

Para executar o frontend:

```powershell
cd frontend
npm install
npm run dev
```

## Testes e evidencias

```powershell
mvn test
.\qa\run-qa.ps1
```

Com Oracle disponivel:

```powershell
sql usuario/senha@localhost:1521/FREEPDB1 @qa/sql/run_all.sql
```

Os dados usados nos testes Java sao mocks e fixtures sinteticas. Eles servem como evidencia de comportamento da API e nao sao inseridos no banco real. A migration `V4__synthetic_seed.sql` tambem usa somente dados ficticios para demonstracao.

As evidencias ficam em:

- `src/test`: testes automatizados Java
- `database/tests`: invariantes de estoque e contabilidade
- `qa/sql`: smoke tests e planos de execucao
- `qa/evidence`: resultados gerados pela rotina de QA
- `qa/TRACEABILITY_MATRIX.md`: ligacao entre requisito, codigo e teste
- `qa/QA_FINAL_REPORT.md`: resumo de qualidade

## Migrations

- `V1__core_schema.sql`: estrutura hospitalar, estoque, contabilidade e financeiro
- `V2__corporate_packages.sql`: packages transacionais principais
- `V3__billing_integration_reporting.sql`: faturamento, relatorios e KPIs
- `V4__synthetic_seed.sql`: dados ficticios de demonstracao
- `V5__enterprise_flows.sql`: partes, contas bancarias, reservas e integracao contabil
- `V6__management_analytics.sql`: indicadores e alertas gerenciais

## Como apresentar na entrevista

Uma explicacao curta pode ser:

> Eu desenvolvi um monolito modular para gestao hospitalar usando Java 21, Spring Boot e Oracle. Mantive no PL/SQL as regras que exigem consistencia forte, como transferencia de leitos, baixa FEFO e liquidacao financeira. No Java, separei API, aplicacao e infraestrutura, usei seguranca por permissao e traduzi erros Oracle sem vazar detalhes internos. Na parte financeira apliquei CQRS, separando o comando de liquidacao das consultas de titulo e aging. Tambem habilitei Virtual Threads para lidar melhor com chamadas JDBC bloqueantes, mantendo o pool de conexoes limitado para proteger o banco.

### Por que PL/SQL e nao somente Java?

Porque as invariantes criticas precisam continuar validas mesmo se outro sistema acessar o mesmo Oracle. Locks, constraints e transacoes perto dos dados reduzem janelas de concorrencia.

### Por que um monolito modular?

Os dominios ainda compartilham banco e transacoes fortes. Microservicos adicionariam rede, consistencia eventual e operacao distribuida sem uma necessidade comprovada. Os limites modulares permitem extracao futura.

### O que CQRS resolveu?

Separou o modelo de escrita, que possui regra transacional e auditoria, do modelo de leitura, que retorna dados prontos para a interface. Isso reduz acoplamento e permite otimizar cada lado independentemente.

### Virtual Threads substituem o pool JDBC?

Nao. Elas tornam a espera bloqueante mais barata no Java, mas cada operacao JDBC ainda precisa de uma conexao. O Hikari limita a concorrencia real contra o Oracle.

### Como o sistema evita duplicidade financeira?

Cada liquidacao recebe uma chave de idempotencia protegida por constraint unica. Se o cliente repetir a mesma requisicao, o banco impede um segundo efeito financeiro.

### Como o sistema evita corrida entre duas liquidacoes?

A procedure bloqueia o titulo com `SELECT FOR UPDATE`. Apenas uma transacao altera o saldo aberto por vez.

### Como os erros sao tratados?

O Oracle usa faixas de codigos por dominio. O adapter converte essas falhas em excecoes de negocio e o handler global produz uma resposta HTTP segura e consistente.

### O que voce melhoraria para producao?

- autenticacao OIDC ou JWT com RBAC persistente
- testes de integracao executados em Oracle no pipeline
- observabilidade com metricas, traces e correlation ID
- secrets em um cofre corporativo
- paginacao e filtros adicionais nas consultas
- teste de carga para ajustar Hikari e limites do Oracle

## Limitacoes conhecidas

- os testes Java usam mocks e nao substituem testes reais das procedures
- as migrations precisam ser validadas em uma instancia Oracle antes de release
- a autenticacao em memoria existe somente para desenvolvimento
- Virtual Threads melhoram concorrencia no Java, mas nao removem limites do banco

## Estrutura principal

```text
hospital-java/
|-- database/tests
|-- docs
|-- frontend
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
