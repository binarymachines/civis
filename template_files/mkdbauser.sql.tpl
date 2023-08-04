CREATE ROLE {name} WITH
  LOGIN
  SUPERUSER
  INHERIT
  CREATEDB
  CREATEROLE
  REPLICATION;

COMMENT ON ROLE {name} IS '{description}';

ALTER ROLE {name} with encrypted password '{pw}';
