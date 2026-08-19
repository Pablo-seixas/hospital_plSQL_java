create or replace view vw_mc_management_monthly as
with months as (
    select add_months(trunc(sysdate, 'MM'), 1 - level) competence from dual connect by level <= 12
), financial as (
    select trunc(s.settled_at, 'MM') competence,
           sum(case when t.title_type = 'RECEIVABLE' then s.principal_amount else 0 end) revenue,
           sum(case when t.title_type = 'PAYABLE' then s.principal_amount else 0 end) expense
      from mc_settlement s join mc_financial_title t on t.title_id = s.title_id
     where s.status = 'CONFIRMED'
     group by trunc(s.settled_at, 'MM')
), billing as (
    select trunc(issued_at, 'MM') competence, sum(amount) invoiced from mc_invoice group by trunc(issued_at, 'MM')
)
select m.competence, nvl(f.revenue,0) revenue, nvl(f.expense,0) expense, nvl(b.invoiced,0) invoiced,
       nvl(f.revenue,0) - nvl(f.expense,0) operating_result,
       lag(nvl(f.revenue,0)) over(order by m.competence) previous_revenue,
       case when lag(nvl(f.revenue,0)) over(order by m.competence) = 0 then null
            else round((nvl(f.revenue,0) - lag(nvl(f.revenue,0)) over(order by m.competence)) / lag(nvl(f.revenue,0)) over(order by m.competence) * 100, 2) end revenue_change_percent,
       sum(nvl(f.revenue,0) - nvl(f.expense,0)) over(order by m.competence rows unbounded preceding) accumulated_result
  from months m left join financial f on f.competence = m.competence left join billing b on b.competence = m.competence;

create or replace view vw_mc_cost_center_ranking as
select competence, cost_center_id, cost_center_name, expense_amount,
       rank() over(partition by competence order by expense_amount desc) expense_rank,
       dense_rank() over(partition by competence order by expense_amount desc) expense_dense_rank,
       round(expense_amount / nullif(sum(expense_amount) over(partition by competence),0) * 100, 2) participation_percent
  from (
        select trunc(e.entry_date, 'MM') competence, c.cost_center_id, c.name cost_center_name, sum(e.debit_amount) expense_amount
          from mc_journal_entry e join mc_journal_batch b on b.batch_id = e.batch_id and b.status = 'POSTED'
          join mc_account a on a.account_id = e.account_id join mc_cost_center c on c.cost_center_id = e.cost_center_id
         where a.code like '4.%'
         group by trunc(e.entry_date, 'MM'), c.cost_center_id, c.name
  );

create or replace view vw_mc_hospital_kpi as
select u.unit_id, u.code unit_code,
       count(distinct case when a.status = 'ACTIVE' then a.admission_id end) active_admissions,
       count(distinct case when a.status = 'DISCHARGED' and a.discharged_at >= trunc(sysdate, 'MM') then a.admission_id end) monthly_discharges,
       round(avg(case when a.status = 'DISCHARGED' then cast(a.discharged_at as date) - cast(a.admitted_at as date) end),2) average_length_of_stay,
       count(distinct case when bed.status = 'OCCUPIED' then bed.bed_id end) occupied_beds,
       count(distinct bed.bed_id) total_beds,
       round(count(distinct case when bed.status = 'OCCUPIED' then bed.bed_id end) / nullif(count(distinct bed.bed_id),0) * 100,2) occupancy_rate
  from mc_business_unit u left join mc_admission a on a.unit_id = u.unit_id left join mc_bed bed on bed.unit_id = u.unit_id
 group by u.unit_id, u.code;

create or replace view vw_mc_management_alert as
select 'INTEGRATION_ERROR' alert_type, 'HIGH' severity, to_char(integration_id) entity_id, 'Accounting integration requires reprocessing' message, created_at detected_at
  from mc_accounting_integration where status = 'ERROR'
union all
select 'OVERDUE_TITLE', 'MEDIUM', to_char(title_id), 'Financial title is overdue', cast(due_date as timestamp)
  from mc_financial_title where status in ('OPEN','PARTIAL') and due_date < trunc(sysdate)
union all
select 'EXPIRING_STOCK', 'MEDIUM', to_char(lot_id), 'Inventory lot expires within 30 days', cast(expires_on as timestamp)
  from mc_inventory_lot where quantity > 0 and expires_on between trunc(sysdate) and trunc(sysdate) + 30
union all
select 'UNCLOSED_HOSPITAL_ACCOUNT', 'LOW', to_char(hospital_account_id), 'Hospital account remains open after discharge', a.discharged_at
  from mc_hospital_account h join mc_admission a on a.admission_id = h.admission_id where h.status = 'OPEN' and a.status = 'DISCHARGED';

