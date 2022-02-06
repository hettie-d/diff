create extension if not exists postgres_fdw;
create extension if not exists dblink;
create schema diff;
\ir catalog_fdw_setup.sql
\ir schema_compare_pkg.sql
\ir constraints_compare_pkg.sql
\ir generate_patches_pkg.sql

--insert your parameters into the call below
/*call diff.catalog_fdw_setup (
  'hettie',
  'localhost',
 null,
 null,
 'postgres')
*/
