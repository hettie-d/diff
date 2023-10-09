select CONCAT('ALTER DEFAULT PRIVILEGES FOR USER "', rolname, 
   '" IN SCHEMA "',nspname::text,'" GRANT ', perm_string[3]::text, ' ON TABLES TO "', rolname, '"') AS "GRANTS"
from (
select nspname,
        object_type,
(string_to_array(rtrim(ltrim(aclexplode(nspacl)::text,'('),')'),',')) as perm_string
from
 (select nspname,
  'schema' as object_type,
  nspacl from pg_namespace
   where nspname not like 'pg_%' and nspname not in ('public', 'information_schema')
 union
 select nspname,
  case(defaclobjtype)
     when 'S' then 'sequence'
      when 'r' then 'table'
      when 'm' then 'mview'
      when 'v' then 'view'
      else 'other'
      end,
  d.defaclacl from pg_default_acl d
    join pg_namespace s on s.oid=defaclnamespace
    where nspname not like 'pg_%' and nspname not in ('public', 'information_schema')

)s
) b
join pg_roles r on r.oid=b.perm_string[2]::oid
where rolname = '{user}'