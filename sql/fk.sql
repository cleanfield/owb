select  
  'set sat_table         "' || cor.table_name || '"' || chr(10) ||
  'set sat_afk           "' || 'S' || substr(ucc.column_name, 2, 2) || '"' || chr(10) ||
  'set sat_pk            "' || ucc.column_name || '"' || chr(10) || chr(10) ||
  'set hub_table         "' || con.table_name || '"' || chr(10) ||
  'set hub_afk           "' || substr(ucc.column_name, 1, 3) || '"' || chr(10) ||
  'set hub_pk            "' || ucc.column_name || '"' || chr(10) || chr(10) || 
  'gps $sat_table $sat_afk $sat_pk $hub_table $hub_afk $hub_pk' || chr(10) 
from user_constraints con
join user_constraints cor on (con.constraint_name = cor.r_constraint_name and substr(con.table_name, 4) = substr(cor.table_name, 4))
join user_cons_columns ucc on (ucc.constraint_name = con.constraint_name)
where con.table_name in ('WHT_BEHANDELING','WHT_BESLISSING_ZM','WHT_PROCESDOSSIER','WHT_RECHTSMIDDEL','WHT_RELATIE_VD','WHT_TYPE_FORUM','WHT_ZAAK','WHT_ZAAK_ZM','WHT_ZITTING','WHT_ZITTINGSLOKATIE','WLT_BGZ_RML','WLT_BHG_BGZ','WLT_BHG_ZITTING','WLT_RLE_ZAK','WLT_ZAK_PDR','WLT_ZAK_ZKZ','WLT_ZITTING_TYPE_FORUM','WLT_ZKZ_BGZ','WLT_ZTG_ZLE','WST_BEHANDELING','WST_BESLISSING_ZM','WST_BGZ_RML','WST_BHG_BGZ','WST_BHG_ZITTING','WST_INSTANTIE','WST_PROCESDOSSIER','WST_RECHTSMIDDEL','WST_RELATIE_VD','WST_RLE_ZAK','WST_TYPE_FORUM','WST_ZAAK','WST_ZAAK_ZM','WST_ZAK_PDR','WST_ZAK_ZKZ','WST_ZITTING','WST_ZITTINGSLOKATIE','WST_ZITTING_TYPE_FORUM','WST_ZKZ_BGZ','WST_ZTG_ZLE')
and con.constraint_type = 'P'
order by con.table_name
;
