set linesize 120                         
set pagesize 50                          
set trimspool on                         
                                         
column status              format a15
column deployed_object     format a30
-- column deployed_type       format a15
column deployed_date       format a20
column location            format a20
-- column location_type       format a10

select status
     , deployed_object
--     , deployed_type
     , deployed_date
     , location
--     , location_type 
from (
select ao.status_when_deployed         status
     , ao.object_name                  deployed_object
     , ao.object_type                  deployed_type
     , ao.version_tag                  deployed_date
     , al.location_name                location
     , al.location_type || ' ' || 
       al.location_type_version        location_type 
     , row_number() over (order by ao.version_tag desc)    rij
from   all_rt_audit_locations al
join   all_rt_audit_objects ao on (ao.location_audit_id = al.location_audit_id)
where  parent_object_audit_id is null
) where rij  < 11
order by deployed_date desc
;