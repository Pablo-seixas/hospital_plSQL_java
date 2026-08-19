whenever sqlerror exit failure rollback
set serveroutput on
declare
    v_period_id number;
    v_batch_id number;
    v_debit_account number;
begin
    select period_id into v_period_id from mc_accounting_period where status = 'OPEN' fetch first 1 row only;
    select account_id into v_debit_account from mc_account where posting_allowed = 'Y' fetch first 1 row only;
    insert into mc_journal_batch(period_id, source_type, source_id, idempotency_key) values (v_period_id, 'QA', 'UNBALANCED', 'QA-UNBALANCED') returning batch_id into v_batch_id;
    insert into mc_journal_entry(batch_id, account_id, entry_date, description, debit_amount) values (v_batch_id, v_debit_account, trunc(sysdate), 'QA imbalance', 100);
    begin
        pkg_accounting.post_batch(v_batch_id, 'QA', 'QA-ACCOUNTING-001');
        raise_application_error(-20990, 'UNBALANCED_BATCH_WAS_ACCEPTED');
    exception when others then
        if sqlcode <> -20303 then raise; end if;
    end;
    rollback;
    dbms_output.put_line('PASS accounting rejects unbalanced journal');
end;
/

