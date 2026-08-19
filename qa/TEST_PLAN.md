# Plano de teste de software

Projeto: HospitalCore Management

Versão: 0.1.0-SNAPSHOT

## Objetivo

Validar regras hospitalares, financeiras, contábeis, de faturamento e estoque, além das fronteiras Java, segurança, API, frontend e integração Oracle.

## Estratégia

Os testes são divididos em unitários, API, segurança, banco, PL/SQL, transação, concorrência, performance, frontend e smoke. Resultados dependentes de Oracle somente podem ser aprovados após execução contra Oracle Free. Análise estática não substitui essa evidência.

## Critérios de entrada

- Java 21 e Maven disponíveis
- Dependências Maven resolvidas ou presentes no cache
- Oracle Free saudável para testes de banco
- Usuário Oracle com privilégios de desenvolvimento controlados
- Dependências npm instaladas para testes do frontend
- Variáveis baseadas em `.env.example`

## Critérios de saída

- Build Java aprovado
- Nenhum teste automatizado reprovado
- Migrations executadas sem objetos inválidos
- Casos críticos de concorrência e rollback aprovados
- Nenhuma credencial ou chave versionada
- Frontend compilado e lint aprovado
- Achados Critical e High corrigidos ou formalmente bloqueados

## Ambientes

Local Windows para build e testes Java. Oracle Free em contêiner para migrations, PL/SQL e concorrência. Node.js para dashboard. GitHub Actions para regressão contínua e secret scanning.

## Evidências

Resultados são gravados em `qa/evidence`. Relatórios Surefire permanecem em `target/surefire-reports`. Saídas Oracle devem ser salvas em `qa/evidence/oracle-test-output.txt`.

