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

pg_dump "$OLD_SUPAVISOR_URL" \
  --quote-all-identifiers \
  --no-owner --no-privileges \
  --data-only \
  --exclude-schema 'extensions|graphql|graphql_public|net|tiger|pgbouncer|vault|realtime|supabase_functions|storage|pg*|information_schema' \
  --schema '*' > data_dump.sql

sed "${sedi[@]}" -e 's/^DROP SCHEMA IF EXISTS "auth";$/-- DROP SCHEMA IF EXISTS "auth";/' dump.sql
sed "${sedi[@]}" -e's/^DROP SCHEMA IF EXISTS "storage";$/-- DROP SCHEMA IF EXISTS "storage";/' dump.sql
sed "${sedi[@]}" -e 's/^CREATE SCHEMA "auth";$/-- CREATE SCHEMA "auth";/' dump.sql
sed "${sedi[@]}" -e 's/^CREATE SCHEMA "storage";$/-- CREATE SCHEMA "storage";/' dump.sql
sed "${sedi[@]}" -e 's/^ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin"/-- ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin"/' dump.sql
psql "$NEW_SUPAVISOR_URL" --file dump.sql
psql "$NEW_SUPAVISOR_URL" --file data_dump.sql
```
[Download](https://raw.githubusercontent.com/mansueli/Supa-Migrate/main/migrate_project.sh) the script above.

## Migrating Schema Only (everything but data):

``` bash
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

> Dependencies (for MIME identification):
> ### Debian/Ubuntu
```
sudo apt-get install libmagic1
```
### Windows
You'll need DLLs for libmagic.  @julian-r maintains a pypi package with the DLLs, you can fetch it with:
```
pip install python-magic-bin
```
### OSX
- When using Homebrew: `brew install libmagic`
- When using macports: `port install file`

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
import re
import magic
filedata = ''

# Function to recursively copy files and directories
def copy_files(old_client, new_client, bucket_name, path):
    objects = old_client.storage.from_(bucket_name).list(path=path)
    
    for obj in objects:
        if obj['metadata'] is None:  # It's a directory
            subdirectory = os.path.join(path, obj['name'])
            # Create the directory if it doesn't exist
            if not os.path.exists(subdirectory):
                os.makedirs(subdirectory)
            copy_files(old_client, new_client, bucket_name, subdirectory)
        else:
            try:
                print(f"Downloading {path}/{obj['name']}")
                # Download file
                download_path = os.path.join(path, obj['name'])
                with open(download_path, 'wb') as f:
                    res = old_client.storage.from_(bucket_name).download(f"{path}/{obj['name']}")
                    f.write(res)
                
                # Get MIME type
                mime_type = magic.from_file(os.path.abspath(download_path), mime=True)
                
                # Upload file
                print(f"Uploading file {path}/{obj['name']}")
                with open(download_path, 'rb') as file_object:
                    print(f"File object type: {type(file_object)}")
                    print(f"File object content: {file_object.read()}")
                    new_client.storage.from_(bucket_name).upload(f"{path}/{obj['name']}", file_object, file_options={"content-type": mime_type, "x-upsert": 'true'})
                
                # Delete local file after uploading
                os.remove(download_path)
            except Exception as e:
                print("Error: ", e)

# Main function
def main():
    # Create clients for the old & new projects
    old_supabase_client = create_client(OLD_DB_URL, OLD_SERVICE_KEY)
    new_supabase_client = create_client(NEW_DB_URL, NEW_SERVICE_KEY)

    # Create all buckets
    buckets = old_supabase_client.storage.list_buckets()
    for bucket in buckets:
        print("Copying objects from", bucket.name)
        try:
            # Check if the bucket exists before creating it
            if not new_supabase_client.storage.get_bucket(bucket.name):
                new_supabase_client.storage.create_bucket(bucket.name, options={"public": bucket.public})
        except Exception as e:
            print("Unable to create bucket:", e)
        
        # Copy files recursively
        copy_files(old_supabase_client, new_supabase_client, bucket.name, "")

if __name__ == "__main__":
    main()
```
[Download](https://raw.githubusercontent.com/mansueli/Supa-Migrate/main/migrate_objects.py) the script above.

# Backup of DB & storage files:

You can use the following colab to download your storage objects and the DB.sql data:
[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/mansueli/Supa-Migrate/blob/main/Backup_Project_%26_Storage.ipynb)

``` bash
#!/usr/bin/env bash

#Edit here:
SUPAVISOR_URL=postgres://postgres.oldproject:[YOUR-PASSWORD]@aws-0-us-east-1.pooler.supabase.com:5432/postgres

#Script:
# Default case for Linux sed, just use "-i"
sedi=(-i)
case "$(uname)" in
  # For macOS, use two parameters
  Darwin*) sedi=(-i "")
esac

pg_dump "$SUPAVISOR_URL" \
  --if-exists \
  --clean \
  --quote-all-identifiers \
  --schema-only \
  --no-owner --no-privileges \
  --exclude-schema 'extensions|graphql|graphql_public|net|tiger|pgbouncer|vault|realtime|supabase_functions|storage|pg*|information_schema' \
  --schema '*' > dump.sql

pg_dump "$SUPAVISOR_URL" \
  --quote-all-identifiers \
  --no-owner --no-privileges \
  --data-only \
  --exclude-schema 'extensions|graphql|graphql_public|net|tiger|pgbouncer|vault|realtime|supabase_functions|storage|pg*|information_schema' \
  --schema '*' > data_dump.sql

sed "${sedi[@]}" -e 's/^DROP SCHEMA IF EXISTS "auth";$/-- DROP SCHEMA IF EXISTS "auth";/' dump.sql
sed "${sedi[@]}" -e's/^DROP SCHEMA IF EXISTS "storage";$/-- DROP SCHEMA IF EXISTS "storage";/' dump.sql
sed "${sedi[@]}" -e 's/^CREATE SCHEMA "auth";$/-- CREATE SCHEMA "auth";/' dump.sql
sed "${sedi[@]}" -e 's/^CREATE SCHEMA "storage";$/-- CREATE SCHEMA "storage";/' dump.sql
sed "${sedi[@]}" -e 's/^ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin"/-- ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin"/' dump.sql
```
[Download](https://raw.githubusercontent.com/mansueli/Supa-Migrate/main/backup_database.sh) the script above.

