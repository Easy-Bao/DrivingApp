\set ON_ERROR_STOP on

SELECT 'CREATE DATABASE auth_db'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'auth_db')
\gexec

SELECT 'CREATE DATABASE driver_db'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'driver_db')
\gexec

SELECT 'CREATE DATABASE trip_db'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'trip_db')
\gexec

SELECT 'CREATE DATABASE bidding_db'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'bidding_db')
\gexec

SELECT 'CREATE DATABASE chat_db'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'chat_db')
\gexec

SELECT 'CREATE DATABASE fare_db'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'fare_db')
\gexec

SELECT 'CREATE DATABASE admin_db'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'admin_db')
\gexec
