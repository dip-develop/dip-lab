-- Create databases for each service
CREATE DATABASE gallery;
CREATE DATABASE automation;
CREATE DATABASE docs;

-- Enable vector extension for gallery
\c gallery;
CREATE EXTENSION IF NOT EXISTS vector;
