# PL/SQL

`PKG_ADMISSION` transfere leitos atomicamente, valida estado esperado, bloqueia recursos, atualiza ocupação e registra auditoria.

`PKG_INVENTORY` realiza baixa FEFO, ignora lotes bloqueados por outros workers, impede saldo negativo e reverte integralmente quando a quantidade é insuficiente.

`PKG_ACCOUNTING` valida partidas dobradas antes de postar, bloqueia período fechado, impede fechamento com lote aberto e consulta saldo contábil.

`PKG_FINANCIAL` cria títulos idempotentes e executa liquidação parcial ou total sob lock pessimista.

`PKG_AUDIT` registra eventos dentro da mesma transação de negócio. Não usa transação autônoma porque uma auditoria de operação revertida não deve aparecer como sucesso.

Os códigos de erro `-201xx`, `-202xx`, `-203xx` e `-204xx` identificam internação, estoque, contabilidade e financeiro. O adapter Java deve traduzi-los para erros de domínio sem expor SQL ou dados sensíveis.

