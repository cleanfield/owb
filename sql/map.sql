set linesize 120
set pagesize 50
set trimspool on

column module                  format a10
column map_name                format a40
column updated_on              format a15
column updated_by              format a15

select m.information_system_name module
     , m.map_name
     , m.updated_on
     , m.updated_by
from owb_rtowner.all_iv_xform_maps m
where  m.map_name like upper('%&1%')
and    m.map_name like nvl(upper('%&2%'), m.map_name)
order  by updated_on desc
;
