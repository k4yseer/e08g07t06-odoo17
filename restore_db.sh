#!/bin/bash
set -e

# --- Arguments ---
DB_USER="$1"     # e.g., odoo17
DB_NAME="$2"     # e.g., odoo
SQL_FILE="$3"    # e.g., /home/azureuser/deploy-temp/odoo.sql

echo "Restoring PostgreSQL database..."
echo "DB_USER=$DB_USER, DB_NAME=$DB_NAME, SQL_FILE=$SQL_FILE"

# Check if SQL file exists
if [ ! -f "$SQL_FILE" ]; then
    echo "Error: SQL file not found at $SQL_FILE"
    exit 1
fi

# Disconnect all other sessions
echo "Disconnecting active connections to $DB_NAME..."
psql -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='$DB_NAME';"

# Drop database if exists
echo "Dropping database if it exists..."
psql -c "DROP DATABASE IF EXISTS $DB_NAME;"

# Create database with owner
echo "Creating database $DB_NAME with owner $DB_USER..."
psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"

# Restore SQL file
echo "Restoring SQL from $SQL_FILE..."
psql -d "$DB_NAME" -f "$SQL_FILE"

echo "Database restore completed successfully!"
