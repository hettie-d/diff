--select * from diff.schema_compare('airlines', 'hettie');
---select * from diff.tables_compare('airlines', 'hettie','postgres_air') order by 2,1
--select * from diff.columns_compare('airlines', 'hettie','postgres_air')
--select * from diff.columns_compare('airlines', 'hettie','postgres_air','flight_calc')
--select * from diff.full_columns_compare('airlines', 'hettie','postgres_air','flight_calc')


drop type if exists diff.object_diff_record cascade;
create type diff.object_diff_record as (
location text,
object_name text,
object_type text,
object_owner text
);

drop type if exists diff.column_diff_record cascade;
create type diff.column_diff_record as (
location text,
table_name text,
column_name text,
data_type text
);

drop type if exists diff.full_column_diff_record cascade;
create type diff.full_column_diff_record as (
location text,
table_name text,
ordinal_position int,
column_name text,
data_type text,
nullable text,
default_val text
);

create or replace function diff.schema_compare(p_source_1 text, p_source_2 text)
returns setof diff.object_diff_record
language plpgsql
as
$body$
begin
return query
execute
$sql$ select $sql$|| quote_literal(p_source_1)||
$sql$,
 a.* from
(select schema_name::text,'schema',schema_owner::text from $sql$||p_source_1||
  $sql$_info_ft.schemata
 where schema_name not like 'pg_%' 
     and schema_name !='information_schema'
except 
select schema_name::text,'schema',schema_owner::text from $sql$||p_source_2||
  $sql$_info_ft.schemata 
 where schema_name not like 'pg_%'
     and schema_name !='information_schema') a
union all
select $sql$|| quote_literal(p_source_2)||
$sql$,
 a.* from
(select schema_name::text,'schema',schema_owner::text from $sql$||p_source_2||
  $sql$_info_ft.schemata
 where schema_name not like 'pg_%'
     and schema_name !='information_schema'
except 
select schema_name::text,'schema',schema_owner::text from $sql$||p_source_1||
  $sql$_info_ft.schemata 
 where schema_name not like 'pg_%'
     and schema_name !='information_schema') a
 $sql$
;
 end;
 $body$;
 
 create or replace function diff.tables_compare(p_source_1 text, 
 p_source_2 text,
 p_schema text)
returns setof diff.object_diff_record
language plpgsql
as
$body$
begin
return query
execute
$sql$ select $sql$|| quote_literal(p_source_1)||
$sql$,
 a.* from
(select relname::text, 
 case relkind when 'r' then 'table'
 when 'v' then 'view'
 else 'matview'
 end , relowner::text from $sql$||p_source_1||
  $sql$_catalog_ft.pg_class c
 join $sql$||p_source_1||$sql$_catalog_ft.pg_namespace n
 on n.oid=relnamespace
 where relkind in ('r', 'm', 'v')
 and nspname=$sql$||quote_literal(p_schema)|| $sql$
except 
select relname::text,
 case relkind when 'r' then 'table'
 when 'v' then 'view'
 else 'matview'
 end,
 relowner::text from $sql$||p_source_2||
  $sql$_catalog_ft.pg_class c
 join $sql$||p_source_2||$sql$_catalog_ft.pg_namespace n
 on n.oid=relnamespace
 where relkind in ('r', 'm', 'v')
 and nspname =$sql$||quote_literal(p_schema)|| $sql$)a
union all
select $sql$|| quote_literal(p_source_2)||
$sql$,
a.* from
(select relname::text,
 case relkind when 'r' then 'table'
 when 'v' then 'view'
 else 'matview'
 end,
 relowner::text from $sql$||p_source_2||
  $sql$_catalog_ft.pg_class c
 join $sql$||p_source_2||$sql$_catalog_ft.pg_namespace n
 on n.oid=relnamespace
 where relkind in ('r', 'm', 'v')
 and nspname=$sql$||quote_literal(p_schema)|| $sql$
except 
select relname::text,
 case relkind when 'r' then 'table'
 when 'v' then 'view'
 else 'matview'
 end,
 relowner::text from $sql$||p_source_1||
  $sql$_catalog_ft.pg_class c
 join $sql$||p_source_1||$sql$_catalog_ft.pg_namespace n
 on n.oid=relnamespace
 where relkind in ('r', 'm', 'v')
 and nspname =$sql$||quote_literal(p_schema)|| $sql$)a
 order by 1,2$sql$;
end;
$body$;

create or replace function diff.columns_compare(p_source_1 text,
p_source_2 text,
p_schema text, 
p_table text default null)
returns setof diff.column_diff_record
language plpgsql
as
$body$
declare
v_sql text;
begin
v_sql := 
$sql$ select $sql$|| quote_literal(p_source_1)||
$sql$,
 a.* from
(
	select table_name::text,column_name::text,data_type::text 
	from $sql$||p_source_1||
  $sql$_info_ft.columns 
where table_schema=$sql$||quote_literal(p_schema)||
	case when p_table is null then $sql$ $sql$  
      else $sql$ and table_name =$sql$||quote_literal(p_table)
	end
	||$sql$
except 
select table_name::text,column_name::text,data_type::text 
from $sql$||p_source_2||
  $sql$_info_ft.columns 
where table_schema=$sql$||quote_literal(p_schema)||
case when p_table is null then $sql$ $sql$  
      else $sql$ and table_name =$sql$||quote_literal(p_table)
	end
	||$sql$
)a
union all
select $sql$|| quote_literal(p_source_2)||
$sql$,
a.* from (
	select table_name::text,column_name::text,data_type::text 
	from $sql$||p_source_2||
  $sql$_info_ft.columns 
where table_schema=$sql$||quote_literal(p_schema)||
	case when p_table is null then $sql$ $sql$  
      else $sql$ and table_name =$sql$||quote_literal(p_table)
	end
	||$sql$
except 
select table_name::text,column_name::text,data_type::text 
from $sql$||p_source_1||
  $sql$_info_ft.columns 
where table_schema=$sql$||quote_literal(p_schema)||
case when p_table is null then $sql$ $sql$  
      else $sql$ and table_name =$sql$||quote_literal(p_table)
	end
	||$sql$
)a

 order by 2,3,1 $sql$
 ;
--raise notice 'table:%, %',p_table, v_sql;
 return query
execute v_sql;
end;
$body$;


create or replace function diff.full_columns_compare(p_source_1 text,
p_source_2 text,
p_schema text, 
p_table text default null)
returns setof diff.full_column_diff_record
language plpgsql
as
$body$
declare
v_sql text;
begin
v_sql := $sql$ select $sql$|| quote_literal(p_source_1)||
$sql$,
 a.* from (
select  table_name::text,ordinal_position::int,
	 column_name::text,data_type::text|| 
case when character_maximum_length is not null then '('||character_maximum_length::text
||')'
else ''
end ||
case data_type when 'numeric'
then '('||numeric_precision::text||','||numeric_scale::text|| ')'
else ''
end
as data_type,
case is_nullable when 'NO' then 'NOT NULL'
else ''
end as nullable,
'default '||column_default  default_val
	from $sql$||p_source_1||
  $sql$_info_ft.columns 
where table_schema=$sql$||quote_literal(p_schema)||
	case when p_table is null then $sql$ $sql$  
      else $sql$ and table_name =$sql$||quote_literal(p_table)
	end
	||$sql$
except 
select  table_name::text,ordinal_position::int,
	 column_name::text,data_type::text|| 
case when character_maximum_length is not null then '('||character_maximum_length::text
||')'
else ''
end ||
case data_type when 'numeric'
then '('||numeric_precision::text||','||numeric_scale::text|| ')'
else ''
end
as data_type,
case is_nullable when 'NO' then 'NOT NULL'
else ''
end as nullable,
'default '||column_default  default_val
	from $sql$||p_source_2||
  $sql$_info_ft.columns 
where table_schema=$sql$||quote_literal(p_schema)||
	case when p_table is null then $sql$ $sql$  
      else $sql$ and table_name =$sql$||quote_literal(p_table)
	end
	||$sql$
)a
union all
select  $sql$|| quote_literal(p_source_2)||
$sql$,
a.* from (
select  table_name::text,ordinal_position::int,
	column_name::text,data_type::text|| 
case when character_maximum_length is not null then '('||character_maximum_length::text
||')'
else ''
end ||
case data_type when 'numeric'
then '('||numeric_precision::text||','||numeric_scale::text|| ')'
else ''
end
as data_type,
case is_nullable when 'NO' then 'NOT NULL'
else ''
end as nullable,
'default '||column_default  default_val
	from $sql$||p_source_2||
  $sql$_info_ft.columns 
where table_schema=$sql$||quote_literal(p_schema)||
	case when p_table is null then $sql$ $sql$  
      else $sql$ and table_name =$sql$||quote_literal(p_table)
	end
	||$sql$
except 
select  table_name::text,ordinal_position::int,
	column_name::text,data_type::text|| 
case when character_maximum_length is not null then '('||character_maximum_length::text
||')'
else ''
end ||
case data_type when 'numeric'
then '('||numeric_precision::text||','||numeric_scale::text|| ')'
else ''
end
as data_type,
case is_nullable when 'NO' then 'NOT NULL'
else ''
end as nullable,
'default '||column_default  default_val
	from $sql$||p_source_1||
  $sql$_info_ft.columns 
where table_schema=$sql$||quote_literal(p_schema)||
	case when p_table is null then $sql$ $sql$  
      else $sql$ and table_name =$sql$||quote_literal(p_table)
	end
	||$sql$
)a
 order by 2,3,1 $sql$
 ;
 --raise notice 'table:%, %',p_table, v_sql;
 return query
execute v_sql;
end;
$body$;