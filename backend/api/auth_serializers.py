from rest_framework import serializers
from .models import CustomerProfile, SellerProfile, Company


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
    address = serializers.CharField(max_length=500, required=False, allow_blank=True, default='')
    company_code = serializers.CharField(max_length=6, required=False, allow_blank=True, default='')

    def validate_email(self, value):
        if SellerProfile.objects.filter(email=value).exists():
            raise serializers.ValidationError('Bu e-posta adresi zaten kullanılıyor.')
        return value

    def validate_phone_number(self, value):
        if value and SellerProfile.objects.filter(phone_number=value).exists():
            raise serializers.ValidationError('Bu telefon numarası zaten kullanılıyor.')
        return value

    def validate_company_code(self, value):
        if value:
            value = value.upper().strip()
            if not Company.objects.filter(secret_code=value).exists():
                raise serializers.ValidationError('Geçersiz firma kodu. Lütfen doğru kodu girdiğinizden emin olun.')
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
    company_code = serializers.SerializerMethodField()
    company_name_display = serializers.SerializerMethodField()

    class Meta:
        model = SellerProfile
        fields = ['id', 'account_id', 'account_type', 'first_name', 'last_name',
                  'full_name', 'email', 'phone_number', 'company_name',
                  'tax_number', 'address', 'created_at', 'is_owner',
                  'company_code', 'company_name_display']

    def get_company_code(self, obj):
        if obj.company:
            return obj.company.secret_code
        return None

    def get_company_name_display(self, obj):
        if obj.company:
            return obj.company.name
        return obj.company_name
