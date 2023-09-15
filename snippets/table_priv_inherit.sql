select nspname||'.'||relname::text,
member,
'n/a',
perm_string[3]::text
from (
select relname,
nspname,
(string_to_array(rtrim(ltrim(aclexplode(relacl)::text,'('),')'),',')) as perm_string
from 
pg_class p
join pg_namespace s
on s.oid=p.relnamespace 
where nspname not like 'pg_%' and nspname not in ('public', 'information_schema')
and relkind in ('r','S','v','m')
) b 
join pg_roles r on r.oid=b.perm_string[2]::oid
join (WITH RECURSIVE x AS
(
  SELECT member::regrole,
         roleid::regrole AS role,
	     roleid,
         member::regrole || ' -> ' || roleid::regrole AS path
  FROM pg_auth_members AS m
  UNION ALL
  SELECT x.member::regrole,
         m.roleid::regrole,
	     m.roleid,
         x.path || ' -> ' || m.roleid::regrole
 FROM pg_auth_members AS m
    JOIN x ON m.member = x.role
  )
  SELECT member, role, roleid, path
  FROM x
  WHERE member::text not like 'pg%' 
  AND member::text!='postgres' 
  AND member::text not like 'rds%'
  and role::text not like 'pg%'
) ir
on ir.roleid=r.oid 
where member::text !='postgres'