#!/bin/bash

echo 'REVOKE CREATE ON DATABASE test1db FROM test1user;' | ./get_root_cli.sh
echo 'DROP USER test1user;' | ./get_root_cli.sh
echo 'DROP DATABASE test1db;' | ./get_root_cli.sh
echo 'CREATE DATABASE test1db;' | ./get_root_cli.sh
echo 'CREATE USER test1user;' | ./get_root_cli.sh
echo "ALTER ROLE test1user WITH PASSWORD 'blablabla';" | ./get_root_cli.sh
export DBUSER=test1user
export DB=test1db
res=`echo 'CREATE SCHEMA bla;' | ./get_user_cli.sh 2>&1 `
if [ "$res" != "ERROR:  permission denied for database test1db" ]; then
   echo "Failure"
   echo "==$res=="
   exit 1
fi

echo "GRANT CREATE ON DATABASE test1db TO test1user;" | ./get_root_cli.sh

echo "schema_priv"
(cat ../schema_priv.sql; echo ";") | ./get_root_cli.sh
echo "table_priv"
(cat ../table_priv.sql; echo ";") | ./get_root_cli.sh
echo "table_priv_inherit"
(cat ../table_priv_inherit.sql; echo ";") | ./get_root_cli.sh
echo "database_priv"
(cat ../database_priv.sql; echo ";") | ./get_root_cli.sh
echo $?