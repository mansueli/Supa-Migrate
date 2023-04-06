#!/usr/bin/env python3
from supabase import create_client
import os

# creating the client for the project
supabase_client = create_client(os.environ['SUPABASE_URL'], os.environ['SERVICE_ROLE_KEY'])

# Iterate through buckets
buckets = supabase_client.storage().list_buckets()
for bucket in buckets:
    print("Copying objects from "+bucket.name)
    objects = supabase_client.storage().from_(bucket.name).list()
    for obj in objects:
        print(obj['name'])
        try:
            with open(obj['name'], 'wb+') as f:
                res = supabase_client.storage().from_(bucket.name).download(obj['name'])
                f.write(res)
                f.close()
        except Exception as e:
            print("error downloading "+ str(e))
