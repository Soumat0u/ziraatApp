import string
import random
from django.db import models
from django.contrib.auth.hashers import make_password, check_password
from django.core.validators import MinValueValidator


def _generate_company_code():
    """6 haneli büyük harf ve rakamdan oluşan rastgele firma kodu üretir."""
    chars = string.ascii_uppercase + string.digits
    while True:
        code = ''.join(random.choices(chars, k=6))
        # Çakışma kontrolü — import döngüsünden kaçınmak için lazy kontrol
        from api.models import Company
        if not Company.objects.filter(secret_code=code).exists():
            return code


class CustomerProfile(models.Model):
    """Müşteri hesap tablosu — ID'ler C ile başlar (C00001, C00002, ...)"""
    account_id = models.CharField(max_length=10, unique=True, blank=True, editable=False)
    first_name = models.CharField(max_length=100)
    last_name = models.CharField(max_length=100)
    email = models.EmailField(unique=True)
    phone_number = models.CharField(max_length=15, unique=True, null=True, blank=True)
    password_hash = models.CharField(max_length=255)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'customers'
        verbose_name = 'Müşteri'
        verbose_name_plural = 'Müşteriler'

    def save(self, *args, **kwargs):
        # İlk kayıtta şifreyi hashle
        if not self.pk and not self.password_hash.startswith(('pbkdf2_', 'argon2', 'bcrypt')):
            self.password_hash = make_password(self.password_hash)
        super().save(*args, **kwargs)
        # Kayıt sonrası account_id oluştur
        if not self.account_id:
            self.account_id = f'C{self.pk:05d}'
            super().save(update_fields=['account_id'])

    def check_password(self, raw_password):
        return check_password(raw_password, self.password_hash)

    @property
    def full_name(self):
        return f'{self.first_name} {self.last_name}'

    @property
    def account_type(self):
        return 'CUSTOMER'

    def __str__(self):
        return f'{self.account_id} - {self.full_name} (Müşteri)'


class Company(models.Model):
    """İşletme/Firma modeli — her firmanın kendine ait bir gizli kodu ve kasası vardır."""
    name = models.CharField(max_length=200)
    secret_code = models.CharField(max_length=6, unique=True, editable=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'companies'
        verbose_name = 'Firma'
        verbose_name_plural = 'Firmalar'

    def save(self, *args, **kwargs):
        if not self.secret_code:
            self.secret_code = _generate_company_code()
        super().save(*args, **kwargs)

    def __str__(self):
        return f'{self.name} ({self.secret_code})'


class SellerProfile(models.Model):
    """Satıcı hesap tablosu — ID'ler S ile başlar (S00001, S00002, ...)"""
    account_id = models.CharField(max_length=10, unique=True, blank=True, editable=False)
    first_name = models.CharField(max_length=100)
    last_name = models.CharField(max_length=100)
    email = models.EmailField(unique=True)
    phone_number = models.CharField(max_length=15, unique=True, null=True, blank=True)
    password_hash = models.CharField(max_length=255)
    company_name = models.CharField(max_length=200)
    tax_number = models.CharField(max_length=20, blank=True, default='')
    address = models.CharField(max_length=500, blank=True, default='')
    company = models.ForeignKey('Company', on_delete=models.SET_NULL, null=True, blank=True, related_name='employees')
    is_owner = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'sellers'
        verbose_name = 'Satıcı'
        verbose_name_plural = 'Satıcılar'

    def save(self, *args, **kwargs):
        if not self.pk and not self.password_hash.startswith(('pbkdf2_', 'argon2', 'bcrypt')):
            self.password_hash = make_password(self.password_hash)
        super().save(*args, **kwargs)
        if not self.account_id:
            self.account_id = f'S{self.pk:05d}'
            super().save(update_fields=['account_id'])

    def check_password(self, raw_password):
        return check_password(raw_password, self.password_hash)

    @property
    def full_name(self):
        return f'{self.first_name} {self.last_name}'

    @property
    def account_type(self):
        return 'SELLER'

    def __str__(self):
        return f'{self.account_id} - {self.company_name} (Satıcı)'


# ─── Auth Token ──────────────────────────────────────────────────────
class AuthToken(models.Model):
    """Basit token tabanlı kimlik doğrulama"""
    token = models.CharField(max_length=64, unique=True)
    account_type = models.CharField(max_length=10)  # CUSTOMER veya SELLER
    account_id = models.CharField(max_length=10)
    profile_id = models.PositiveIntegerField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'auth_tokens'

    def __str__(self):
        return f'Token: {self.account_id} ({self.account_type})'


# ─── Ürün Modelleri (mevcut — değişiklik yok) ────────────────────────
class Category(models.Model):
    name = models.CharField(max_length=100)
    icon_name = models.CharField(max_length=50, blank=True)

    def __str__(self):
        return self.name


class Plant(models.Model):
    plant_name = models.CharField(max_length=255)  # Bitki Adı
    disease_name = models.CharField(max_length=255) # Hastalık/Zararlı Adı
    active_ingredient = models.CharField(max_length=255) # Etken Madde
    dosage = models.CharField(max_length=255, null=True, blank=True)
    category = models.ForeignKey(Category, on_delete=models.CASCADE)

    def __str__(self):
        return f"{self.plant_name} - {self.disease_name}"


class Medicine(models.Model):
    name = models.CharField(max_length=255) # ilaç
    active_ingredient = models.CharField(max_length=255) # aktif madde
    formulation = models.CharField(max_length=255) # formulasyon
    category = models.ForeignKey(Category, on_delete=models.CASCADE)

    def __str__(self):
        return self.name


class SellerInventory(models.Model):
    seller = models.ForeignKey(SellerProfile, on_delete=models.CASCADE)
    medicine = models.ForeignKey(Medicine, on_delete=models.CASCADE)
    price = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(0.0)])
    stock_quantity = models.PositiveIntegerField(default=0)
    last_updated = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('seller', 'medicine')

    @property
    def stock_status(self):
        if self.stock_quantity == 0:
            return 'Yok'
        elif self.stock_quantity <= 10:
            return 'Azalıyor'
        return 'Var'

    def __str__(self):
        return f"{self.seller.company_name} - {self.medicine.name}"


class Notification(models.Model):
    # Bildirimler her iki hesap türüne de gidebilir
    account_type = models.CharField(max_length=10)  # CUSTOMER veya SELLER
    account_id = models.CharField(max_length=10)
    title = models.CharField(max_length=100)
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Bildirim: {self.account_id} - {self.title}"


class ChatHistory(models.Model):
    account_type = models.CharField(max_length=10)
    account_id = models.CharField(max_length=10)
    question = models.TextField()
    answer = models.TextField()
    product_context = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"Sohbet: {self.account_id} - {self.question[:50]}"


class Debt(models.Model):
    """Veresiye (borç) takip modeli — satıcı-müşteri arası borç kaydı"""
    STATUS_CHOICES = [
        ('PENDING_CUSTOMER', 'Müşteri Onayı Bekliyor'),
        ('ACTIVE', 'Aktif'),
        ('PAID', 'Ödendi'),
        ('REJECTED', 'Reddedildi'),
    ]

    seller = models.ForeignKey(
        SellerProfile, on_delete=models.CASCADE, related_name='debts_as_seller'
    )
    customer = models.ForeignKey(
        CustomerProfile, on_delete=models.CASCADE, related_name='debts_as_customer'
    )
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    description = models.CharField(max_length=500, blank=True, default='')
    due_date = models.DateField()
    status = models.CharField(
        max_length=20, choices=STATUS_CHOICES, default='PENDING_CUSTOMER'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    customer_confirmed_at = models.DateTimeField(null=True, blank=True)
    approval_token = models.CharField(max_length=64, unique=True, blank=True, null=True)

    def save(self, *args, **kwargs):
        if not self.approval_token:
            import uuid
            self.approval_token = uuid.uuid4().hex
        super().save(*args, **kwargs)


    class Meta:
        db_table = 'debts'
        ordering = ['-created_at']
        verbose_name = 'Veresiye'
        verbose_name_plural = 'Veresiyeler'

    def __str__(self):
        return f"{self.seller.company_name} → {self.customer.full_name}: {self.amount} TL ({self.get_status_display()})"


class DebtItem(models.Model):
    debt = models.ForeignKey(Debt, on_delete=models.CASCADE, related_name='items')
    medicine = models.ForeignKey(Medicine, on_delete=models.SET_NULL, null=True, blank=True)
    name = models.CharField(max_length=255) # İlaç adı veya Ek Ücret açıklaması
    quantity = models.PositiveIntegerField(default=1)
    price = models.DecimalField(max_digits=12, decimal_places=2) # Birim fiyat
    total_price = models.DecimalField(max_digits=12, decimal_places=2) # quantity * price
    
    class Meta:
        db_table = 'debt_items'
        verbose_name = 'Veresiye Kalemi'
        verbose_name_plural = 'Veresiye Kalemleri'
        
    def __str__(self):
        return f"{self.name} x {self.quantity} = {self.total_price} TL"


class CashRegister(models.Model):
    """Her firmanın tek bir kasası vardır."""
    company = models.OneToOneField(Company, on_delete=models.CASCADE, related_name='cash_register')
    balance = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'cash_registers'
        verbose_name = 'Kasa'
        verbose_name_plural = 'Kasalar'

    def __str__(self):
        return f'{self.company.name} Kasası — ₺{self.balance}'


class CashTransaction(models.Model):
    """Kasa hareketleri — gelir ve gider kayıtları."""
    TRANSACTION_TYPES = [
        ('INCOME', 'Gelir'),
        ('EXPENSE', 'Gider'),
    ]

    cash_register = models.ForeignKey(CashRegister, on_delete=models.CASCADE, related_name='transactions')
    employee = models.ForeignKey(SellerProfile, on_delete=models.SET_NULL, null=True, related_name='cash_transactions')
    transaction_type = models.CharField(max_length=10, choices=TRANSACTION_TYPES)
    amount = models.DecimalField(max_digits=12, decimal_places=2, validators=[MinValueValidator(0.01)])
    description = models.CharField(max_length=500)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'cash_transactions'
        ordering = ['-created_at']
        verbose_name = 'Kasa Hareketi'
        verbose_name_plural = 'Kasa Hareketleri'

    def __str__(self):
        prefix = '+' if self.transaction_type == 'INCOME' else '-'
        return f'{prefix}₺{self.amount} — {self.description}'
