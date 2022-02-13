--select * from diff.privs_compare('airlines', 'hettie','postgres_air_large');
--select * from diff.privs_compare('dev', 'prod','bx');
--select * from diff.privs_schema_compare('airlines', 'hettie');
--select * from diff.db_privs_select ('stage')
drop type if exists diff.priv_diff_record cascade;
create type diff.priv_diff_record as (
   location text,
   table_name text,
   user_name text,
   permission text
);

 drop type if exists diff.priv_schema_diff_record cascade;
create type diff.priv_schema_diff_record as (
   location text,
   schema_name text,
   user_name text,
   object_type text,
   permission text
);

 create or replace function diff.privs_compare(
   p_source_1 text, 
   p_source_2 text,
   p_schema text)
returns setof diff.priv_diff_record
language plpgsql
as
$body$
begin
return query  execute
   $sql$ select $sql$|| quote_literal(p_source_1)||
   $sql$,
    a.* from
     (select * from dblink('fs_$sql$||p_source_1||$sql$',
     	$$select 
     	    relname::text,
          rolname,
          perm_string[3]::text
       from (
          select 
            relname,
            (string_to_array(rtrim(ltrim(aclexplode(relacl)::text,'('),')'),',')) as perm_string
          from  pg_class p
          join pg_namespace s
            on s.oid=p.relnamespace 
          where nspname=$sql$||quote_literal(p_schema)||$sql$
                 and relkind in ('r','S','v','m')
              ) b 
       join pg_roles r on r.oid=b.perm_string[2]::oid
          where rolname !='postgres'
         $$)
       AS t1 (relname text, user_name text, perm text)
     except 
      select * from dblink('fs_$sql$||p_source_2||$sql$',
     	$$select 
     	    relname::text,
          rolname,
          perm_string[3]::text
        from (
          select 
            relname,
            (string_to_array(rtrim(ltrim(aclexplode(relacl)::text,'('),')'),',')) as perm_string
          from pg_class p
          join pg_namespace s
              on s.oid=p.relnamespace 
          where nspname=$sql$||quote_literal(p_schema)||$sql$
               and relkind in ('r','S','v','m')
           ) b 
         join pg_roles r on r.oid=b.perm_string[2]::oid
             where rolname !='postgres'
          $$)
       AS t1 (relname text, user_name text, perm text)) a
    union all
     select $sql$|| quote_literal(p_source_2)||
     $sql$,
       a.* from
        (select * from dblink('fs_$sql$||p_source_2||$sql$',
     	    $$select relname::text,
            rolname,
            perm_string[3]::text
           from (
             select 
               relname,
               (string_to_array(rtrim(ltrim(aclexplode(relacl)::text,'('),')'),',')) as perm_string
              from pg_class p
               join pg_namespace s
                 on s.oid=p.relnamespace 
               where nspname=$sql$||quote_literal(p_schema)||$sql$
                 and relkind in ('r','S','v','m')
                 ) b 
         join pg_roles r on r.oid=b.perm_string[2]::oid
             where rolname !='postgres'
          $$) 
       AS t1 (relname text, user_name text, perm text)
    except 
       select * from dblink('fs_$sql$||p_source_1||$sql$',
     	    $$select 
     	       relname::text,
             rolname,
             perm_string[3]::text
           from (
             select 
               relname,
               (string_to_array(rtrim(ltrim(aclexplode(relacl)::text,'('),')'),',')) as perm_string
               from pg_class p
               join pg_namespace s
                 on s.oid=p.relnamespace 
                  where nspname=$sql$||quote_literal(p_schema)||$sql$
                   and relkind in ('r','S','v','m')
                ) b
           join pg_roles r on r.oid=b.perm_string[2]::oid
                where rolname !='postgres'
              $$) 
         AS t1 (relname text, user_name text, perm text)) a
   order by 1,2,3 $sql$;
end;
$body$;
 
create or replace function diff.privs_schema_compare(
   p_source_1 text, 
   p_source_2 text)
returns setof diff.priv_schema_diff_record
language plpgsql
as
$body$
declare v_sql text;
begin
v_sql:=$sql$ select $sql$|| quote_literal(p_source_1)||
$sql$,
 a.* from
(select * from dblink('fs_$sql$||p_source_1||$sql$',
	$$select nspname::text,
rolname,
object_type,
perm_string[3]::text
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
where rolname !='postgres'
$$)
AS t1 (relname text, user_name text, object_type text, perm text)
except 
select * from dblink('fs_$sql$||p_source_2||$sql$',
	$$select nspname::text,
rolname,
object_type,
perm_string[3]::text
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
where rolname !='postgres'
$$)
AS t1 (nsp text, user_name text, object_type text,  perm text))a
union all
select $sql$|| quote_literal(p_source_2)||
$sql$,
 a.* from
(select * from dblink('fs_$sql$||p_source_2||$sql$',
	$$select nspname::text,
rolname,
object_type,
perm_string[3]::text
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
where nspname not like 'pg_%' and nspname not in ('public', 'information_schema')

) b 
join pg_roles r on r.oid=b.perm_string[2]::oid
where rolname !='postgres'
$$)
AS t1 (relname text, user_name text, object_type text,  perm text)
except 
select * from dblink('fs_$sql$||p_source_1||$sql$',
	$$select nspname::text,
rolname,
object_type,
perm_string[3]::text
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

)s) b 
join pg_roles r on r.oid=b.perm_string[2]::oid
where rolname !='postgres'
$$)
AS t1 (nsp text, user_name text, object_type text,  perm text))a
order by 1,2 $sql$;
raise notice '%', v_sql;
return query execute v_sql;
end;
$body$;

drop type if exists diff.db_privs_record cascade;
create type diff.db_privs_record as (
   object_type text,
   object_name text,
   user_name text,
   schema_default_priv text,
   permission text
);

create or replace function diff.db_privs_direct_select (p_db_name text)
returns setof diff.db_privs_record
language plpgsql
as
$body$
declare v_sql text;
begin
	v_sql := $sql$ select 'schema priv' ,
a.* from
(select * from dblink('fs_$sql$||p_db_name||$sql$',
	$$select 
	    nspname::text,
      rolname,
      object_type,
      perm_string[3]::text
  from (
        select 
           nspname,
           object_type,
           (string_to_array(rtrim(ltrim(aclexplode(nspacl)::text,'('),')'),',')) as perm_string
        from  (select 
                  nspname, 
                 'schema' as object_type,
                  nspacl 
               from pg_namespace 
               where nspname not like 'pg_%' 
                     and nspname not in ('public', 'information_schema')
               union
               select 
                  nspname, 
                  case(defaclobjtype)
        	           when 'S' then 'sequence'
                     when 'r' then 'table'
                  end,
                  d.defaclacl 
               from pg_default_acl d
               join pg_namespace s on s.oid=defaclnamespace 
               where nspname not like 'pg_%' 
                     and nspname not in ('public', 'information_schema')
               
                 )s
        where nspname not like 'pg_%' and nspname not in ('public', 'information_schema')      
        ) b 
  join pg_roles r on r.oid=b.perm_string[2]::oid
  where rolname !='postgres'
  $$)
AS t1 (relname text, user_name text, object_type text,perm text)
)a
union all
 select 'table priv' $sql$ ||
$sql$,
 a.* from
(select * from dblink('fs_$sql$||p_db_name||$sql$',
	$$select nspname||'.'||relname::text,
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
$$)
AS t1 (relname text, user_name text, object_type text,perm text))a

$sql$;
raise notice '%', v_sql;
return query execute v_sql;
end ;$body$;

create or replace function diff.db_privs_select (p_db_name text)
returns setof diff.db_privs_record
language plpgsql
as
$body$
declare v_sql text;
begin
	v_sql := $sql$ select 'schema priv' ,
a.* from
(select * from dblink('fs_$sql$||p_db_name||$sql$',
	$$select nspname::text,
rolname,
object_type,
perm_string[3]::text
from (
select nspname,
object_type,
(string_to_array(rtrim(ltrim(aclexplode(nspacl)::text,'('),')'),',')) as perm_string
from  (select nspname, 
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
where nspname not like 'pg_%' and nspname not in ('public', 'information_schema')

) b 
join pg_roles r on r.oid=b.perm_string[2]::oid
where rolname !='postgres'
$$)
AS t1 (relname text, user_name text, object_type text,perm text)
)a
union all
 select 'table priv' $sql$ ||
$sql$,
 a.* from
(select * from dblink('fs_$sql$||p_db_name||$sql$',
	$$select nspname||'.'||relname::text,
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
$$)
AS t1 (relname text, user_name text, object_type text,perm text))a

union all
 select 'table priv inherit' $sql$ ||
$sql$,
 a.* from
(select * from dblink('fs_$sql$||p_db_name||$sql$',
	$$select nspname||'.'||relname::text,
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
$$)
AS t1 (relname text, user_name text, object_type text,perm text))a
$sql$;
raise notice '%', v_sql;
return query execute v_sql;
end ;$body$;

/*
WITH RECURSIVE x AS
(
  SELECT member::regrole,
         roleid::regrole AS role,
         member::regrole || ' -> ' || roleid::regrole AS path
  FROM pg_auth_members AS m
  UNION ALL
  SELECT x.member::regrole,
         m.roleid::regrole,
         x.path || ' -> ' || m.roleid::regrole
 FROM pg_auth_members AS m
    JOIN x ON m.member = x.role
  )
  SELECT member, role, path
  FROM x
  WHERE member::text not like 'pg%' 
  AND member::text!='postgres' 
  AND member::text not like 'rds%'
  and role::text not like 'pg%'
  ORDER BY member::text, role::text;

*/
