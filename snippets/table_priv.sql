select nspname||'.'||relname::text,
rolname,
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
where rolname !='postgres'