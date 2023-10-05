#!/bin/bash

echo 'REVOKE CREATE ON DATABASE test1db FROM test2user;' | ./get_root_cli.sh
echo 'DROP USER test2user;' | ./get_root_cli.sh
echo 'DROP DATABASE test2db;' | ./get_root_cli.sh
echo 'CREATE DATABASE test2db;' | ./get_root_cli.sh
echo 'CREATE USER test2user;' | ./get_root_cli.sh
echo "ALTER ROLE test2user WITH PASSWORD 'blablabla';" | ./get_root_cli.sh
export DBUSER=test2user
export DB=test2db
res=`echo 'CREATE SCHEMA bla;' | ./get_user_cli.sh 2>&1 `
if [ "$res" != "ERROR:  permission denied for database test2db" ]; then
   echo "Failure"
   echo "==$res=="
   exit 1
fi

echo "GRANT CREATE ON DATABASE test2db TO test2user;" | ./get_root_cli.sh

res=`echo 'CREATE SCHEMA bla;' | ./get_user_cli.sh 2>&1 `
if [ "$res" != "CREATE SCHEMA" ]; then
   echo "Failure"
   echo "==$res=="
   exit 1
fi

res=`echo "SELECT schema_name FROM information_schema.schemata WHERE schema_name='bla';" | (DBUSER=postgres ./get_user_cli.sh) | grep bla`
if [ "$(echo -n $res)" != "bla" ]; then
   echo "Failure"
   echo "==$res=="
   exit 1
fi

echo "schema_priv"
(cat ../schema_priv.sql; echo ";") | sed 's/{user}/test2user/' | (DBUSER=postgres ./get_user_cli.sh)

res=`echo 'CREATE SCHEMA bla1;' | (DBUSER=postgres ./get_user_cli.sh 2>&1)`
if [ "$res" != "CREATE SCHEMA" ]; then
   echo "Failure"
   echo "==$res=="
   exit 1
fi

echo "GRANT CREATE ON SCHEMA bla1 TO test2user;" | (DBUSER=postgres ./get_user_cli.sh)

echo "schema_priv 1"
res=`(cat ../schema_priv.sql; echo ";") | sed 's/{user}/test2user/' | (DBUSER=postgres ./get_user_cli.sh | grep bla1)`
if [ "$(echo -n $res)" != "GRANT CREATE ON schema bla1 TO \"test2user\"" ]; then
	echo "Failure"
	echo "==$res=="
	exit 1
fi
echo "Grants visible as:"
echo "$res"
echo "table_priv"
(cat ../table_priv.sql; echo ";") | ./get_root_cli.sh
echo "table_priv_inherit"
(cat ../table_priv_inherit.sql; echo ";") | ./get_root_cli.sh
echo "database_priv"
(cat ../database_priv.sql; echo ";") | sed 's/{user}/test2user/' | ./get_root_cli.sh
echo $?

echo "REVOKE CREATE ON SCHEMA bla1 FROM test2user;" | (DBUSER=postgres ./get_user_cli.sh)

echo "REVOKE CREATE ON DATABASE test2db FROM test2user;" | ./get_root_cli.sh

echo "ALTER DEFAULT PRIVILEGES FOR USER test2user GRANT CREATE ON SCHEMAS TO test2user;" | (DBUSER=postgres ./get_user_cli.sh)


res=`echo 'CREATE SCHEMA bla2;' | (DBUSER=postgres ./get_user_cli.sh 2>&1)`

echo "schema_priv 2"
(cat ../schema_priv.sql; echo ";") | sed 's/{user}/test2user/' | (DBUSER=postgres ./get_user_cli.sh | grep bla1)

echo "database_priv 2"
(cat ../database_priv.sql; echo ";") | sed 's/{user}/test2user/' | ./get_root_cli.sh
echo $?


