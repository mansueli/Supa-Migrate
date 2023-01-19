#!/usr/bin/env bash

#Edit here:
OLD_DB_URL=db.old_project_ref.supabase.co
NEW_DB_URL=db.new_project_ref.supabase.co
OLD_DB_PASS=secret_password_here
NEW_DB_PASS=secret_new_password_here

#Script:
# Default case for Linux sed, just use "-i"
sedi=(-i)
case "$(uname)" in
  # For macOS, use two parameters
  Darwin*) sedi=(-i "")
esac

PGPASSWORD="$OLD_DB_PASS" pg_dump -d postgres -U postgres \
  --clean \
  --if-exists \
  --quote-all-identifiers \
  --exclude-table-data 'storage.objects' \
  --exclude-schema 'extensions|graphql|graphql_public|net|pgbouncer|pgsodium|pgsodium_masks|realtime|supabase_functions|pg_toast|pg_catalog|pg_*|information_schema' \
  --schema '*' \
  -h "$OLD_DB_URL" > dump.sql

sed "${sedi[@]}" -e 's/^DROP SCHEMA IF EXISTS "auth";$/-- DROP SCHEMA IF EXISTS "auth";/' dump.sql
sed "${sedi[@]}" -e's/^DROP SCHEMA IF EXISTS "storage";$/-- DROP SCHEMA IF EXISTS "storage";/' dump.sql
sed "${sedi[@]}" -e 's/^CREATE SCHEMA "auth";$/-- CREATE SCHEMA "auth";/' dump.sql
sed "${sedi[@]}" -e 's/^CREATE SCHEMA "storage";$/-- CREATE SCHEMA "storage";/' dump.sql
sed "${sedi[@]}" -e 's/^ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin"/-- ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin"/' dump.sql


PGPASSWORD="$NEW_DB_PASS" psql -d postgres -U postgres \
  --variable ON_ERROR_STOP=1 \
  --file dump.sql \
  -h "$NEW_DB_URL" -p 6543
