#!/bin/bash

echo 'CREATE USER test3user;' | ./get_root_cli.sh
echo 'CREATE ROLE test3role;' | ./get_root_cli.sh
echo "ALTER ROLE test3user WITH PASSWORD 'blablabla';" | ./get_root_cli.sh
echo "GRANT test3role TO test3user;" | ./get_root_cli.sh

echo "user roles after granted"
res=`(cat ../user_roles.sql; echo ";") | sed 's/{user}/test3user/' | (DBUSER=postgres ./get_user_cli.sh) | grep test3user`
if [ ! "$(echo -n $res)" = "GRANT test3role TO test3user" ]; then
   echo "Failure"
   echo "res: $res"
   exit 1
fi
echo $res

echo "REVOKE test3role FROM test3user;" | ./get_root_cli.sh

echo "user roles after revoked"
res=`(cat ../user_roles.sql; echo ";") | sed 's/{user}/test3user/' | (DBUSER=postgres ./get_user_cli.sh) | grep test3user`
if [ ! "$(echo -n $res)" = "" ]; then
   echo "Failure"
   echo "res: $res"
   exit 1
fi
echo $res


echo 'DROP USER test3user;' | ./get_root_cli.sh
echo 'DROP ROLE test3role;' | ./get_root_cli.sh


