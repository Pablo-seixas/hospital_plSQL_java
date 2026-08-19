whenever sqlerror exit failure rollback
set echo on
set serveroutput on
spool qa/evidence/oracle-test-output.txt
select object_type, object_name, status from user_objects where status = 'INVALID' order by object_type, object_name;
select name, type, line, position, text from user_errors order by name, sequence;
@database/tests/accounting_invariants.sql
@database/tests/inventory_invariants.sql
@qa/sql/smoke_integrity.sql
@qa/sql/performance_plans.sql
spool off
exit success

