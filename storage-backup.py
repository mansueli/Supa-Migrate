#!/usr/bin/env python3
import os
from supabase import create_client, Client

SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_SERVICE_ROLE = os.environ.get("SUPABASE_SERVICE_ROLE")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE)
buckets = supabase.storage.list_buckets()
for bucket in buckets:
    print("Copying objects from "+bucket.name)
    objects = supabase.storage.from_(bucket.name).list()
    folder = str(bucket.name)
    if not os.path.exists(folder):
        os.mkdir(folder)
    for obj in objects:
        print(obj['name'])
        try:
            with open(folder+'/'+obj['name'], 'wb+') as f:
                res = supabase.storage.from_(bucket.name).download(obj['name'])
                f.write(res)
                f.close()
        except Exception as e:
            print("error downloading "+ str(e))
