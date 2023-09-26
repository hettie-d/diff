#!/bin/bash

echo 'DROP USER test3user;' | ./get_root_cli.sh
echo 'CREATE USER test3user;' | ./get_root_cli.sh
echo 'CREATE ROLE test3role;' | ./get_root_cli.sh
echo "ALTER ROLE test3user WITH PASSWORD 'blablabla';" | ./get_root_cli.sh
echo "GRANT test3role TO test3user;" | ./get_root_cli.sh

echo "user roles 1"
(cat ../user_roles.sql; echo ";") | sed 's/{user}/test3user/' | (DBUSER=postgres ./get_user_cli.sh)

echo "REVOKE test3role FROM test3user;" | ./get_root_cli.sh

echo "user roles 1"
(cat ../user_roles.sql; echo ";") | sed 's/{user}/test3user/' | (DBUSER=postgres ./get_user_cli.sh)


