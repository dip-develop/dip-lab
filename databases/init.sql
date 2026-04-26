-- Create databases for each service
CREATE DATABASE immich;
CREATE DATABASE n8n;
CREATE DATABASE nextcloud;
CREATE DATABASE paperless;

-- Enable vector extension for immich
\c immich;
CREATE EXTENSION IF NOT EXISTS vector;