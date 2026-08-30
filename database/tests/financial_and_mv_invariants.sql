whenever sqlerror exit failure rollback
set serveroutput on
declare
    v_unit_id number;
    v_cost_center_id number;
    v_title_id number;
    v_same_title_id number;
    v_status mc_financial_title.status%type;
    v_open_amount mc_financial_title.open_amount%type;
    v_settlement_id number;
    v_reversal_id number;
    v_count number;
begin
    select unit_id into v_unit_id from mc_business_unit fetch first 1 row only;
    select cost_center_id into v_cost_center_id from mc_cost_center where unit_id = v_unit_id fetch first 1 row only;

    pkg_financial.create_title('RECEIVABLE', v_unit_id, v_cost_center_id, 'QA-FIN-MV', 'QA-FIN-TITLE-001', trunc(sysdate), trunc(sysdate) + 30, 1000, v_title_id);
    pkg_financial.create_title('RECEIVABLE', v_unit_id, v_cost_center_id, 'QA-FIN-MV', 'QA-FIN-TITLE-001', trunc(sysdate), trunc(sysdate) + 30, 1000, v_same_title_id);
    if v_title_id <> v_same_title_id then raise_application_error(-20970, 'TITLE_IDEMPOTENCY_FAILED'); end if;

    begin
        pkg_financial.create_title('RECEIVABLE', v_unit_id, v_cost_center_id, 'QA-FIN-MV', 'QA-FIN-TITLE-001', trunc(sysdate), trunc(sysdate) + 30, 999, v_same_title_id);
        raise_application_error(-20971, 'IDEMPOTENCY_MISMATCH_ACCEPTED');
    exception when others then
        if sqlcode <> -20406 then raise; end if;
    end;

    pkg_financial.settle_title(v_title_id, 'QA-FIN-SETTLE-001', 400, 10, 5, 0, 'QA', 'QA-FIN-001');
    select status, open_amount into v_status, v_open_amount from mc_financial_title where title_id = v_title_id;
    if v_status <> 'PARTIAL' or v_open_amount <> 600 then raise_application_error(-20972, 'PARTIAL_SETTLEMENT_FAILED'); end if;

    begin
        pkg_financial.settle_title(v_title_id, 'QA-FIN-SETTLE-001', 400, 10, 5, 0, 'QA', 'QA-FIN-002');
        raise_application_error(-20973, 'DUPLICATE_SETTLEMENT_ACCEPTED');
    exception when others then
        if sqlcode <> -20403 then raise; end if;
    end;

    savepoint before_closed_period_test;
    update mc_accounting_period set status = 'CLOSED' where fiscal_year = extract(year from sysdate) and fiscal_month = extract(month from sysdate);
    begin
        pkg_financial.settle_title(v_title_id, 'QA-FIN-CLOSED-PERIOD', 100, 0, 0, 0, 'QA', 'QA-FIN-CLOSED');
        raise_application_error(-20978, 'CLOSED_PERIOD_SETTLEMENT_ACCEPTED');
    exception when others then
        if sqlcode <> -20404 then raise; end if;
    end;
    rollback to before_closed_period_test;

    pkg_financial.settle_title(v_title_id, 'QA-FIN-SETTLE-002', 600, 0, 0, 0, 'QA', 'QA-FIN-003');
    select status, open_amount into v_status, v_open_amount from mc_financial_title where title_id = v_title_id;
    if v_status <> 'SETTLED' or v_open_amount <> 0 then raise_application_error(-20974, 'FULL_SETTLEMENT_FAILED'); end if;

    select settlement_id into v_settlement_id from mc_settlement where idempotency_key = 'QA-FIN-SETTLE-002';
    pkg_financial.reverse_settlement(v_settlement_id, 'QA-FIN-REVERSAL-001', 'QA', 'QA-FIN-004', v_reversal_id);
    select status, open_amount into v_status, v_open_amount from mc_financial_title where title_id = v_title_id;
    if v_status <> 'PARTIAL' or v_open_amount <> 600 then raise_application_error(-20975, 'SETTLEMENT_REVERSAL_FAILED'); end if;

    rollback;
    pkg_reporting.refresh_analytics('QA');
    select count(*) into v_count from vw_mc_analytics_refresh_status where materialized_view_name = 'MV_MC_EXECUTIVE_KPI' and refresh_rank = 1 and status = 'SUCCESS';
    if v_count <> 1 then raise_application_error(-20976, 'MV_REFRESH_NOT_LOGGED'); end if;
    select count(*) into v_count from mv_mc_executive_kpi where unit_id = v_unit_id;
    if v_count <> 1 then raise_application_error(-20977, 'MV_UNIT_KPI_NOT_REFRESHED'); end if;

    dbms_output.put_line('PASS financial lifecycle, idempotency, reversal and MV refresh');
end;
/
