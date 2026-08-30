# Relatório técnico de entrega

## Identificação

Projeto: HospitalCore Management

Versão: 0.1.0-SNAPSHOT

Data da validação: 30 de agosto de 2026

Responsável: Pablo Seixas

## Objetivo

Este relatório apresenta a comparação entre o repositório local e o GitHub, as alterações implementadas no núcleo PL/SQL e as evidências coletadas no Oracle Database Free 23.

## Comparação com o GitHub

Branch analisada: `master`

Repositório remoto: `Pablo-seixas/hospital_plSQL_java`

Resultado da comparação:

- nenhuma alteração nova foi encontrada no GitHub
- o repositório local estava um commit à frente do remoto
- não foi necessário executar merge de conteúdo remoto
- as alterações locais foram preservadas
- o README remoto estava desatualizado em relação à disponibilidade do Oracle e aos testes PL/SQL

## Escopo implementado

### Compatibilidade Oracle

- correção de constraint com referência entre colunas
- declaração correta de exceção de lock
- reescrita da materialized view para uma construção aceita pelo Oracle 23
- correção da captura de erro dentro do package de integração

### Financeiro

- criação idempotente de títulos
- validação de divergência entre chave e payload
- liquidação parcial e total
- validação de juros, multa e desconto
- bloqueio pessimista do título
- validação de competência aberta
- cancelamento de título
- estorno de liquidação
- auditoria do ciclo financeiro

### Materialized view

- implementação do refresh no `PKG_REPORTING`
- registro de início, sucesso e falha
- armazenamento da quantidade de linhas atualizadas
- criação da view de acompanhamento do último refresh
- atualização do scheduler para chamar o package

### Testes

- teste de lançamento contábil desequilibrado
- teste de prevenção de estoque negativo
- teste de liquidação parcial
- teste de liquidação total
- teste de duplicidade
- teste de payload idempotente divergente
- teste de competência fechada
- teste de estorno
- teste de refresh da materialized view
- smoke test de integridade
- análise dos planos de execução

## Resultado da validação

| Item | Resultado |
|---|---|
| Container Oracle | Ativo |
| Migrations | 7 aprovadas |
| Objetos criados | 178 |
| Objetos inválidos | 0 |
| Package financeiro | Compilado e testado |
| Package de relatórios | Compilado e testado |
| Materialized view | Atualizada com sucesso |
| Scheduler | Ativo e agendado |
| Testes contábeis | Aprovados |
| Testes de estoque | Aprovados |
| Testes financeiros | Aprovados |
| Smoke test | Aprovado |

## Riscos restantes

- a suíte Java depende da correção do truststore local para baixar dependências Maven
- os testes de concorrência em múltiplas sessões ainda devem ser automatizados
- a autenticação em memória é adequada somente para desenvolvimento
- uma implantação produtiva precisa de gestão externa de segredos

## Conclusão

O núcleo Oracle foi validado em uma instalação limpa. As migrations compilaram, os objetos permaneceram válidos e os testes financeiros, contábeis, de estoque e de analytics foram aprovados.

O projeto está adequado para demonstração técnica e análise de portfólio. Para uma liberação produtiva, ainda são necessários os controles de identidade, observabilidade, pipeline dedicado e testes de concorrência descritos neste relatório.
