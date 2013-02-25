source c:/Scripts/omb_exec.tcl
source c:/Scripts/gps.tcl

set collectie GPS_EB_DELETIONS
# set collectie [lindex $argv 0]
# set collectie [string toupper $collectie]

exec_omb OMBCONNECT OWB_RTOWNER/INFORM@10.40.200.166:12235:DWIO
# exec_omb OMBCONNECT OWB_RTOWNER/INFORMT@10.40.200.164:12239:DWIT

exec_omb OMBCC 'INFORM'
exec_omb OMBCONNECT CONTROL_CENTER
exec_omb OMBCOMMIT

exec_omb OMBCREATE TRANSIENT DEPLOYMENT_ACTION_PLAN 'RAL_MAP'
set mappings [OMBRETRIEVE COLLECTION '$collectie' GET MAPPING REFERENCES]
set i 1
foreach map $mappings {
  set action [file tail $map]
  set action [string range $map 2 28]
  set action $i$action
  exec_omb OMBALTER DEPLOYMENT_ACTION_PLAN 'RAL_MAP' ADD ACTION '$action' SET PROPERTIES(OPERATION) VALUES('REPLACE') SET REF MAPPING '$map'
  incr i
}

exec_omb OMBDEPLOY DEPLOYMENT_ACTION_PLAN 'RAL_MAP'
exec_omb OMBDROP DEPLOYMENT_ACTION_PLAN 'RAL_MAP'
exec_omb OMBCOMMIT

exec_omb OMBCC 'PFM_INFORM'
exec_omb OMBCREATE TRANSIENT DEPLOYMENT_ACTION_PLAN 'RAL_PF_PCK'
set packages [OMBRETRIEVE COLLECTION '$collectie' GET PROCESS_FLOW_PACKAGE REFERENCES]
set i 1
foreach package $packages {
  set action [file tail $package]
  set action [string range $package 2 28]
  set action $i$action
  exec_omb OMBALTER DEPLOYMENT_ACTION_PLAN 'RAL_PF_PCK' ADD ACTION '$action' SET PROPERTIES(OPERATION) VALUES('REPLACE') SET REF PROCESS_FLOW_PACKAGE '$package'
  incr i
}

exec_omb OMBCREATE TRANSIENT DEPLOYMENT_ACTION_PLAN 'RAL_PF_PCK'
exec_omb OMBDEPLOY DEPLOYMENT_ACTION_PLAN 'RAL_PF_PCK'
exec_omb OMBDROP DEPLOYMENT_ACTION_PLAN 'RAL_PF_PCK'
exec_omb OMBCOMMIT

exec_omb OMBDISCONNECT 


source c:/Scripts/omb_exec.tcl
source c:/Scripts/gps.tcl

exec_omb OMBCONNECT OWB_RTOWNER/INFORM@10.40.200.166:12235:DWIO
exec_omb OMBCC 'INFORM'
exec_omb OMBCONNECT CONTROL_CENTER
exec_omb OMBDROP DEPLOYMENT_ACTION_PLAN 'RAL_PF_PCK'
exec_omb OMBCOMMIT
