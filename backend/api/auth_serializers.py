from rest_framework import serializers
from .models import CustomerProfile, SellerProfile


class CustomerRegisterSerializer(serializers.Serializer):
    first_name = serializers.CharField(max_length=100)
    last_name = serializers.CharField(max_length=100)
    email = serializers.EmailField()
    phone_number = serializers.CharField(max_length=15, required=False, allow_blank=True)
    password = serializers.CharField(min_length=6, write_only=True)

    def validate_email(self, value):
        if CustomerProfile.objects.filter(email=value).exists():
            raise serializers.ValidationError('Bu e-posta adresi zaten kullanılıyor.')
        return value

    def validate_phone_number(self, value):
        if value and CustomerProfile.objects.filter(phone_number=value).exists():
            raise serializers.ValidationError('Bu telefon numarası zaten kullanılıyor.')
        return value


class SellerRegisterSerializer(serializers.Serializer):
    first_name = serializers.CharField(max_length=100)
    last_name = serializers.CharField(max_length=100)
    email = serializers.EmailField()
    phone_number = serializers.CharField(max_length=15, required=False, allow_blank=True)
    password = serializers.CharField(min_length=6, write_only=True)
    company_name = serializers.CharField(max_length=200)
    tax_number = serializers.CharField(max_length=20, required=False, allow_blank=True, default='')

    def validate_email(self, value):
        if SellerProfile.objects.filter(email=value).exists():
            raise serializers.ValidationError('Bu e-posta adresi zaten kullanılıyor.')
        return value

    def validate_phone_number(self, value):
        if value and SellerProfile.objects.filter(phone_number=value).exists():
            raise serializers.ValidationError('Bu telefon numarası zaten kullanılıyor.')
        return value


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField()


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
