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
