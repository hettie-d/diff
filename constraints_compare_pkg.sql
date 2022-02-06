--select * from diff.full_constraint_compare('prod','stage','bx')
--select * from diff.full_constraint_compare('stage','prod','bx','supplier_commodity_states')
--select * from diff.constraint_compare('prod','stage','bx')
--select * from diff.constraint_compare('stage','dev','bx','supplier_commodity_states')
--select * from diff.constraint_compare('stage','dev','bx')
--select * from diff.constraint_compare('dev','prod','bx')
--select * from diff.constraint_compare('prod','stage,'bx')
--select * from diff.constraint_compare('stage','dev','bx', 'meter_suppliers')

drop type if exists diff.constraint_diff_record cascade;
create type diff.constraint_diff_record as (
   location text,
   table_name text,
   constraint_type text,
   ref_table text,
   const_def text
);
create or replace function diff.constraint_compare(p_source_1 text,
   p_source_2 text,
   p_schema text, 
   p_table text default null)
returns setof diff.constraint_diff_record
language plpgsql
as
$body$
declare
   v_sql text;
begin
   v_sql := 
   $sql$ select $sql$|| quote_literal(p_source_1)||
   $sql$,  a.* from
   (select s.nspname||'.'||c.relname, 
      case contype
      when 'c' then 'check'
      when 'p' then 'primary key'
      when 'f' then 'foreign key'
      when 'u' then 'unique'
      when 'x' then 'exclusion'
      end as constraint_type, 
      case contype when 'f' then
      fs.nspname||'.' ||fc.relname
      else ''
      end as ref_table,
      const_def
   from $sql$||p_source_1||
       $sql$_catalog_ft.constraint_def cn
     join $sql$||p_source_1||
       $sql$_catalog_ft.pg_namespace s
       on s.oid=connamespace
     join $sql$||p_source_1||
       $sql$_catalog_ft.pg_class c 
       on c.oid=cn.conrelid
     left outer join $sql$||p_source_1||
        $sql$_catalog_ft.pg_class fc
        on confrelid=fc.oid
     left outer join $sql$||p_source_1||
        $sql$_catalog_ft.pg_namespace fs
        on fs.oid=fc.relnamespace
    where s.nspname =$sql$||quote_literal(p_schema)||
         case when p_table is null then $sql$ $sql$  
         else $sql$ and c.relname= $sql$||quote_literal(p_table)
   	     end
   	     ||$sql$ 
    except 
    select s.nspname||'.'||c.relname, 
       case contype
          when 'c' then 'check'
          when 'p' then 'primary key'
          when 'f' then 'foreign key'
          when 'u' then 'unique'
          when 'x' then 'exclusion'
          end as constraint_type, 
       case contype when 'f' then
         fs.nspname||'.' ||fc.relname
       else ''
       end as ref_table,
       const_def
    from $sql$||p_source_2||
         $sql$_catalog_ft.constraint_def cn
         join $sql$||p_source_2||
           $sql$_catalog_ft.pg_namespace s
           on s.oid=connamespace
         join $sql$||p_source_2||
            $sql$_catalog_ft.pg_class c 
            on c.oid=cn.conrelid
         left outer join $sql$||p_source_2||
            $sql$_catalog_ft.pg_class fc
            on confrelid=fc.oid
         left outer join $sql$||p_source_2||
            $sql$_catalog_ft.pg_namespace fs
            on fs.oid=fc.relnamespace
    where s.nspname =$sql$||quote_literal(p_schema)||
          case when p_table is null then $sql$ $sql$  
          else $sql$ and c.relname= $sql$||quote_literal(p_table)
    	    end||
     $sql$	
    )a
   union all 
    select $sql$|| quote_literal(p_source_2)||
    $sql$, a.* from
   (select s.nspname||'.'||c.relname, 
      case contype
        when 'c' then 'check'
        when 'p' then 'primary key'
        when 'f' then 'foreign key'
        when 'u' then 'unique'
        when 'x' then 'exclusion'
        end as constraint_type, 
      case contype when 'f' then
        fs.nspname||'.' ||fc.relname
        else ''
        end as ref_table,
      const_def
    from $sql$||p_source_2||
      $sql$_catalog_ft.constraint_def cn
    join $sql$||p_source_2||
      $sql$_catalog_ft.pg_namespace s
      on s.oid=connamespace
    join $sql$||p_source_2||
      $sql$_catalog_ft.pg_class c 
      on c.oid=cn.conrelid
    left outer join $sql$||p_source_2||
      $sql$_catalog_ft.pg_class fc
      on confrelid=fc.oid
    left outer join $sql$||p_source_2||
      $sql$_catalog_ft.pg_namespace fs
      on fs.oid=fc.relnamespace
    where s.nspname =$sql$||quote_literal(p_schema)||
      case when p_table is null then $sql$ $sql$  
         else $sql$ and c.relname= $sql$||quote_literal(p_table)
   	  end
   	||$sql$
   except 
   select s.nspname||'.'||c.relname, 
     case contype
       when 'c' then 'check'
       when 'p' then 'primary key'
       when 'f' then 'foreign key'
       when 'u' then 'unique'
       when 'x' then 'exclusion'
       end as constraint_type,
     case contype when 'f' then
       fs.nspname||'.' ||fc.relname
       else ''
       end as ref_table,
     const_def
   from $sql$||p_source_1||
     $sql$_catalog_ft.constraint_def cn
   join $sql$||p_source_1||
     $sql$_catalog_ft.pg_namespace s
     on s.oid=connamespace
   join $sql$||p_source_1||
     $sql$_catalog_ft.pg_class c 
     on c.oid=cn.conrelid
   left outer join $sql$||p_source_1||
     $sql$_catalog_ft.pg_class fc
     on confrelid=fc.oid
   left outer join $sql$||p_source_1||
     $sql$_catalog_ft.pg_namespace fs
     on fs.oid=fc.relnamespace
   where s.nspname =$sql$||quote_literal(p_schema)||
   case when p_table is null then $sql$ $sql$  
         else $sql$ and c.relname= $sql$||quote_literal(p_table)
   	end
   	||$sql$
   )a
    order by 2,3,4,1 $sql$
 ;

raise notice 'table:%, %',p_table, v_sql;
 return query
execute v_sql;
end;
$body$;


drop type if exists diff.full_constraint_diff_record cascade;
create type diff.full_constraint_diff_record as (
location text,
table_name text,
constraint_type text,
constraint_name text,
ref_table text,
const_def text
);

create or replace function diff.full_constraint_compare(p_source_1 text,
p_source_2 text,
p_schema text, 
p_table text default null)
returns setof diff.full_constraint_diff_record
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
(select s.nspname||'.'||c.relname, 
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
from $sql$||p_source_1||
  $sql$_catalog_ft.constraint_def cn
join $sql$||p_source_1||
  $sql$_catalog_ft.pg_namespace s
on s.oid=connamespace
join $sql$||p_source_1||
  $sql$_catalog_ft.pg_class c 
on c.oid=cn.conrelid
left outer join $sql$||p_source_1||
  $sql$_catalog_ft.pg_class fc
on confrelid=fc.oid
left outer join $sql$||p_source_1||
  $sql$_catalog_ft.pg_namespace fs
on fs.oid=fc.relnamespace
where s.nspname =$sql$||quote_literal(p_schema)||
case when p_table is null then $sql$ $sql$  
      else $sql$ and c.relname= $sql$||quote_literal(p_table)
	end
	||$sql$ 
except 
select s.nspname||'.'||c.relname, 
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
from $sql$||p_source_2||
  $sql$_catalog_ft.constraint_def cn
join $sql$||p_source_2||
  $sql$_catalog_ft.pg_namespace s
on s.oid=connamespace
join $sql$||p_source_2||
  $sql$_catalog_ft.pg_class c 
on c.oid=cn.conrelid
left outer join $sql$||p_source_2||
  $sql$_catalog_ft.pg_class fc
on confrelid=fc.oid
left outer join $sql$||p_source_2||
  $sql$_catalog_ft.pg_namespace fs
on fs.oid=fc.relnamespace
where s.nspname =$sql$||quote_literal(p_schema)||
case when p_table is null then $sql$ $sql$  
      else $sql$ and c.relname= $sql$||quote_literal(p_table)
	end||
 $sql$	
)a
union all 
 select $sql$|| quote_literal(p_source_2)||
$sql$,
 a.* from
(select s.nspname||'.'||c.relname, 
case contype
when 'c' then 'check'
when 'p' then 'primary key'
when 'f' then 'foreign key'
when 'u' then 'unique'
when 'x' then 'exclusion'
end as constraint_type, 
conname::text,
/*array_agg(pa.attname::text) as constr_columns,*/
case contype when 'f' then
fs.nspname||'.' ||fc.relname
else ''
end as ref_table,
const_def
from $sql$||p_source_2||
  $sql$_catalog_ft.constraint_def cn
join $sql$||p_source_2||
  $sql$_catalog_ft.pg_namespace s
on s.oid=connamespace
join $sql$||p_source_2||
  $sql$_catalog_ft.pg_class c 
on c.oid=cn.conrelid
left outer join $sql$||p_source_2||
  $sql$_catalog_ft.pg_class fc
on confrelid=fc.oid
left outer join $sql$||p_source_2||
  $sql$_catalog_ft.pg_namespace fs
on fs.oid=fc.relnamespace
where s.nspname =$sql$||quote_literal(p_schema)||
case when p_table is null then $sql$ $sql$  
      else $sql$ and c.relname= $sql$||quote_literal(p_table)
	end
	||$sql$
except 
select s.nspname||'.'||c.relname, 
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
/*array_agg(fpa.attname::text)as fconstr_columns*/
const_def
from $sql$||p_source_1||
  $sql$_catalog_ft.constraint_def cn
join $sql$||p_source_1||
  $sql$_catalog_ft.pg_namespace s
on s.oid=connamespace
join $sql$||p_source_1||
  $sql$_catalog_ft.pg_class c 
on c.oid=cn.conrelid
left outer join $sql$||p_source_1||
  $sql$_catalog_ft.pg_class fc
on confrelid=fc.oid
left outer join $sql$||p_source_1||
  $sql$_catalog_ft.pg_namespace fs
on fs.oid=fc.relnamespace
where s.nspname =$sql$||quote_literal(p_schema)||
case when p_table is null then $sql$ $sql$  
      else $sql$ and c.relname= $sql$||quote_literal(p_table)
	end
	||$sql$
)a
 order by 2,3,4,1 $sql$
 ;

raise notice 'table:%, %',p_table, v_sql;
 return query
execute v_sql;
end;
$body$;