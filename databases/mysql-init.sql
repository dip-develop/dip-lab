-- Seafile creates ccnet_db, seafile_db, seahub_db automatically during setup
-- Only create the user and grant wildcard privileges for any future databases
CREATE USER IF NOT EXISTS 'cloud'@'%' IDENTIFIED WITH caching_sha2_password BY 'Bestame9101';
GRANT ALL PRIVILEGES ON `ccnet_db`.* TO 'cloud'@'%';
GRANT ALL PRIVILEGES ON `seafile_db`.* TO 'cloud'@'%';
GRANT ALL PRIVILEGES ON `seahub_db`.* TO 'cloud'@'%';

ALTER USER 'root'@'%' IDENTIFIED WITH caching_sha2_password BY 'Bestame9101';
FLUSH PRIVILEGES;
