explain plan set statement_id = 'HC_AGING' for
select title_type, aging_bucket, title_count, open_amount from vw_mc_financial_aging where unit_id = 1;
select plan_table_output from table(dbms_xplan.display(null, 'HC_AGING', 'BASIC +PREDICATE +ALIAS'));

explain plan set statement_id = 'HC_INTEGRATION_QUEUE' for
select integration_id, source_type, source_id from mc_accounting_integration where status = 'PENDING' order by created_at fetch first 100 rows only;
select plan_table_output from table(dbms_xplan.display(null, 'HC_INTEGRATION_QUEUE', 'BASIC +PREDICATE +ALIAS'));

explain plan set statement_id = 'HC_FEFO' for
select lot_id, quantity, reserved_quantity from mc_inventory_lot where product_id = 1 and unit_id = 1 and quantity > reserved_quantity and (expires_on is null or expires_on >= trunc(sysdate)) order by expires_on nulls last, lot_id;
select plan_table_output from table(dbms_xplan.display(null, 'HC_FEFO', 'BASIC +PREDICATE +ALIAS'));

