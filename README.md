# Supa-Migrate
Migrating schema &amp; data between supabase projects.
You can use the following Python notebook for full migration:

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
  --exclude-schema 'extensions|graphql|graphql_public|net|tiger|pgbouncer|vault|realtime|supabase_functions|storage|pg*|information_schema' \
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

## Migrating Objects (Python):
Alternatively, feel free to use the colab that does both migrations:
[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/mansueli/Supa-Migrate/blob/main/Migrate_Project_%26_Storage.ipynb)

> **Note** 
> The Storage migration script requires [supabase-py](https://pypi.org/project/supabase/).

> **Warning** 
> You still need to re-create the RLS policies for the buckets.

``` python
#!/usr/bin/env python3
#Edit here:
OLD_DB_URL='https://old_project_ref.supabase.co'
NEW_DB_URL='https://new_project_ref.supabase.co'
OLD_SERVICE_KEY = 'eyJ0000J9.eyJQ.oPyK-LSECRET-aC1I'
NEW_SERVICE_KEY = 'eyJ0000J9.eyJpSERVICE_ROLE.d4tffFJoc8iHsk_KEY'

# Script:
from supabase import create_client
import os
filedata = ''

#creating the clients for the old & new projects
old_supabase_client = create_client(OLD_DB_URL, OLD_SERVICE_KEY)
new_supabase_client = create_client(NEW_DB_URL, NEW_SERVICE_KEY)

#Create all buckets
buckets = old_supabase_client.storage().list_buckets()
for bucket in buckets:
    print("Copying objects from "+bucket.name)
    objects = old_supabase_client.storage().from_(bucket.name).list()
    try:
      new_supabase_client.storage().create_bucket(bucket.name, public=bucket.public)
    except:
      print("unable to create bucket")
    for obj in objects:
        print(obj['name'])
        try:
          with open(obj['name'], 'wb+') as f:
            res = old_supabase_client.storage().from_(bucket.name).download(obj['name'])
            f.write(res)
            f.close()
        except Exception as e: 
            print("error downloading "+ str(e))
        try:
          with open(obj['name'], 'rb+') as f:
            res = new_supabase_client.storage().from_(bucket.name).upload(obj['name'], obj['name'])
          # Delete file after uploading it
          if os.path.exists(os.path.abspath(obj['name'])):
              os.remove(os.path.abspath(obj['name']))
        except Exception as e: 
          print("error uploading | " + str(e))
```
[Download](https://raw.githubusercontent.com/mansueli/Supa-Migrate/main/migrate_objects.py) the script above.

# Backup of DB & storage files:

You can use the following colab to download your storage objects and the DB.sql data:
[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/mansueli/Supa-Migrate/blob/main/Backup_Project_%26_Storage.ipynb)

``` bash
#!/usr/bin/env bash

#Edit here:
OLD_DB_URL=db.old_project_ref.supabase.co
OLD_DB_PASS=secret_password_here

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
  --exclude-schema 'extensions|graphql|graphql_public|net|tiger|pgbouncer|vault|realtime|supabase_functions|storage|pg*|information_schema' \
  --schema '*' > dump.sql 

sed "${sedi[@]}" -e 's/^DROP SCHEMA IF EXISTS "auth";$/-- DROP SCHEMA IF EXISTS "auth";/' dump.sql
sed "${sedi[@]}" -e's/^DROP SCHEMA IF EXISTS "storage";$/-- DROP SCHEMA IF EXISTS "storage";/' dump.sql
sed "${sedi[@]}" -e 's/^CREATE SCHEMA "auth";$/-- CREATE SCHEMA "auth";/' dump.sql
sed "${sedi[@]}" -e 's/^CREATE SCHEMA "storage";$/-- CREATE SCHEMA "storage";/' dump.sql
sed "${sedi[@]}" -e 's/^ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin"/-- ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin"/' dump.sql
```
[Download](https://raw.githubusercontent.com/mansueli/Supa-Migrate/main/backup_database.sh) the script above.

