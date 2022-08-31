# Supa-Migrate
Migrating schema &amp; data between supabase projects. You still need to [migrate storage objects](https://supabase.com/docs/guides/database#migrate-storage-objects).

## Before you begin:
 - Install PSQL & pgdump on your system ([macOS](https://stackoverflow.com/a/55564878/2188186), [Windows](https://www.enterprisedb.com/downloads/postgres-postgresql-downloads) or [Linux](https://www.postgresql.org/download/linux/ubuntu/)).
 - Run `ALTER ROLE postgres SUPERUSER` in the [SQL Editor](https://app.supabase.com/project/_/sql) in both projects.
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
PGPASSWORD="$OLD_DB_PASS" pg_dump --clean --if-exists --quote-all-identifiers -h $OLD_DB_URL -U postgres > dump.sql -p 6543
PGPASSWORD="$OLD_DB_PASS" psql -U postgres -h $OLD_DB_URL -d postgres -p 6543 -c 'ALTER ROLE postgres NOSUPERUSER'
PGPASSWORD="$NEW_DB_PASS" psql -h $NEW_DB_URL -U postgres -f dump.sql -p 6543
PGPASSWORD="$NEW_DB_PASS" psql -U postgres -h $NEW_DB_URL -d postgres -p 6543 -c 'TRUNCATE storage.objects'
PGPASSWORD="$NEW_DB_PASS" psql -U postgres -h $NEW_DB_URL -d postgres -p 6543 -c 'ALTER ROLE postgres NOSUPERUSER'
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
PGPASSWORD=$OLD_DB_PASS pg_dump --clean --if-exists --schema-only --quote-all-identifiers -h $OLD_DB_URL -U postgres > dump.sql
PGPASSWORD="$OLD_DB_PASS" psql -U postgres -h $OLD_DB_URL -d postgres -p 6543 -c 'ALTER ROLE postgres NOSUPERUSER'
PGPASSWORD="$NEW_DB_PASS" psql -h $NEW_DB_URL -U postgres -f dump.sql -p 6543
PGPASSWORD="$NEW_DB_PASS" psql -U postgres -h $NEW_DB_URL -d postgres -p 6543 -c 'TRUNCATE storage.objects'
PGPASSWORD="$NEW_DB_PASS" psql -U postgres -h $NEW_DB_URL -d postgres -p 6543 -c 'ALTER ROLE postgres NOSUPERUSER'
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
