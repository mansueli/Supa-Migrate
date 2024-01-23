#!/usr/bin/env bash
#Edit here:
export POSTGRES_USERNAME=POSTGRES_ORIGIN_USERNAME
export POSTGRES_PASSWORD=POSTGRES_ORIGIN_PASSWORD
export POSTGRES_DATABASE=POSTGRES_ORIGIN_DATABASE
export POSTGRES_HOST=POSTGRES_ORIGIN_HOST
export SUPA_URL=SUPABASE_HOST
export SUPA_PASSWORD=SUPABASE_PASSWORD
#Script:
# Default case for Linux sed, just use "-i"
sedi=(-i)
case "$(uname)" in
  # For macOS, use two parameters
  Darwin*) sedi=(-i "")
esac

PGSSLMODE=allow pg_dump postgres://"$POSTGRES_USERNAME":"$POSTGRES_PASSWORD"@"$POSTGRES_HOST":5432/"$POSTGRES_DATABASE" \
  --if-exists \
  --clean \
  --quote-all-identifiers \
  --schema-only \
  --no-owner --no-privileges \
  --exclude-schema 'extensions|graphql|graphql_public|net|tiger|pgbouncer|vault|realtime|supabase_functions|storage|pg*|information_schema' \
  --schema '*' > dump.sql

PGSSLMODE=allow pg_dump postgres://"$POSTGRES_USERNAME":"$POSTGRES_PASSWORD"@"$POSTGRES_HOST":5432/"$POSTGRES_DATABASE" \
  --quote-all-identifiers \
  --no-owner --no-privileges \
  --data-only \
  --exclude-schema 'extensions|graphql|graphql_public|net|tiger|pgbouncer|vault|realtime|supabase_functions|storage|pg*|information_schema' \
  --schema '*' > data_dump.sql  
sed "${sedi[@]}" -e's/^DROP SCHEMA IF EXISTS "storage";$/-- DROP SCHEMA IF EXISTS "storage";/' dump.sql
sed "${sedi[@]}" -e 's/^CREATE SCHEMA "auth";$/-- CREATE SCHEMA "auth";/' dump.sql
sed "${sedi[@]}" -e 's/^CREATE SCHEMA "storage";$/-- CREATE SCHEMA "storage";/' dump.sql
sed "${sedi[@]}" -e 's/POSTGRES_ORIGIN_USERNAME/postgres/g' dump.sql
sed "${sedi[@]}" -e 's/POSTGRES_ORIGIN_DATABASE/postgres/g' dump.sql
psql "$SUPA_URL" --file dump.sql
psql "$SUPA_URL" --file data_dump.sql
