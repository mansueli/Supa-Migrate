#!/usr/bin/env bash
#Edit here:
POSTGRES_USERNAME=POSTGRES_ORIGIN_USERNAME
POSTGRES_PASSWORD=POSTGRES_ORIGIN_PASSWORD
POSTGRES_DATABASE=POSTGRES_ORIGIN_DATABASE
POSTGRES_HOST=POSTGRES_ORIGIN_HOST
SUPA_URL=SUPABASE_HOST
SUPA_PASSWORD=SUPABASE_PASSWORD
#Script:
# Default case for Linux sed, just use "-i"
sedi=(-i)
case "$(uname)" in
  # For macOS, use two parameters
  Darwin*) sedi=(-i "")
esac

pg_dump "sslmode=require" postgres://postgres:"$POSTGRES_PASSWORD"@"$POSTGRES_HOST":5432/"$POSTGRES_ORIGIN_DATABASE" \
  --clean \
  --if-exists \
  --quote-all-identifiers \
  --exclude-schema 'extensions|graphql|graphql_public|net|pgbouncer|pgsodium|pgsodium_masks|realtime|supabase_functions|storage|pg_*|information_schema' \
  --schema '*' > dump.sql 
#sed -i -e 's/;max_client_conn = 100/max_client_conn = 200/g' pgbouncer.ini
sed "${sedi[@]}" -e's/^DROP SCHEMA IF EXISTS "storage";$/-- DROP SCHEMA IF EXISTS "storage";/' dump.sql
sed "${sedi[@]}" -e 's/^CREATE SCHEMA "auth";$/-- CREATE SCHEMA "auth";/' dump.sql
sed "${sedi[@]}" -e 's/^CREATE SCHEMA "storage";$/-- CREATE SCHEMA "storage";/' dump.sql
sed "${sedi[@]}" -e 's/"$POSTGRES_ORIGIN_DATABASE"/postgres/g' dump.sql
sed "${sedi[@]}" -e 's/"$POSTGRES_ORIGIN_USERNAME"/postgres/g' dump.sql
psql postgres://postgres:"$SUPA_PASSWORD"@"$SUPA_URL":6543/postgres --file dump.sql 
