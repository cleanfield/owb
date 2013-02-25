DECLARE 
  P_LOCATION_NAME    VARCHAR2(30);
  P_TASK_TYPE        VARCHAR2(30);
  P_TASK_NAME        VARCHAR2(50);
  P_SYSTEM_PARAMS    VARCHAR2(50);
  P_CUSTOM_PARAMS    VARCHAR2(50);
BEGIN
--
  P_TASK_NAME := '&1';
--
  select 'LOC_' || INFORMATION_SYSTEM_NAME 
  into   P_LOCATION_NAME
  from   OWB_RTOWNER.ALL_IV_XFORM_MAPS
  where  MAP_NAME = P_TASK_NAME;
--
  P_TASK_TYPE := 'MAPPING';
--
  P_SYSTEM_PARAMS := NULL;
  P_CUSTOM_PARAMS := NULL;
--
  INF_SYS.INF_RUN_OWB_CODE.RUN ( P_LOCATION_NAME, P_TASK_TYPE, P_TASK_NAME, P_SYSTEM_PARAMS, P_CUSTOM_PARAMS );
  COMMIT; 
END; 
/