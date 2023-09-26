SELECT CONCAT('GRANT ', r.rolname, ' TO ', u.rolname) "GRANTS" 
FROM pg_auth_members as am 
INNER JOIN pg_roles r on r.oid=am.roleid 
INNER JOIN pg_roles u on u.oid=am.member where u.rolname='{user}'
