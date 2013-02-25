set linesize 120
set pagesize 50
set trimspool on

column audit_execution_id      format 999999999
column creation_date           format 999999999
column task_object_name        format a30
column task_name               format a40
column execution_object_name   format a30
column moeder                  format 999999999
column errors                  format 999
column warnings                format 999
column elapse                  format 99999

select to_char(ae.creation_date, 'dd-mm-yyyy hh24:mi:ss')  creation_date
     , ae.task_object_name
--     , ae.task_name
     , ae.execution_object_name
--     , ae.parent_audit_execution_id
     , ae.top_level_audit_execution_id                                                             moeder
/*
     , case when ae.number_of_task_errors > 0 then ae.number_of_task_errors else null end          errors
     , case when ae.number_of_task_warnings > 0 then ae.number_of_task_warnings else null end      warnings
*/
     , ae.number_of_task_errors                                                                    errors
     , ae.number_of_task_warnings                                                                  warnings
     , elapse
from wb_rt_audit_executions ae
where creation_date > sysdate - 1
order by audit_execution_id desc
; 
