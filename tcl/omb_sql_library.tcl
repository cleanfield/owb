# OMB/Tcl Library met routines om interactie met een Oracle database mogelijk te maken 
# 20-jan-2011 Ruben A. van Schoonneveldt.
# Kopie van http://forums.oracle.com/forums/thread.jspa?messageID=3629305&#3629305
#
# Gebruikt java.sql classes
#
# Revisie gegevens
# $Author$
# $Date$ 
# $Rev$
#
package require java
# 
proc oracleConnect { serverName databaseName portNumber username password } {
 
   # import required classes 
   java::import java.sql.Connection
   java::import java.sql.DriverManager
   java::import java.sql.ResultSet
   java::import java.sql.SQLWarning
   java::import java.sql.Statement
   java::import java.sql.CallableStatement
   java::import java.sql.ResultSetMetaData 
   java::import java.sql.DatabaseMetaData 
   java::import java.sql.Types
   java::import oracle.jdbc.OracleDatabaseMetaData
 
   # load database driver .
   java::call Class forName oracle.jdbc.OracleDriver 
 
   # set the connection url.
   append url jdbc:oracle:thin
   append url :
   append url $username
   append url / 
   append url $password
   append url "@"
   append url $serverName
   append url :
   append url $portNumber
   append url :
   append url $databaseName
 
   set oraConnection [ java::call DriverManager getConnection $url ] 
   set oraDatabaseMetaData [ $oraConnection getMetaData ]
   set oraDatabaseVersion [ $oraDatabaseMetaData getDatabaseProductVersion ]
 
   puts "Connected to: $url"
   puts "$oraDatabaseVersion"
   
   return $oraConnection 
}
 
 
proc oracleDisconnect { oraConnect } {
  $oraConnect close
}
 
proc oraJDBCType { oraType } {
  #translation of JDBC types as defined in XOPEN interface
  set rv "NUMBER"
  switch $oraType {
     "0" {set rv "NULL"}
     "1" {set rv "CHAR"}
     "2" {set rv "NUMBER"}
     "3" {set rv "DECIMAL"}
     "4" {set rv "INTEGER"}
     "5" {set rv "SMALLINT"}
     "6" {set rv "FLOAT"}
     "7" {set rv "REAL"}
     "8" {set rv "DOUBLE"}
     "12" {set rv "VARCHAR"}
     "16" {set rv "BOOLEAN"}
     "91" {set rv "DATE"}
     "92" {set rv "TIME"}
     "93" {set rv "TIMESTAMP"}
     default {set rv "OBJECT"}
  }
  return $rv
}
 
proc oracleQuery { oraConnect oraQuery } {
 
   set oraStatement [ $oraConnect createStatement ]
   set oraResults [ $oraStatement executeQuery $oraQuery ]
 
   # The following metadata dump is not required, but will be a helpfull sort of thing
   # if ever want to really build an abstraction layer
   set oraResultsMetaData [ $oraResults getMetaData ] 
   set columnCount        [ $oraResultsMetaData getColumnCount ]
   set i 1
 
   #puts "ResultSet Metadata:"
   while { $i <= $columnCount} {
      set fname [ $oraResultsMetaData getColumnName $i]
      set ftype [oraJDBCType [ $oraResultsMetaData getColumnType $i]]
      #puts "Output Field $i Name: $fname Type: $ftype"
      incr i
   }
   # end of metadata dump
 
   return $oraResults
}
 
##########################################################
# SAMPLE CODE to run a quick query and dump the results. #
##########################################################
#set oraConn [ oracleConnect myserver orcl 1555 scott tiger ]
#set oraRs [ oracleQuery $oraConn "select name, count(*) numlines from user_source group by name" ]
 
#for each row in the result set
#while {[$oraRs next]} {
  #grab the field values
#  set procName [$oraRs getString name]
#  set procCount [$oraRs getInt numlines]
#  puts "Program unit $procName comprises $procCount lines"
#}
 
#$oraRs close
 
#oracleDisconnect $oraConn
