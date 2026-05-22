from rest_framework import serializers
from decimal import Decimal
from .models import CustomerProfile, SellerProfile, Category, Plant, Medicine, SellerInventory, Notification, Debt


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
                  'tax_number', 'address', 'created_at']


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


class StoreListSerializer(serializers.ModelSerializer):
    product_count = serializers.IntegerField(read_only=True)

    class Meta:
        model = SellerProfile
        fields = ['id', 'company_name', 'phone_number', 'address', 'product_count']


class InventoryUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = SellerInventory
        fields = ['price', 'stock_quantity']


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = '__all__'


# ─── Veresiye (Borç) Serializer'ları ─────────────────────────────────
class DebtSellerInfoSerializer(serializers.ModelSerializer):
    full_name = serializers.CharField(read_only=True)

    class Meta:
        model = SellerProfile
        fields = ['id', 'account_id', 'full_name', 'company_name', 'phone_number']


class DebtCustomerInfoSerializer(serializers.ModelSerializer):
    full_name = serializers.CharField(read_only=True)

    class Meta:
        model = CustomerProfile
        fields = ['id', 'account_id', 'full_name', 'phone_number']


class DebtItemSerializer(serializers.ModelSerializer):
    class Meta:
        from .models import DebtItem
        model = DebtItem
        fields = ['id', 'medicine', 'name', 'quantity', 'price', 'total_price']

class DebtSerializer(serializers.ModelSerializer):
    seller_info = DebtSellerInfoSerializer(source='seller', read_only=True)
    customer_info = DebtCustomerInfoSerializer(source='customer', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    items = DebtItemSerializer(many=True, read_only=True)

    class Meta:
        model = Debt
        fields = [
            'id', 'seller', 'customer', 'seller_info', 'customer_info',
            'amount', 'description', 'due_date', 'status', 'status_display',
            'created_at', 'updated_at', 'customer_confirmed_at', 'items', 'approval_token',
        ]
        read_only_fields = ['seller', 'customer', 'status', 'created_at', 'updated_at', 'customer_confirmed_at']


class DebtCreateItemSerializer(serializers.Serializer):
    medicine_id = serializers.IntegerField(required=False, allow_null=True)
    name = serializers.CharField(max_length=255)
    quantity = serializers.IntegerField(min_value=1)
    price = serializers.DecimalField(max_digits=12, decimal_places=2, required=False, allow_null=True)

class DebtCreateSerializer(serializers.Serializer):
    """Satıcı borç oluştururken kullanılacak serializer"""
    customer_identifier = serializers.CharField(max_length=50)
    items = DebtCreateItemSerializer(many=True)
    due_date = serializers.DateField()
    description = serializers.CharField(max_length=500, required=False, allow_blank=True, default='')
