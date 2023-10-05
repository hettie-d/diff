## Snippets

These snippets will have small parts of SQL that allow to generate GRANTS statements that recreate the current state of permissions _of the particular user_.

Ultimate goal (not yeat achieved!) is to be able to get postgres implementation of `SHOW GRANTS` statement, available in MySQL.

They are intended to be used as parts of other applications (see example shell scripts under `tests` folder).

Conventions:

1. `{user}` is to be replaced by the name of the actual user when SQL is passed to the server.
2. Each snippet is supposed to output a table with GRANT statements in GRANTS column
3. GRANT statements should be executable DDL statements.

Current limitations:

1. We are _not_ examining recursive role relationships - only directly granted roles will be displayed
2. Existing tests run against only one postgresql version - TBD add aversion coverage.
