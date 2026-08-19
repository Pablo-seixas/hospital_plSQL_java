whenever sqlerror exit failure rollback
set serveroutput on
declare
    v_product_id number;
    v_unit_id number;
begin
    select product_id into v_product_id from mc_product fetch first 1 row only;
    select unit_id into v_unit_id from mc_business_unit fetch first 1 row only;
    begin
        pkg_inventory.issue_fefo(v_product_id, v_unit_id, 999999, 'QA', 'NEGATIVE-STOCK', 'QA', 'QA-INVENTORY-001');
        raise_application_error(-20991, 'NEGATIVE_STOCK_WAS_ACCEPTED');
    exception when others then
        if sqlcode <> -20202 then raise; end if;
    end;
    rollback;
    dbms_output.put_line('PASS inventory prevents negative stock');
end;
/
