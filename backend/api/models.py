from django.db import models
from django.contrib.auth.hashers import make_password, check_password
from django.core.validators import MinValueValidator


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
