import os
import django

# 1. Django ayarlarını yükle
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from api.models import Plant, Medicine

def print_all_records():
    plants = Plant.objects.all()
    meds = Medicine.objects.all()

    print("\n" + "="*80)
    print(f"BİTKİ ÇÖZÜMLERİ (Toplam: {plants.count()})")
    print("="*80)
    print(f"{'ID':<5} | {'BİTKİ ADI':<20} | {'HASTALIK/ZARARLI':<30} | {'ETKEN MADDE'}")
    print("-"*80)
    for p in plants:
        print(f"{p.id:<5} | {p.plant_name[:20]:<20} | {p.disease_name[:30]:<30} | {p.active_ingredient}")

    print("\n" + "="*80)
    print(f"RUHSATLI İLAÇLAR (Toplam: {meds.count()})")
    print("="*80)
    print(f"{'ID':<5} | {'İLAÇ ADI':<20} | {'ETKEN MADDE':<30} | {'FORMÜLASYON'}")
    print("-"*80)
    for m in meds:
        print(f"{m.id:<5} | {m.name[:20]:<20} | {m.active_ingredient[:30]:<30} | {m.formulation}")

if __name__ == "__main__":
    print_all_records()