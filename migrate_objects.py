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
