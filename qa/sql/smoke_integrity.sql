declare
    v_count number;
begin
    select count(*) into v_count from mc_admission a join mc_admission b on b.current_bed_id = a.current_bed_id and b.admission_id > a.admission_id where a.status = 'ACTIVE' and b.status = 'ACTIVE';
    if v_count > 0 then raise_application_error(-20980, 'DUPLICATE_ACTIVE_BED_FOUND'); end if;
    select count(*) into v_count from mc_inventory_lot where quantity < 0 or reserved_quantity < 0 or reserved_quantity > quantity;
    if v_count > 0 then raise_application_error(-20981, 'INVALID_INVENTORY_BALANCE'); end if;
    select count(*) into v_count from (select e.batch_id from mc_journal_entry e join mc_journal_batch b on b.batch_id = e.batch_id where b.status = 'POSTED' group by e.batch_id having sum(e.debit_amount) <> sum(e.credit_amount));
    if v_count > 0 then raise_application_error(-20982, 'UNBALANCED_POSTED_BATCH'); end if;
    dbms_output.put_line('PASS database integrity smoke tests');
end;
/

