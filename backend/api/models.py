from django.db import models
from django.contrib.auth.models import AbstractUser
from django.core.validators import MinValueValidator

class User(AbstractUser):
    ROLE_CHOICES = (
        ('CUSTOMER', 'Müşteri'),
        ('SELLER', 'Satıcı'),
    )
    role = models.CharField(max_length=10, choices=ROLE_CHOICES, default='CUSTOMER')
    phone_number = models.CharField(max_length=15, unique=True, null=True, blank=True)
    company_name = models.CharField(max_length=100, blank=True, null=True)

    def __str__(self):
        return f"{self.username} - {self.get_role_display()}"

class Category(models.Model):
    name = models.CharField(max_length=100)
    icon_name = models.CharField(max_length=50, blank=True)

    def __str__(self):
        return self.name

class Product(models.Model):
    name = models.CharField(max_length=200)
    active_ingredient = models.CharField(max_length=200)
    category = models.ForeignKey(Category, related_name='products', on_delete=models.CASCADE)
    usage_instructions = models.TextField(help_text="Teknik kullanım talimatları")
    image = models.ImageField(upload_to='product_images/', null=True, blank=True)

    def __str__(self):
        return self.name

class SellerInventory(models.Model):
    seller = models.ForeignKey(User, on_delete=models.CASCADE, limit_choices_to={'role': 'SELLER'})
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    price = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(0.0)])
    stock_quantity = models.PositiveIntegerField(default=0)
    last_updated = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('seller', 'product')

    @property
    def stock_status(self):
        if self.stock_quantity == 0:
            return 'Yok'
        elif self.stock_quantity <= 10:
            return 'Azalıyor'
        return 'Var'

    def __str__(self):
        return f"{self.seller.company_name} - {self.product.name}"

class Notification(models.Model):
    user = models.ForeignKey(User, related_name='notifications', on_delete=models.CASCADE)
    title = models.CharField(max_length=100)
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Bildirim: {self.user.username} - {self.title}"

class ChatHistory(models.Model):
    user = models.ForeignKey(User, related_name='chat_history', on_delete=models.CASCADE)
    question = models.TextField()
    answer = models.TextField()
    product_context = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"Sohbet: {self.user.username} - {self.question[:50]}"
