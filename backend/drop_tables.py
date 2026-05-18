import os, django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.db import connection

tables = [
    'api_sellerinventory',
    'api_plant',
    'api_medicine',
    'api_product', # Old one
    'api_chathistory',
    'api_notification',
    'api_user_groups',
    'api_user_user_permissions',
    'api_user',
    'api_category',
]

with connection.cursor() as cursor:
    for table in tables:
        try:
            cursor.execute(f"DROP TABLE IF EXISTS {table} CASCADE;")
            print(f"Dropped {table}")
        except Exception as e:
            print(f"Error dropping {table}: {e}")
