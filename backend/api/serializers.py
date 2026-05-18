from rest_framework import serializers
from .models import CustomerProfile, SellerProfile, Category, Plant, Medicine, SellerInventory, Notification


class CustomerProfileSerializer(serializers.ModelSerializer):
    account_type = serializers.CharField(read_only=True)
    full_name = serializers.CharField(read_only=True)

    class Meta:
        model = CustomerProfile
        fields = ['id', 'account_id', 'account_type', 'first_name', 'last_name',
                  'full_name', 'email', 'phone_number', 'created_at']


class SellerProfileSerializer(serializers.ModelSerializer):
    account_type = serializers.CharField(read_only=True)
    full_name = serializers.CharField(read_only=True)

    class Meta:
        model = SellerProfile
        fields = ['id', 'account_id', 'account_type', 'first_name', 'last_name',
                  'full_name', 'email', 'phone_number', 'company_name',
                  'tax_number', 'created_at']


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = '__all__'


class PlantSerializer(serializers.ModelSerializer):
    category = CategorySerializer(read_only=True)
    class Meta:
        model = Plant
        fields = '__all__'


class MedicineSerializer(serializers.ModelSerializer):
    category = CategorySerializer(read_only=True)
    class Meta:
        model = Medicine
        fields = '__all__'


class SellerInventorySerializer(serializers.ModelSerializer):
    medicine = MedicineSerializer(read_only=True)
    class Meta:
        model = SellerInventory
        fields = ['id', 'seller', 'medicine', 'price', 'stock_quantity', 'stock_status', 'last_updated']
        read_only_fields = ['stock_status']


class InventoryUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = SellerInventory
        fields = ['price', 'stock_quantity']


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = '__all__'
