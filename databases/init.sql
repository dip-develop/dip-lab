-- Create databases for each service
CREATE DATABASE gallery;
CREATE DATABASE automation;
CREATE DATABASE docs;

-- Enable vector extension for gallery
\c gallery;
CREATE EXTENSION IF NOT EXISTS vector;

-- ── Isolated test user for the opt-in dev-agents container ─────────────
-- Created by the postgres container's first-start initdb, with password
-- and (optionally) initial DB name substituted in by env_file at
-- container start. The user only has rights on databases whose name
-- starts with `dev_test_` - it CANNOT drop or alter the prod databases
-- (`gallery`, `automation`, `docs`, `app`).
--
-- Tokens like __TEST_*__ are filled in from databases/.env on first
-- start. If they remain literal in the running container, the CREATE
-- USER will fail loudly and you'll know .env is missing values.

DO $$
BEGIN
    IF '${TEST_POSTGRES_USER:-}' <> '' THEN
        EXECUTE format(
            'CREATE USER %I WITH PASSWORD %L',
            '${TEST_POSTGRES_USER}',
            '${TEST_POSTGRES_PASSWORD}'
        );
        -- Allow creating/dropping any future test DB (but nothing else).
        EXECUTE format(
            'GRANT CREATE ON DATABASE %I TO %I',
            'app',
            '${TEST_POSTGRES_USER}'
        );
        -- Pre-create the initial test database, if its name was set.
        IF '${TEST_POSTGRES_DB:-}' <> '' THEN
            EXECUTE format(
                'CREATE DATABASE %I OWNER %I',
                '${TEST_POSTGRES_DB}',
                '${TEST_POSTGRES_USER}'
            );
        END IF;
    END IF;
END
$$;
