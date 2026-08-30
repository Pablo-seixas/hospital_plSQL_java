create or replace package pkg_audit as
    procedure record_event(p_actor varchar2, p_action varchar2, p_entity_type varchar2, p_entity_id varchar2, p_correlation_id varchar2, p_old_value clob default null, p_new_value clob default null);
end pkg_audit;
/

create or replace package body pkg_audit as
    procedure record_event(p_actor varchar2, p_action varchar2, p_entity_type varchar2, p_entity_id varchar2, p_correlation_id varchar2, p_old_value clob default null, p_new_value clob default null) is
    begin
        insert into mc_audit_event(actor, action, entity_type, entity_id, correlation_id, old_value, new_value)
        values (p_actor, p_action, p_entity_type, p_entity_id, p_correlation_id, p_old_value, p_new_value);
    end;
end pkg_audit;
/

create or replace package pkg_admission as
    procedure transfer_bed(p_admission_id number, p_expected_bed_id number, p_new_bed_id number, p_reason varchar2, p_actor varchar2, p_correlation_id varchar2);
end pkg_admission;
/

create or replace package body pkg_admission as
    procedure transfer_bed(p_admission_id number, p_expected_bed_id number, p_new_bed_id number, p_reason varchar2, p_actor varchar2, p_correlation_id varchar2) is
        v_current_bed_id number;
        v_status mc_admission.status%type;
        v_new_status mc_bed.status%type;
        e_resource_busy exception;
        pragma exception_init(e_resource_busy, -54);
    begin
        select current_bed_id, status into v_current_bed_id, v_status from mc_admission where admission_id = p_admission_id for update wait 5;
        if v_status <> 'ACTIVE' then raise_application_error(-20101, 'ADMISSION_NOT_ACTIVE'); end if;
        if v_current_bed_id <> p_expected_bed_id then raise_application_error(-20102, 'BED_STATE_CHANGED'); end if;
        select status into v_new_status from mc_bed where bed_id = p_new_bed_id for update wait 5;
        if v_new_status <> 'AVAILABLE' then raise_application_error(-20103, 'TARGET_BED_UNAVAILABLE'); end if;
        select status into v_new_status from mc_bed where bed_id = v_current_bed_id for update wait 5;
        savepoint before_bed_transfer;
        update mc_bed_occupancy set ended_at = systimestamp, transfer_reason = p_reason where admission_id = p_admission_id and ended_at is null;
        update mc_bed set status = 'AVAILABLE', record_version = record_version + 1 where bed_id = v_current_bed_id;
        update mc_bed set status = 'OCCUPIED', record_version = record_version + 1 where bed_id = p_new_bed_id and status = 'AVAILABLE';
        if sql%rowcount <> 1 then raise_application_error(-20103, 'TARGET_BED_UNAVAILABLE'); end if;
        update mc_admission set current_bed_id = p_new_bed_id where admission_id = p_admission_id;
        insert into mc_bed_occupancy(admission_id, bed_id, transfer_reason) values (p_admission_id, p_new_bed_id, p_reason);
        pkg_audit.record_event(p_actor, 'BED_TRANSFERRED', 'ADMISSION', to_char(p_admission_id), p_correlation_id,
            json_object('bedId' value v_current_bed_id), json_object('bedId' value p_new_bed_id));
    exception
        when e_resource_busy then raise_application_error(-20104, 'BED_LOCK_TIMEOUT');
    end;
end pkg_admission;
/

create or replace package pkg_inventory as
    procedure issue_fefo(p_product_id number, p_unit_id number, p_quantity number, p_reference_type varchar2, p_reference_id varchar2, p_actor varchar2, p_correlation_id varchar2);
end pkg_inventory;
/

create or replace package body pkg_inventory as
    procedure issue_fefo(p_product_id number, p_unit_id number, p_quantity number, p_reference_type varchar2, p_reference_id varchar2, p_actor varchar2, p_correlation_id varchar2) is
        v_remaining number := p_quantity;
        v_take number;
        v_available number;
    begin
        if p_quantity <= 0 then raise_application_error(-20201, 'INVALID_ISSUE_QUANTITY'); end if;
        savepoint before_inventory_issue;
        for lot in (select lot_id, quantity, reserved_quantity from mc_inventory_lot
                     where product_id = p_product_id and unit_id = p_unit_id and quantity > reserved_quantity
                       and (expires_on is null or expires_on >= trunc(sysdate))
                     order by expires_on nulls last, lot_id for update skip locked) loop
            exit when v_remaining = 0;
            v_available := lot.quantity - lot.reserved_quantity;
            v_take := least(v_available, v_remaining);
            update mc_inventory_lot set quantity = quantity - v_take, record_version = record_version + 1 where lot_id = lot.lot_id;
            insert into mc_inventory_movement(lot_id, movement_type, quantity, reference_type, reference_id, correlation_id, actor)
            values (lot.lot_id, 'ISSUE', v_take, p_reference_type, p_reference_id, p_correlation_id, p_actor);
            v_remaining := v_remaining - v_take;
        end loop;
        if v_remaining > 0 then rollback to before_inventory_issue; raise_application_error(-20202, 'INSUFFICIENT_STOCK'); end if;
        pkg_audit.record_event(p_actor, 'INVENTORY_ISSUED', 'PRODUCT', to_char(p_product_id), p_correlation_id, null,
            json_object('quantity' value p_quantity, 'unitId' value p_unit_id));
    exception
        when dup_val_on_index then rollback to before_inventory_issue; raise_application_error(-20203, 'DUPLICATE_INVENTORY_REQUEST');
    end;
end pkg_inventory;
/

create or replace package pkg_accounting as
    procedure post_batch(p_batch_id number, p_actor varchar2, p_correlation_id varchar2);
    procedure close_period(p_period_id number, p_actor varchar2, p_correlation_id varchar2);
    function account_balance(p_account_id number, p_as_of_date date) return number;
end pkg_accounting;
/

create or replace package body pkg_accounting as
    procedure post_batch(p_batch_id number, p_actor varchar2, p_correlation_id varchar2) is
        v_period_status mc_accounting_period.status%type;
        v_batch_status mc_journal_batch.status%type;
        v_debit number;
        v_credit number;
    begin
        select b.status, p.status into v_batch_status, v_period_status from mc_journal_batch b join mc_accounting_period p on p.period_id = b.period_id where b.batch_id = p_batch_id for update;
        if v_batch_status <> 'DRAFT' then raise_application_error(-20301, 'BATCH_NOT_DRAFT'); end if;
        if v_period_status <> 'OPEN' then raise_application_error(-20302, 'ACCOUNTING_PERIOD_CLOSED'); end if;
        select nvl(sum(debit_amount),0), nvl(sum(credit_amount),0) into v_debit, v_credit from mc_journal_entry where batch_id = p_batch_id;
        if v_debit = 0 or v_debit <> v_credit then raise_application_error(-20303, 'UNBALANCED_JOURNAL'); end if;
        update mc_journal_batch set status = 'POSTED', posted_at = systimestamp where batch_id = p_batch_id;
        pkg_audit.record_event(p_actor, 'JOURNAL_POSTED', 'JOURNAL_BATCH', to_char(p_batch_id), p_correlation_id);
    end;

    procedure close_period(p_period_id number, p_actor varchar2, p_correlation_id varchar2) is
        v_open_batches number;
    begin
        select count(*) into v_open_batches from mc_journal_batch where period_id = p_period_id and status = 'DRAFT';
        if v_open_batches > 0 then raise_application_error(-20304, 'OPEN_BATCHES_EXIST'); end if;
        update mc_accounting_period set status = 'CLOSED', closed_at = systimestamp, closed_by = p_actor where period_id = p_period_id and status = 'OPEN';
        if sql%rowcount <> 1 then raise_application_error(-20305, 'PERIOD_NOT_OPEN'); end if;
        pkg_audit.record_event(p_actor, 'PERIOD_CLOSED', 'ACCOUNTING_PERIOD', to_char(p_period_id), p_correlation_id);
    end;

    function account_balance(p_account_id number, p_as_of_date date) return number is
        v_balance number;
    begin
        select nvl(sum(e.debit_amount - e.credit_amount), 0) into v_balance from mc_journal_entry e join mc_journal_batch b on b.batch_id = e.batch_id where e.account_id = p_account_id and e.entry_date <= p_as_of_date and b.status = 'POSTED';
        return v_balance;
    end;
end pkg_accounting;
/

create or replace package pkg_financial as
    procedure create_title(p_type varchar2, p_unit_id number, p_cost_center_id number, p_reference varchar2, p_idempotency_key varchar2, p_issue_date date, p_due_date date, p_amount number, p_title_id out number);
    procedure settle_title(p_title_id number, p_idempotency_key varchar2, p_principal number, p_interest number, p_penalty number, p_discount number, p_actor varchar2, p_correlation_id varchar2);
end pkg_financial;
/

create or replace package body pkg_financial as
    procedure create_title(p_type varchar2, p_unit_id number, p_cost_center_id number, p_reference varchar2, p_idempotency_key varchar2, p_issue_date date, p_due_date date, p_amount number, p_title_id out number) is
    begin
        insert into mc_financial_title(title_type, unit_id, cost_center_id, external_reference, idempotency_key, issue_date, due_date, original_amount, open_amount)
        values (p_type, p_unit_id, p_cost_center_id, p_reference, p_idempotency_key, p_issue_date, p_due_date, p_amount, p_amount)
        returning title_id into p_title_id;
    exception when dup_val_on_index then
        select title_id into p_title_id from mc_financial_title where idempotency_key = p_idempotency_key;
    end;

    procedure settle_title(p_title_id number, p_idempotency_key varchar2, p_principal number, p_interest number, p_penalty number, p_discount number, p_actor varchar2, p_correlation_id varchar2) is
        v_open number;
        v_status mc_financial_title.status%type;
    begin
        select open_amount, status into v_open, v_status from mc_financial_title where title_id = p_title_id for update wait 5;
        if v_status not in ('OPEN','PARTIAL') then raise_application_error(-20401, 'TITLE_NOT_SETTLEABLE'); end if;
        if p_principal <= 0 or p_principal > v_open then raise_application_error(-20402, 'INVALID_SETTLEMENT_AMOUNT'); end if;
        insert into mc_settlement(title_id, idempotency_key, principal_amount, interest_amount, penalty_amount, discount_amount)
        values (p_title_id, p_idempotency_key, p_principal, nvl(p_interest,0), nvl(p_penalty,0), nvl(p_discount,0));
        update mc_financial_title set open_amount = open_amount - p_principal,
            status = case when open_amount - p_principal = 0 then 'SETTLED' else 'PARTIAL' end,
            record_version = record_version + 1 where title_id = p_title_id;
        pkg_audit.record_event(p_actor, 'TITLE_SETTLED', 'FINANCIAL_TITLE', to_char(p_title_id), p_correlation_id, null, json_object('principal' value p_principal));
    exception when dup_val_on_index then raise_application_error(-20403, 'DUPLICATE_SETTLEMENT');
    end;
end pkg_financial;
/
