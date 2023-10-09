#!/bin/bash

echo 'ALTER DEFAULT PRIVILEGES FOR USER "test3user" IN SCHEMA "test3schema" REVOKE SELECT, INSERT ON TABLES FROM "test3user";' | ./get_root_cli.sh
echo 'DROP USER test3user;' | ./get_root_cli.sh
echo 'DROP SCHEMA test3schema;' | ./get_root_cli.sh
echo 'CREATE USER test3user;' | ./get_root_cli.sh
echo 'CREATE SCHEMA test3schema;' | ./get_root_cli.sh
echo 'ALTER DEFAULT PRIVILEGES FOR USER "test3user" IN SCHEMA "test3schema" GRANT SELECT, INSERT ON TABLES TO "test3user";' | ./get_root_cli.sh
resSelect=`(cat ../table_default_priv.sql ; echo ";") | sed 's/{user}/test3user/' |(DBUSER=postgres ./get_user_cli.sh|grep SELECT)`
resInsert=`(cat ../table_default_priv.sql ; echo ";") | sed 's/{user}/test3user/' |(DBUSER=postgres ./get_user_cli.sh|grep INSERT)`
if [ ! "$(echo -n $resSelect)" = 'ALTER DEFAULT PRIVILEGES FOR USER "test3user" IN SCHEMA "test3schema" GRANT SELECT ON TABLES TO "test3user"' ]; then
  echo "SELECT is missing: $resSelect"
  exit 1
fi

if [ ! "$(echo -n $resInsert)" = 'ALTER DEFAULT PRIVILEGES FOR USER "test3user" IN SCHEMA "test3schema" GRANT INSERT ON TABLES TO "test3user"' ]; then
  echo "INSERT is missing: $resSelect"
  exit 1
fi
