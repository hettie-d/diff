SELECT r.rolname, db.datname, perm.name, has_database_privilege(r.rolname, db.datname, perm.name) 
FROM pg_roles as r, pg_database as db, 
  (SELECT 'CONNECT' as name UNION ALL SELECT 'CREATE' as name UNION ALL SELECT 'TEMPORARY' as name UNION ALL SELECT 'TEMP' as name ) as perm 
   WHERE has_database_privilege(r.rolname, db.datname, perm.name) AND r.rolname not like 'pg_%';