source c:/Scripts/tcl/omb_sql_library.tcl
source c:/Scripts/omb_exec.tcl
source c:/Scripts/tcl/connect.tcl
#
proc runmap {map waar} {
  #
  set oraConn [ connect SQL $waar ]
  set ombconn [ connect OWB $waar ]
  #
  set sql "select information_system_name owb_module from owb_rtowner.all_iv_xform_maps where map_name = '$map'"
  set oraRs [ oracleQuery $oraConn $sql ]
  #
  while {[$oraRs next]} {
    set owb_module [$oraRs getString owb_module]
  }
  #
  $oraRs close
  oracleDisconnect $oraConn
  #  
  exec_omb OMBCC 'INFORM'
  exec_omb OMBCC '$owb_module'
  exec_omb OMBCONNECT CONTROL_CENTER
  exec_omb OMBSTART MAPPING '$map' IN 'LOC_$owb_module' 
  exec_omb OMBCOMMIT
  exec_omb OMBDISCONNECT 
}
