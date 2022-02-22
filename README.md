# diff 

This repo (the name is subject to change) contains several packages which offer a fast and convenient way to compare two databases. You establish connections with any number of databases and compare any twp of them.

## Requirements.

The easiest way to use this tool is to run it on one of your local databases. However, you can install it on any database server providing you have permission to creat a foreign server.

## What you can do with this tool?

* Compare list of existing schemas and their ownership
* Compare list of tables in the same schema
* Compare columns for the tables with the same names in the same schemas
* Compare constraints on the same tables
* Comprate schema- and object-level permissions
* Generate patches
* Generate full list of permissions for a given database
* More to come

## Installation

* Clone the repo and run \_load_all.sql file.

It will install postgres_fdw extension if it was not installed before and compile all packages.

* Run diff.catalog_fdw_setup for each of the databases you are planning to compare (see detailed description below)


## Usage

### diff.catalog_fdw_setup 
call diff.catalog_fdw_setup (
            p_database_alias text,
            p_database text,
            p_host text default 'localhost',
            p_port text default null,
            p_user text default null,
            p_password text default null);
            

* Creates a foreign server which points to the database p_database on p_host (default 'localhost' connecting to post p_port mapping with p_user (default current_user) and p_password. The server name is fs_p_database_alias or fs_p_databas if the first parameter is null
* imports pg_catalog schema from p_database into p_database_alias_catalog_ft schema
* imports information_schema from p_database into p_database_alias_info_ft schema

###  schema_compare_pkg.sql

* diff.schema_compare(
         p_source_1 text, 
         p_source_2 text) - compares schemas/ownerships
* diff.tables_compare(
         p_source_1 text, 
         p_source_2 text,
         p_schema text)  - compares tables/views/mviews in the specified schema
 * diff.columns_compare(
         p_source_1 text,
         p_source_2 text,
         p_schema text, 
         p_table text default null) - compares columns in the specified table (or in all tables in schmema if p_table is null)
* diff.full_columns_compare(
         p_source_1 text,
         p_source_2 text,
         p_schema text, 
         p_table text default null) - same as previous, but includes comparison of defaults, null/not null and the order of columns
 
 ### constraints_compare_pkg.sql
 
 * diff.constraint_compare(
          p_source_1 text,
          p_source_2 text,
          p_schema text, 
          p_table text default null) - compares constraints in the specified table (or in all tables in schmema if p_table is null)

 
 * diff.full_constraint_compare(
          p_source_1 text,
          p_source_2 text,
          p_schema text, 
          p_table text default null) - same as previous, but includes constraint names compare

 ### generate_patches_pkg.sql
 
 * diff.generate_patch_table(
          p_from text,
          p_to text,
          p_schema text, 
          p_table text ) - generate patch to make table p_table in schema p_schema to make the table on p_to look the same as on p_from
 *  diff.generate_patch_constraint(
            p_from text,
            p_to text,
            p_schema text, 
            p_table text default null) - generate patches for missing constraints 
            
 ### priv_compare_pkg.sql
 
 * diff.privs_compare(
          p_source_1 text, 
          p_source_2 text,
          p_schema text)    - compares object-level permission in p_schema
 * diff.privs_schema_compare(
          p_source_1 text, 
          p_source_2 text) -  compares schema-level permission         
 * diff.db_privs_direct_select (
          p_db_name text) - list of all explicity granted permissions within a specified database
* diff.db_privs_select (
          p_db_name text) - list of all existing permissions on objects (as a result of applying all grants)