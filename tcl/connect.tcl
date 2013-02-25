proc connect {naarwat waar} {
#
  switch [string toupper $waar] {
    O {
      set hostname "10.40.200.166"
      set sid      "DWIO"
      set port     "12235"
      set user     "OWB_RTOWNER"
      set password "INFORM"
    }
    T {
      set hostname "10.40.200.164"
      set sid      "DWIT"
      set port     "12239"
      set user     "OWB_RTOWNER"
      set password "INFORMT"
    }
  }
#
  switch [string toupper $naarwat] {
    OWB {
        set conn "$user/$password@$hostname:$port:$sid" 
        exec_omb OMBCONNECT $conn
    }
    SQL {
        set conn [ oracleConnect $hostname $sid $port $user $password ]
    }
  }
#
  return $conn
#
}
