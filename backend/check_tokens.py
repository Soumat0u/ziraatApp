import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from api.models import CustomerProfile, SellerProfile, AuthToken

def check_tokens():
    print("\n--- AUTH TOKENS ---")
    tokens = AuthToken.objects.all()
    for t in tokens:
        print(f"Token: {t.token[:8]}... | Account ID: {t.account_id} | Type: {t.account_type} | Profile ID: {t.profile_id} | Created: {t.created_at}")

    print("\n--- CUSTOMERS ---")
    customers = CustomerProfile.objects.all()
    for c in customers:
        print(f"ID: {c.id} | Account ID: {c.account_id} | Name: {c.full_name} | Email: {c.email} | Phone: {c.phone_number}")

    print("\n--- SELLERS ---")
    sellers = SellerProfile.objects.all()
    for s in sellers:
        print(f"ID: {s.id} | Account ID: {s.account_id} | Company: {s.company_name} | Email: {s.email} | Phone: {s.phone_number}")

if __name__ == "__main__":
    check_tokens()
