--select * from diff.generate_patch_table('prod','stage','bx', 'supplier_products');
--select * from diff.generate_patch_table('stage','prod','bx', 'brokerages');
--select * from diff.generate_patch_table('prod','stage','bx', 'brokerages');
--select * from diff.generate_patch_table('prod','dev','bx', 'rates');
--select * from diff.generate_patch_table('prod','stage','bx', 'active_storage_blobs');
--select * from diff.generate_patch_constraint('stage','dev','bx','supplier_commodity_states');
--select * from diff.generate_patch_constraint('dev','stage','bx','supplier_commodity_states');
--select * from diff.generate_patch_constraint('dev','stage','bx','meter_suppliers');
--select * from diff.generate_patch_constraint('dev','stage','bx');
--select * from diff.generate_patch_constraint('stage','dev','bx');
create or replace function diff.generate_patch_table_ext(p_from text,
p_to text,
p_schema_from text, 
p_schema_to text,
p_table text )
returns text
language plpgsql
as
$body$
declare
v_sql text;
v_patch text;
v_cnt_from int;
v_cnt_to int;
v_rec record;
v_alter_column text;
i int;
begin
	drop table if exists from_table;
	drop table if exists to_table;
v_sql := $sql$ create temp table  from_table
as 
select  
table_name::text,
ordinal_position::int,
column_name::text,
data_type::text|| 
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
	from $sql$||p_from||
  $sql$_info_ft.columns 
where table_schema=$sql$||quote_literal(p_schema_from)||
	case when p_table is null then $sql$ $sql$  
      else $sql$ and table_name =$sql$||quote_literal(p_table)
	end
	;
execute v_sql;	
GET DIAGNOSTICS v_cnt_from:=ROW_COUNT;
v_sql :=
$sql$ create temp table  to_table
as select  table_name::text,
ordinal_position::int,
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
	from $sql$||p_to||
  $sql$_info_ft.columns 
where table_schema=$sql$||quote_literal(p_schema_to)||
	case when p_table is null then $sql$ $sql$  
      else $sql$ and table_name =$sql$||quote_literal(p_table)
	end;
execute v_sql;
GET DIAGNOSTICS v_cnt_to:=ROW_COUNT;
if v_cnt_to=0 then ---create table
v_patch:=$$ 
create table $$||p_schema_to||$$.$$||p_table||$$ ($$;
for v_rec in (select * from from_table order by ordinal_position) loop
if v_patch is not null then v_patch:=v_patch||',
';
end if;
v_patch :=v_patch||'
'||v_rec.column_name||' '|| v_rec.data_type||' '||v_rec.nullable||
case when v_rec.default_val is null then ''
else ' '||v_rec.default_val
end;
end loop;
v_patch:=v_patch||')'; 
else ---alter table
 for v_rec in (select * from from_table
  where column_name not in (select column_name from to_table) ) loop
if v_patch is null then v_patch:=$$ 
alter table $$||p_schema_to||$$.$$||p_table; 
else v_patch:=v_patch||',
';
end if;
v_patch :=v_patch || ' add '||v_rec.column_name||' '|| v_rec.data_type||' '||v_rec.nullable||
case when v_rec.default_val is null then ''
else ' '||v_rec.default_val
end;
end loop;
for v_rec in (select * from to_table
  where column_name not in (select column_name from from_table) ) loop
if v_patch is null then v_patch:=$$ 
alter table $$||p_schema_to||$$.$$||p_table; 
else v_patch:=v_patch||',';
 end if;
v_patch :=v_patch || ' drop '||v_rec.column_name;
end loop;
end if;-- create or alter
for v_rec in (
select fr.column_name, 
fr.data_type as new_data_type,
t.data_type as old_data_type,
fr.nullable as new_nullable,
t.nullable as old_nullable,
fr.default_val as new_default,
t.default_val as old_default
from from_table fr
join to_table t
on fr.column_name=t.column_name
and (fr.data_type !=t.data_type
or fr.nullable !=t.nullable
or coalesce(fr.default_val,' ') !=coalesce(t.default_val,' '))) loop
if v_patch is null then v_patch:=$$ 
alter table $$||p_schema_to||$$.$$||p_table; 
else v_patch:=v_patch||',
';
 end if;
v_patch:=v_patch||' alter column '||v_rec.column_name||
case when v_rec.new_data_type!=v_rec.old_data_type
then ' type ' ||v_rec.new_data_type
else ''
end||
case when v_rec.new_nullable ='NOT NULL' and v_rec.old_nullable=''
then ' set NOT NULL'
when v_rec.old_nullable ='NOT NULL' and v_rec.new_nullable=''
then ' drop NOT NULL'
else ''
end||
case when v_rec.new_default is not null and v_rec.old_default is null
then ' set '|| v_rec.new_default
when v_rec.new_default is null and v_rec.old_default is not null
then ' drop default'
when v_rec.new_default!=v_rec.old_default
then ' '||v_rec.new_default
else ''
end;
end loop;

return v_patch;
end;
$body$;
--
create or replace function diff.generate_patch_constraint_ext(p_from text,
p_to text,
p_schema_from text, 
p_schema_to text,
p_table text default null)
returns text
language plpgsql
as
$body$
declare
v_sql text;
v_patch text;
v_cnt_from int;
v_cnt_to int;
v_rec record;
i int;
begin
	drop table if exists from_table;
	drop table if exists to_table;
v_sql := $sql$ create temp table  from_table
as 
select s.nspname||'.'||c.relname as table_name, 
case contype
when 'c' then 'check'
when 'p' then 'primary key'
when 'f' then 'foreign key'
when 'u' then 'unique'
when 'x' then 'exclusion'
end as constraint_type, 
conname::text,
case contype when 'f' then
fs.nspname||'.' ||fc.relname
else ''
end as ref_table,
const_def
from $sql$||p_from||
  $sql$_catalog_ft.constraint_def cn
join $sql$||p_from||
  $sql$_catalog_ft.pg_namespace s
on s.oid=connamespace
join $sql$||p_from||
  $sql$_catalog_ft.pg_class c 
on c.oid=cn.conrelid
left outer join $sql$||p_from||
  $sql$_catalog_ft.pg_class fc
on confrelid=fc.oid
left outer join $sql$||p_from||
  $sql$_catalog_ft.pg_namespace fs
on fs.oid=fc.relnamespace
where s.nspname =$sql$||quote_literal(p_schema_from)||
case when p_table is null then $sql$ $sql$  
      else $sql$ and c.relname= $sql$||quote_literal(p_table)
	end
	;
execute v_sql;	
GET DIAGNOSTICS v_cnt_from:=ROW_COUNT;
v_sql :=
$sql$ create temp table  to_table
as 
select s.nspname||'.'||c.relname as table_name, 
case contype
when 'c' then 'check'
when 'p' then 'primary key'
when 'f' then 'foreign key'
when 'u' then 'unique'
when 'x' then 'exclusion'
end as constraint_type, 
conname::text,
case contype when 'f' then
fs.nspname||'.' ||fc.relname
else ''
end as ref_table,
const_def
from $sql$||p_to||
  $sql$_catalog_ft.constraint_def cn
join $sql$||p_to||
  $sql$_catalog_ft.pg_namespace s
on s.oid=connamespace
join $sql$||p_to||
  $sql$_catalog_ft.pg_class c 
on c.oid=cn.conrelid
left outer join $sql$||p_to||
  $sql$_catalog_ft.pg_class fc
on confrelid=fc.oid
left outer join $sql$||p_to||
  $sql$_catalog_ft.pg_namespace fs
on fs.oid=fc.relnamespace
where s.nspname =$sql$||quote_literal(p_schema_to)||
case when p_table is null then $sql$ $sql$  
      else $sql$ and c.relname= $sql$||quote_literal(p_table)
		end;
execute v_sql;
GET DIAGNOSTICS v_cnt_to:=ROW_COUNT;
--
for v_rec in (select * from to_table
  where (table_name, const_def) not in 
  (select table_name, const_def from from_table) order by constraint_type desc)  loop
if v_patch is null then v_patch:='';
else v_patch:=v_patch||$$;
$$;
end if;
 v_patch:=v_patch||$$alter table  $$||v_rec.table_name||
$$ drop constraint $$||v_rec.conname;
end loop;

 for v_rec in (select * from from_table
  where (table_name, const_def) not in 
  (select table_name, const_def from to_table) 
   order by constraint_type desc) loop
if v_patch is null then v_patch:='';
else v_patch:=v_patch||$$;
$$;
end if;
 v_patch:=v_patch||$$alter table  $$||v_rec.table_name||
$$ add constraint $$||v_rec.conname||$$ $$||v_rec.const_def;
end loop;

for v_rec in (
select fr.table_name,
	fr.conname as new_conname, 
    t.conname as old_conname 
from from_table fr
join to_table t
on fr.table_name=t.table_name
and fr.const_def=t.const_def
and fr.conname !=t.conname) loop
if v_patch is null then v_patch:='';
else v_patch:=v_patch||$$;
$$;
end if;
v_patch:=v_patch||$$ alter table $$||v_rec.table_name||
$$ rename constraint $$||v_rec.old_conname||$$ to $$||v_rec.new_conname;
end loop;

return v_patch;
end;
$body$;

