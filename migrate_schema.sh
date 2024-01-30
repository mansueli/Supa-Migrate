#!/usr/bin/env bash

#Edit here:
OLD_SUPAVISOR_URL=postgres://postgres.oldproject:[YOUR-PASSWORD]@aws-0-us-east-1.pooler.supabase.com:5432/postgres
NEW_SUPAVISOR_URL=postgres://postgres.newproject:[YOUR-PASSWORD]@aws-0-us-east-1.pooler.supabase.com:5432/postgres

#Script:
# Default case for Linux sed, just use "-i"
sedi=(-i)
case "$(uname)" in
  # For macOS, use two parameters
  Darwin*) sedi=(-i "")
esac

pg_dump "$OLD_SUPAVISOR_URL" \
  --if-exists \
  --clean \
  --quote-all-identifiers \
  --schema-only \
  --no-owner --no-privileges \
  --exclude-schema 'extensions|graphql|graphql_public|net|tiger|pgbouncer|vault|realtime|supabase_functions|storage|pg*|information_schema' \
  --schema '*' > dump.sql

sed "${sedi[@]}" -e 's/^DROP SCHEMA IF EXISTS "auth";$/-- DROP SCHEMA IF EXISTS "auth";/' dump.sql
sed "${sedi[@]}" -e's/^DROP SCHEMA IF EXISTS "storage";$/-- DROP SCHEMA IF EXISTS "storage";/' dump.sql
sed "${sedi[@]}" -e 's/^CREATE SCHEMA "auth";$/-- CREATE SCHEMA "auth";/' dump.sql
sed "${sedi[@]}" -e 's/^CREATE SCHEMA "storage";$/-- CREATE SCHEMA "storage";/' dump.sql
sed "${sedi[@]}" -e 's/^ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin"/-- ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin"/' dump.sql
psql "$NEW_SUPAVISOR_URL" --file dump.sql
