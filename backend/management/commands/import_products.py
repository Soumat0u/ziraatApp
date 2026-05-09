import json
from django.core.management.base import BaseCommand
from your_app.models import Product, Category

class Command(BaseCommand):
    def handle(self, *args, **options):
        with open('bku_database.json', 'r', encoding='utf-8') as f:
            data = json.load(f)
            for item in data:
                # Kategoriyi bul veya oluştur
                category, _ = Category.objects.get_or_create(name=item['category'])
                # Ürünü veritabanına kaydet
                Product.objects.update_or_create(
                    name=item['name'],
                    defaults={
                        'active_ingredient': item['active_ingredient'],
                        'category': category,
                        'usage_instructions': item.get('usage_instructions', ''),
                    }
                )
        self.stdout.write(self.style.SUCCESS('Veriler başarıyla PostgreSQL'e aktarıldı!'))