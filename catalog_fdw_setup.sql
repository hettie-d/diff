 --call diff.catalog_fdw_setup(null,'hettie');
--call diff.catalog_fdw_setup(null,'airlines');
--call diff.catalog_fdw_setup('demo');

create or replace procedure diff.catalog_fdw_setup (
  p_database_alias text,
  p_database text,
  p_host text default 'localhost',
  p_port text default null,
  p_user text default null,
  p_password text default null)
language plpgsql
as
$BODY$
declare 
  v_port text;
  v_user text;
  v_database_alias text;
  v_error text;
begin
  v_port :=coalesce(p_port, '5432');
  v_user :=coalesce (p_user, current_user);
  v_database_alias:=coalesce (p_database_alias, p_database);
  execute 
    $$drop server if exists fs_$$||v_database_alias||
    $$ cascade; 
    create server fs_$$||v_database_alias||
    $$ FOREIGN DATA WRAPPER postgres_fdw options
       (host $$||quote_literal(p_host) ||$$,
        port $$||quote_literal(v_port)||$$, 
        dbname $$||quote_literal(p_database)||
        $$)$$;

  execute $$create user mapping for 
  public server fs_$$||v_database_alias||
        $$ OPTIONS (user $$||quote_literal(v_user)||
           case when p_password is not null then $$, password $$||quote_literal(p_password)
            else $$ $$
            end ||
            $$)$$;
  execute $$grant usage on foreign server  fs_$$||v_database_alias||$$ to public$$;
  execute $$drop schema if exists  $$||v_database_alias||$$_catalog_ft cascade$$;
  execute $$create schema $$||v_database_alias||$$_catalog_ft$$;
  execute $$grant usage on schema $$||v_database_alias||$$_catalog_ft to public$$;
  execute $$drop schema if exists $$||v_database_alias||$$_info_ft cascade$$;
  execute $$create schema $$||v_database_alias||$$_info_ft$$;
  execute $$grant usage on schema $$||v_database_alias||$$_info_ft to public$$;
  execute $$import foreign schema "pg_catalog" except	(pg_attribute, 
  						 pg_replication_slots,
  						 pg_statistic,
  						 pg_stats,
					     pg_stats_ext_exprs,
					     pg_statistic_ext_data)from server
  	fs_$$||v_database_alias||$$ into $$||v_database_alias||$$_catalog_ft$$;
	
  execute $$create foreign table $$||v_database_alias||$$_catalog_ft.pg_attribute(
     attrelid oid,
     attname name,
     atttypid oid,
     ttstattarget integer,
     attlen smallint,
     attnum smallint,
     attndims integer,
     attcacheoff integer,
     atttypmod integer,
     attbyval boolean,
     attstorage "char",
     attalign "char",
     attnotnull boolean,
     atthasdef boolean,
     atthasmissing boolean,
     attidentity "char",
     attgenerated "char",
     attisdropped boolean,
     attislocal boolean,
     attinhcount int,
     attcollation oid,
     attacl aclitem[],
     attoptions text[],
     attfdwoptions text[]
  	)
   SERVER fs_$$||v_database_alias||$$
      OPTIONS (schema_name 'pg_catalog', table_name 'pg_attribute')$$;
      
  execute $$create or replace view  $$||v_database_alias||$$_catalog_ft.constraint_def as
        select * from dblink('fs_$$||v_database_alias||$$',
	          'select oid,
            conname,
            connamespace,
            contype,
            condeferrable,
            condeferred,
            convalidated,
            conrelid,
            contypid,
            conindid,
            conparentid,
            confrelid,
            confupdtype,
            confdeltype,
            confmatchtype,
            conislocal,
            coninhcount,
            connoinherit,
            conkey,
            confkey,
            conpfeqop,
            conppeqop,
            conffeqop,
            conexclop,					 
  	        pg_get_constraintdef(oid) as const_def
        from pg_constraint'					 
)
AS pg_constraint_def(
      oid oid,
      conname name,
      connamespace oid,
      contype "char",
      condeferrable boolean,
      condeferred boolean,
      convalidated boolean,
      conrelid oid,
      contypid oid,
      conindid oid,
      conparentid oid,
      confrelid oid,
      confupdtype "char",
      confdeltype "char",
      confmatchtype "char" ,
      conislocal boolean,
      coninhcount integer,
      connoinherit boolean,
      conkey smallint[],
      confkey smallint[],
      conpfeqop oid[],
      conppeqop oid[],
      conffeqop oid[],
      conexclop oid[],
  	  const_def text )$$;

  execute $$import foreign schema "information_schema" 
      from server
  	  fs_$$||v_database_alias||$$ into $$||v_database_alias||$$_info_ft$$;
  	
exception when others then
 GET STACKED DIAGNOSTICS v_error = MESSAGE_TEXT;
raise notice '%', v_error;
end;
$BODY$;


