\set ON_ERROR_STOP on

SELECT 'CREATE DATABASE admin_db'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'admin_db')
\gexec
