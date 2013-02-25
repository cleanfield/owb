rem SYNOPSYS
rem
rem   @sqlplus_exec_template.sql rt_owner location_name {PLSQL | SQL_LOADER | PROCESS} task_name system_params custom_params
rem
rem NAME
rem
rem   sqlplus_exec_template.sql - SQLPlus Execution Template
rem
rem USAGE
rem
rem   rt_owner      := e.g. MY_RUNTIME    - Name of the Runtime Repository Owner
rem
rem   location_name :- e.g. MY_WAREHOUSE  - Physical Name of the Location to which this task was deployed
rem                                         (i.e. a DB Location or a Process Location or the Platform Schema)
rem                                         Note: Always use "PlaformSchema" for SQL_LOADER types.
rem
rem   task_type     :- PLSQL              - OWB PL/SQL Mapping
rem                 |  SQL_LOADER         - OWB SQL*Loader Mapping
rem                 |  PROCESS            - OWB ProcessFlow
rem
rem   task_name     :- e.g. MY_MAPPING    - Physical Name of the Deployed Object
rem
rem   custom_params :- { , | (name = value [, name = value]...)}
rem                    e.g. ","
rem                    or   MY_PARAM=1,YOUR_PARAM=true
rem
rem   system_params :- { , | (name = value [, name = value]...)}
rem                    e.g. ","
rem                    or   MY_PARAM=1,YOUR_PARAM=true
rem
rem RETURNS
rem
rem   1 if task reports SUCCESS, 2 if WARNING, 3 if ERROR
rem
rem
rem DESCRIPTION
rem
rem   This SQL*Plus script can be called from the SQL*Plus shell.  Through SQL*Plus OWB
rem   objects can be executed through scheduling tools such as cron and AT as well as 
rem   enterprise environments such as Autosys and Tivoli.
rem
rem   A separate script oem_exec_template.sql is provided for more friendly execution
rem   from OEM.
rem
rem   This script is design to be run from a Runtime User, not the Runtime Repository Owner.
rem   The Runtime Repository Owner is nominated in the parameters.
rem
rem   In its unchanged form the script takes the three keys required to identify 
rem   the executable task. 
rem
rem   The task is executed with the default parameters configured prior to deployment.
rem
rem   The custom_params and system_params values override the default input parameters 
rem   of the task.
rem   
rem   Note: The comma character can be escaped using the backslash character; likewise the backslash 
rem         character can be escaped by itself.
rem
rem   A list of the valid System Parameters for each task type can be obtained from the OWB
rem   documentation, but generally the deployed defaults are sufficient.  The Custom Parameters
rem   are defined on the object in the OWB Designer.
rem
rem EXAMPLE
rem
rem   sqlplus user/password@tns_name @sqlplus_exec_template.sql MY_RUNTIME MY_WAREHOUSE PLSQL MY_MAPPING "," ","
rem   sqlplus user/password@tns_name @sqlplus_exec_template.sql MY_RUNTIME PlatformSchema SQL_LOADER MY_LOAD "," ","
rem   sqlplus user/password@tns_name @sqlplus_exec_template.sql MY_RUNTIME MY_WORKFLOW PROCESS MY_PROCESS "," ","
--

define OEM_FRIENDLY=false

set serveroutput on
set verify off

whenever sqlerror exit failure;

define REPOS_OWNER=&1
define LOCATION_NAME=&2
define TASK_TYPE=&3
define TASK_NAME=&4
define SYSTEM_PARAMS=&5
define CUSTOM_PARAMS=&6

alter session set current_schema = &REPOS_OWNER;
set role wb_r_&REPOS_OWNER, wb_u_&REPOS_OWNER;

variable exec_return_code number;

declare
  l_oem_style          boolean := &OEM_FRIENDLY;
  l_audit_execution_id number;                                  -- Audit Execution Id
  l_audit_result       number := wb_rt_api_exec.RESULT_FAILURE; -- Result Code
  l_audit_result_disp  varchar2(64) := 'FAILURE';               -- Result Display Code

  l_task_type_name     varchar2(64);                            -- Task Type Name
  l_task_type          varchar2(64);                            -- Task Type
  l_task_name          varchar2(64);                            -- Task Name
  l_location_name      varchar2(64);                            -- Location Name
  
  procedure override_input_parameter
  (
    p_audit_execution_id in number,
    p_parameter_name in varchar2,
    p_value in varchar2,
    p_parameter_kind in number
  )
  is
    l_parameter_kind varchar2(64);
  begin
    
    if p_parameter_kind = wb_rt_api_exec.PARAMETER_KIND_SYSTEM
    then
      l_parameter_kind := 'SYSTEM';
    else
      l_parameter_kind := 'CUSTOM';
    end if;
    
    dbms_output.put_line('|  ' || p_parameter_name || '%' || l_parameter_kind || '=' || '''' || p_value || '''');
 
    wb_rt_api_exec.override_input_parameter
    (
      p_audit_execution_id,
      p_parameter_name,
      p_value,
      p_parameter_kind
    );
      
  end;

  procedure override_input_parameters
  (
    p_audit_execution_id in number,
    p_parameters varchar2,
    p_parameter_kind in number
  )
  is
    l_anchor_offset number := 1;
    l_start_offset number := 1;
    l_equals_offset number;
    l_comma_offset number;
    l_value_offset number;
    l_esc_offset number;
    l_esc_count number;
    l_esc_char varchar2(4);
    l_parameter_name varchar2(4000);
    l_parameter_value varchar2(4000);

    function strip_escape
    (
      p_escapedString varchar2
    )
    return varchar2
    is
      l_strippedString varchar2(4000);
      l_a_char varchar2(4);
      l_b_char varchar2(4);
      l_strip_offset number := 1;
    begin
      loop
        exit when p_escapedString is null or l_strip_offset > length(p_escapedString);
        l_a_char := SUBSTR(p_escapedString, l_strip_offset, 1);
        if l_strip_offset = length(p_escapedString)
        then
          l_strippedString := l_strippedString || l_a_char;
          exit;
        else
          if l_a_char = '\'
          then
            l_b_char := SUBSTR(p_escapedString, l_strip_offset + 1, 1);
            if l_b_char = '\' or l_b_char = ','
            then
              l_strippedString := l_strippedString || l_b_char;
              l_strip_offset := l_strip_offset + 1;
            end if;
          else
            l_strippedString := l_strippedString || l_a_char;
          end if;
        end if;
        l_strip_offset := l_strip_offset + 1;
      end loop;

      return l_strippedString; 
    end;

  begin
    loop
      l_equals_offset := INSTR(p_parameters, '=', l_start_offset);

      exit when l_equals_offset = 0;

      l_start_offset := l_equals_offset + 1;
      loop
        l_comma_offset := INSTR(p_parameters, ',', l_start_offset);

        if l_comma_offset = 0
        then
          l_comma_offset := length(p_parameters) + 1;
          exit;
        else
          l_esc_count := 0;
          l_esc_offset := l_comma_offset - 1;
          loop
            l_esc_char := SUBSTR(p_parameters, l_esc_offset, 1);
            exit when l_esc_char != '\';
            l_esc_count := l_esc_count + 1;
            l_esc_offset := l_esc_offset - 1;
          end loop;

          if MOD(l_esc_count, 2) != 0
          then
            l_start_offset := l_comma_offset + 1;
          else
            exit;
          end if;
        end if;
      end loop;

      l_parameter_name := LTRIM(RTRIM(SUBSTR(p_parameters, l_anchor_offset, l_equals_offset - l_anchor_offset)));
      l_parameter_value := strip_escape(SUBSTR(p_parameters, l_equals_offset + 1, l_comma_offset - (l_equals_offset + 1)));

      -- Override Input Parameter
      override_input_parameter(p_audit_execution_id, l_parameter_name, l_parameter_value, p_parameter_kind);

      exit when l_comma_offset >= length(p_parameters)-1;

      l_start_offset := l_comma_offset + 1;
      l_anchor_offset := l_start_offset;

    end loop;
  end;
  
  procedure override_custom_input_params
  (
    p_audit_execution_id in number,
    p_parameters varchar2
  )
  is
    l_parameter_kind number := wb_rt_api_exec.PARAMETER_KIND_CUSTOM;
  begin
    override_input_parameters(p_audit_execution_id, p_parameters, l_parameter_kind);
    null;
  end;
  
  procedure override_system_input_params
  (
    p_audit_execution_id in number,
    p_parameters varchar2
  )
  is
    l_parameter_kind number := wb_rt_api_exec.PARAMETER_KIND_SYSTEM;
  begin
    override_input_parameters(p_audit_execution_id, p_parameters, l_parameter_kind);
    null;
  end;
  
begin
  --
  -- Initialize Return Code
  --
  :exec_return_code := wb_rt_api_exec.RESULT_FAILURE;
  
  --
  -- Import Parameters
  --
  dbms_output.put_line('Stage 1: Decoding Parameters');
  l_task_type_name := '&TASK_TYPE';
  if UPPER(l_task_type_name) = 'PLSQL'
  then
    l_task_type := 'PLSQL';
  elsif UPPER(l_task_type_name) = 'SQL_LOADER'
  then
    l_task_type := 'SQLLoader';
  elsif UPPER(l_task_type_name) = 'PROCESS'
  then
    l_task_type := 'ProcessFlow';
  else
    l_task_type := l_task_type_name;
  end if;
  l_task_name := '&TASK_NAME';
  l_location_name := '&LOCATION_NAME';
  dbms_output.put_line('|  location_name=' || l_location_name);
  dbms_output.put_line('|  task_type=' || l_task_type);
  dbms_output.put_line('|  task_name=' || l_task_name);

  --
  -- Decode Parameters
  --
  begin
    --
    -- Prepare Execution
    --
    dbms_output.put_line('Stage 2: Opening Task');
    l_audit_execution_id := wb_rt_api_exec.open(l_task_type, l_task_name, l_location_name);
    dbms_output.put_line('|  l_audit_execution_id=' || to_char(l_audit_execution_id));

    commit;

    --
    -- Override Parameters
    --
    dbms_output.put_line('Stage 3: Overriding Parameters');
    override_system_input_params(l_audit_execution_id, '&SYSTEM_PARAMS');
    override_custom_input_params(l_audit_execution_id, '&CUSTOM_PARAMS');
    
    -- 
    -- Execute
    -- 
    dbms_output.put_line('Stage 4: Executing Task');
    l_audit_result := wb_rt_api_exec.execute(l_audit_execution_id);
    if l_audit_result = wb_rt_api_exec.RESULT_SUCCESS
    then
      l_audit_result_disp := 'SUCCESS';
    elsif l_audit_result = wb_rt_api_exec.RESULT_WARNING
    then
      l_audit_result_disp := 'WARNING';
    elsif l_audit_result = wb_rt_api_exec.RESULT_FAILURE
    then
      l_audit_result_disp := 'FAILURE';
    else
      l_audit_result_disp := 'UNKNOWN';
    end if;
    dbms_output.put_line('|  l_audit_result=' || to_char(l_audit_result) || ' (' || l_audit_result_disp || ')');

    -- Finish Execution
    dbms_output.put_line('Stage 5: Closing Task');
    wb_rt_api_exec.close(l_audit_execution_id);

    commit;

    dbms_output.put_line('Stage 6: Processing Result');
    if l_oem_style
    then
      if l_audit_result = wb_rt_api_exec.RESULT_SUCCESS
      then
        :exec_return_code := 0;
      elsif l_audit_result = wb_rt_api_exec.RESULT_WARNING
      then
        :exec_return_code := 0;
      else
        :exec_return_code := l_audit_result;
      end if;
    else
      :exec_return_code := l_audit_result;
    end if;
    dbms_output.put_line('|  exit=' || to_char(:exec_return_code));
  exception
    when no_data_found
    then
      raise_application_error(-20001, 'Task not found - Please check the Task Type, Name and Location are correct.');
  end;
end;
/
exit :exec_return_code;
