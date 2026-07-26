# im-standard-sql

sql-schema (in sqlite-syntax) of the information model database-schema as defined in the modelling tool.

It is relationally as complete as possible in sql(ite).
It check foreign keys, unique keys and check constraints.

Its content is more consistently checked as the json-schema-definition can check content.
json-schema lacks different concepts like (unique key, foreign key) necessary for a complete consistent database.

Some additional checks are expressed as SQL-views and -checks in im-standard-dbchecks.sql
- Check that translated unique names (like entity-name) are also unique in translated values.