-- Create databases for each service
CREATE DATABASE gallery;
CREATE DATABASE automation;
CREATE DATABASE docs;
CREATE DATABASE IF NOT EXISTS cloud;
CREATE DATABASE IF NOT EXISTS ccnet_db;
CREATE DATABASE IF NOT EXISTS seafile_ui_db;

-- Create cloud user
CREATE USER IF NOT EXISTS 'cloud'@'%' IDENTIFIED BY 'Cloud9101';
GRANT ALL PRIVILEGES ON cloud.* TO 'cloud'@'%';
GRANT ALL PRIVILEGES ON ccnet_db.* TO 'cloud'@'%';
GRANT ALL PRIVILEGES ON seafile_ui_db.* TO 'cloud'@'%';
FLUSH PRIVILEGES;

-- Enable vector extension for gallery
\c gallery;
CREATE EXTENSION IF NOT EXISTS vector;