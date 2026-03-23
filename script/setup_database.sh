#!/bin/bash

# Database Setup Script for Hanko
# This script needs to be run by a database administrator

DB_HOST="100.105.46.111"
DB_NAME="zenkai_hanko_db"
DB_USER="zenkai_hanko_user"
DB_PASSWORD="trangbg2k"

echo "Setting up database for Hanko application..."
echo "Host: $DB_HOST"
echo "Database: $DB_NAME"
echo "User: $DB_USER"
echo ""

# Connect as superuser to create database and user
psql -h "$DB_HOST" -U postgres -d postgres << EOF
-- Create database
CREATE DATABASE $DB_NAME;

-- Create user
CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;

-- Connect to the new database and grant schema privileges
\c $DB_NAME

-- Grant schema privileges
GRANT ALL PRIVILEGES ON SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $DB_USER;

-- Show current permissions
SELECT 
    grantee,
    privilege_type,
    table_schema
FROM information_schema.role_table_grants 
WHERE grantee = '$DB_USER'
AND table_schema = 'public';
EOF

echo ""
echo "Database setup complete."
echo "Created database: $DB_NAME"
echo "Created user: $DB_USER"
echo ""
echo "Now update the Hanko configuration and run migrations:"
echo "cd backend && HANKO_CONFIG=config/config.yaml ./hanko migrate up"