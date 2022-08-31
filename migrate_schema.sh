#!/usr/bin/env bash

#Edit here:
OLD_DB_URL=db.old_project_ref.supabase.co
NEW_DB_URL=db.new_project_ref.supabase.co
OLD_DB_PASS=secret_password_here
NEW_DB_PASS=secret_new_password_here

#Script:
PGPASSWORD="$OLD_DB_PASS" pg_dump --clean --if-exists --schema-only --quote-all-identifiers -h $OLD_DB_URL -U postgres > dump.sql -p 6543
PGPASSWORD="$OLD_DB_PASS" psql -U postgres -h $OLD_DB_URL -d postgres -p 6543 -c 'ALTER ROLE postgres NOSUPERUSER'
PGPASSWORD="$NEW_DB_PASS" psql -h $NEW_DB_URL -U postgres -f dump.sql -p 6543
PGPASSWORD="$NEW_DB_PASS" psql -U postgres -h $NEW_DB_URL -d postgres -p 6543 -c 'TRUNCATE storage.objects'
PGPASSWORD="$NEW_DB_PASS" psql -U postgres -h $NEW_DB_URL -d postgres -p 6543 -c 'ALTER ROLE postgres NOSUPERUSER'
