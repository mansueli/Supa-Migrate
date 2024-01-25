#!/usr/bin/env bash

#Edit here:
OLD_SUPAVISOR_URL=postgres://postgres.oldproject:[YOUR-PASSWORD]@aws-0-us-east-1.pooler.supabase.com:5432/postgres
NEW_SUPAVISOR_URL=postgres://postgres.newproject:[YOUR-PASSWORD]@aws-0-us-east-1.pooler.supabase.com:5432/postgres
OLD_DB_PASS=secret_password_here
NEW_DB_PASS=secret_new_password_here

#Script:
# Default case for Linux sed, just use "-i"
sedi=(-i)
case "$(uname)" in
  # For macOS, use two parameters
  Darwin*) sedi=(-i "")
esac

pg_dump "$OLD_SUPAVISOR_URL" \
  --clean \
  --if-exists \
  --quote-all-identifiers \
  --exclude-table-data 'storage.objects' \
  --schema-only
  --exclude-schema 'extensions|graphql|graphql_public|net|tiger|pgbouncer|vault|realtime|supabase_functions|storage|pg*|information_schema' \
  --schema '*' > dump.sql 
  
pg_dump "$OLD_SUPAVISOR_URL" \
  --clean \
  --if-exists \
  --quote-all-identifiers \
  --exclude-table-data 'storage.objects' \
  --data-only
  --exclude-schema 'extensions|graphql|graphql_public|net|tiger|pgbouncer|vault|realtime|supabase_functions|storage|pg*|information_schema' \
  --schema '*' > data_dump.sql 

sed "${sedi[@]}" -e 's/^DROP SCHEMA IF EXISTS "auth";$/-- DROP SCHEMA IF EXISTS "auth";/' dump.sql
sed "${sedi[@]}" -e's/^DROP SCHEMA IF EXISTS "storage";$/-- DROP SCHEMA IF EXISTS "storage";/' dump.sql
sed "${sedi[@]}" -e 's/^CREATE SCHEMA "auth";$/-- CREATE SCHEMA "auth";/' dump.sql
sed "${sedi[@]}" -e 's/^CREATE SCHEMA "storage";$/-- CREATE SCHEMA "storage";/' dump.sql
sed "${sedi[@]}" -e 's/^ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin"/-- ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin"/' dump.sql
psql "$NEW_SUPAVISOR_URL" --file dump.sql 
psql "$NEW_SUPAVISOR_URL" --file data_dump.sql 
