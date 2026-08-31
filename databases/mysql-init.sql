-- Seafile creates ccnet_db, seafile_db, seahub_db automatically during setup.
-- Only create the user and grant wildcard privileges for any future databases.
--
-- The real passwords are substituted in at container start by entrypoint.sh
-- from the environment variables in databases/.env. The placeholders below
-- are intentionally invalid (MySQL refuses to start with them) so a user
-- who forgets to fill the env file gets a loud failure instead of a silent
-- default password.
--
-- Do NOT replace the __MYSQL_*_PASSWORD__ / __TEST_*_PASSWORD__ tokens with
-- literal values in this file - they would end up in git.

CREATE USER IF NOT EXISTS 'cloud'@'%' IDENTIFIED WITH caching_sha2_password BY '__MYSQL_CLOUD_PASSWORD__';
GRANT ALL PRIVILEGES ON `ccnet_db`.* TO 'cloud'@'%';
GRANT ALL PRIVILEGES ON `seafile_db`.* TO 'cloud'@'%';
GRANT ALL PRIVILEGES ON `seahub_db`.* TO 'cloud'@'%';

ALTER USER 'root'@'%' IDENTIFIED WITH caching_sha2_password BY '__MYSQL_ROOT_PASSWORD__';
FLUSH PRIVILEGES;

-- ── Isolated test user for the opt-in dev-agents container ─────────────
-- Grants are scoped to databases whose name starts with `dev_test_`.
-- The dev-agents container connects as this user only. The user CANNOT
-- drop or alter the prod databases (`cloud`, `app`, `ccnet_db`,
-- `seafile_db`, `seahub_db`).
--
-- The pre-create + grant pattern below is a no-op if TEST_MYSQL_USER
-- is empty, so users who don't want dev-agents DB access can leave
-- the test creds blank.

CREATE USER IF NOT EXISTS '__TEST_MYSQL_USER__'@'%' IDENTIFIED WITH caching_sha2_password BY '__TEST_MYSQL_PASSWORD__';
GRANT ALL PRIVILEGES ON `dev\_test\_%`.* TO '__TEST_MYSQL_USER__'@'%';

-- Pre-create the initial test database, if its name was set. The
-- dev-agents container can then create/drop other `dev_test_*` DBs
-- at will.
CREATE DATABASE IF NOT EXISTS `__TEST_MYSQL_DB__`;
GRANT ALL PRIVILEGES ON `__TEST_MYSQL_DB__`.* TO '__TEST_MYSQL_USER__'@'%';
FLUSH PRIVILEGES;
