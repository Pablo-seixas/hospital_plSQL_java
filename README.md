# HospitalCore Management

HospitalCore Management é uma plataforma corporativa fictícia para gestão hospitalar, financeira e contábil. O processamento transacional crítico permanece no Oracle por meio de packages PL/SQL; o backend Java oferece APIs versionadas, segurança e integração controlada. O frontend é um console gerencial orientado a consulta. Operações críticas aparecem somente para perfis autorizados.

## Estado atual

O projeto inclui auditoria do ambiente, modelo hospitalar, financeiro, contábil e de faturamento, estoque FEFO, integração contábil rastreável, auditoria, relatórios analíticos, adapters Java para procedures Oracle, autorização e dashboard executivo.

## Stack

Java 21, Spring Boot 3, Spring Security, Spring JDBC, Spring Data JPA, Flyway, Oracle Database, Maven, JUnit 5 e OpenAPI.

## Execução

Copie `.env.example` para `.env` e substitua os valores locais. Disponibilize uma instância Oracle Free com o service name configurado. Crie o usuário da aplicação com privilégios limitados para tabelas, views, sequences, procedures e scheduler necessários. Exporte as variáveis do arquivo e execute:

```powershell
mvn -Poracle spring-boot:run
```

Swagger fica disponível em `http://localhost:8080/swagger-ui.html` e health check em `http://localhost:8080/actuator/health`.

## Arquitetura

Os módulos usam portas de aplicação e adapters de infraestrutura. Controllers não conhecem JDBC. Chamadas PL/SQL ficam concentradas em repositories/adapters Oracle. A transação é iniciada pela aplicação e os packages não executam commit; savepoints internos preservam atomicidade sem retirar o controle do Java.

O schema inicial está em `src/main/resources/db/migration`. Constraints e índices baseados em função protegem invariantes também contra integrações externas. Locks pessimistas com timeout, `skip locked`, chaves de idempotência e versões de registro tratam concorrência de leitos, estoque e liquidações.

## Segurança

As rotas exigem autenticação e permissões no backend. A primeira API exige `admission.transfer`. Credenciais não são versionadas. Mensagens SQL internas não são devolvidas diretamente ao cliente. Autenticação básica existe apenas como bootstrap de desenvolvimento; JWT/OIDC e persistência RBAC fazem parte do próximo incremento.

## Testes e Oracle

Execute testes Java com `mvn test`. Testes reais dos packages exigem Oracle e serão separados em perfil de integração. PostgreSQL ou H2 não são utilizados para alegar compatibilidade PL/SQL. O relatório em `QA_FINAL_REPORT.md` distingue testes executados de bloqueados.

## Documentação

- `docs/ENVIRONMENT_AUDIT.md`: inventário local e decisões de reutilização
- `docs/ARCHITECTURE.md`: limites, transações e estratégia Oracle
- `docs/PLSQL.md`: catálogo das rotinas e invariantes
- `QA_FINAL_REPORT.md`: evidências e limitações atuais

## Limitações verificadas

As migrations precisam ser compiladas em Oracle real antes de release. O ambiente auditado não contém Oracle e o serviço Docker está parado. O frontend usa dados sintéticos de demonstração quando a API não está disponível. Autenticação local serve para avaliação técnica; produção requer integração com provedor OIDC corporativo.
