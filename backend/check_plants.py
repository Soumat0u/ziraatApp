import os, django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from api.models import Plant
from collections import Counter

names = list(Plant.objects.values_list('plant_name', flat=True))
c = Counter(names)
print(f'Unique plants: {len(c)}')
for name, count in c.most_common(15):
    print(f'  {name}: {count} kayit')

# Sample one plant
p = Plant.objects.first()
if p:
    print(f'\nOrnek: plant={p.plant_name}, disease={p.disease_name}, ingredient={p.active_ingredient}')
