insert into mc_business_unit(code, name) values ('MC-NORTH', 'MedCore North Unit');
insert into mc_business_unit(code, name) values ('MC-COAST', 'MedCore Coast Unit');

insert into mc_cost_center(unit_id, code, name) select unit_id, 'CC-CLINICAL', 'Clinical Operations' from mc_business_unit;
insert into mc_cost_center(unit_id, code, name) select unit_id, 'CC-PHARMACY', 'Pharmacy Operations' from mc_business_unit;

insert into mc_account(code, name, nature, posting_allowed) values ('1', 'Assets', 'D', 'N');
insert into mc_account(code, name, nature, posting_allowed) values ('1.1.01', 'Cash and Banks', 'D', 'Y');
insert into mc_account(code, name, nature, posting_allowed) values ('1.1.02', 'Accounts Receivable', 'D', 'Y');
insert into mc_account(code, name, nature, posting_allowed) values ('2', 'Liabilities', 'C', 'N');
insert into mc_account(code, name, nature, posting_allowed) values ('2.1.01', 'Accounts Payable', 'C', 'Y');
insert into mc_account(code, name, nature, posting_allowed) values ('3.1.01', 'Healthcare Revenue', 'C', 'Y');
insert into mc_account(code, name, nature, posting_allowed) values ('4.1.01', 'Clinical Supplies Expense', 'D', 'Y');

insert into mc_accounting_period(fiscal_year, fiscal_month) values (extract(year from sysdate), extract(month from sysdate));

insert into mc_bed(unit_id, code)
select u.unit_id, 'BED-' || lpad(level, 3, '0') from mc_business_unit u connect by level <= 40 and prior unit_id = unit_id and prior sys_guid() is not null;

insert into mc_product(sku, name, product_type)
select 'MED-' || lpad(level, 4, '0'), 'Synthetic Medication ' || level, 'MEDICATION' from dual connect by level <= 100;

insert into mc_product(sku, name, product_type)
select 'MAT-' || lpad(level, 4, '0'), 'Synthetic Clinical Material ' || level, 'MATERIAL' from dual connect by level <= 100;

insert into mc_patient(synthetic_name, birth_date)
select 'Synthetic Patient ' || lpad(level, 5, '0'), date '1940-01-01' + mod(level * 37, 25000) from dual connect by level <= 2000;

insert into mc_business_parameter(parameter_key, version_no, value_type, parameter_value, valid_from, approved_by)
values ('FINANCIAL.DEFAULT_LATE_FEE_PERCENT', 1, 'NUMBER', '2.00', systimestamp, 'SYSTEM_SEED');

