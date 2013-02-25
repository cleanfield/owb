set linesize 120
set pagesize 50
set trimspool on

column flow_package            format a15
column overkoepelende_flow     format a15
column flow                    format a25
column activity                format a40

select prc1.package_name       flow_package
     , act2.process_name       overkoepelende_flow
     , prc1.process_name       flow
     , act1.activity_name      activity
from   all_iv_processes prc1
join   all_iv_process_activities act1 on (prc1.process_id = act1.process_id)
join   all_iv_process_activities act2 on (act1.process_name = act2.activity_name)
-- join   all_iv_processes prc2 on (prc2.activity_name = prc1.process_name) 
where act1.activity_name like upper('%&1%')
order by prc1.process_name desc
       , act2.process_name desc;
