# Supa-Migrate
Migrating schema &amp; data between supabase projects. You still need to [migrate storage objects](https://supabase.com/docs/guides/database#migrate-storage-objects).
You can use the following Python notebook for full migration including storage items:

[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/mansueli/Supa-Migrate/blob/main/Migrate_Project_%26_Storage.ipynb)


## Before you begin:
 - Install PSQL & pgdump on your system ([macOS](https://stackoverflow.com/a/55564878/2188186), [Windows](https://www.enterprisedb.com/downloads/postgres-postgresql-downloads) or [Linux](https://www.postgresql.org/download/linux/ubuntu/)).
 - Edit project data in the scripts you will use. 
 - Run the script you selected 😊

## Migrating everything:
``` bash
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

pg_dump postgres://postgres:"$OLD_DB_PASS"@"$OLD_DB_URL":6543/postgres \
  --clean \
  --if-exists \
  --quote-all-identifiers \
  --exclude-table-data 'storage.objects' \
  --exclude-schema 'extensions|graphql|graphql_public|net|pgbouncer|pgsodium|pgsodium_masks|realtime|supabase_functions|storage|pg_*|information_schema' \
  --schema '*' > dump.sql 

sed "${sedi[@]}" -e 's/^DROP SCHEMA IF EXISTS "auth";$/-- DROP SCHEMA IF EXISTS "auth";/' dump.sql
sed "${sedi[@]}" -e's/^DROP SCHEMA IF EXISTS "storage";$/-- DROP SCHEMA IF EXISTS "storage";/' dump.sql
sed "${sedi[@]}" -e 's/^CREATE SCHEMA "auth";$/-- CREATE SCHEMA "auth";/' dump.sql
sed "${sedi[@]}" -e 's/^CREATE SCHEMA "storage";$/-- CREATE SCHEMA "storage";/' dump.sql
sed "${sedi[@]}" -e 's/^ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin"/-- ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin"/' dump.sql
psql postgres://postgres:"$NEW_DB_PASS"@"$NEW_DB_URL":6543/postgres --file dump.sql 
```
[Download](https://raw.githubusercontent.com/mansueli/Supa-Migrate/main/migrate_project.sh) the script above.

## Migrating Schema Only (everything but data):

``` bash
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

pg_dump postgres://postgres:"$OLD_DB_PASS"@"$OLD_DB_URL":6543/postgres \
  --clean \
  --if-exists \
  --schema-only \
  --quote-all-identifiers \
  --exclude-table-data 'storage.objects' \
  --exclude-schema 'extensions|graphql|graphql_public|net|pgbouncer|pgsodium|pgsodium_masks|realtime|supabase_functions|storage|pg_*|information_schema' \
  --schema '*' > dump.sql 

sed "${sedi[@]}" -e 's/^DROP SCHEMA IF EXISTS "auth";$/-- DROP SCHEMA IF EXISTS "auth";/' dump.sql
sed "${sedi[@]}" -e's/^DROP SCHEMA IF EXISTS "storage";$/-- DROP SCHEMA IF EXISTS "storage";/' dump.sql
sed "${sedi[@]}" -e 's/^CREATE SCHEMA "auth";$/-- CREATE SCHEMA "auth";/' dump.sql
sed "${sedi[@]}" -e 's/^CREATE SCHEMA "storage";$/-- CREATE SCHEMA "storage";/' dump.sql
sed "${sedi[@]}" -e 's/^ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin"/-- ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin"/' dump.sql
psql postgres://postgres:"$NEW_DB_PASS"@"$NEW_DB_URL":6543/postgres --file dump.sql
```
[Download](https://raw.githubusercontent.com/mansueli/Supa-Migrate/main/migrate_schema.sh) the script above.

> **Note** 
>
> You can display the output to console by adding an extra `-x` to the first line of the script. 
>
> Example:
> ```
> #!/usr/bin/env bash -x
> ```
