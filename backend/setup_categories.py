import os, django, random
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from api.models import Category, Plant, Medicine, SellerProfile, SellerInventory

# 1. Kategorileri oluştur
cat_data = [
    ('Gübreler', 'leaf'),
    ('İlaçlar', 'bug'),
    ('Tohumlar', 'grain'),
    ('Katkılar', 'flask'),
    ('Ruhsatlı Ürünler', 'verified'),
]
categories = {}
for name, icon in cat_data:
    cat, _ = Category.objects.get_or_create(name=name, defaults={'icon_name': icon})
    categories[name] = cat
    print(f'Kategori: {cat.name} (id={cat.id})')

# 2. Bitki Çözümleri (Plant)
gubre_items = [
    ('Domates', 'Besin Noksanlığı', 'NPK 20-20-20', '3 kg/da'),
    ('Salatalık', 'Demir Klorozu', 'Şelatlı Demir EDTA', '100 g/da'),
]
ilac_items = [
    ('Domates', 'Domates Sarı Yaprak Kıvırcıklık', 'İmidakloprid 350 SC', '0.5 ml/lt'),
    ('Biber', 'Kırmızı Örümcek', 'Abamektin 1.8 EC', '0.75 ml/lt'),
]

for p_name, d_name, ingr, dosage in gubre_items + ilac_items:
    Plant.objects.get_or_create(
        plant_name=p_name,
        disease_name=d_name,
        active_ingredient=ingr,
        category=categories['Gübreler' if (p_name, d_name, ingr, dosage) in gubre_items else 'İlaçlar'],
        defaults={'dosage': dosage}
    )

# 3. Ruhsatlı İlaçlar (Medicine)
sample_meds = [
    ('FENOMİR', 'Fenpyroximate', 'SC'),
    ('ADAMA', 'Abamectin', 'EC'),
    ('CONFIDOR', 'Imidacloprid', 'SC'),
    ('REGLONE', 'Diquat', 'SL'),
]

created_meds = []
for name, ingr, form in sample_meds:
    m, _ = Medicine.objects.get_or_create(
        name=name,
        active_ingredient=ingr,
        formulation=form,
        category=categories['Ruhsatlı Ürünler']
    )
    created_meds.append(m)

# 4. Test Satıcısı ve Envanteri
from django.contrib.auth.hashers import make_password
seller, created = SellerProfile.objects.get_or_create(
    email='test@satici.com',
    defaults={
        'first_name': 'Test',
        'last_name': 'Satıcı',
        'password_hash': make_password('password123'),
        'company_name': 'Ziraat Bayi A.Ş.',
        'phone_number': '5551234567',
    }
)

for m in created_meds:
    SellerInventory.objects.get_or_create(
        seller=seller,
        medicine=m,
        defaults={
            'price': random.randint(100, 1500) + 0.99,
            'stock_quantity': random.randint(10, 100)
        }
    )

print("Veritabanı başarıyla güncellendi.")
