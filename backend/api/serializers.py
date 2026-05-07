from rest_framework import serializers
from .models import User, Category, Product, SellerInventory, Notification

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'role', 'phone_number', 'company_name']

class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = '__all__'

class ProductSerializer(serializers.ModelSerializer):
    category = CategorySerializer(read_only=True)
    class Meta:
        model = Product
        fields = '__all__'

class SellerInventorySerializer(serializers.ModelSerializer):
    product = ProductSerializer(read_only=True)
    class Meta:
        model = SellerInventory
        fields = ['id', 'seller', 'product', 'price', 'stock_quantity', 'stock_status', 'last_updated']
        read_only_fields = ['stock_status']

class InventoryUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = SellerInventory
        fields = ['price', 'stock_quantity']

class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = '__all__'
