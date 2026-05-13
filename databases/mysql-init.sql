CREATE DATABASE IF NOT EXISTS cloud;
CREATE DATABASE IF NOT EXISTS ccnet_db;
CREATE DATABASE IF NOT EXISTS seafile_ui_db;

CREATE USER IF NOT EXISTS 'cloud'@'%' IDENTIFIED WITH mysql_native_password BY 'Bestame9101';
GRANT ALL PRIVILEGES ON cloud.* TO 'cloud'@'%';
GRANT ALL PRIVILEGES ON ccnet_db.* TO 'cloud'@'%';
GRANT ALL PRIVILEGES ON seafile_ui_db.* TO 'cloud'@'%';

ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY 'Bestame9101';
FLUSH PRIVILEGES;
