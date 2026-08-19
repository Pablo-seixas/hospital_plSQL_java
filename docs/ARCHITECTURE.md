# Arquitetura

O sistema adota monólito modular porque os domínios compartilham transações fortes e um banco Oracle corporativo. Essa escolha mantém consistência e permite extração futura de módulos sem introduzir coordenação distribuída prematura.

Cada módulo separa API, aplicação, domínio e infraestrutura. Interfaces de aplicação representam portas; adapters Oracle encapsulam `SimpleJdbcCall`, queries nativas e tradução de falhas. O Oracle é dono das invariantes que precisam sobreviver a qualquer canal de integração.

## Transações

A aplicação define a fronteira transacional. Packages não executam commit. Savepoints permitem desfazer trabalho parcial antes de propagar erros. Transferências bloqueiam internação e leitos em ordem previsível. Estoque usa FEFO com `for update skip locked`. Liquidação bloqueia o título e usa chave única de idempotência. O fechamento contábil recusa lotes em rascunho.

## Módulos previstos

Admission, inventory, financial, accounting, billing, audit, integration, reporting, analytics, security e administration. O incremento atual implementa o núcleo relacional dos quatro primeiros e a infraestrutura transversal inicial.

